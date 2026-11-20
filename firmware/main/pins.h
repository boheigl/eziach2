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

// The ESP32-S3's pins on the main board (../main_pcb/spec.md, I/O table).

#ifndef PINS_H
#define PINS_H

// I2C bus 1, through the contacts: the discant's ADCs 10h-15h and the gauges' NAU7802 (2Ah)
#define PIN_SDA1 13
#define PIN_SCL1 14
#define PIN_INT1 21
// I2C bus 2, in the bass: the bass's ADCs 10h-12h and the DAC (18h)
#define PIN_SDA2 47
#define PIN_SCL2 48
#define PIN_INT2 38
// I2S to the DAC [2026-11-19: one module pin to the right, in the DAC's pin order, so the
// four lines run straight down to it; SDA1 took IO13]
#define PIN_MCLK 9
#define PIN_BCLK 10
#define PIN_WCLK 11
#define PIN_DOUT 12
// others
#define PIN_DAC_RESET 39     // low: DAC in reset
#define PIN_DISCANT_ON 40    // the discant's 3.3 V through 10k / 100k: high when it is plugged
#define PIN_VBUS 41          // USB's 5 V through 68k / 100k
#define PIN_CC1 2            // USB-C CC1 and CC2 (ADC1 channels 1 and 3): what the source offers
#define PIN_CC2 4
#define PIN_CHG_EN1 5        // the charger's EN1 / EN2: 500 mA (low/high by pulls) or 1 A by ILIM (high/low)
#define PIN_CHG_EN2 6
#define PIN_VBAT 1           // the cell through 1M / 1M (ADC1 channel 0)
#define PIN_LOW_BAT 42       // high: the red low-battery light

#define I2C_FREQ_HZ 400000   // ../hall_pcb/spec.md: rise times checked for 400 kHz

#endif
