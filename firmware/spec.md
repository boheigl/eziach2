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

## 2a. Tuning: low thirds [given 2026-11-18: thirds -14 cents, adjustable]

A Steirische plays in few keys and is not tuned equal-tempered: a chord's third is tuned
low, towards the just third (5:4, 386.3 cents, 13.7 under the tempered 400). Every reed
belongs to one key and one direction, so the tuner knows its chord; the table here does too.

- `third_cents` in `config/eziach.toml` [tuning], −14.
- `tools/gen_config.py` finds the chord per discant row and direction from the table's tones
  (the major triad that is complete and covers most tones): push G, C, F, B (B♭), pull D, G,
  C, F, the rows' tonics and dominants. Each bass chord (three tones) is analysed on its own;
  single bass notes are roots and stay. 39 tones of the table are thirds.
- The cents go with every tone into `keymap.c`, through `mapping` and `instrument` to the
  synthesizer: TinySoundFont, changed here by `tsf_channel_note_on_tuned()`, detunes the
  voices of that one note (`tsf.h`, marked `eziach:`). Checked on the host: the voice plays
  exactly −14.00 cents, later notes tempered again.
- USB-MIDI stays tempered (per-note tuning would need the MIDI Tuning Standard).
- A note held by two keys keeps the first key's tuning (one voice per note and channel).

## 3. Keys [../switch_hall/spec.md §6]

A key goes on a fixed distance above its rest reading and off below a smaller one [given
2026-11-20: switching at the top of the stroke only; before: at 20 % / 10 % of the
calibrated travel]: 18 and 10 ADC counts (DRV5055A2, 30 mV/mT [2026-11-26: 9 and 5 with the A3]), about 0.48 and 0.27 mT, about 0.19 and 0.11 mm at
rest (`[keys]` in `config/eziach.toml`). So the switching does not depend on the bottom:
a key that is calibrated short, or a sensor that runs into its limit at the bottom, still
switches at the same place. The rest follows drift while the key is up (below half the
release distance), slowly — a time constant of about 5 s — so a key pressed slowly is not
followed. The span (bottom − rest, from a calibration pass, kept in NVS; until then 930
counts, the estimate from the field: 25 mT × 30 mV/mT over 0.806 mV per count) gives only
the direction a press moves the reading (the magnet's pole) and the travel `keys` shows.
[chosen; the counts to tune on the prototype: noise, drift, the soft stop's return]

## 4. Force [../strain_gauge/spec.md]

Newtons = sign × (counts − zero) / 2190 [estimated: 6.73 µV/N per cell at 3.3 V, gain 128];
zero tared at start and followed while no key is pressed; the sign set once by a push.

**Drift measurement** [2026-11-21; TODO 21]: `force track off` stops following the zero
(back on with `force track on` or a restart), `force log on` prints a CSV line every
100 ms: `F,t_ms,cell0,cell1,zero,newtons,key`, each cell's mean counts over the 100 ms,
the zero, the force from the means, and 1 if a key was down. Capture the console
(`screen -L /dev/ttyACM0`, or `idf.py monitor | tee`) and keep the lines with `grep '^F,'`.
With the zero held, `newtons` while nothing is touched is the drift itself; a known
weight on the hand plate gives the real counts per newton. The averaging and the line
are `force_avg_add()` / `force_avg_line()` in `force.c`, host-tested.
Level for the volume as ../ctrl: dead band 0.3 N, then 3.2 per newton (127 at about 40 N).

## 5. Hardware

| Module | Part | Notes |
|---|---|---|
| `bus.c` | two I²C buses, 400 kHz | bus 1 through the contacts (discant), bus 2 in the bass; pins in `pins.h` from ../main_pcb/spec.md |
| `keyio.c` | ADS7128 × 6 + 3 | auto-sequence over all 8 inputs, the channel ID appended, one 16-byte read per ADC (about 0.4 ms); ALERT left open drain |
| `nau7802.c` | NAU7802, bus 1, 2Ah | gain 128, 320/s, both cells in turn, 3 conversions dropped after each switch: about 45 force readings/s |
| `dac.c` | TLV320DAC3100, bus 2, 18h | I²S slave, MCLK 256 fs, NDAC 1, MDAC 2, DOSR 128; headphones, −6 dB digital |
| `synthesizer.c` | I²S 48 kHz, 64-frame blocks (1.3 ms) | TinySoundFont on the mapped `soundfont` partition, 32 voices, its own task on core 1, notes through a queue |
| `midi.c` | USB (TinyUSB) | the USB device "eziach", MIDI and a serial port: notes, CC 7, CC 123 |
| `usb_console.c` | USB (TinyUSB CDC) | the console over USB; `download`: restart into the ROM's loader over USB-Serial/JTAG |
| `history.c` | RAM, flash partition `coredump` (64 KB at 0x510000) | every log line also into a 4 KB ring that a restart or crash does not clear (power does): `history`; the last reset's reason logged at start; a crash's core dump (ELF) kept in flash: `crash` sums it up (task, address, reason, backtrace), `crash erase`, or `idf.py coredump-info` |
| `power.c` | IO40, IO41, IO1, IO42, IO2/IO4, IO5/IO6 | discant plugged, USB, battery (1M/1M), low-battery light below 3.4 V without USB; the USB source's offer from CC1/CC2 and the charger's input set to match (1 A from 1.5 A or 3 A sources, else 500 mA; ../main_pcb/spec.md §2) |
| `settings.c` | NVS | key spans, force sign |
| `app_main.c` | | control loop on core 0 every 1 ms; the discant's ADCs and gauges re-initialised when it is plugged in; console |

Register values: the ADS7128's and the TLV320DAC3100's checked against their datasheets
(SBAS868A, SLAS671) on 2026-11-18, every field the firmware writes; the NAU7802's against
Rev 1.7 on 2026-11-20 (Rev 2.6, which the board's design cites, was not to be had): the
power-on sequence (§9.1), PU_CTRL, CTRL1, CTRL2 bit for bit, the result MSB first,
REG0x15 = 0x30 as the datasheet's own example. One addition: REG0x1C is now written 0 —
its bit 7 puts a capacitor across VIN2P/VIN2N (for one-channel use), and the datasheet
gives no default; we read both channels.

## 6. Building, flashing, bring-up

```sh
. ~/esp/esp-idf-v5.5.6/export.sh
idf.py build                       # generates the key table, fetches esp_tinyusb
idf.py -p /dev/ttyUSB0 flash monitor   # the first time, over UART0: app and soundfont (sound/ZiachMini.sf2, partition at 0x310000)
make -C test                       # host tests of the core
make -C test sf2                   # the soundfont through TinySoundFont on the host
```

**One USB cable** [given 2026-11-20]: the instrument is a USB device with two functions,
MIDI and a serial port (`/dev/ttyACM0` on Linux, a COM port on Windows), the console's
(`usb_console.c`). A terminal on it (`idf.py -p /dev/ttyACM0 monitor`, `screen
/dev/ttyACM0`) gets the same commands as UART0; while it is open, the console's output
goes there instead of UART0. To flash over the same cable: the command `download` (or
opening the port at 1200 baud) restarts into the ROM's download mode — the firmware gives
the chip's USB PHY back to its USB-Serial/JTAG and sets RTC_CNTL_FORCE_DOWNLOAD_BOOT, as
ESP-IDF's own USB console does — and the port comes back as the USB-Serial/JTAG
(`/dev/ttyACM0` again): `idf.py -p /dev/ttyACM0 flash`. esptool's reset at the end starts
the firmware [to check on the hardware: the ROM clears the download flag; if the chip
stays in the loader, a power cycle].

UART0 (the main board's TX / RX test pads, a USB-serial adapter) stays for the first
flashing, the boot messages before USB is up, and a firmware that does not start (boot
pad to GND at power-on for the download mode).

Console commands (`help`): `status`, `keys` (every key's place, ADC input, raw reading,
span, travel), `cal begin` / `cal end` (each key once to the bottom; saved), `sign` (while
pushing; saved), `tare`, `force` (zero, tracking, log), `force log on|off` (the drift log,
§4), `force track on|off` (zero tracking, not saved), `log on|off` (notes), `play <board> <row> <key>`, `history`
(the log since power-on, kept over restarts and crashes; the notes of `log on` and the
console's own output are not in it), `crash` / `crash erase` (the stored crash), `download`
(restart into the download mode over USB).

Bring-up order: `status` (boards, gauges, DAC); `keys`, pressing keys one after the other:
does each move its own line (the place assumption of §1)?; `cal`; `sign`; `play` and
`log on` against the old instrument's tones; `status` for the synth's load while playing
chords.

## 7. Status (2026-11-17)

- Done: configuration and generator; the core with host tests (`make -C test`: key table
  against ../ctrl's tones, hysteresis, calibration for either pole, re-trigger on reversal,
  shared chord tones, adjustment mode); the soundfont checked on the host (`make -C test
  sf2`): one preset "Diskant", 8 looped samples at 44.1 kHz (roots 39-86) over keys
  0-127; every one of the table's 64 tones sounds, holds while held and is in tune within
  14 cents; a full chord of 10 tones clipped at 0 dB, so the synth runs at -12 dB (peak
  -2.7 dBFS) and the DAC at 0 dB; all drivers; builds with ESP-IDF v5.5.6 without warnings
  (app 427 KB of 3 MB, 2026-11-21).
- `sound/ZiachMini.sf2` differs from ../ctrl's in two bytes [given 2026-11-18: fix the
  overlap in the copy]: the "D3" sample's zones (root 74) covered keys 73-86 and overlapped
  the "D4" zones (85-127), so notes 85 and 86 (the table's 83 and 84 at transposition 2)
  sounded both samples, louder and beating. They end at 84 now. Loops checked: inside the
  rules, seams without jumps (waveform match 0.87-0.998); the "D2" loop ends 2.3 dB louder
  than it starts [to judge by ear].
- The bass's lowest tones lie up to 13 half tones under the lowest sample (39): played
  slower, so darker than the sampled range [to judge by ear].
- Not yet run on hardware. Open: the synth's load at full
  polyphony (TinySoundFont keeps the samples as float in PSRAM), the force's scale
  (2190 counts/N estimated), the actuation points.
