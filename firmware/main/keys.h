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

// Key states from the Hall sensors' readings (../switch_hall/spec.md §6), without hardware:
// the driver (keyio.c) feeds every key's 12-bit reading in with keys_update(). Each key has
// a rest reading, tracked slowly while it is released, and a span (bottom - rest, signed by
// the magnet's pole). A key goes on CONF_KEY_ACTUATE_COUNTS above its rest (in the span's
// direction) and off again below CONF_KEY_RELEASE_COUNTS, whatever its full travel: it
// switches at the top of its stroke. travel = (reading - rest) / span is only shown. The
// interface of the changed keys is that of ../ctrl/keyio.h.

#ifndef KEYS_H
#define KEYS_H

#include "keymap.h"
#include <stdbool.h>
#include <stdint.h>

typedef enum key_state_t { OFF = 0, ON } key_state_t;

// all keys released, no rest reading yet, default span
void keys_init(void);

// a new reading of key `i`; the first one sets its rest
void keys_update(int i, uint16_t reading);

// current state of key `i`
key_state_t keys_get_state(int i);

// travel of key `i`, 0 at rest .. 1 at the bottom (may run a little beyond)
float keys_get_travel(int i);

// next key whose state changed since it was last returned; false if none
bool keys_get_next_changed(int *i, key_state_t *state);

// forget the returned states: keys held now are returned as changed (ON) again
// (../ctrl keyio_clear_states: after a change of the bellows' direction)
void keys_clear_states(void);

// calibration: between begin and end every key is pressed to the bottom once; end takes
// each key's largest deviation from rest as its span (its sign: the direction a press
// moves the reading; its size: the travel shown). Returns the number of keys whose
// deviation was large enough (more than a quarter of the default span).
void keys_cal_begin(void);
int keys_cal_end(void);

// spans, to keep them over a restart (NVS)
void keys_get_spans(int16_t spans[KEYMAP_NUM_KEYS]);
void keys_set_spans(const int16_t spans[KEYMAP_NUM_KEYS]);

#endif
