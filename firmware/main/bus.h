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

// The two I2C buses (pins.h): bus 1 to the discant through the contacts, bus 2 in the bass.

#ifndef BUS_H
#define BUS_H

#include "driver/i2c_master.h"
#include "esp_err.h"
#include <stdbool.h>
#include <stdint.h>

esp_err_t bus_init(void);

// a device on bus 1 or 2
esp_err_t bus_add(int bus, uint8_t addr, i2c_master_dev_handle_t *dev);

// does a device answer at addr?
bool bus_probe(int bus, uint8_t addr);

// one register byte (ADS7128 / NAU7802 style: write opcode/register, then data)
esp_err_t bus_write(i2c_master_dev_handle_t dev, const uint8_t *data, size_t len);
esp_err_t bus_write_read(i2c_master_dev_handle_t dev, const uint8_t *w, size_t wlen, uint8_t *r, size_t rlen);
esp_err_t bus_read(i2c_master_dev_handle_t dev, uint8_t *r, size_t rlen);

#endif
