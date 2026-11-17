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

#include "bus.h"
#include "pins.h"

#define TIMEOUT_MS 10

static i2c_master_bus_handle_t buses[2];

static esp_err_t new_bus(int port, int sda, int scl, i2c_master_bus_handle_t *h) {
	i2c_master_bus_config_t c = {
		.i2c_port = port,
		.sda_io_num = sda,
		.scl_io_num = scl,
		.clk_source = I2C_CLK_SRC_DEFAULT,
		.glitch_ignore_cnt = 7,
		.flags.enable_internal_pullup = false,   // 2k2 on the main board, 4k7 on the key boards
	};
	return i2c_new_master_bus(&c, h);
}

esp_err_t bus_init(void) {
	esp_err_t e = new_bus(0, PIN_SDA1, PIN_SCL1, &buses[0]);
	if(e != ESP_OK) return e;
	return new_bus(1, PIN_SDA2, PIN_SCL2, &buses[1]);
}

esp_err_t bus_add(int bus, uint8_t addr, i2c_master_dev_handle_t *dev) {
	i2c_device_config_t c = {
		.dev_addr_length = I2C_ADDR_BIT_LEN_7,
		.device_address = addr,
		.scl_speed_hz = I2C_FREQ_HZ,
	};
	return i2c_master_bus_add_device(buses[bus - 1], &c, dev);
}

bool bus_probe(int bus, uint8_t addr) {
	return i2c_master_probe(buses[bus - 1], addr, TIMEOUT_MS) == ESP_OK;
}

esp_err_t bus_write(i2c_master_dev_handle_t dev, const uint8_t *data, size_t len) {
	return i2c_master_transmit(dev, data, len, TIMEOUT_MS);
}

esp_err_t bus_write_read(i2c_master_dev_handle_t dev, const uint8_t *w, size_t wlen, uint8_t *r, size_t rlen) {
	return i2c_master_transmit_receive(dev, w, wlen, r, rlen, TIMEOUT_MS);
}

esp_err_t bus_read(i2c_master_dev_handle_t dev, uint8_t *r, size_t rlen) {
	return i2c_master_receive(dev, r, rlen, TIMEOUT_MS);
}
