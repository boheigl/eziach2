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
#define CC1_CH  ADC_CHANNEL_1     // IO2
#define CC2_CH  ADC_CHANNEL_3     // IO4
static int offer_ma = 0, limit_ma = 500;

// the charger's mode (BQ24074, SLUS810 Table 7-2): EN2 low / EN1 high 500 mA, EN2 high /
// EN1 low the ILIM limit (1.5k: about 1.0 A)
static void set_limit(int ma) {
	bool high = ma >= 1000;
	gpio_set_level(PIN_CHG_EN1, !high);
	gpio_set_level(PIN_CHG_EN2, high);
	limit_ma = high ? 1000 : 500;
}

esp_err_t power_init(void) {
	gpio_config_t in = {
		.pin_bit_mask = (1ULL << PIN_DISCANT_ON) | (1ULL << PIN_VBUS),
		.mode = GPIO_MODE_INPUT,
	};
	gpio_config(&in);
	gpio_config_t out = {.pin_bit_mask = (1ULL << PIN_LOW_BAT) | (1ULL << PIN_CHG_EN1) | (1ULL << PIN_CHG_EN2),
	                     .mode = GPIO_MODE_OUTPUT};
	gpio_set_level(PIN_CHG_EN1, 1);     // as the pulls: 500 mA
	gpio_set_level(PIN_CHG_EN2, 0);
	gpio_config(&out);
	gpio_set_level(PIN_LOW_BAT, 0);

	adc_oneshot_unit_init_cfg_t u = {.unit_id = ADC_UNIT_1};
	esp_err_t e = adc_oneshot_new_unit(&u, &adc);
	if(e != ESP_OK) return e;
	adc_oneshot_chan_cfg_t c = {.atten = ADC_ATTEN_DB_12, .bitwidth = ADC_BITWIDTH_DEFAULT};
	if((e = adc_oneshot_config_channel(adc, VBAT_CH, &c)) != ESP_OK) return e;
	if((e = adc_oneshot_config_channel(adc, CC1_CH, &c)) != ESP_OK) return e;
	if((e = adc_oneshot_config_channel(adc, CC2_CH, &c)) != ESP_OK) return e;
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

static int read_mv(adc_channel_t ch) {
	int raw = 0, mv = 0;
	if(adc_oneshot_read(adc, ch, &raw) != ESP_OK)
		return -1;
	if(cali)
		adc_cali_raw_to_voltage(cali, raw, &mv);   // the curve is VBAT's channel's; close enough for CC
	else
		mv = raw * 3100 / 4095;
	return mv;
}

int power_battery_mv(void) {
	int mv = read_mv(VBAT_CH);
	return mv < 0 ? -1 : mv * 2;  // 1M / 1M divider
}

// The source's Rp against our 5.1k Rd (USB Type-C spec, vRd ranges): 0.25-0.61 V default
// USB power (500 mA on USB 2), 0.70-1.16 V 1.5 A, 1.31-2.04 V 3.0 A. The higher of CC1/CC2
// is the connected one.
int power_usb_offer_ma(void) {
	return offer_ma;
}

int power_charge_limit_ma(void) {
	return limit_ma;
}

void power_update(void) {
	int mv = power_battery_mv();
	gpio_set_level(PIN_LOW_BAT, !power_usb() && mv > 0 && mv < POWER_LOW_BAT_MV);
	int cc = read_mv(CC1_CH), cc2 = read_mv(CC2_CH);
	if(cc2 > cc) cc = cc2;
	offer_ma = !power_usb() || cc < 200 ? 0 : cc < 660 ? 500 : cc < 1230 ? 1500 : 3000;
	int want = offer_ma >= 1500 ? 1000 : 500;
	if(want != limit_ma) {
		set_limit(want);
		ESP_LOGI(TAG, "USB offers %d mA (CC %d mV): charger input %d mA", offer_ma, cc, limit_ma);
	}
}
