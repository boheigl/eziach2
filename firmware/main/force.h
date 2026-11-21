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
#include <stddef.h>
#include <stdint.h>

void force_init(void);

// set zero to this reading (at start: the average of a few readings, nothing touched)
void force_tare(int32_t counts);

// follow a slow drift of the zero while nothing is played (strain_gauge/spec.md: re-tare
// while no key is pressed); `portion` of the difference per call. Nothing while tracking
// is off.
void force_track_zero(int32_t counts, float portion);

// zero tracking on (the default after force_init) or off: off for measuring the drift
// (console `force track off`; not saved)
void force_set_tracking(bool on);
bool force_tracking(void);

// the current zero, counts (sum of both cells)
float force_zero(void);

// which way is push: +1 or -1 (CONF_FORCE_SIGN at start; set once by a push, kept in NVS)
void force_set_sign(int sign);
int force_get_sign(void);

// the force in newtons, signed: positive = push
float force_newtons(int32_t counts);

// ../ctrl's level: 0 inside the dead band, beyond it (|F| - offset) x gain, signed
float force_level(float newtons);

// The drift log (console `force log on`): the readings averaged over an interval, then
// one CSV line per interval. FORCE_LOG_HEADER names its columns: the time in ms, each
// cell's mean counts, the zero, the force in N from the two cells' mean, whether a key
// was down in the interval. Every line starts with "F," so that it can be picked out of
// a console capture (grep '^F,').
#define FORCE_LOG_HEADER "F,t_ms,cell0,cell1,zero,newtons,key"
typedef struct {
	int64_t sum[2];
	int n;
	bool key;
} force_avg_t;
void force_avg_add(force_avg_t *a, const int32_t cells[2], bool key_down);
// writes the interval's line (no newline) and starts the next interval; 0 and nothing
// written when it had no reading
int force_avg_line(force_avg_t *a, uint32_t ms, char *buf, size_t len);

#endif
