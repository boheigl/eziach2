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

// Key to tones, for push and for pull (from ../ctrl/mapping.c). The table is no longer
// read at run time: tools/gen_config.py writes it into keymap.c at build time.

#ifndef MAPPING_H
#define MAPPING_H

#include "keymap.h"
#include <stdbool.h>
#include <stdint.h>

#define MAPPING_MAX_KEYS KEYMAP_MAX_NOTES
typedef struct mapping_entry_t {
	int nkeys;                         // tones of this key (a chord: up to 3)
	uint8_t keys[MAPPING_MAX_KEYS];    // MIDI note numbers
	float cents[MAPPING_MAX_KEYS];     // each tone's tuning against tempered ([tuning] in the config)
	uint8_t channel;                   // MIDI channel
} mapping_entry_t;

// tones of key `key_index` (into keymap_keys) for the bellows' direction
mapping_entry_t mapping_map(bool is_push, int key_index);

// key index of board / row / key, -1 if there is none
int mapping_find(uint8_t board, uint8_t row, uint8_t key);

#endif
