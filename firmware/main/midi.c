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

#include "midi.h"
#include "esp_log.h"
#include "tinyusb.h"
#include "tinyusb_default_config.h"
#include "usb_console.h"

// descriptors as ESP-IDF's examples peripherals/usb/device/tusb_midi and tusb_serial_device:
// one device, two functions, a serial port (the console, usb_console.c) and MIDI; with CDC
// on, esp_tinyusb's device descriptor declares the IAD a composite device needs
enum { ITF_NUM_CDC = 0, ITF_NUM_CDC_DATA, ITF_NUM_MIDI, ITF_NUM_MIDI_STREAMING, ITF_COUNT };
enum { EP_EMPTY = 0, EPNUM_CDC_NOTIF, EPNUM_CDC, EPNUM_MIDI };
#define TOTAL_LEN (TUD_CONFIG_DESC_LEN + TUD_CDC_DESC_LEN + CFG_TUD_MIDI * TUD_MIDI_DESC_LEN)

static const char *strings[6] = {
	(char[]){0x09, 0x04},   // English
	"eziach",               // manufacturer
	"eziach",               // product
	"0001",                 // serial
	"eziach MIDI",          // MIDI interface
	"eziach console",       // CDC interface
};

static const uint8_t config_desc[] = {
	TUD_CONFIG_DESCRIPTOR(1, ITF_COUNT, 0, TOTAL_LEN, 0, 100),
	TUD_CDC_DESCRIPTOR(ITF_NUM_CDC, 5, (0x80 | EPNUM_CDC_NOTIF), 8, EPNUM_CDC, (0x80 | EPNUM_CDC), 64),
	TUD_MIDI_DESCRIPTOR(ITF_NUM_MIDI, 4, EPNUM_MIDI, (0x80 | EPNUM_MIDI), 64),
};

esp_err_t midi_init(void) {
	tinyusb_config_t c = TINYUSB_DEFAULT_CONFIG();
	c.descriptor.string = strings;
	c.descriptor.string_count = sizeof(strings) / sizeof(strings[0]);
	c.descriptor.full_speed_config = config_desc;
	esp_err_t e = tinyusb_driver_install(&c);
	if(e != ESP_OK)
		return e;
	return usb_console_init();
}

bool midi_mounted(void) {
	return tud_midi_mounted();
}

static void send(uint8_t a, uint8_t b, uint8_t c) {
	if(!tud_midi_mounted())
		return;
	uint8_t m[3] = {a, b, c};
	tud_midi_stream_write(0, m, 3);
}

void midi_note(uint8_t channel, uint8_t note, uint8_t velocity, bool on) {
	send((on ? 0x90 : 0x80) | (channel & 0x0F), note & 0x7F, on ? velocity & 0x7F : 0);
}

void midi_volume(uint8_t channel, uint8_t volume) {
	send(0xB0 | (channel & 0x0F), 7, volume & 0x7F);
}

void midi_all_notes_off(uint8_t channel) {
	send(0xB0 | (channel & 0x0F), 123, 0);
}
