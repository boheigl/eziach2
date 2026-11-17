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

static float zero = 0.0f;   // counts at no force
static int sign = CONF_FORCE_SIGN;

void force_init(void) {
	zero = 0.0f;
	sign = CONF_FORCE_SIGN;
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
	zero += portion * ((float)counts - zero);
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
