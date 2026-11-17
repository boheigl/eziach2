// Host tests of the firmware's core (no ESP-IDF, no hardware): make -C firmware/test
#include "config.h"
#include "force.h"
#include "instrument.h"
#include "keymap.h"
#include "keys.h"
#include "mapping.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int failures = 0;
#define CHECK(X) do { if(!(X)) { printf("FAIL %s:%d  %s\n", __FILE__, __LINE__, #X); failures++; } } while(0)

// ---- a recorder for the instrument's output
typedef struct { uint8_t ch, note; bool on; float cents; } ev_t;
static ev_t evs[256];
static int nev = 0, n_all_off = 0, last_volume = -1;
static void rec_note(uint8_t ch, uint8_t n, uint8_t vel, bool on, float cents) { (void)vel; evs[nev++] = (ev_t){ch, n, on, cents}; }
static void rec_volume(uint8_t v) { last_volume = v; }
static void rec_all_off(void) { n_all_off++; }
static const instrument_out_t rec = {rec_note, rec_volume, rec_all_off};
static void clear_rec(void) { nev = 0; n_all_off = 0; }
static bool has(uint8_t ch, uint8_t n, bool on) {
	for(int i = 0; i < nev; i++) if(evs[i].ch == ch && evs[i].note == n && evs[i].on == on) return true;
	return false;
}

// a key's reading at a travel fraction (default span, rest 2000)
#define REST 2000
static uint16_t at(float travel) { return (uint16_t)(REST + travel * CONF_KEY_DEFAULT_SPAN); }
static void all_at_rest(void) { for(int i = 0; i < KEYMAP_NUM_KEYS; i++) keys_update(i, REST); }
static void press(int i) { keys_update(i, at(1.0f)); }
static void release(int i) { keys_update(i, at(0.0f)); }

static void test_keymap(void) {
	CHECK(KEYMAP_NUM_KEYS == 64);
	int discant = 0, bass = 0;
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) { if(keymap_keys[i].board) bass++; else discant++; }
	CHECK(discant == 46 && bass == 18);
	// every key exactly once in the channel table
	int seen[KEYMAP_NUM_KEYS] = {0};
	for(int b = 0; b < KEYMAP_NUM_BOARDS; b++)
		for(int a = 0; a < KEYMAP_NUM_ADDR; a++)
			for(int c = 0; c < KEYMAP_NUM_AIN; c++) {
				int k = keymap_by_channel[b][a][c];
				if(k >= 0) {
					seen[k]++;
					CHECK(keymap_keys[k].board == b && keymap_keys[k].addr == 0x10 + a && keymap_keys[k].ain == c);
				}
			}
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) CHECK(seen[i] == 1);
	// tones as ../ctrl/GCFB_Michlbauer_versetzt.toml
	mapping_entry_t e;
	int k = mapping_find(0, 0, 3);                    // discant row 0, third key: [0][0][2]
	e = mapping_map(true, k);  CHECK(e.nkeys == 1 && e.keys[0] == 47 && e.channel == 0);
	e = mapping_map(false, k); CHECK(e.nkeys == 1 && e.keys[0] == 50);
	k = mapping_find(0, 3, 10);                       // discant row 3, last key: [0][3][9]
	e = mapping_map(true, k);  CHECK(e.keys[0] == 89);
	e = mapping_map(false, k); CHECK(e.keys[0] == 87);
	k = mapping_find(1, 1, 2);                        // bass row 1, key 2: chord [54, 57, 62]
	e = mapping_map(true, k);  CHECK(e.nkeys == 3 && e.keys[0] == 54 && e.keys[2] == 62 && e.channel == 2);
	e = mapping_map(false, k); CHECK(e.nkeys == 3 && e.keys[0] == 55 && e.keys[2] == 63);
	k = mapping_find(1, 1, 9);                        // bass row 1, key 9: 24 push, 35 pull, channel 1
	e = mapping_map(true, k);  CHECK(e.nkeys == 1 && e.keys[0] == 24 && e.channel == 1);
	e = mapping_map(false, k); CHECK(e.keys[0] == 35);
	CHECK(mapping_find(0, 0, 14) == -1 && mapping_find(1, 2, 1) == -1);
}

static void test_keys(void) {
	keys_init();
	all_at_rest();
	int k; key_state_t s;
	CHECK(!keys_get_next_changed(&k, &s));
	keys_update(5, at(CONF_KEY_ACTUATE - 0.02f));  CHECK(keys_get_state(5) == OFF);
	keys_update(5, at(CONF_KEY_ACTUATE + 0.02f));  CHECK(keys_get_state(5) == ON);
	CHECK(keys_get_next_changed(&k, &s) && k == 5 && s == ON);
	CHECK(!keys_get_next_changed(&k, &s));
	keys_update(5, at(CONF_KEY_RELEASE + 0.02f));  CHECK(keys_get_state(5) == ON);     // hysteresis
	keys_update(5, at(CONF_KEY_RELEASE - 0.02f));  CHECK(keys_get_state(5) == OFF);
	CHECK(keys_get_next_changed(&k, &s) && k == 5 && s == OFF);
	// clear: a held key comes back as changed
	press(7); CHECK(keys_get_next_changed(&k, &s) && k == 7);
	keys_clear_states();
	CHECK(keys_get_next_changed(&k, &s) && k == 7 && s == ON);
	release(7); keys_get_next_changed(&k, &s);
	// calibration: a key whose magnet makes the reading fall
	keys_cal_begin();
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) keys_update(i, REST - 500);   // every key to the bottom, falling
	all_at_rest();
	CHECK(keys_cal_end() == KEYMAP_NUM_KEYS);
	keys_update(3, REST - 120);  CHECK(keys_get_state(3) == ON);           // 0.24 of 500, falling
	keys_update(3, REST + 400);  CHECK(keys_get_state(3) == OFF);
	int16_t sp[KEYMAP_NUM_KEYS]; keys_get_spans(sp); CHECK(sp[3] == -500);
	// rest drift while released is followed
	keys_init(); keys_update(0, 2000);
	for(int i = 0; i < 3000; i++) keys_update(0, 2000 + i / 100);    // 30 counts, slowly
	keys_update(0, 2030 + (int)(0.15f * CONF_KEY_DEFAULT_SPAN)); CHECK(keys_get_state(0) == OFF);
}

static void test_force(void) {
	force_init();
	force_tare(1000);
	CHECK(fabsf(force_newtons(1000)) < 1e-6f);
	float n = force_newtons(1000 + (int32_t)(10 * CONF_FORCE_COUNTS_PER_NEWTON));
	CHECK(fabsf(n - 10.0f * CONF_FORCE_SIGN) < 1e-3f);
	// ../ctrl forceio math: dead band, then (|F| - offset) x gain
	CHECK(force_level(CONF_FORCE_OFFSET * 0.5f) == 0.0f);
	CHECK(fabsf(force_level(10.0f) - (10.0f - CONF_FORCE_OFFSET) * CONF_FORCE_PUSH_GAIN) < 1e-4f);
	CHECK(fabsf(force_level(-10.0f) - (-10.0f + CONF_FORCE_OFFSET) * CONF_FORCE_PULL_GAIN) < 1e-4f);
	force_track_zero(2000, 0.5f);
	CHECK(fabsf(force_newtons(1500)) < 1e-6f);
}

static void settle(float newtons) { for(int i = 0; i < 40; i++) instrument_step(newtons); }

static void test_instrument(void) {
	keys_init(); all_at_rest();
	instrument_init(&rec);
	settle(10.0f);                                    // push
	CHECK(instrument_is_push() && last_volume > 0);
	int k = mapping_find(0, 0, 3);                    // push 47, pull 50; transpose 2
	clear_rec(); press(k); instrument_step(10.0f);
	CHECK(nev == 1 && has(0, 47 + CONF_TRANSPOSE, true));
	CHECK(evs[0].cents == CONF_THIRD_CENTS);            // H on G-row push: the third of G
	// pull while held: all off, the same key again with its pull tone
	clear_rec(); settle(-10.0f);
	CHECK(!instrument_is_push() && n_all_off == 1 && has(0, 50 + CONF_TRANSPOSE, true));
	CHECK(evs[nev - 1].cents == 0.0f);                  // D on pull: the root of D
	clear_rec(); release(k); instrument_step(-10.0f);
	CHECK(has(0, 50 + CONF_TRANSPOSE, false));
	// two bass chords sharing a tone: it goes off only with the last
	settle(10.0f);
	int c1 = mapping_find(1, 0, 2), c2 = mapping_find(1, 0, 4);   // push [58 62 65], [57 60 65]
	clear_rec(); press(c1); press(c2); instrument_step(10.0f);
	CHECK(has(2, 65 + CONF_TRANSPOSE, true));
	clear_rec(); release(c1); instrument_step(10.0f);
	CHECK(has(2, 58 + CONF_TRANSPOSE, false) && !has(2, 65 + CONF_TRANSPOSE, false));
	clear_rec(); release(c2); instrument_step(10.0f);
	CHECK(has(2, 65 + CONF_TRANSPOSE, false));
	// small force does not turn the direction
	settle(10.0f); settle(CONF_FORCE_THRESHOLD * -0.5f); CHECK(instrument_is_push());
	// quit keys: adjustment, a key of the transposition row sets it, quit keys again end it
	int q[CONF_NUM_QUIT_KEYS] = CONF_QUIT_KEYS;
	for(int i = 0; i < CONF_NUM_QUIT_KEYS; i++) press(q[i]);
	clear_rec(); instrument_step(10.0f);
	CHECK(instrument_is_adjusting() && n_all_off == 1);
	for(int i = 0; i < CONF_NUM_QUIT_KEYS; i++) release(q[i]);
	instrument_step(10.0f);
	int t = mapping_find(0, CONF_TRANSPOSE_ROW, 6);
	press(t); instrument_step(10.0f); release(t); instrument_step(10.0f);
	CHECK(instrument_transpose() == 5);
	for(int i = 0; i < CONF_NUM_QUIT_KEYS; i++) press(q[i]);
	instrument_step(10.0f);
	CHECK(!instrument_is_adjusting());
	clear_rec();
	for(int i = 0; i < CONF_NUM_QUIT_KEYS; i++) release(q[i]);
	instrument_step(10.0f);
	CHECK(nev == 0);                                  // no stray note-offs
}

int main(void) {
	test_keymap();
	test_keys();
	test_force();
	test_instrument();
	if(failures) { printf("%d check(s) failed\n", failures); return 1; }
	printf("all core tests passed\n");
	return 0;
}
