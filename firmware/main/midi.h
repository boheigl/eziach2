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

// USB-MIDI out (TinyUSB): the same notes and volume as the synthesizer, for a computer or app.
// midi_init() installs the USB device: MIDI and the console's serial port (usb_console.h).

#ifndef MIDI_H
#define MIDI_H

#include "esp_err.h"
#include <stdbool.h>
#include <stdint.h>

esp_err_t midi_init(void);

// all three send nothing while no USB host has the device mounted
void midi_note(uint8_t channel, uint8_t note, uint8_t velocity, bool on);
void midi_volume(uint8_t channel, uint8_t volume);      // CC 7
void midi_all_notes_off(uint8_t channel);               // CC 123

bool midi_mounted(void);

#endif
