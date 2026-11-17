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

// What the main board tells about power (../main_pcb/spec.md §2, §3): the discant plugged
// (its 3.3 V on IO40), USB there (IO41), the cell's voltage (IO1), and the red light for a
// low battery (IO42).

#ifndef POWER_H
#define POWER_H

#include "esp_err.h"
#include <stdbool.h>

#define POWER_LOW_BAT_MV 3400   // the red light below this, without USB [chosen, to be tuned]

esp_err_t power_init(void);
bool power_discant_on(void);
bool power_usb(void);
int power_battery_mv(void);

// call now and then: switches the low-battery light
void power_update(void);

#endif
