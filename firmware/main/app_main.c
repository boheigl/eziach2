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

// Start-up and the control loop (core 0): keys and force in, instrument.c, notes out to the
// synthesizer (core 1) and USB-MIDI. A console on UART0 (the TX/RX test pads) for bring-up.

#include "bus.h"
#include "config.h"
#include "force.h"
#include "instrument.h"
#include "keyio.h"
#include "keymap.h"
#include "keys.h"
#include "mapping.h"
#include "midi.h"
#include "nau7802.h"
#include "power.h"
#include "settings.h"
#include "synthesizer.h"
#include "esp_console.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *TAG = "eziach";

static const float channel_volumes[CONF_NUM_CHANNELS] = CONF_CHANNEL_VOLUMES;
static SemaphoreHandle_t lock;          // the control loop against console commands
static volatile bool log_notes = false;
static volatile float newtons = 0.0f;   // last force
static int32_t cells[2];

// ---- the instrument's output: synthesizer and USB-MIDI alike

static void out_note(uint8_t ch, uint8_t note, uint8_t vel, bool on, float cents) {
	synthesizer_note_update(ch, note, vel, on, cents);
	midi_note(ch, note, vel, on);           // USB-MIDI stays tempered
	if(log_notes)
		printf("note %s ch %d %3d %+.0f ct\n", on ? "on " : "off", ch, note, on ? cents : 0.0f);
}

static void out_volume(uint8_t v) {
	static uint8_t last = 255;
	synthesizer_change_volume(v);
	if(v != last) {
		for(int c = 0; c < CONF_NUM_CHANNELS; c++)
			midi_volume(c, (uint8_t)(v * channel_volumes[c]));
		last = v;
	}
}

static void out_all_notes_off(void) {
	synthesizer_all_notes_off();
	for(int c = 0; c < CONF_NUM_CHANNELS; c++)
		midi_all_notes_off(c);
	if(log_notes)
		printf("all notes off\n");
}

static const instrument_out_t out = {out_note, out_volume, out_all_notes_off};

// ---- the control loop

static void tare(void) {
	int64_t sum = 0;
	int n = 0;
	for(int i = 0; i < 200 && n < 16; i++) {      // 16 pairs, about 0.4 s
		int32_t s;
		if(nau7802_poll(&s, cells)) { sum += s; n++; }
		vTaskDelay(pdMS_TO_TICKS(2));
	}
	if(n)
		force_tare((int32_t)(sum / n));
	ESP_LOGI(TAG, "force tared (%d readings)", n);
}

static bool any_key_down(void) {
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++)
		if(keys_get_state(i) == ON) return true;
	return false;
}

static void control_task(void *arg) {
	(void)arg;
	TickType_t last_check = 0;
	for(;;) {
		xSemaphoreTake(lock, portMAX_DELAY);
		// the discant comes and goes with the plug: its ADCs and the gauges then too
		TickType_t now = xTaskGetTickCount();
		if(now - last_check > pdMS_TO_TICKS(500)) {
			last_check = now;
			if(!keyio_board_up(1)) keyio_init_board(1);
			if(power_discant_on()) {
				if(!keyio_board_up(0)) keyio_init_board(0);
				if(!nau7802_up() && nau7802_init() == ESP_OK) tare();
			}
			power_update();
		}
		keyio_scan();
		int32_t sum;
		if(nau7802_poll(&sum, cells)) {
			newtons = force_newtons(sum);
			// re-tare slowly while nothing is played (../strain_gauge/spec.md)
			if(!any_key_down() && fabsf(newtons) < CONF_FORCE_THRESHOLD)
				force_track_zero(sum, 0.002f);
		}
		instrument_step(newtons);
		xSemaphoreGive(lock);
		vTaskDelay(1);
	}
}

// ---- bring-up console

static int cmd_status(int argc, char **argv) {
	(void)argc; (void)argv;
	float avg, peak;
	synthesizer_load(&avg, &peak);
	printf("boards: discant %s (plug %s), bass %s; gauges %s\n", keyio_board_up(0) ? "up" : "down",
	       power_discant_on() ? "in" : "out", keyio_board_up(1) ? "up" : "down", nau7802_up() ? "up" : "down");
	printf("force %+.2f N (%s), cells %ld / %ld, sign %+d\n", newtons, instrument_is_push() ? "push" : "pull",
	       (long)cells[0], (long)cells[1], force_get_sign());
	printf("synth: %d voices, load %.0f %% avg, %.0f %% peak; MIDI %s\n", synthesizer_voices(),
	       avg * 100, peak * 100, midi_mounted() ? "mounted" : "not mounted");
	printf("battery %d mV, USB %s; transpose %d%s\n", power_battery_mv(), power_usb() ? "yes" : "no",
	       instrument_transpose(), instrument_is_adjusting() ? ", adjusting" : "");
	return 0;
}

static int cmd_keys(int argc, char **argv) {
	(void)argc; (void)argv;
	int16_t spans[KEYMAP_NUM_KEYS];
	keys_get_spans(spans);
	printf(" idx board row key  adc ain  raw  span travel\n");
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) {
		const keymap_key_t *k = &keymap_keys[i];
		printf("%4d %5s %3d %3d  %02Xh %3d %4d %5d %+5.2f %s\n", i, k->board ? "bass" : "disc", k->row, k->key,
		       k->addr, k->ain, keyio_raw(i), spans[i], keys_get_travel(i), keys_get_state(i) == ON ? "ON" : "");
	}
	return 0;
}

static int cmd_cal(int argc, char **argv) {
	if(argc == 2 && !strcmp(argv[1], "begin")) {
		xSemaphoreTake(lock, portMAX_DELAY);
		out_all_notes_off();
		keys_cal_begin();
		xSemaphoreGive(lock);
		printf("press every key once to the bottom, then: cal end\n");
	} else if(argc == 2 && !strcmp(argv[1], "end")) {
		xSemaphoreTake(lock, portMAX_DELAY);
		int good = keys_cal_end();
		xSemaphoreGive(lock);
		printf("%d of %d keys calibrated%s\n", good, KEYMAP_NUM_KEYS, settings_save() == ESP_OK ? ", saved" : "");
	} else {
		printf("cal begin | cal end\n");
	}
	return 0;
}

static int cmd_sign(int argc, char **argv) {
	(void)argc; (void)argv;
	// the player pushes now: make that positive
	float n = newtons;
	if(fabsf(n) < 2.0f) {
		printf("push harder (%.2f N now) and repeat\n", n);
		return 0;
	}
	if(n < 0)
		force_set_sign(-force_get_sign());
	printf("push is %+d%s\n", force_get_sign(), settings_save() == ESP_OK ? ", saved" : "");
	return 0;
}

static int cmd_tare(int argc, char **argv) {
	(void)argc; (void)argv;
	xSemaphoreTake(lock, portMAX_DELAY);
	tare();
	xSemaphoreGive(lock);
	return 0;
}

static int cmd_log(int argc, char **argv) {
	log_notes = argc == 2 && !strcmp(argv[1], "on");
	return 0;
}

static int cmd_play(int argc, char **argv) {
	// play a key's tones for the current direction, without pressing it (checks the table)
	if(argc != 4) { printf("play <board 0|1> <row> <key>\n"); return 0; }
	int i = mapping_find(atoi(argv[1]), atoi(argv[2]), atoi(argv[3]));
	if(i < 0) { printf("no such key\n"); return 0; }
	mapping_entry_t e = mapping_map(instrument_is_push(), i);
	out_volume(100);
	for(int n = 0; n < e.nkeys; n++) out_note(e.channel, e.keys[n] + instrument_transpose(), CONF_VELOCITY, true, e.cents[n]);
	vTaskDelay(pdMS_TO_TICKS(700));
	for(int n = 0; n < e.nkeys; n++) out_note(e.channel, e.keys[n] + instrument_transpose(), 0, false, 0.0f);
	return 0;
}

static void console_init(void) {
	esp_console_repl_t *repl = NULL;
	esp_console_repl_config_t rc = ESP_CONSOLE_REPL_CONFIG_DEFAULT();
	rc.prompt = "eziach>";
	esp_console_dev_uart_config_t uc = ESP_CONSOLE_DEV_UART_CONFIG_DEFAULT();
	ESP_ERROR_CHECK(esp_console_new_repl_uart(&uc, &rc, &repl));
	static const esp_console_cmd_t cmds[] = {
		{.command = "status", .help = "boards, force, synth load, battery", .func = cmd_status},
		{.command = "keys", .help = "every key: place, ADC input, raw reading, span, travel", .func = cmd_keys},
		{.command = "cal", .help = "cal begin | cal end: each key's span (press each once to the bottom)", .func = cmd_cal},
		{.command = "sign", .help = "while pushing: make push positive", .func = cmd_sign},
		{.command = "tare", .help = "zero the force (nothing touched)", .func = cmd_tare},
		{.command = "log", .help = "log on | off: print notes", .func = cmd_log},
		{.command = "play", .help = "play <board> <row> <key>: the key's tones for the current direction", .func = cmd_play},
	};
	for(unsigned i = 0; i < sizeof(cmds) / sizeof(cmds[0]); i++)
		ESP_ERROR_CHECK(esp_console_cmd_register(&cmds[i]));
	esp_console_register_help_command();
	ESP_ERROR_CHECK(esp_console_start_repl(repl));
}

void app_main(void) {
	ESP_LOGI(TAG, "%d keys (discant and bass)", KEYMAP_NUM_KEYS);
	keys_init();
	force_init();
	ESP_ERROR_CHECK(settings_init());
	ESP_ERROR_CHECK(power_init());
	ESP_ERROR_CHECK(bus_init());
	if(synthesizer_init() != ESP_OK)
		ESP_LOGE(TAG, "no sound");
	if(midi_init() != ESP_OK)
		ESP_LOGE(TAG, "no USB-MIDI");
	instrument_init(&out);
	lock = xSemaphoreCreateMutex();
	xTaskCreatePinnedToCore(control_task, "control", 4096, NULL, 10, NULL, 0);
	console_init();
}
