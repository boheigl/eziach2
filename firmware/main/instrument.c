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

#include "instrument.h"
#include "config.h"
#include "force.h"
#include "keys.h"
#include "mapping.h"
#include <math.h>
#include <string.h>

static const instrument_out_t *out = 0;
static const int quit_keys[CONF_NUM_QUIT_KEYS] = CONF_QUIT_KEYS;

static bool is_push = true;
static bool adjusting = false;
static float old_force = 0.0f;
static int8_t transpose = CONF_TRANSPOSE;
// how many held keys sound each note: chords share tones (bass), so a note goes off
// only when the last key that sounds it is released (../ctrl switched it off at once).
// A second key sounding the same note keeps the first one's tuning.
static uint8_t sounding[16][128];

static void all_notes_off(void) {
	memset(sounding, 0, sizeof(sounding));
	out->all_notes_off();
}

static void note(uint8_t channel, int n, bool on, float cents) {
	if(n < 0 || n > 127 || channel > 15)
		return;
	uint8_t *c = &sounding[channel][n];
	if(on) {
		if((*c)++ == 0)
			out->note(channel, n, CONF_VELOCITY, true, cents);
	} else if(*c > 0) {
		if(--(*c) == 0)
			out->note(channel, n, 0, false, 0.0f);
	}
}

// ../ctrl synthesizer_update: every tone of the key, transposed
static void update_key(int key_index, key_state_t state) {
	mapping_entry_t e = mapping_map(is_push, key_index);
	for(int i = 0; i < e.nkeys; i++)
		note(e.channel, e.keys[i] + transpose, state == ON, e.cents[i]);
}

static bool is_quit_keys_pressed(void) {
	for(int i = 0; i < CONF_NUM_QUIT_KEYS; i++)
		if(keys_get_state(quit_keys[i]) == OFF)
			return false;
	return true;
}

void instrument_init(const instrument_out_t *o) {
	out = o;
	is_push = true;
	adjusting = false;
	old_force = 0.0f;
	transpose = CONF_TRANSPOSE;
	memset(sounding, 0, sizeof(sounding));
}

void instrument_step(float newtons) {
	int k;
	key_state_t s;
	if(adjusting) {
		// adjustment mode (../ctrl): a key of the transposition row sets it, the quit keys
		// together end it
		while(keys_get_next_changed(&k, &s)) {
			const keymap_key_t *kk = &keymap_keys[k];
			if(s == ON && kk->board == 0 && kk->row == CONF_TRANSPOSE_ROW)
				transpose = kk->key - 1;
			if(is_quit_keys_pressed()) {
				adjusting = false;
				break;
			}
		}
		return;
	}

	// the force: smoothed; its sign is the direction once it passes the threshold
	float force = newtons * CONF_NEW_FORCE_PORTION + old_force * (1.0f - CONF_NEW_FORCE_PORTION);
	old_force = force;
	if(fabsf(force) > CONF_FORCE_THRESHOLD) {
		bool new_is_push = force > 0.0f;
		if(new_is_push != is_push) {
			// the other direction: other tones; held keys come back as changed (ON)
			all_notes_off();
			is_push = new_is_push;
			keys_clear_states();
		}
	}
	float level = fabsf(force_level(force));
	out->volume(level > 127.0f ? 127 : (uint8_t)level);

	while(keys_get_next_changed(&k, &s)) {
		update_key(k, s);
		if(is_quit_keys_pressed()) {
			all_notes_off();
			adjusting = true;
			return;
		}
	}
}

bool instrument_is_push(void) { return is_push; }
bool instrument_is_adjusting(void) { return adjusting; }
int instrument_transpose(void) { return transpose; }
