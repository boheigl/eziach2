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

#include "mapping.h"

mapping_entry_t mapping_map(bool is_push, int key_index) {
	const keymap_key_t *k = &keymap_keys[key_index];
	mapping_entry_t e = {0};
	e.nkeys = is_push ? k->n_push : k->n_pull;
	for(int i = 0; i < e.nkeys; i++) {
		e.keys[i] = is_push ? k->push[i] : k->pull[i];
		e.cents[i] = is_push ? k->push_cents[i] : k->pull_cents[i];
	}
	e.channel = k->channel;
	return e;
}

int mapping_find(uint8_t board, uint8_t row, uint8_t key) {
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) {
		const keymap_key_t *k = &keymap_keys[i];
		if(k->board == board && k->row == row && k->key == key)
			return i;
	}
	return -1;
}
