# Firmware — design record

The ESP32-S3's firmware on the main board (`../main_pcb/`): reads the Hall keys of both
halves (`../hall_pcb/`) and the load cells (`../strain_gauge/`), plays the tones through the
DAC to the earphone jack and sends them as USB-MIDI. ESP-IDF, C [given 2026-11-17]. Tags as
in `../discant/spec.md`.

## 1. What comes from ../ctrl [given 2026-11-17: reuse the old firmware]

`../ctrl` is the Raspberry Pi firmware of the first eziach (the user's, LGPL-2.1): GPIO key
matrices, an AS5048 angle sensor for the bellows, FluidSynth. Its musical part carries over:

| ../ctrl | Here |
|---|---|
| `GCFB_Michlbauer_versetzt.toml`: tones per key on push and pull, chords | `config/`, unchanged [given: this tuning] |
| `eziach.toml`: MIDI channels (discant 0, bass 1, chords 2), channel volumes, transposition 2, quit keys, smoothing | `config/eziach.toml` |
| `ZiachMini.sf2`, the recorded Steirische | the synth's sound [given: own synth] |
| `main_loop.c`: smoothing, direction by the force's sign past a threshold, on reversal all notes off and the held keys again with the other direction's tones, volume (CC 7) from the force, adjustment mode (quit keys, transposition) | `main/instrument.c`, the same logic |
| `mapping.c`: key → tones, per direction | `main/mapping.c`; the table is generated at build time |
| `forceio.c`: dead band, push / pull gain, sign | `main/force.c`, the same math on newtons from the load cells |
| `keyio.c`: changed keys one by one, clearing states | `main/keys.c`, the same interface on calibrated Hall readings |
| `synthesizer.c`: note on / off, volume, all off | the same interface, on TinySoundFont instead of FluidSynth |
| bcm2835 GPIO / SPI, AS5048, ALSA | not used |

**One change:** a count per sounding note. Bass chords share tones (60 in two chords); in
../ctrl releasing one key silenced the tone of another still held.

**Old places → new keys.** In ../ctrl a table's index `[matrix][row][col]` is the key's
place (`map_sensors` only translated it to the old wiring), and the old shape
(`../../shape/eziach_shape_123d_funcs.py`) numbers columns along +x like the new boards. So
`[0][r][c]` is discant row r, key c + 1, and `[1][r][c]` bass row r, key c + 1 (key 1 at the
lowest X, `../hall_pcb/<board>/board.scad`). [unverified: to check on the instrument, one
key after the other; `mirror` in `config/eziach.toml` turns a board's rows round]

## 2. Generated tables

`tools/gen_config.py` joins `config/eziach.toml`, the tuning table and
`../hall_pcb/{discant,bass}/channels.json` (which ADC input reads which key) into
`keymap.c`/`keymap.h` (64 keys: board, row, key, I²C bus, ADC address, input, MIDI channel,
push and pull tones) and `config.h`. It stops if a key of the table is not on a board, a
board's key has no tone, or two keys share an input: 46 discant + 18 bass, checked.

## 3. Keys [../switch_hall/spec.md §6]

Travel = (reading − rest) / span, the span signed by the magnet's pole. A key goes on at
20 % of its travel and off at 10 %; the rest follows slow drift while the key is clearly up
(below 5 %). The span comes from a calibration pass (each key pressed once to the bottom),
kept in NVS; until then 600 counts, the estimate from the field (32 mT × 15 mV/mT over
0.806 mV per count). [chosen; to tune on the instrument]

## 4. Force [../strain_gauge/spec.md]

Newtons = sign × (counts − zero) / 2190 [estimated: 6.73 µV/N per cell at 3.3 V, gain 128];
zero tared at start and followed while no key is pressed; the sign set once by a push.
Level for the volume as ../ctrl: dead band 0.3 N, then 3.2 per newton (127 at about 40 N).

## 5. Status (2026-11-17)

- Done: configuration, generator, `mapping`, `keys`, `force`, `instrument`, with host tests
  (`make -C test`: key table against ../ctrl's tones, hysteresis, calibration with either
  pole, re-trigger on reversal, shared chord tones, adjustment mode).
- Open: the ESP-IDF project and the hardware drivers (ADS7128, NAU7802, TLV320DAC3100, I²S,
  TinySoundFont, USB-MIDI, power), and bring-up on the instrument. ESP-IDF is not installed yet.
