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

// The load cells' ADC (NAU7802 on the discant board, bus 1, 2Ah; ../hall_pcb/spec.md §3a):
// both half bridges, one per channel, gain 128, 320 samples/s, read in turn.

#ifndef NAU7802_H
#define NAU7802_H

#include "esp_err.h"
#include <stdbool.h>
#include <stdint.h>

esp_err_t nau7802_init(void);

// polls the chip; true when a new pair of readings is complete: *sum = cell 1 + cell 2,
// cells[] each (counts). Errors mark the chip down (nau7802_up()).
bool nau7802_poll(int32_t *sum, int32_t cells[2]);

bool nau7802_up(void);

#endif
