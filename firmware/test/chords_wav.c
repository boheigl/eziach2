// Chords to listen to, each tempered and then with its thirds low ([tuning] in the config):
//   make -C firmware/test chords   ->  build/chords.wav (48 kHz, mono)
// Per discant row and direction: the row's tones in the middle range (MIDI 60..79, before
// the transposition), with the bass note and bass chord of the same root, as the instrument
// plays them (transposition CONF_TRANSPOSE, channel volumes, the synthesizer's gain).
#define TSF_IMPLEMENTATION
#include "tsf.h"
#include "config.h"
#include "keymap.h"
#include <stdio.h>
#include <stdlib.h>

#define RATE 48000
static const char *names[12] = {"C", "Cis", "D", "Es", "E", "F", "Fis", "G", "Gis", "A", "B", "H"};
static const float chvol[CONF_NUM_CHANNELS] = CONF_CHANNEL_VOLUMES;

static short *out = NULL;
static int len = 0, cap = 0;

static void render(tsf *f, float seconds) {
	int n = (int)(seconds * RATE);
	if(len + n > cap) { cap = (len + n) * 2; out = realloc(out, cap * sizeof(short)); }
	tsf_render_short(f, out + len, n, 0);
	len += n;
}

// the key whose single tone (bass) or triad (chord) has this root, in this direction
static int bass_key(int root, int is_push, int chord) {
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) {
		const keymap_key_t *k = &keymap_keys[i];
		if(k->board != 1) continue;
		int n = is_push ? k->n_push : k->n_pull;
		const uint8_t *t = is_push ? k->push : k->pull;
		if(!chord && n == 1 && t[0] % 12 == root) return i;
		if(chord && n == 3)
			for(int r = 0; r < 3; r++) {
				int pr = t[r] % 12, has3 = 0, has5 = 0;
				for(int j = 0; j < 3; j++) { has3 |= (t[j] - pr + 12) % 12 == 4; has5 |= (t[j] - pr + 12) % 12 == 7; }
				if(pr == root && has3 && has5) return i;
			}
	}
	return -1;
}

static int found_bass, found_chord;

static void play(tsf *f, int row, int is_push, int tuned, int *root_out) {
	int root = -1;
	// the discant row's tones in this direction; their chord's root from the tuned thirds
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) {
		const keymap_key_t *k = &keymap_keys[i];
		if(k->board != 0 || k->row != row) continue;
		int note = is_push ? k->push[0] : k->pull[0];
		float c = is_push ? k->push_cents[0] : k->pull_cents[0];
		if(c != 0.0f) root = (note - 4 + 12) % 12;
		if(note < 60 || note > 79) continue;
		tsf_channel_note_on_tuned(f, 0, note + CONF_TRANSPOSE, CONF_VELOCITY / 127.0f, tuned ? c : 0.0f);
	}
	*root_out = root;
	found_bass = found_chord = 0;
	for(int chord = 0; chord < 2 && root >= 0; chord++) {
		int b = bass_key(root, is_push, chord);
		if(b < 0) continue;
		if(chord) found_chord = 1; else found_bass = 1;
		const keymap_key_t *k = &keymap_keys[b];
		int n = is_push ? k->n_push : k->n_pull;
		for(int j = 0; j < n; j++) {
			int note = is_push ? k->push[j] : k->pull[j];
			float c = is_push ? k->push_cents[j] : k->pull_cents[j];
			tsf_channel_note_on_tuned(f, k->channel, note + CONF_TRANSPOSE, CONF_VELOCITY / 127.0f, tuned ? c : 0.0f);
		}
	}
	render(f, 2.5f);
	tsf_note_off_all(f);
	render(f, tuned ? 1.2f : 0.5f);
}

int main(int argc, char **argv) {
	const char *sf2 = argc > 1 ? argv[1] : "../sound/ZiachMini.sf2";
	const char *wav = argc > 2 ? argv[2] : "build/chords.wav";
	tsf *f = tsf_load_filename(sf2);
	if(!f) { printf("cannot load %s\n", sf2); return 1; }
	tsf_set_output(f, TSF_MONO, RATE, CONF_SYNTH_GAIN_DB);
	tsf_set_max_voices(f, 64);
	for(int c = 0; c < CONF_NUM_CHANNELS; c++) {
		tsf_channel_set_presetnumber(f, c, 0, 0);
		tsf_channel_set_volume(f, c, 100 / 127.0f * chvol[c]);
	}
	render(f, 0.5f);
	float t = 0.5f;
	printf("time    chord (sounding, transposition %+d)\n", CONF_TRANSPOSE);
	for(int row = 0; row < 4; row++)
		for(int dir = 0; dir < 2; dir++) {
			int root;
			for(int tuned = 0; tuned < 2; tuned++) {
				play(f, row, dir == 0, tuned, &root);
				if(tuned == 0)
					printf("%5.1f s  row %d %-4s %-3s major%s: tempered, then at %5.1f s with thirds %+.0f cents\n", t, row,
					       dir == 0 ? "push" : "pull", root >= 0 ? names[(root + CONF_TRANSPOSE) % 12] : "?",
					       found_bass && found_chord ? " + bass, bass chord" : found_bass ? " + bass" : found_chord ? " + bass chord" : "",
					       t + 3.0f, (double)CONF_THIRD_CENTS);
				t += tuned ? 3.7f : 3.0f;
			}
		}
	FILE *w = fopen(wav, "wb");
	if(!w) { printf("cannot write %s\n", wav); return 1; }
	int bytes = len * 2, riff = bytes + 36;
	unsigned char h[44] = {'R','I','F','F',0,0,0,0,'W','A','V','E','f','m','t',' ',16,0,0,0,1,0,1,0,
	                       RATE & 255, (RATE >> 8) & 255, RATE >> 16, 0, (RATE * 2) & 255, ((RATE * 2) >> 8) & 255, (RATE * 2) >> 16, 0,
	                       2,0,16,0,'d','a','t','a',0,0,0,0};
	for(int i = 0; i < 4; i++) { h[4 + i] = (riff >> (8 * i)) & 255; h[40 + i] = (bytes >> (8 * i)) & 255; }
	fwrite(h, 1, 44, w);
	fwrite(out, 2, len, w);
	fclose(w);
	printf("%s: %.1f s\n", wav, (float)len / RATE);
	tsf_close(f);
	free(out);
	return 0;
}
