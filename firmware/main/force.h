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

// The bellows' force from the load cells, without hardware (the NAU7802 driver, nau7802.c,
// feeds the sum of both cells' counts in). ../ctrl/forceio.c read an angle; the dead band
// and the separate push / pull gains are its math. Positive is push.

#ifndef FORCE_H
#define FORCE_H

#include <stdbool.h>
#include <stdint.h>

void force_init(void);

// set zero to this reading (at start: the average of a few readings, nothing touched)
void force_tare(int32_t counts);

// follow a slow drift of the zero while nothing is played (strain_gauge/spec.md: re-tare
// while no key is pressed); `portion` of the difference per call
void force_track_zero(int32_t counts, float portion);

// which way is push: +1 or -1 (CONF_FORCE_SIGN at start; set once by a push, kept in NVS)
void force_set_sign(int sign);
int force_get_sign(void);

// the force in newtons, signed: positive = push
float force_newtons(int32_t counts);

// ../ctrl's level: 0 inside the dead band, beyond it (|F| - offset) x gain, signed
float force_level(float newtons);

#endif
