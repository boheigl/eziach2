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

#include "force.h"
#include "config.h"
#include <math.h>
#include <stdio.h>
#include <string.h>

static float zero = 0.0f;   // counts at no force
static int sign = CONF_FORCE_SIGN;
static bool tracking = true;

void force_init(void) {
	zero = 0.0f;
	sign = CONF_FORCE_SIGN;
	tracking = true;
}

void force_set_sign(int s) {
	sign = s < 0 ? -1 : 1;
}

int force_get_sign(void) {
	return sign;
}

void force_tare(int32_t counts) {
	zero = (float)counts;
}

void force_track_zero(int32_t counts, float portion) {
	if(tracking)
		zero += portion * ((float)counts - zero);
}

void force_set_tracking(bool on) {
	tracking = on;
}

bool force_tracking(void) {
	return tracking;
}

float force_zero(void) {
	return zero;
}

float force_newtons(int32_t counts) {
	return sign * ((float)counts - zero) / CONF_FORCE_COUNTS_PER_NEWTON;
}

float force_level(float newtons) {
	// as ../ctrl forceio_read_force(): dead band, then a gain per direction
	if(fabsf(newtons) < CONF_FORCE_OFFSET)
		return 0.0f;
	if(newtons > 0.0f)
		return (newtons - CONF_FORCE_OFFSET) * CONF_FORCE_PUSH_GAIN;
	return (newtons + CONF_FORCE_OFFSET) * CONF_FORCE_PULL_GAIN;
}

void force_avg_add(force_avg_t *a, const int32_t cells[2], bool key_down) {
	a->sum[0] += cells[0];
	a->sum[1] += cells[1];
	a->n++;
	a->key |= key_down;
}

int force_avg_line(force_avg_t *a, uint32_t ms, char *buf, size_t len) {
	if(a->n == 0)
		return 0;
	double c0 = (double)a->sum[0] / a->n, c1 = (double)a->sum[1] / a->n;
	// newtons as force_newtons(), from the mean (not rounded to whole counts)
	double f = sign * (c0 + c1 - zero) / CONF_FORCE_COUNTS_PER_NEWTON;
	int r = snprintf(buf, len, "F,%lu,%.1f,%.1f,%.1f,%.3f,%d", (unsigned long)ms, c0, c1, (double)zero, f, a->key ? 1 : 0);
	memset(a, 0, sizeof *a);
	return r < 0 ? 0 : r;
}
