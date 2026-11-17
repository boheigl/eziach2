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

// What ../ctrl/main_loop.c did, without hardware: from the force and the key changes to
// notes and volume. One call of instrument_step() is one pass of the old loop; the notes go
// out through the callbacks (the synthesizer and USB-MIDI).

#ifndef INSTRUMENT_H
#define INSTRUMENT_H

#include <stdbool.h>
#include <stdint.h>

typedef struct instrument_out_t {
	void (*note)(uint8_t channel, uint8_t note, uint8_t velocity, bool on);
	void (*volume)(uint8_t volume);   // 0..127, every channel (MIDI CC 7)
	void (*all_notes_off)(void);
} instrument_out_t;

void instrument_init(const instrument_out_t *out);

// one pass: the force in newtons (positive = push), then every changed key (keys.h)
void instrument_step(float newtons);

bool instrument_is_push(void);
bool instrument_is_adjusting(void);
int instrument_transpose(void);

#endif
