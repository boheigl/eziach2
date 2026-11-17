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

#include "synthesizer.h"
#include "config.h"
#include "dac.h"
#include "pins.h"
#include "tsf.h"
#include "driver/i2s_std.h"
#include "esp_log.h"
#include "esp_partition.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"

static const char *TAG = "synth";

#define MAX_VOICES 32          // melody, bass and three-note chords with their releases
#define QUEUE_LEN 64

typedef enum { EV_NOTE, EV_VOLUME, EV_ALL_OFF } ev_type_t;
typedef struct ev_t {
	uint8_t type, channel, key, velocity;
	bool on;
	float cents;
} ev_t;

static tsf *sf = NULL;
static QueueHandle_t events;
static i2s_chan_handle_t tx;
static const float channel_volumes[CONF_NUM_CHANNELS] = CONF_CHANNEL_VOLUMES;
static volatile int voices = 0;
static int64_t load_sum = 0, load_peak = 0, load_n = 0;
static portMUX_TYPE load_lock = portMUX_INITIALIZER_UNLOCKED;

static void apply(const ev_t *e) {
	switch(e->type) {
	case EV_NOTE:
		if(e->on)
			tsf_channel_note_on_tuned(sf, e->channel, e->key, e->velocity / 127.0f, e->cents);
		else
			tsf_channel_note_off(sf, e->channel, e->key);
		break;
	case EV_VOLUME:
		for(int c = 0; c < CONF_NUM_CHANNELS; c++)
			tsf_channel_set_volume(sf, c, e->velocity / 127.0f * channel_volumes[c]);
		break;
	case EV_ALL_OFF:
		for(int c = 0; c < CONF_NUM_CHANNELS; c++)
			tsf_channel_note_off_all(sf, c);
		break;
	}
}

static void audio_task(void *arg) {
	(void)arg;
	static int16_t buf[CONF_PERIOD_SIZE * 2];
	for(;;) {
		ev_t e;
		while(xQueueReceive(events, &e, 0) == pdTRUE)
			apply(&e);
		int64_t t0 = esp_timer_get_time();
		tsf_render_short(sf, buf, CONF_PERIOD_SIZE, 0);
		int64_t dt = esp_timer_get_time() - t0;
		voices = tsf_active_voice_count(sf);
		portENTER_CRITICAL(&load_lock);
		load_sum += dt;
		load_n++;
		if(dt > load_peak) load_peak = dt;
		portEXIT_CRITICAL(&load_lock);
		size_t written;
		i2s_channel_write(tx, buf, sizeof(buf), &written, portMAX_DELAY);   // paces the loop
	}
}

static esp_err_t i2s_init(void) {
	i2s_chan_config_t cc = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
	cc.dma_desc_num = 3;
	cc.dma_frame_num = CONF_PERIOD_SIZE;    // 64 frames: 1.3 ms per block
	cc.auto_clear = true;
	esp_err_t e = i2s_new_channel(&cc, &tx, NULL);
	if(e != ESP_OK) return e;
	i2s_std_config_t sc = {
		.clk_cfg = I2S_STD_CLK_DEFAULT_CONFIG(CONF_SAMPLE_RATE),      // MCLK = 256 fs
		.slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_STEREO),
		.gpio_cfg = {
			.mclk = PIN_MCLK, .bclk = PIN_BCLK, .ws = PIN_WCLK, .dout = PIN_DOUT, .din = I2S_GPIO_UNUSED,
		},
	};
	if((e = i2s_channel_init_std_mode(tx, &sc)) != ESP_OK) return e;
	return i2s_channel_enable(tx);
}

esp_err_t synthesizer_init(void) {
	const esp_partition_t *p = esp_partition_find_first(ESP_PARTITION_TYPE_DATA, 0x40, "soundfont");
	if(!p) {
		ESP_LOGE(TAG, "no soundfont partition");
		return ESP_ERR_NOT_FOUND;
	}
	const void *data;
	esp_partition_mmap_handle_t h;
	esp_err_t e = esp_partition_mmap(p, 0, p->size, ESP_PARTITION_MMAP_DATA, &data, &h);
	if(e != ESP_OK) return e;
	// TinySoundFont converts the samples to float in RAM (PSRAM: SPIRAM_USE_MALLOC)
	sf = tsf_load_memory(data, p->size);
	if(!sf) {
		ESP_LOGE(TAG, "%s: not a soundfont (flashed? idf.py flash writes it)", CONF_SOUNDFONT_NAME);
		return ESP_ERR_INVALID_STATE;
	}
	tsf_set_output(sf, TSF_STEREO_INTERLEAVED, CONF_SAMPLE_RATE, CONF_SYNTH_GAIN_DB);
	tsf_set_max_voices(sf, MAX_VOICES);
	for(int c = 0; c < CONF_NUM_CHANNELS; c++) {
		tsf_channel_set_bank_preset(sf, c, 0, 0);       // its one preset, as FluidSynth's default
		tsf_channel_set_volume(sf, c, channel_volumes[c]);
	}
	ESP_LOGI(TAG, "%s: %d preset(s), first \"%s\"", CONF_SOUNDFONT_NAME, tsf_get_presetcount(sf),
	         tsf_get_presetname(sf, 0));
	events = xQueueCreate(QUEUE_LEN, sizeof(ev_t));
	if((e = i2s_init()) != ESP_OK) return e;
	if((e = dac_init()) != ESP_OK)
		ESP_LOGW(TAG, "no DAC: rendering on, nothing to hear");
	xTaskCreatePinnedToCore(audio_task, "audio", 4096, NULL, 20, NULL, 1);
	return ESP_OK;
}

static void post(ev_t e) {
	if(events && xQueueSend(events, &e, 0) != pdTRUE)
		ESP_LOGW(TAG, "event queue full");
}

void synthesizer_note_update(uint8_t channel, uint8_t key, uint8_t velocity, bool on_off, float cents) {
	post((ev_t){EV_NOTE, channel, key, velocity, on_off, cents});
}

void synthesizer_change_volume(uint8_t volume) {
	static uint8_t last = 255;
	if(volume == last)
		return;
	last = volume;
	post((ev_t){EV_VOLUME, 0, 0, volume, false, 0.0f});
}

void synthesizer_all_notes_off(void) {
	post((ev_t){EV_ALL_OFF, 0, 0, 0, false, 0.0f});
}

void synthesizer_load(float *avg, float *peak) {
	const float period_us = 1e6f * CONF_PERIOD_SIZE / CONF_SAMPLE_RATE;
	portENTER_CRITICAL(&load_lock);
	*avg = load_n ? (float)load_sum / load_n / period_us : 0.0f;
	*peak = (float)load_peak / period_us;
	load_sum = load_peak = load_n = 0;
	portEXIT_CRITICAL(&load_lock);
}

int synthesizer_voices(void) {
	return voices;
}
