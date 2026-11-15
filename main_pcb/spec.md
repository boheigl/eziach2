# Main board in the bass — design record

The board with everything that is not key reading: the ESP32-S3, the audio DAC and
the earphone jack, USB-C, the charger, and the 3.3 V supply for both halves. It sits at
the bottom of the bass box on the +x side (`../bass/elec.scad`). Tags as in
`../switch/spec.md`: **[given]**, **[datasheet]**, **[chosen]**, **[estimated]**,
**[unverified]**.

`design.py` is the one source (parts, nets, placement). `build.sh` runs `gen_pcb.py`
(board), `route.py` (routing, up to three tries scored by KiCad's DRC) and `gen_sch.py`
(schematic), then writes the fabrication files to `fab/`. `export_scad.py` writes
`board.scad` (outline, screw holes, every part as a box), which `../bass/elec.scad`
includes. The scripts come from `../hall_pcb/` and from the discant's old main board
(git history: `discant/main_pcb`), whose module, DAC and USB circuit this board keeps.

## 1. Place and size [given: elec.scad]

- **45.5 × 33 mm, 1.0 mm thick**, flat on the front wall's inside, 0.47 mm above it
  on three pads; parts on one side only, facing the back cover. 5.1 mm from the
  board's top to the back cover.
- **Board frame:** X from the board's edge at the +x side wall towards −x, Y up (the
  bass's z), seen from the parts. USB-C and charge light sit at X = 0, in the side
  wall: USB-C at Y 21.3 (z −104.5), light at Y 29.0. The earphone jack is the case's
  (§2), its axis over the board at Y 9.8.
- **Four layers** [chosen]: top, ground plane, signals, bottom. The bottom carries no
  parts, so it routes freely; all four are filled with ground where nothing else runs.
  Tracks 0.127 mm, power 0.4 mm where it fits; vias 0.45 / 0.2.
- **Screws:** three M2 from the parts' side into pilots in the front wall,
  (4.4, 30.6), (25.0, 30.6), (22.4, 2.6). No copper on the top under the heads
  (⌀4.4). The pilots were placed clear of the hand plate's 1 mm recess (2 mm wall
  behind it); the recess is gone since [given 2026-11-15], the wall 3 mm everywhere.
  The old placeholder had one pilot under the module.
- **Antenna:** the module's antenna end at the board's bottom edge; no copper on any
  layer from X 24.6 to the edge below Y 6.6.

## 2. Circuit

JLCPCB/LCSC part numbers: `LCSC` in `design.py`, into the schematic and the BOM
(`fab/main_pcb-bom.csv`, JLCPCB's columns) [all in stock, checked 2026-11-15]; L1 is
Sunlord SWPA252012S2R2MT (2.2 µH, Isat 2.07 A), F1 SMD1206P150TF, FB1 Murata BLM15AG601SN1D.

| Part | What for |
|---|---|
| ESP32-S3-WROOM-1-N16R8 | the controller; USB on its own pins (firmware, MIDI) |
| GCT USB4105-GF-A, USB-C 16 pin | charging, firmware, MIDI; 5.1k on CC1/CC2 (a sink); USBLC6-2SC6 on D+/D− |
| BQ24074RGTR | charger with power path: OUT (VSYS) runs the system from USB or battery |
| TPS63001DRCR, 2.2 µH | buck-boost to 3.3 V from VSYS (3.0 … 4.4 V) |
| AO3401A × 2, BAT54C | the system switch (DET, VBUS) and the discant's 3.3 V (DET only) |
| LTST-S326KGJRKT, DMG1012T × 2 | the red/green charge light; the green switch and the ESP32's low-battery red |
| TLV320DAC3100IRHB, TLV75518 | I²S DAC with headphone driver; its 1.8 V core supply |
| 3 solder pads P19–P21 | the earphone jack's wires (tip, ring, sleeve); 100 µF coupling caps on the board |
| SRV05-4 | ESD on the contacts' SDA, SCL, INT |
| PTC 1206, 1.5 A hold | in the battery's plus lead |
| 18 solder pads 1.5 × 1.5 | the wires (§4) |

- **Earphone jack in the case** [given 2026-11-15: a panel jack fixed in the case, a
  bulge in the back cover allowed]: Switchcraft 35PRM3 (metal, M6 × 0.75, knurled
  nut; flange ⌀9.5, body ⌀7.7, 21.3 behind the wall [datasheet: drawing 35PRM3]),
  through the side wall from inside, its body over the board 1.0 above it, three
  wires to P19–P21 under its lugs. Plugging loads the case, not the board. Under the
  jack (`JACK_ZONE`) the parts stay low; on its axis the body clears 1.9 mm, the
  flange at the board's edge 1.0 (`gen_pcb.py` lists the parts there, the bass's
  clash check proves them). The on-board SJ-3523-SMT before stood 5.2–5.37 high
  [distributors], more than the 5.13 to the back cover.
- **Battery protection in the cell** [chosen 2026-11-14]: the pouch cell comes with
  its own protection board (PCM), as cells with leads usually do; the board only adds
  the fuse. This saves the DW01A and its two FETs, for which the board had no room.
  [unverified: the cell actually ordered]
- **Charger settings** [datasheet, values to check]: ISET 1k ≈ 0.9 A charge (0.22 C for
  4 Ah); ILIM 1.5k ≈ 1.0 A from USB (EN2 high, EN1 low); TS a fixed 10k (no
  thermistor in the cell [unverified]); TMR 75k, a fast-charge timer of about 10 h
  [unverified: K_TMR]; ITERM open, 10 % termination; CE low.
- **Charge light** [given 2026-11-15: red while charging, green when full, red also when
  the battery runs low]: a side-emitting red/green LED with a common anode on VSYS
  (LiteOn LTST-S326KGJRKT [unverified: which pad is which colour; height 1.6]), its lens
  at the board's edge behind the wall's ⌀1.6 hole. About 1.5 mA each [estimated].
  - **Red** through R9 (1k5) into the charger's ~CHG, low while charging; and into Q5
    (DMG1012T), which the ESP32 turns on through IO42 (LOW_BAT, R28 100k down, so it
    is off while the ESP32 is not running).
  - **Green** through R27 (1k5) and Q4 (DMG1012T) into the charger's ~PGOOD, low only
    with USB. Q4's gate is ~CHG, pulled up through the red LED and R9 once ~CHG lets
    go: green comes on when the charge is done and red goes off. Without USB ~PGOOD is
    open, so no green.
  - **Firmware:** LOW_BAT on when VBAT (IO1) falls below a threshold and no USB is
    there (IO41), e.g. 3.4 V [chosen, to be tuned]; blinking is up to it.
  - [unverified: no current into an unpowered charger's ~CHG from VSYS through red and
    R9; the BQ24074's ~CHG and ~PGOOD sink current for the LED, datasheet]
- **3.3 V:** TPS63001, PS/SYNC high: fixed frequency, no power-save bursts near the
  audio. It carries the ESP32 (up to about 350 mA in bursts), both key boards' sensors
  (46 + 18 × 2–4 mA [datasheet], up to about 260 mA) and the ADCs. [estimated]
- **Measuring:** VBAT through 1M/1M to IO1 (ADC); VBUS through 100k/100k to IO41;
  the discant's 3.3 V through 10k (100k down) to IO40, so the firmware knows whether
  the discant is plugged.

## 3. Switching on [given: assembly/spec.md, plugging switches the system on]

- **DET** is pulled up to VSYS (1M, 10k in series) and tied to ground by the discant's
  contact board when the halves are plugged for playing. Pulled low:
  - **Q2** (AO3401A, from VSYS) drives the regulator's EN: the system is on;
  - **Q3** (AO3401A, from 3.3 V) passes 3.3 V to the contacts for the discant. The
    100 nF on its gate (with the 10k) ramps it over about 1 ms, against the
    discant's capacitors.
- **USB alone** also switches the system on (VBUS into EN through the BAT54C), so that
  firmware can go in and the ESP32 can show the battery while it charges; the
  discant's 3.3 V stays off: apart, the contacts carry nothing. The firmware may put
  the ESP32 to sleep when neither DET nor a USB host is there.
- Off, the battery feeds only the charger's quiescent current and the 1M dividers
  (about 2 µA). [estimated]

## 4. Pins and wires

**I²C, two buses** [given: the discant's ADCs use 10h–15h; ../hall_pcb/spec.md §6]:

| | ESP32 | |
|---|---|---|
| bus 1, through the contacts | IO9 SDA1, IO14 SCL1, IO21 INT1 | discant's ADCs 10h–15h, the gauges' NAU7802 (2Ah); pull-ups 2k2 to the discant's 3.3 V, so the pins carry nothing apart |
| bus 2, in the bass | IO47 SDA2, IO48 SCL2, IO38 INT2 | bass's ADCs 10h–12h, the DAC (18h); pull-ups 2k2 to 3.3 V |
| I²S | IO10 MCLK, IO11 BCLK, IO12 WCLK, IO13 DOUT | DAC |
| others | IO39 DAC reset, IO40 discant on, IO41 VBUS, IO1 VBAT, IO42 low-battery light, IO0 boot | |

The module's pins face the parts on its long side (27–40) and its top end (15–26);
I²S drops straight from pins 18–21 to the DAC above them.

**Solder pads** along the bottom edge, two rows of nine at 2 mm, where the wires
arrive (elec.scad `wires()`): the contacts' nine (3.3 V × 2, GND × 3, SDA, SCL, INT,
DET), the bass key board's five (3.3 V, GND, SDA, SCL, INT), the battery (+ via the
fuse, −), a spare GND and 3.3 V. The wires and their lengths: `../assembly/spec.md`, Wiring. Test pads for boot, reset, TX, RX and GND at the top.

## 5. Open

- **Pinouts:** the module, USBLC6, BQ24074, TPS63001, TLV755, SRV05, AO3400/AO3401
  were checked against KiCad's symbol library; the DAC's pinout against SLAS671C's pin
  table (2026-11-15: all 32 pins as in `design.py`; I²C 18h; RESET low; SPKVDD at
  3.3 V is allowed, it must not be below AVDD), the BAT54C's from its datasheet.
- **3.3 V budget** [estimated 2026-11-15]: ESP32-S3 about 100 mA (peaks about 350),
  64 Hall sensors 130 … 260 mA [datasheet: SBAS640C], DAC 10 … 30 mA, NAU7802 with
  the gauges about 10 mA, ADCs under 1 mA: about 270 mA typical, 650 mA peak.
  The TPS63001 gives 1200 mA in step-down (VIN 3.6 … 5.5 V) and up to 800 mA in boost
  (VIN > 2.4 V), switch limit 1.6 … 2.0 A [datasheet: SLVS520C, checked 2026-11-15]: the
  650 mA peak fits even on a low battery (inductor peak about 0.83 A at VSYS 3.0 V, 1.0 A
  at 2.5 V, by its Equation 4). Pinout as in `design.py` (FB to VOUT, PS/SYNC high,
  VINA through 100 Ω); 10 µF in (≥ 4.7 µF), 3 × 22 µF out (15 µF nominal) are within
  its advice. L1 is 2.2 µH as in all the datasheet's examples [chosen 2026-11-15; was
  1.5 µH], 1008, Isat 2 A (peak about 0.82 A at 3.0 V, by Equation 4).
- **Routing** [2026-11-14]: all nets routed (four tries, the best kept); KiCad's DRC
  finds no clearance errors, shorts or open connections. What it still lists: the
  USB socket's shell pads at the board's edge (they reach past it by design), the
  wire pads' and the module's courtyards (the pads sit closer than their courtyards,
  the module's courtyard carries its antenna's keepout), silkscreen, and one GND
  pad with fewer thermal spokes. One fix by hand after build.sh: a 0.4 mm +1V8
  piece at the DAC narrowed to 0.127 mm, too near SCL2; route.py no longer counts
  +1V8 as power (a few mA), so a new build does not need it.
- The DAC's speaker outputs are left open (earphones only).
