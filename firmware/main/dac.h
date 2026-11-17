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

// The audio DAC with headphone driver (TLV320DAC3100, bus 2, 18h; ../main_pcb/spec.md):
// I2S slave, 16 bit stereo, its clock from MCLK = 256 x 48 kHz, out to the earphone jack.

#ifndef DAC_H
#define DAC_H

#include "esp_err.h"
#include <stdint.h>

// call once MCLK runs (synthesizer_init starts I2S first)
esp_err_t dac_init(void);

// headphone volume, 0 dB .. -63.5 dB in 0.5 dB steps (digital)
esp_err_t dac_set_volume_db(float db);

#endif
