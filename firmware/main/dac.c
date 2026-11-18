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

#include "dac.h"
#include "bus.h"
#include "pins.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "dac";

// TLV320DAC3100 [datasheet SLAS671, checked 2026-11-18 field by field: P0 R4, R11-14, R27,
// R60, R63-66; P1 R31, R33, R35-37, R40-41]. Registers are (page, register).
#define ADDR 0x18

static i2c_master_dev_handle_t dev;
static bool added = false;
static int cur_page = -1;

static esp_err_t wr(int page, uint8_t reg, uint8_t v) {
	esp_err_t e;
	if(page != cur_page) {
		uint8_t p[2] = {0x00, (uint8_t)page};
		if((e = bus_write(dev, p, 2)) != ESP_OK) return e;
		cur_page = page;
	}
	uint8_t b[2] = {reg, v};
	return bus_write(dev, b, 2);
}

esp_err_t dac_init(void) {
	esp_err_t e;
	gpio_config_t g = {.pin_bit_mask = 1ULL << PIN_DAC_RESET, .mode = GPIO_MODE_OUTPUT};
	gpio_config(&g);
	gpio_set_level(PIN_DAC_RESET, 0);
	vTaskDelay(pdMS_TO_TICKS(2));
	gpio_set_level(PIN_DAC_RESET, 1);
	vTaskDelay(pdMS_TO_TICKS(2));
	if(!added) {
		if((e = bus_add(2, ADDR, &dev)) != ESP_OK) return e;
		added = true;
	}
	cur_page = -1;
	static const struct { int page; uint8_t reg, val; } seq[] = {
		{0, 0x01, 0x01},   // software reset
		{0, 0x04, 0x00},   // CODEC_CLKIN = MCLK, no PLL
		{0, 0x0B, 0x81},   // NDAC = 1, on
		{0, 0x0C, 0x82},   // MDAC = 2, on
		{0, 0x0D, 0x00},   // DOSR = 128: 12.288 MHz / (1 x 2 x 128) = 48 kHz
		{0, 0x0E, 0x80},
		{0, 0x1B, 0x00},   // I2S, 16 bit, BCLK and WCLK inputs
		{0, 0x3C, 0x01},   // processing block PRB_P1
		{1, 0x1F, 0xC4},   // headphone drivers HPL and HPR on, common mode 1.35 V
		{1, 0x21, 0x4E},   // pop removal timing
		{1, 0x23, 0x44},   // DAC left to the left mixer, right to the right
		{1, 0x28, 0x06},   // HPL driver 0 dB, unmuted
		{1, 0x29, 0x06},   // HPR driver 0 dB, unmuted
		{1, 0x24, 0x80},   // left analog volume to HPL, 0 dB
		{1, 0x25, 0x80},   // right analog volume to HPR, 0 dB
		{0, 0x3F, 0xD4},   // DAC left and right on, left data to left, right to right
		{0, 0x41, 0x00},   // digital volume 0 dB, left and right (the synth leaves the headroom)
		{0, 0x42, 0x00},
		{0, 0x40, 0x00},   // unmute
	};
	for(unsigned i = 0; i < sizeof(seq) / sizeof(seq[0]); i++) {
		if((e = wr(seq[i].page, seq[i].reg, seq[i].val)) != ESP_OK) {
			ESP_LOGW(TAG, "not answering at step %u (%s)", i, esp_err_to_name(e));
			return e;
		}
		if(i == 0)
			vTaskDelay(pdMS_TO_TICKS(2));
	}
	ESP_LOGI(TAG, "up: 48 kHz, headphones");
	return ESP_OK;
}

esp_err_t dac_set_volume_db(float db) {
	if(db > 0.0f) db = 0.0f;
	if(db < -63.5f) db = -63.5f;
	int8_t v = (int8_t)(db * 2.0f);    // 0.5 dB steps, two's complement
	esp_err_t e = wr(0, 0x41, (uint8_t)v);
	if(e != ESP_OK) return e;
	return wr(0, 0x42, (uint8_t)v);
}
