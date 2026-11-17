// Host check of the soundfont with TinySoundFont, as the synthesizer uses it:
//   make -C firmware/test sf2
// lists the presets, plays one note per MIDI channel (preset 0, as FluidSynth did in ../ctrl),
// checks that it sounds and measures its pitch (zero crossings), writes build/sf2_test.wav.
#define TSF_IMPLEMENTATION
#include "tsf.h"
#include "config.h"
#include "keymap.h"
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define RATE 48000

static int failures = 0;

// fundamental of a mono block by autocorrelation (robust against overtones)
static float pitch(const short *s, int n) {
	int best = 0; double bestv = 0;
	for(int lag = RATE / 1200; lag < RATE / 30; lag++) {
		double v = 0;
		for(int i = 0; i + lag < n; i++) v += (double)s[i] * s[i + lag];
		if(v > bestv) { bestv = v; best = lag; }
	}
	// the first lag whose correlation is close to the best: the fundamental, not a multiple
	for(int lag = RATE / 1200; lag < best; lag++) {
		double v = 0;
		for(int i = 0; i + lag < n; i++) v += (double)s[i] * s[i + lag];
		double p = 0; for(int i = 0; i + lag - 1 < n && lag > 1; i++) p += (double)s[i] * s[i + lag - 1];
		double q = 0; for(int i = 0; i + lag + 1 < n; i++) q += (double)s[i] * s[i + lag + 1];
		if(v > 0.9 * bestv && v >= p && v >= q) { best = lag; break; }
	}
	return best ? (float)RATE / best : 0;
}

int main(int argc, char **argv) {
	const char *path = argc > 1 ? argv[1] : "../sound/ZiachMini.sf2";
	tsf *f = tsf_load_filename(path);
	if(!f) { printf("FAIL cannot load %s\n", path); return 1; }
	printf("%s: %d presets\n", path, tsf_get_presetcount(f));
	for(int i = 0; i < tsf_get_presetcount(f); i++)
		printf("  preset %d: %s\n", i, tsf_get_presetname(f, i));
	tsf_set_output(f, TSF_MONO, RATE, 0.0f);
	tsf_set_max_voices(f, 32);
	for(int ch = 0; ch < 3; ch++) tsf_channel_set_presetnumber(f, ch, 0, 0);

	// one note per channel: melody A4 (69), bass A2 (45), chord tone C4 (60)
	int notes[3] = {69, 45, 60};
	int n = RATE / 2;
	short *buf = malloc(sizeof(short) * n * 3);
	for(int ch = 0; ch < 3; ch++) {
		tsf_channel_note_on(f, ch, notes[ch], 50 / 127.0f);
		tsf_render_short(f, buf + ch * n, n, 0);
		tsf_channel_note_off_all(f, ch);
		short tail[RATE / 4]; tsf_render_short(f, tail, RATE / 4, 0);   // let it release
		double rms = 0; int peak = 0;
		for(int i = n / 4; i < n; i++) { rms += (double)buf[ch * n + i] * buf[ch * n + i]; if(abs(buf[ch * n + i]) > peak) peak = abs(buf[ch * n + i]); }
		rms = sqrt(rms / (n * 3 / 4));
		float want = 440.0f * powf(2.0f, (notes[ch] - 69) / 12.0f);
		float got = pitch(buf + ch * n + n / 4, 4096);
		float cents = got > 0 ? 1200.0f * log2f(got / want) : 9999;
		printf("channel %d note %d: rms %.0f peak %d, pitch %.1f Hz (want %.1f, %+.0f cents)\n",
		       ch, notes[ch], rms, peak, got, want, cents);
		if(rms < 100) { printf("FAIL channel %d is silent\n", ch); failures++; }
		if(fabsf(cents) > 50) { printf("FAIL channel %d off pitch\n", ch); failures++; }
	}
	// a wav to listen to
	FILE *w = fopen("build/sf2_test.wav", "wb");
	if(w) {
		int bytes = n * 3 * 2;
		unsigned char h[44] = {'R','I','F','F',0,0,0,0,'W','A','V','E','f','m','t',' ',16,0,0,0,1,0,1,0,
		                       RATE & 255, (RATE >> 8) & 255, RATE >> 16, 0, (RATE * 2) & 255, ((RATE * 2) >> 8) & 255, (RATE * 2) >> 16, 0,
		                       2,0,16,0,'d','a','t','a',0,0,0,0};
		int riff = bytes + 36;
		for(int i = 0; i < 4; i++) { h[4 + i] = (riff >> (8 * i)) & 255; h[40 + i] = (bytes >> (8 * i)) & 255; }
		fwrite(h, 1, 44, w); fwrite(buf, 2, n * 3, w); fclose(w);
	}
	free(buf);

	// every tone the key table uses (keymap.c, with the starting transposition): sounds,
	// holds while the key is held (the sample's loop), in tune; at the firmware's gain
	tsf_set_output(f, TSF_MONO, RATE, CONF_SYNTH_GAIN_DB);
	static short t[RATE * 3 / 2];
	int checked = 0, worst_note = -1; float worst = 0;
	bool done[16][128] = {{0}};
	for(int i = 0; i < KEYMAP_NUM_KEYS; i++) {
		const keymap_key_t *k = &keymap_keys[i];
		for(int dir = 0; dir < 2; dir++) {
			int nn = dir ? k->n_pull : k->n_push;
			for(int j = 0; j < nn; j++) {
				int note = (dir ? k->pull[j] : k->push[j]) + CONF_TRANSPOSE;
				if(done[k->channel][note]) continue;
				done[k->channel][note] = true;
				tsf_note_off_all(f); tsf_render_short(f, t, RATE / 2, 0);          // silence
				tsf_channel_note_on(f, k->channel, note, CONF_VELOCITY / 127.0f);
				tsf_render_short(f, t, RATE * 3 / 2, 0);
				double a = 0, b = 0;
				for(int x = RATE / 4; x < RATE / 2; x++) a += (double)t[x] * t[x];
				for(int x = RATE; x < RATE * 3 / 2; x++) b += (double)t[x] * t[x];
				a = sqrt(a / (RATE / 4)); b = sqrt(b / (RATE / 2));
				float want = 440.0f * powf(2.0f, (note - 69) / 12.0f);
				float got = pitch(t + RATE / 4, 8192);
				float cents = got > 0 ? 1200.0f * log2f(got / want) : 9999;
				// an octave error of the pitch finder on dull low tones is not a tuning error
				float c2 = fabsf(cents - 1200.0f * roundf(cents / 1200.0f));
				if(a < 30) { printf("FAIL ch %d note %d silent\n", k->channel, note); failures++; }
				if(b < 0.5 * a) { printf("FAIL ch %d note %d fades while held (%.0f -> %.0f)\n", k->channel, note, a, b); failures++; }
				if(c2 > 30) { printf("FAIL ch %d note %d off pitch: %.1f Hz, want %.1f\n", k->channel, note, got, want); failures++; }
				if(c2 > worst) { worst = c2; worst_note = note; }
				checked++;
			}
		}
	}
	printf("%d tones of the key table: all sound and hold; worst tuning %.0f cents (note %d)\n", checked, worst, worst_note);

	// every note starts exactly one stereo pair: no two zones overlap (they did at 85-86 in
	// ../ctrl's original; the copy in sound/ has the "D3" zones ending at 84)
	for(int note = 0; note < 128; note++) {
		tsf_note_off_all(f);
		for(int i = 0; i < 40; i++) tsf_render_short(f, t, RATE / 20, 0);   // releases end
		tsf_channel_note_on(f, 0, note, 0.4f);
		tsf_render_short(f, t, 64, 0);
		int v = tsf_active_voice_count(f);
		if(v != 2) { printf("FAIL note %d starts %d voices\n", note, v); failures++; }
	}
	printf("notes 0-127: each starts one stereo pair\n");

	// a tuned note (a chord's third, [tuning] in the config): its voices play exactly that much lower
	{
		double tc[2];
		for(int pass = 0; pass < 2; pass++) {
			tsf_note_off_all(f);
			for(int i = 0; i < 40; i++) tsf_render_short(f, t, RATE / 20, 0);
			if(pass) tsf_channel_note_on_tuned(f, 0, 71, 0.4f, CONF_THIRD_CENTS);
			else tsf_channel_note_on(f, 0, 71, 0.4f);
			tsf_render_short(f, t, 64, 0);
			tc[pass] = 0;
			for(int v = 0; v < f->voiceNum; v++)
				if(f->voices[v].playingPreset != -1 && f->voices[v].ampenv.segment < TSF_SEGMENT_RELEASE) { tc[pass] = f->voices[v].pitchInputTimecents; break; }
		}
		double d = tc[1] - tc[0];
		printf("note 71 tuned %+.1f cents: its voices play %+.2f cents\n", (double)CONF_THIRD_CENTS, d);
		if(fabs(d - CONF_THIRD_CENTS) > 0.01) { printf("FAIL the tuning does not reach the voice\n"); failures++; }
		// and the next untuned note is back at tempered
		tsf_note_off_all(f);
		for(int i = 0; i < 40; i++) tsf_render_short(f, t, RATE / 20, 0);
		tsf_channel_note_on(f, 0, 71, 0.4f);
		tsf_render_short(f, t, 64, 0);
		for(int v = 0; v < f->voiceNum; v++)
			if(f->voices[v].playingPreset != -1 && f->voices[v].ampenv.segment < TSF_SEGMENT_RELEASE) {
				if(fabs(f->voices[v].pitchInputTimecents - tc[0]) > 0.01) { printf("FAIL the tuning sticks to later notes\n"); failures++; }
				break;
			}
	}

	// a full chord: six melody tones, a bass tone and a three-note chord at full volume
	int chord[] = {67, 71, 74, 79, 83, 86};
	tsf_note_off_all(f); tsf_render_short(f, t, RATE / 2, 0);
	for(int i = 0; i < 6; i++) tsf_channel_note_on(f, 0, chord[i] + CONF_TRANSPOSE, CONF_VELOCITY / 127.0f);
	tsf_channel_note_on(f, 1, 31 + CONF_TRANSPOSE, CONF_VELOCITY / 127.0f);
	for(int i = 0; i < 3; i++) tsf_channel_note_on(f, 2, (int[]){55, 59, 62}[i] + CONF_TRANSPOSE, CONF_VELOCITY / 127.0f);
	tsf_channel_set_volume(f, 2, 0.6f);
	tsf_render_short(f, t, RATE, 0);
	int clip = 0, peak = 0;
	for(int x = 0; x < RATE; x++) { if(abs(t[x]) >= 32767) clip++; if(abs(t[x]) > peak) peak = abs(t[x]); }
	printf("full chord (10 tones): peak %d of 32767, %d samples clipped\n", peak, clip);
	if(clip) { printf("FAIL the full chord clips\n"); failures++; }

	tsf_close(f);
	if(failures) return 1;
	printf("soundfont ok\n");
	return 0;
}
