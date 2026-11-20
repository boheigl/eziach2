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

#include "history.h"
#include "esp_attr.h"
#include "esp_core_dump.h"
#include "esp_log.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

static const char *TAG = "history";

#define SIZE  4096
#define MAGIC 0x657A6C67u        // "ezlg": the ring holds what an earlier run wrote
typedef struct {
	uint32_t magic;
	uint32_t head;               // where the next character goes
	uint32_t used;               // characters held, up to SIZE
	char buf[SIZE];
} ring_t;
static __NOINIT_ATTR ring_t ring;    // not cleared on a restart (a panic, esp_restart)
static portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;
static vprintf_like_t previous = NULL;

static void put(const char *s, size_t n) {
	portENTER_CRITICAL(&mux);
	for(size_t i = 0; i < n; i++) {
		ring.buf[ring.head] = s[i];
		ring.head = (ring.head + 1) % SIZE;
		if(ring.used < SIZE) ring.used++;
	}
	portEXIT_CRITICAL(&mux);
}

// every log line: into the ring, then on as before (the console, UART or USB)
static int hook(const char *fmt, va_list ap) {
	char line[200];
	va_list copy;
	va_copy(copy, ap);
	int n = vsnprintf(line, sizeof(line), fmt, copy);
	va_end(copy);
	if(n > 0)
		put(line, (size_t)n < sizeof(line) ? (size_t)n : sizeof(line) - 1);
	return previous ? previous(fmt, ap) : vprintf(fmt, ap);
}

static const char *reason_name(esp_reset_reason_t r) {
	switch(r) {
	case ESP_RST_POWERON:   return "power on";
	case ESP_RST_EXT:       return "reset pin";
	case ESP_RST_SW:        return "restart by the firmware";
	case ESP_RST_PANIC:     return "crash (panic)";
	case ESP_RST_INT_WDT:   return "interrupt watchdog";
	case ESP_RST_TASK_WDT:  return "task watchdog";
	case ESP_RST_WDT:       return "watchdog";
	case ESP_RST_DEEPSLEEP: return "wake from deep sleep";
	case ESP_RST_BROWNOUT:  return "brown-out (supply dropped)";
	case ESP_RST_USB:       return "USB";
	case ESP_RST_JTAG:      return "JTAG";
	default:                return "unknown";
	}
}

void history_init(void) {
	esp_reset_reason_t r = esp_reset_reason();
	bool kept = ring.magic == MAGIC && ring.head < SIZE && ring.used <= SIZE
	            && r != ESP_RST_POWERON && r != ESP_RST_BROWNOUT;
	if(!kept) {
		ring.magic = MAGIC;
		ring.head = ring.used = 0;
	} else {
		const char *mark = "---- restart ----\n";
		put(mark, strlen(mark));
	}
	previous = esp_log_set_vprintf(hook);
	ESP_LOGI(TAG, "start; last reset: %s%s", reason_name(r), kept ? " (the ring kept what came before)" : "");
	if(esp_core_dump_image_check() == ESP_OK)
		ESP_LOGW(TAG, "a crash is stored: `crash` shows it, `crash erase` clears it");
}

void history_print(void) {
	static char copy[SIZE];
	portENTER_CRITICAL(&mux);
	uint32_t n = ring.used, start = (ring.head + SIZE - ring.used) % SIZE;
	for(uint32_t i = 0; i < n; i++)
		copy[i] = ring.buf[(start + i) % SIZE];
	portEXIT_CRITICAL(&mux);
	fwrite(copy, 1, n, stdout);
	printf("---- %lu of %d bytes ----\n", (unsigned long)n, SIZE);
}

void history_crash_print(void) {
	esp_err_t e = esp_core_dump_image_check();
	if(e != ESP_OK) {
		printf("no crash stored (%s)\n", esp_err_to_name(e));
		return;
	}
	static esp_core_dump_summary_t s;
	char reason[160] = "";
	if(esp_core_dump_get_summary(&s) != ESP_OK) {
		printf("a crash is stored, but its summary cannot be read: idf.py coredump-info\n");
		return;
	}
	esp_core_dump_get_panic_reason(reason, sizeof(reason));
	printf("crash in task \"%s\" at 0x%08lx: %s\nbacktrace:", s.exc_task, (unsigned long)s.exc_pc, reason);
	for(uint32_t i = 0; i < s.exc_bt_info.depth && i < 16; i++)
		printf(" 0x%08lx", (unsigned long)s.exc_bt_info.bt[i]);
	printf("%s\nto source lines: xtensa-esp32s3-elf-addr2line -pfiaC -e build/eziach.elf <addresses>,\n"
	       "or the whole dump: idf.py -p /dev/ttyACM0 coredump-info\n", s.exc_bt_info.corrupted ? " (corrupted)" : "");
}

void history_crash_erase(void) {
	esp_err_t e = esp_core_dump_image_erase();
	printf("%s\n", e == ESP_OK ? "crash erased" : esp_err_to_name(e));
}
