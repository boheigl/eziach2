/* eziach - electrical accordion
 *
 * Copyright (C) 2026  Benno Heigl
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "nau7802.h"
#include "bus.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "nau7802";

// registers [datasheet: Nuvoton NAU7802 Rev 1.7 (Rev 2.6 not to be had), checked 2026-11-20:
// §9.1 power-on sequence, §11.1-11.3 PU_CTRL/CTRL1/CTRL2 bit for bit, §11.9 result
// MSB first, §11.10 REG0x15 = 0x30 as §9.1's example, §11.15 PGA_CAP_EN]
#define ADDR 0x2A
#define REG_PU_CTRL 0x00   // bit 0 RR, 1 PUD, 2 PUA, 3 PUR (ready), 4 CS (start), 5 CR (data ready), 7 AVDDS
#define REG_CTRL1   0x01   // bits 2:0 gain (111 = 128)
#define REG_CTRL2   0x02   // bits 1:0 CALMOD, 2 CALS, 3 CAL_ERR, 6:4 CRS (111 = 320/s), 7 CHS (channel 2)
#define REG_ADCO_B2 0x12   // 24-bit result, MSB first
#define REG_ADC     0x15   // bits 5:4 REG_CHPS: 11 = chopper clock off (the usual setting)
#define REG_PWR     0x1C   // bit 7 PGA_CAP_EN: a capacitor across VIN2P/VIN2N, for one-channel use only
#define CRS_320 (7 << 4)
#define DISCARD 3          // conversions dropped after a channel switch, while the filter settles [chosen]

static i2c_master_dev_handle_t dev;
static bool added = false, up = false;
static int channel = 0, discard = 0;
static int32_t cell[2];

static esp_err_t wr(uint8_t reg, uint8_t v) {
	uint8_t b[2] = {reg, v};
	return bus_write(dev, b, 2);
}

static esp_err_t rd(uint8_t reg, uint8_t *v, size_t n) {
	return bus_write_read(dev, &reg, 1, v, n);
}

static esp_err_t select_channel(int ch) {
	channel = ch;
	discard = DISCARD;
	return wr(REG_CTRL2, CRS_320 | (ch ? 0x80 : 0x00));
}

static esp_err_t calibrate(void) {
	// internal offset calibration of the current channel (CALMOD 00, CALS)
	uint8_t v;
	esp_err_t e = rd(REG_CTRL2, &v, 1);
	if(e != ESP_OK) return e;
	if((e = wr(REG_CTRL2, (v & ~0x03) | 0x04)) != ESP_OK) return e;
	for(int i = 0; i < 100; i++) {
		vTaskDelay(pdMS_TO_TICKS(5));
		if((e = rd(REG_CTRL2, &v, 1)) != ESP_OK) return e;
		if(!(v & 0x04)) return (v & 0x08) ? ESP_FAIL : ESP_OK;
	}
	return ESP_ERR_TIMEOUT;
}

esp_err_t nau7802_init(void) {
	esp_err_t e;
	up = false;
	if(!added) {
		if((e = bus_add(1, ADDR, &dev)) != ESP_OK) return e;
		added = true;
	}
	if((e = wr(REG_PU_CTRL, 0x01)) != ESP_OK) goto fail;          // register reset
	vTaskDelay(pdMS_TO_TICKS(1));
	if((e = wr(REG_PU_CTRL, 0x02)) != ESP_OK) goto fail;          // digital power up
	uint8_t v = 0;
	for(int i = 0; i < 20 && !(v & 0x08); i++) {
		vTaskDelay(pdMS_TO_TICKS(1));
		if((e = rd(REG_PU_CTRL, &v, 1)) != ESP_OK) goto fail;
	}
	if(!(v & 0x08)) { e = ESP_ERR_TIMEOUT; goto fail; }
	// analog power up; AVDDS 0: AVDD from outside (+3V3 through the ferrite), the LDO off
	if((e = wr(REG_PU_CTRL, 0x06)) != ESP_OK) goto fail;
	if((e = wr(REG_CTRL1, 0x07)) != ESP_OK) goto fail;             // gain 128
	if((e = wr(REG_ADC, 0x30)) != ESP_OK) goto fail;               // chopper clock off
	// both channels in use: no PGA capacitor across channel 2's inputs (the datasheet gives
	// no default for this register, so it is set), full bias currents
	if((e = wr(REG_PWR, 0x00)) != ESP_OK) goto fail;
	vTaskDelay(pdMS_TO_TICKS(600));                                // AVDD and PGA settle
	if((e = wr(REG_PU_CTRL, 0x16)) != ESP_OK) goto fail;           // start conversions
	for(int ch = 1; ch >= 0; ch--) {                               // each channel's offset
		if((e = select_channel(ch)) != ESP_OK) goto fail;
		if((e = calibrate()) != ESP_OK) goto fail;
	}
	up = true;
	ESP_LOGI(TAG, "up: gain 128, 320/s, two channels");
	return ESP_OK;
fail:
	ESP_LOGW(TAG, "not answering (%s)", esp_err_to_name(e));
	return e;
}

bool nau7802_up(void) {
	return up;
}

bool nau7802_poll(int32_t *sum, int32_t cells[2]) {
	if(!up)
		return false;
	uint8_t v;
	if(rd(REG_PU_CTRL, &v, 1) != ESP_OK)
		goto lost;
	if(!(v & 0x20))
		return false;                                               // no new conversion
	uint8_t d[3];
	if(rd(REG_ADCO_B2, d, 3) != ESP_OK)
		goto lost;
	if(discard > 0) {
		discard--;
		return false;
	}
	int32_t x = (int32_t)((uint32_t)d[0] << 24 | (uint32_t)d[1] << 16 | (uint32_t)d[2] << 8) >> 8;   // sign-extend 24 bit
	cell[channel] = x;
	int done = channel == 1;
	if(select_channel(1 - channel) != ESP_OK)
		goto lost;
	if(done) {
		cells[0] = cell[0];
		cells[1] = cell[1];
		*sum = cell[0] + cell[1];
		return true;
	}
	return false;
lost:
	ESP_LOGW(TAG, "lost");
	up = false;
	return false;
}
