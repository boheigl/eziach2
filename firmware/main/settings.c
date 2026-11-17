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

#include "settings.h"
#include "force.h"
#include "keymap.h"
#include "keys.h"
#include "esp_log.h"
#include "nvs.h"
#include "nvs_flash.h"

static const char *TAG = "settings";
#define NS "eziach"

esp_err_t settings_init(void) {
	esp_err_t e = nvs_flash_init();
	if(e == ESP_ERR_NVS_NO_FREE_PAGES || e == ESP_ERR_NVS_NEW_VERSION_FOUND) {
		nvs_flash_erase();
		e = nvs_flash_init();
	}
	if(e != ESP_OK) return e;
	nvs_handle_t h;
	if(nvs_open(NS, NVS_READONLY, &h) != ESP_OK) {
		ESP_LOGI(TAG, "nothing stored yet: keys uncalibrated, force sign from the config");
		return ESP_OK;
	}
	int16_t spans[KEYMAP_NUM_KEYS];
	size_t n = sizeof(spans);
	if(nvs_get_blob(h, "spans", spans, &n) == ESP_OK && n == sizeof(spans)) {
		keys_set_spans(spans);
		ESP_LOGI(TAG, "key calibration loaded");
	}
	int8_t sign;
	if(nvs_get_i8(h, "sign", &sign) == ESP_OK)
		force_set_sign(sign);
	nvs_close(h);
	return ESP_OK;
}

esp_err_t settings_save(void) {
	nvs_handle_t h;
	esp_err_t e = nvs_open(NS, NVS_READWRITE, &h);
	if(e != ESP_OK) return e;
	int16_t spans[KEYMAP_NUM_KEYS];
	keys_get_spans(spans);
	if((e = nvs_set_blob(h, "spans", spans, sizeof(spans))) == ESP_OK &&
	   (e = nvs_set_i8(h, "sign", (int8_t)force_get_sign())) == ESP_OK)
		e = nvs_commit(h);
	nvs_close(h);
	return e;
}
