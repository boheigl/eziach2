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

#include "keys.h"
#include "config.h"
#include <stdlib.h>

typedef struct key_t {
	float rest;            // reading at rest, tracked while released
	int16_t span;          // bottom - rest
	uint16_t last;         // last reading
	bool has_rest;         // rest set by a first reading
	key_state_t state;     // current state
	key_state_t reported;  // state last returned by keys_get_next_changed
	int16_t cal_min, cal_max;   // deviations from rest during calibration
} key_t;

static key_t keys[KEYMAP_NUM_KEYS];
static int next_scan = 0;      // where keys_get_next_changed goes on (round robin, as ../ctrl)
static bool calibrating = false;

void keys_init(void) {
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) {
		keys[i] = (key_t){0};
		keys[i].span = CONF_KEY_DEFAULT_SPAN;
	}
	next_scan = 0;
	calibrating = false;
}

float keys_get_travel(int i) {
	key_t *k = &keys[i];
	if(!k->has_rest || k->span == 0)
		return 0.0f;
	return ((float)k->last - k->rest) / (float)k->span;
}

void keys_update(int i, uint16_t reading) {
	key_t *k = &keys[i];
	k->last = reading;
	if(!k->has_rest) {
		k->rest = reading;
		k->has_rest = true;
	}
	if(calibrating) {
		int d = (int)reading - (int)(k->rest + 0.5f);
		if(d < k->cal_min) k->cal_min = d;
		if(d > k->cal_max) k->cal_max = d;
		return;            // no playing, no rest tracking while calibrating
	}
	float t = keys_get_travel(i);
	if(k->state == OFF && t >= CONF_KEY_ACTUATE)
		k->state = ON;
	else if(k->state == ON && t <= CONF_KEY_RELEASE)
		k->state = OFF;
	// the rest drifts (temperature, the soft stop): follow it while the key is clearly up
	if(k->state == OFF && t < CONF_KEY_RELEASE / 2.0f)
		k->rest += CONF_KEY_REST_FOLLOW * ((float)reading - k->rest);
}

key_state_t keys_get_state(int i) {
	return keys[i].state;
}

bool keys_get_next_changed(int *i, key_state_t *state) {
	for(int n = 0; n < KEYMAP_NUM_KEYS; n++) {
		int j = (next_scan + n) % KEYMAP_NUM_KEYS;
		key_t *k = &keys[j];
		if(k->state != k->reported) {
			k->reported = k->state;
			*i = j;
			*state = k->state;
			next_scan = (j + 1) % KEYMAP_NUM_KEYS;
			return true;
		}
	}
	return false;
}

void keys_clear_states(void) {
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++)
		keys[i].reported = OFF;
}

void keys_cal_begin(void) {
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) {
		keys[i].cal_min = keys[i].cal_max = 0;
		keys[i].state = OFF;
	}
	calibrating = true;
}

int keys_cal_end(void) {
	int good = 0;
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) {
		key_t *k = &keys[i];
		int d = (-k->cal_min > k->cal_max) ? k->cal_min : k->cal_max;
		if(abs(d) > CONF_KEY_DEFAULT_SPAN / 4) {
			k->span = d;
			good++;
		}
	}
	calibrating = false;
	return good;
}

void keys_get_spans(int16_t spans[KEYMAP_NUM_KEYS]) {
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++)
		spans[i] = keys[i].span;
}

void keys_set_spans(const int16_t spans[KEYMAP_NUM_KEYS]) {
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++)
		if(spans[i] != 0)
			keys[i].span = spans[i];
}
