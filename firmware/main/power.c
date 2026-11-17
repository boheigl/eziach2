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

#include "power.h"
#include "pins.h"
#include "driver/gpio.h"
#include "esp_adc/adc_cali.h"
#include "esp_adc/adc_cali_scheme.h"
#include "esp_adc/adc_oneshot.h"
#include "esp_log.h"

static const char *TAG = "power";

static adc_oneshot_unit_handle_t adc;
static adc_cali_handle_t cali = NULL;
#define VBAT_CH ADC_CHANNEL_0     // IO1 = ADC1 channel 0

esp_err_t power_init(void) {
	gpio_config_t in = {
		.pin_bit_mask = (1ULL << PIN_DISCANT_ON) | (1ULL << PIN_VBUS),
		.mode = GPIO_MODE_INPUT,
	};
	gpio_config(&in);
	gpio_config_t led = {.pin_bit_mask = 1ULL << PIN_LOW_BAT, .mode = GPIO_MODE_OUTPUT};
	gpio_config(&led);
	gpio_set_level(PIN_LOW_BAT, 0);

	adc_oneshot_unit_init_cfg_t u = {.unit_id = ADC_UNIT_1};
	esp_err_t e = adc_oneshot_new_unit(&u, &adc);
	if(e != ESP_OK) return e;
	adc_oneshot_chan_cfg_t c = {.atten = ADC_ATTEN_DB_12, .bitwidth = ADC_BITWIDTH_DEFAULT};
	if((e = adc_oneshot_config_channel(adc, VBAT_CH, &c)) != ESP_OK) return e;
	adc_cali_curve_fitting_config_t cc = {.unit_id = ADC_UNIT_1, .chan = VBAT_CH,
	                                      .atten = ADC_ATTEN_DB_12, .bitwidth = ADC_BITWIDTH_DEFAULT};
	if(adc_cali_create_scheme_curve_fitting(&cc, &cali) != ESP_OK) {
		ESP_LOGW(TAG, "no ADC calibration: battery voltage approximate");
		cali = NULL;
	}
	return ESP_OK;
}

bool power_discant_on(void) {
	return gpio_get_level(PIN_DISCANT_ON);
}

bool power_usb(void) {
	return gpio_get_level(PIN_VBUS);
}

int power_battery_mv(void) {
	int raw = 0, mv = 0;
	if(adc_oneshot_read(adc, VBAT_CH, &raw) != ESP_OK)
		return -1;
	if(cali)
		adc_cali_raw_to_voltage(cali, raw, &mv);
	else
		mv = raw * 3100 / 4095;
	return mv * 2;                // 1M / 1M divider
}

void power_update(void) {
	int mv = power_battery_mv();
	gpio_set_level(PIN_LOW_BAT, !power_usb() && mv > 0 && mv < POWER_LOW_BAT_MV);
}
