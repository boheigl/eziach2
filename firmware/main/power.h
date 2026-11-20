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
// low battery (IO42). The charger's input current follows the USB-C source: CC1/CC2 read
// (IO2, IO4) and the charger's EN1/EN2 set (IO5, IO6): 1 A from a source offering 1.5 A or
// 3 A, else 500 mA (a PC's port, an A-to-C cable).

#ifndef POWER_H
#define POWER_H

#include "esp_err.h"
#include <stdbool.h>

#define POWER_LOW_BAT_MV 3400   // the red light below this, without USB [chosen, to be tuned]

esp_err_t power_init(void);
bool power_discant_on(void);
bool power_usb(void);
int power_battery_mv(void);
// the USB source's offer in mA from its CC voltage (0: none seen) and the charger's input limit
int power_usb_offer_ma(void);
int power_charge_limit_ma(void);

// call now and then: switches the low-battery light
void power_update(void);

#endif
