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

#include "keyio.h"
#include "bus.h"
#include "keymap.h"
#include "keys.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "keyio";

// ADS7128 (= ADS7138's register map) [datasheet SBAS868A; to check at bring-up]
#define OP_READ  0x10   // single register read: opcode, register, then read
#define OP_WRITE 0x08   // single register write: opcode, register, data
#define OP_SET   0x18   // set bits
#define REG_SYSTEM_STATUS   0x00
#define REG_GENERAL_CFG     0x01   // bit 0 RST, bit 1 CAL (offset calibration)
#define REG_DATA_CFG        0x02   // bits 5:4 APPEND_STATUS: 01 = 4-bit channel ID after the data
#define REG_OSR_CFG         0x03
#define REG_OPMODE_CFG      0x04
#define REG_PIN_CFG         0x05   // 0: all channels analog inputs (the default)
#define REG_SEQUENCE_CFG    0x10   // bit 4 SEQ_START, bits 1:0 SEQ_MODE (01 auto)
#define REG_AUTO_SEQ_CH_SEL 0x12   // channels in the auto sequence
// ALERT_PIN_CFG (17h) stays at its default, open drain: the six ALERTs share INT

typedef struct adc_t {
	i2c_master_dev_handle_t dev;
	bool added;
} adc_t;

static adc_t adcs[KEYMAP_NUM_BOARDS][KEYMAP_NUM_ADDR];
static bool up[KEYMAP_NUM_BOARDS];
static uint16_t raw[KEYMAP_NUM_KEYS];

static esp_err_t reg_write(i2c_master_dev_handle_t d, uint8_t reg, uint8_t v) {
	uint8_t b[3] = {OP_WRITE, reg, v};
	return bus_write(d, b, 3);
}

static esp_err_t reg_read(i2c_master_dev_handle_t d, uint8_t reg, uint8_t *v) {
	uint8_t b[2] = {OP_READ, reg};
	return bus_write_read(d, b, 2, v, 1);
}

static esp_err_t init_adc(i2c_master_dev_handle_t d) {
	esp_err_t e;
	if((e = reg_write(d, REG_GENERAL_CFG, 0x01)) != ESP_OK) return e;    // reset
	vTaskDelay(pdMS_TO_TICKS(2));
	if((e = reg_write(d, REG_GENERAL_CFG, 0x02)) != ESP_OK) return e;    // offset calibration
	for(int i = 0; i < 20; i++) {
		uint8_t v = 0xFF;
		if((e = reg_read(d, REG_GENERAL_CFG, &v)) != ESP_OK) return e;
		if(!(v & 0x02)) break;
		vTaskDelay(pdMS_TO_TICKS(1));
	}
	if((e = reg_write(d, REG_PIN_CFG, 0x00)) != ESP_OK) return e;        // all analog
	if((e = reg_write(d, REG_DATA_CFG, 0x10)) != ESP_OK) return e;       // append the channel ID
	if((e = reg_write(d, REG_OSR_CFG, 0x00)) != ESP_OK) return e;        // no averaging
	if((e = reg_write(d, REG_AUTO_SEQ_CH_SEL, 0xFF)) != ESP_OK) return e;
	return reg_write(d, REG_SEQUENCE_CFG, 0x11);                         // auto sequence, start
}

esp_err_t keyio_init_board(int b) {
	int bus = b + 1;
	up[b] = false;
	for(int a = 0; a < keymap_num_adc[b]; a++) {
		uint8_t addr = keymap_adc_addr[b][a];
		adc_t *x = &adcs[b][addr - KEYMAP_ADDR_BASE];
		if(!x->added) {
			esp_err_t e = bus_add(bus, addr, &x->dev);
			if(e != ESP_OK) return e;
			x->added = true;
		}
		esp_err_t e = init_adc(x->dev);
		if(e != ESP_OK) {
			ESP_LOGW(TAG, "board %d: ADC %02Xh does not answer (%s)", b, addr, esp_err_to_name(e));
			return e;
		}
	}
	up[b] = true;
	ESP_LOGI(TAG, "board %d: %d ADCs up", b, keymap_num_adc[b]);
	return ESP_OK;
}

bool keyio_board_up(int b) {
	return up[b];
}

bool keyio_scan(void) {
	bool ok = true;
	for(int b = 0; b < KEYMAP_NUM_BOARDS; b++) {
		if(!up[b])
			continue;
		for(int a = 0; a < keymap_num_adc[b]; a++) {
			uint8_t addr = keymap_adc_addr[b][a];
			// eight frames of two bytes: 12-bit result, then the channel ID
			uint8_t d[16];
			if(bus_read(adcs[b][addr - KEYMAP_ADDR_BASE].dev, d, sizeof(d)) != ESP_OK) {
				ESP_LOGW(TAG, "board %d: ADC %02Xh lost", b, addr);
				up[b] = false;
				ok = false;
				break;
			}
			for(int i = 0; i < 8; i++) {
				uint16_t w = (d[2 * i] << 8) | d[2 * i + 1];
				int ch = w & 0x0F;
				int k = ch < KEYMAP_NUM_AIN ? keymap_by_channel[b][addr - KEYMAP_ADDR_BASE][ch] : -1;
				if(k >= 0) {
					raw[k] = w >> 4;
					keys_update(k, raw[k]);
				}
			}
		}
	}
	return ok;
}

uint16_t keyio_raw(int k) {
	return raw[k];
}
