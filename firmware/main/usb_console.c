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

#include "usb_console.h"
#include "esp_console.h"
#include "esp_log.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "hal/usb_serial_jtag_ll.h"
#include "soc/rtc_cntl_reg.h"
#include "tinyusb.h"
#include "tinyusb_cdc_acm.h"
#include "tinyusb_console.h"
#include <stdio.h>
#include <string.h>

static const char *TAG = "usb console";

#define LINE 128
// what the CDC callbacks (TinyUSB's task) hand to the console task: a command line, or one
// of these
#define MSG_OPEN     "\x01open"
#define MSG_CLOSE    "\x01close"
#define MSG_DOWNLOAD "\x01download"
static QueueHandle_t msgs;
static char line[LINE];
static int len = 0;

static void post(const char *m) {
	char b[LINE];
	strlcpy(b, m, sizeof(b));
	xQueueSend(msgs, b, 0);
}

static void echo(const char *s) {
	tinyusb_cdcacm_write_queue(TINYUSB_CDC_ACM_0, (const uint8_t *)s, strlen(s));
	tinyusb_cdcacm_write_flush(TINYUSB_CDC_ACM_0, 0);
}

static void on_rx(int itf, cdcacm_event_t *ev) {
	(void)ev;
	uint8_t b[64];
	size_t n = 0;
	if(tinyusb_cdcacm_read(itf, b, sizeof(b), &n) != ESP_OK)
		return;
	for(size_t i = 0; i < n; i++) {
		char c = (char)b[i];
		if(c == '\r' || c == '\n') {
			if(c == '\n' && len == 0) continue;      // the LF of a CR LF
			line[len] = 0;
			echo("\r\n");
			post(line);
			len = 0;
		} else if(c == '\b' || c == 0x7F) {
			if(len > 0) { len--; echo("\b \b"); }
		} else if(c >= ' ' && len < LINE - 1) {
			line[len++] = c;
			char e[2] = {c, 0};
			echo(e);
		}
	}
}

static void on_line_state(int itf, cdcacm_event_t *ev) {
	(void)itf;
	post(ev->line_state_changed_data.dtr ? MSG_OPEN : MSG_CLOSE);
}

// the Arduino boards' convention: a port opened at 1200 baud asks for the bootloader
static void on_line_coding(int itf, cdcacm_event_t *ev) {
	(void)itf;
	if(ev->line_coding_changed_data.p_line_coding->bit_rate == 1200)
		post(MSG_DOWNLOAD);
}

esp_err_t usb_console_init(void) {
	msgs = xQueueCreate(4, LINE);
	if(!msgs)
		return ESP_ERR_NO_MEM;
	tinyusb_config_cdcacm_t c = {
		.cdc_port = TINYUSB_CDC_ACM_0,
		.callback_rx = on_rx,
		.callback_line_state_changed = on_line_state,
		.callback_line_coding_changed = on_line_coding,
	};
	return tinyusb_cdcacm_init(&c);
}

void usb_console_download(void) {
	ESP_LOGW(TAG, "restarting into the ROM's download mode over USB");
	vTaskDelay(pdMS_TO_TICKS(50));
	tud_disconnect();                          // the host sees the device go
	vTaskDelay(pdMS_TO_TICKS(200));
	// the chip's one USB PHY back to the USB-Serial/JTAG, which the ROM's loader speaks
	// (TinyUSB had it for the OTG controller); RTC_CNTL keeps this over the restart
	usb_serial_jtag_ll_phy_enable_external(false);
	usb_serial_jtag_ll_phy_enable_pad(true);
	// as ESP-IDF's own USB console does for its download reboot
	REG_WRITE(RTC_CNTL_OPTION1_REG, RTC_CNTL_FORCE_DOWNLOAD_BOOT);
	esp_restart();
}

static void task(void *arg) {
	(void)arg;
	bool open = false;
	char m[LINE];
	for(;;) {
		xQueueReceive(msgs, m, portMAX_DELAY);
		if(!strcmp(m, MSG_DOWNLOAD)) {
			usb_console_download();
		} else if(!strcmp(m, MSG_OPEN)) {
			if(!open && tinyusb_console_init(TINYUSB_CDC_ACM_0) == ESP_OK) {
				open = true;
				printf("\neziach console over USB (help: the commands)\neziach> ");
				fflush(stdout);
			}
		} else if(!strcmp(m, MSG_CLOSE)) {
			if(open) {
				tinyusb_console_deinit(TINYUSB_CDC_ACM_0);    // back to UART0
				open = false;
			}
		} else {
			if(m[0]) {
				int ret = 0;
				esp_err_t e = esp_console_run(m, &ret);
				if(e == ESP_ERR_NOT_FOUND) printf("unknown command: %s\n", m);
				else if(e == ESP_ERR_INVALID_ARG) ;          // only spaces
				else if(e != ESP_OK) printf("error: %s\n", esp_err_to_name(e));
			}
			printf("eziach> ");
			fflush(stdout);
		}
	}
}

void usb_console_start(void) {
	if(msgs)
		xTaskCreate(task, "usb console", 4096, NULL, 5, NULL);
}
