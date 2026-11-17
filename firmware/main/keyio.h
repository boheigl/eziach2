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

// The Hall keys' ADCs (ADS7128, ../hall_pcb/spec.md): every channel read in auto-sequence
// and fed into keys.c. Replaces ../ctrl's matrix scan.

#ifndef KEYIO_H
#define KEYIO_H

#include "esp_err.h"
#include <stdbool.h>

// set up the ADCs of a board (0 discant, 1 bass); fails if one does not answer
esp_err_t keyio_init_board(int board);

// read every key of the boards that are up, into keys_update(); false if a board failed
// (it is then marked down until keyio_init_board() again)
bool keyio_scan(void);

bool keyio_board_up(int board);

// last raw reading of a key (bring-up)
uint16_t keyio_raw(int key_index);

#endif
