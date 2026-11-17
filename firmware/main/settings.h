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

// What the instrument learns once and keeps in NVS: every key's span (calibration) and which
// way the force is push.

#ifndef SETTINGS_H
#define SETTINGS_H

#include "esp_err.h"

esp_err_t settings_init(void);     // NVS up, and the stored values into keys.c and force.c
esp_err_t settings_save(void);     // the current values out of keys.c and force.c

#endif
