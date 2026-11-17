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

// The sound: ZiachMini.sf2 from its flash partition through TinySoundFont, rendered in a
// task of its own into I2S and the DAC. The interface is ../ctrl/synthesizer.h's (which
// drove FluidSynth); calls only queue events, the audio task applies them.

#ifndef SYNTHESIZER_H
#define SYNTHESIZER_H

#include "esp_err.h"
#include <stdbool.h>
#include <stdint.h>

esp_err_t synthesizer_init(void);

// cents: the tone's tuning against tempered (note on only)
void synthesizer_note_update(uint8_t channel, uint8_t key, uint8_t velocity, bool on_off, float cents);

// 0..127 on every channel, scaled by its channel volume (../ctrl: MIDI CC 7)
void synthesizer_change_volume(uint8_t volume);

void synthesizer_all_notes_off(void);

// render time of one block against its length, average and peak since the last call (0..1)
void synthesizer_load(float *avg, float *peak);

// voices sounding now
int synthesizer_voices(void);

#endif
