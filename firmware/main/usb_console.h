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

// The console over USB: the device's second function, a serial port (CDC-ACM). A terminal on
// the computer (/dev/ttyACM0, a COM port) gets the console's commands, as on UART0; while
// it is open (DTR), the console's output goes to USB instead of UART0. Firmware over the
// same cable: `download` (or opening the port at 1200 baud) restarts into the ROM's
// download mode over the chip's USB-Serial/JTAG, for `idf.py -p /dev/ttyACM0 flash`.

#ifndef USB_CONSOLE_H
#define USB_CONSOLE_H

#include "esp_err.h"

// after tinyusb_driver_install(): the serial port (midi_init calls it)
esp_err_t usb_console_init(void);

// after the console's commands are registered: lines from USB start being run
void usb_console_start(void);

// restart into the ROM's download mode over USB; does not return
void usb_console_download(void);

#endif
