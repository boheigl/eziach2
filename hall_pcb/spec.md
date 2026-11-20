# Hall-sensor boards — design record

The key boards for the Hall-sensor keys of `../switch_hall/`. Tags:
**[given]**, **[datasheet]**, **[chosen]**, **[estimated]**,
**[unverified]**.

`design.py` is the one source (parts, nets, placement) for both boards; the
environment variable `HALL_BOARD` picks `discant` or `bass`. `build.sh discant` /
`build.sh bass` runs `gen_pcb.py` (board), `route.py` (routing, up to three tries
scored by KiCad's DRC) and `gen_sch.py` (schematic), then writes the fabrication
files to `<board>/fab/` and a browser view (`export_view.py`, `<board>/viewer.html`). The routing scripts come from the old `../discant/main_pcb`
(git history), reduced to two layers.

## 1. Decisions [given, 2026-11-13]

- **One board for the whole discant**, in the staircase's slope plane. A board
  for the bass will follow from the same description.
- **No controller on the board.** ADS7128 ADCs on I²C; the ESP32 in the bass
  reads them over the existing 5-wire bus (INT, 3V3, SDA, SCL, GND) through the
  bellows. The calibration lives in the ESP32.
- **The gauges' ADC on the discant board** [chosen 2026-11-15]: the NAU7802 that reads
  the two strain gauges sits on this board at its back edge, between the gauges; the
  separate link board in a pocket beside them is gone (§3a).
- Sensors **always powered** (no group switching, since nothing on the board
  could switch them).

## 2. Geometry [chosen]

- **Frame:** X along the rows, Y up the slope in the board's plane; row k's keys
  at Y = k × 16.28 (√(16² + 3²)), key h of row k at X = −120 + 20 (h − 1) + 10 k.
- **Tilt:** the four rows differ by a pure shift (10, 16, 3), so a flat board in
  the slope plane lies under every key at the same place. It is tilted 10.6°
  against each row; `../switch_hall/key.scad` (`board_tilt`) keeps the collar
  0.43 mm higher for it.
- **Sensor position:** each sensor sits on the board's underside where its key's
  axis meets the Hall element: 0.40 mm down the slope from where the axis meets
  the board's top ((1.6 + 0.55) × 3/16; element depth 0.55 [unverified: SBAS640C Figure 6-5 gives 0.65 ± 0.08]).
- **Outline:** a trapezoid 265.8 × 64.8 mm, its slanted ends parallel to the
  staircase's ends: 8 mm beyond the outermost keys along X, 8 mm in front of row
  0 and behind row 3.
- **Screw holes:** ⌀2.2 for M2 (cover through the board into the housing; **brass**
  countersunk machine screws, DIN 965 CuZn, which cut their own thread in the housing's
  ⌀1.7 pilots (over the tap drill 1.6: printed holes come out small) [given 2026-11-15: brass, not steel, near the magnets]; the pilots hold
  only about 2.2 mm under the board, too little for heat-set inserts; tighten gently,
  brass is soft), on a regular
  grid every 40 mm [given 2026-11-14]. In each gap between two rows a line of them, each
  in the middle of three keys [given 2026-11-15: half way between two keys, 9.5 from
  their axes, they came too near the keys]: two of the lower row and the upper row's key
  between them, 11.2 from all three axes (5.07 up from the lower row; `TRI_Y` in
  `design.py`), so the screw's countersunk head (⌀4) stays 1.7 clear of the caps (⌀15)
  in plan. A line 3.5 in front of row 0 [given 2026-11-15: at 5 the thumb bar stood
  0.9 mm into a 3 mm screwdriver's way], 10.6 from its keys, and one 5 behind row 3,
  half way between its keys, 11.2 from them. 27 holes on the discant; the ADCs stay on the gaps'
  middle lines between them.
- **All parts on the underside**, so the cover with the key tubes lies flat on
  the top, which carries only the ground plane.

## 3. Circuit

JLCPCB/LCSC part numbers: `LCSC` in `design.py`, into the schematic and the BOM
(`fab/<board>-bom.csv`, JLCPCB's columns) [all in stock, checked 2026-11-15].

| Part | Count | What for |
|---|---|---|
| DRV5055A3QDBZR, SOT-23 | 46 | linear Hall sensor, 15 mV/mT and ±88 mT at 3.3 V, ratiometric; pins 1 VCC, 2 OUT, 3 GND [datasheet: SBAS640C, checked 2026-11-15] |
| 100 nF 0402 | 46 | one beside every sensor (datasheet: at least 10 nF) |
| ADS7128IRTER, WQFN-16 3 × 3 | 6 | 8 channels, 12 bit, I²C [datasheet SBAS868A] |
| 1 µF 0402 | 18 | AVDD, DVDD and DECAP of every ADC [datasheet] |
| address resistors 0402 | 5 | 11h/12h/13h: 11k/33k/100k to GND; 14h/15h: 100k/33k to DECAP; 10h: none |
| discant: J1, a row of 5 wire pads (2 mm, plated holes) / bass: JST SH BM05B-SRSS-TB (vertical) | 1 | bus: INT, 3V3, SDA, SCL, GND; on the discant the contacts' wires, soldered from the top |
| 10 µF 0805 | 1 | on +3V3 by the bus's way in |
| 10k, 4k7, 4k7 0402 | 3 | pull-ups INT, SDA, SCL |

- **ADCs:** AVDD is also the ADC's reference. Sensors and ADCs share 3.3 V, so the
  reading is ratiometric and supply drift cancels. [datasheet]
- **ALERT** is its own pin on the ADS7128, so all 8 channels are inputs: 6 ADCs
  give 48 channels for 46 keys. The six ALERTs (open drain) are wired together to
  INT. Each channel's digital window comparator takes the calibrated actuation
  point with hysteresis, and the ESP32 reads the flags when INT falls. ALERT is
  open drain by default [datasheet: SBAS868A]; the firmware must not set it to
  push-pull (ALERT_PIN_CFG), or the six outputs fight.
- **Pinout and addresses checked** against SBAS868A (2026-11-15): pins as in
  `design.py`, Table 2's resistors (R1 to DECAP, R2 to GND) give 10h … 15h as planned.
- **ADS7128, not ADS7138** [chosen 2026-11-15]: the ADS7138 was the first choice, but
  JLCPCB had 39 at 7–9.5 $ each (9 per instrument). The ADS7128 (C2867992, about 2–3 $)
  is its superset: same pins and address table, and all of the ADS7138's 110 registers
  at the same addresses; it adds only the RMS and zero-crossing modules (registers 0Fh, C0h–C2h,
  E3h–E7h) [datasheets SBAS868A, SBAS976A compared 2026-11-15]. Firmware written for
  the ADS7138 runs unchanged. The TLA2528 (cheaper still) has no ALERT pin (pin 12 NC).
- **Addresses 10h … 15h** do not collide with the PCAL9555A expanders (20h–27h).
- **Pull-ups:** INT here. SDA and SCL 4k7 here as well [chosen 2026-11-15: fitted],
  parallel to the main board's 2k2 on the same 3.3 V: about 1k5 per line. The ADS7128
  allows a rise time of 120 ns [datasheet SBAS868A, 7.6: one column for standard, fast
  and fast mode plus], the I²C standard 300 ns at 400 kHz; at t_r ≈ 0.85 R C, 2k2 alone
  meets 120 ns only up to about 64 pF, 1k5 up to about 94 pF. Each bus carries about
  80–120 pF [estimate: wire, 6 or 3 ADCs, NAU7802 or DAC, ESD diodes, ESP32, tracks].
  1k5 sinks about 2 mA at 0.4 V, within I²C's 3 mA (R ≥ 1 kΩ). To check: the rise time
  on SCL/SDA with a scope on the assembled instrument (bus 1 with the discant plugged);
  if it stays under 120 ns without them, they can come off.
- **Current:** 46 × 2–4 mA = 92 … 184 mA for the sensors, plus well under 1 mA for
  the ADCs. [datasheet: SBAS640C, SBAS868A]

## 3a. The gauges' ADC (discant) [chosen 2026-11-15]

| Part | Count | What for |
|---|---|---|
| NAU7802SGI, SOP-16 (C2614351) | 1 | U7: both half bridges, 24 bit, I²C 2Ah [datasheet: Nuvoton NAU7802 Rev 2.6] |
| J2, J3: 3 wire pads each (2 mm, plated holes) | 2 | the gauges' leads E+, middle, E− |
| 10k 0.1 % 25 ppm/K 0402 (C190095) | 4 | a divider of AVDD for each half bridge's other side, the two side by side |
| 47R 0402, 100 nF 0402 | 4 + 2 | the input filter per channel, as the datasheet's application circuit |
| ferrite 600 Ω, 10 µF + 100 nF | 1 + 2 | AVDD from +3V3 (the LDO stays off, the power-on default) |
| 100 nF, 1 µF + 100 nF, 100 nF | | REFP/GREF, DVDD, VBG |

- **Where:** underside, middle of the back edge (X 0, Y 49.4), pins 1–8 (the analog
  side) towards the edge. J1 (bus) at X 0, J2/J3 at X ∓12, all 1.8 inside the back
  edge, straight in front of the channels that bring the wires under the board
  (`../discant/gauge_link.scad`): gauge leads about 19 mm, contacts 28 mm [model].
- **Ratiometric:** REFP and the bridges' excitation are both AVDD, so supply noise and
  drift cancel to first order. With AVDD at 3.3 V the bridge middles sit at 1.65 V,
  inside the PGA's common-mode window at gain 128 (AVSS + 1.5 … AVDD − 1.5 V, given at
  5 V) [datasheet]; the LDO at 3.0 V would have left none. The ferrite keeps the Hall
  sensors' and ADCs' ripple off AVDD.
- **Analog beside digital, checked 2026-11-15:**
  - Signal: the bought load cells give 1 mV/V at 490 N, 6.7 µV/N at 3.3 V; playing
    forces of 20–40 N are 0.13–0.27 mV (`../strain_gauge/spec.md` §4a). The NAU7802's
    noise is 50 nV at 10 SPS, 150 nV at 80 SPS [datasheet]: about 0.02 N. Disturbances
    under about 0.1 µV do not matter; the estimates below stay under that.
  - I²C (400 kHz, SDA/SCL beside and over the chip): coupled through about 0.02 pF
    into an input that carries 100 nF, 3.3 V edges give under 1 nV; the input filter
    (47 R + 47 R, 100 nF: about 17 kHz) and the sinc filter at 2.3 / 18 Hz bandwidth
    take the rest. The bus traffic is the same wherever the chip sits; the link board
    had it too.
  - Hall sensors and ADS7128: no switching supply on the board; their current comes
    and goes slowly and returns through the ground plane on the top, not through the
    gauges' E− wires, which go to the chip's own ground pins.
  - Leads: 19 mm each in the groove, away from the bus wires; before, the far gauge's
    76 mm ran beside SDA/SCL in the same groove. Better than before.
  - The other way round, the gauges' currents against the Hall sensors [estimate
    2026-11-15]: the bridges' excitation (DC, about 3.3 mA per 1000 Ω cell) is the
    only current worth a look; 3.3 mA 1 mm from a sensor gives 0.7 µT, 0.01 mV at
    15 mV/mT, far under the ADS7128's 0.8 mV step, constant (the calibration takes
    it), mostly cancelled by its return beside it and lying in the board's plane, which
    the DRV5055 does not sense. The ferrite FB1 sits 5 mm beside U141, off the
    magnet's axis. The sensors' own 90–180 mA on +3V3 were there before.
  - Heat: the board's 0.3–0.6 W warms the dividers slowly and both resistors alike;
    their ratio drifts with their 25 ppm/K mismatch at most, which taring at start
    takes out.
- **Gauges** [given 2026-11-15]: two bought half-bridge load cells of 1000 Ω, about
  6.6 mA from AVDD in all through the ferrite (300 mA). DRDY is unused (the ESP32 polls,
  `../assembly/spec.md`).

## 4. Which ADC reads which key

- **Lower three ADCs** (between rows 0 and 1, Y = 8.1): all of row 0 and row 1
  except its rightmost key, eight each, by X.
- **Upper three ADCs** (between rows 2 and 3, Y = 40.7): the rest, 7/7/8, by X.
- **Channels:** `gen_pcb.py` assigns the keys to the AIN pins by angle round the
  chip, so the tracks fan out without crossing. The firmware's table is
  `discant/channels.json` (address → AINn → row, key).

## 5. Layout rules [chosen]

- Two layers, 1.6 mm. Tracks 0.2 mm, clearance 0.2 mm; 3.3 V 0.4 mm where it
  fits. Vias 0.6 / 0.3. Copper to the edge 0.3 mm.
- **Routing:** on the underside. The top is the ground plane; tracks cross it
  only briefly (4 × the cost per mm). Every ground pad gets a via to the plane
  first; both faces are then filled with ground. Net order: the short nets at
  each ADC (DECAP, ADDR), then the bus (SDA, SCL, INT), then +3V3, the key lines
  last. Routed first, the key lines filled the ADCs' surroundings and left the bus
  and +3V3 unrouted (2026-11-14: 35 open on the discant, 14 on the bass).
- **The bus on the top** [chosen 2026-11-14]: SDA, SCL, INT and +3V3 run from ADC
  to ADC, and every ADC's key lines fan out all round it, so on the underside alone
  the bus has to cross a fan at every chip (bus first: 23 open on the discant, 15 on
  the bass, nearly all of them bus and +3V3). In lanes along each row of ADCs, and
  from there to the connector (on the discant to J1 and the NAU7802 in the middle of the
  back edge) (`BUS_LANES` in `design.py`), the top costs the bus no
  more than the underside, and the underside costs it 1.6; it drops to the pins
  through vias. The lanes form a tree, so the ground plane stays one piece round
  their ends; the bus's 400 kHz and the slow sensor signals do not mind the slot.
- **No via in a pad** [2026-11-18, review/hall_pcb.md MAJOR]: the router dropped vias
  into or against SMD pads (182 on the discant, 72 on the bass), where solder runs down
  them. The vias are tented and the pads' mask openings are their copper, so a via's
  drill now keeps 0.15 mm from any SMD pad's copper (`novia` in `route.py`); its ring
  may touch the pad, or a short neck joins them. Thermal pads (the ADCs' exposed pads)
  are exempt. Checked on the boards with a pcbnew script: no drill in or within 0.15 of
  an SMD pad.
- **ADC fan-out** [2026-11-19]: without vias in the pins the ADCs' pins ended up
  enclosed by +3V3 and the bus round each chip, and the key lines, routed last, found no
  way out (26 open on the discant). So before any net, every signal pin of an ADC
  (not GND, not DECAP) gets a short track to a via on a ring 2.5 mm round the chip's
  middle, the middle pins of each side first (the corner pins can still turn aside);
  a pin left over has its chip's fan-outs redone with it first, all 81 then fit. The
  fan-outs belong to their nets from the start and stay when a net is torn up.
- **Stitching** [2026-11-19]: tracks on a face cut pieces off its ground fill; a piece
  holding a GND pad's via is then off ground (KiCad keeps it: not an empty island).
  After the fill every piece but the largest gets a GND via into the other face's
  largest piece, and the faces are filled again.
- **Finishing round** [2026-11-19]: tearing up others stops after 25 minutes in the
  main pass; the nets still open are then routed once more with tearing allowed until
  minute 42 (build.sh stops a try at 50).
- **Rip-up:** a cell in the clearance of two nets may be torn up too (both nets
  go); the search for a way through others' copper runs from the terminal back to
  the net's tree, since a terminal shut in otherwise ran the search out of steps.
- **Small parts at the ADC:** 3.5 mm out from the pin they serve, pads radial.
  The DVDD cap (pin 10) sits out past pin 9, the address resistor (pin 11) in front
  of pins 10/11, so ALERT (pin 12, at the corner) leaves straight outwards; with the
  resistor in front of it, its ADDR track and SCL round the corner shut it in.
- **The ADCs' turn** (`ADC_ROT`, environment `HALL_ADC_ROT`): at 45° a corner points
  along the row, the one with ALERT, SCL and SDA (pins 12–14) to +X, into the gap
  between the keys' fans, where the bus runs; the four sides face the four diagonal
  directions in which the keys lie. `gen_pcb.py` lays the small parts out in the
  chip's own frame and turns them with it. Turning cannot spare the bus its
  crossings (a chain through a node ringed by the key lines), only ease the escape
  from the pins. **45° is the default** [chosen 2026-11-14]: with the bus lanes,
  three tries each, the best left 15 open on the discant (0°: 21) and 2 on the
  bass (0°: 14). Five more tries on the discant, starting from its open nets
  (`HALL_PRI`), brought it to 9: SDA, SCL, INT and four key lines (KEY1_6, KEY1_10,
  KEY3_6, KEY3_7); four more on the bass did no better than 2 (+3V3 and one key
  line).
- **Routed again** [2026-11-18/19, with no via in a pad, the fan-out, stitching and the
  finishing round; the boards finished by hand on 2026-11-15/16 are in git history, and
  R12, moved by hand then, is back where `design.py` puts it]:
  - **Bass:** all routed by `build.sh bass` itself (the third of three tries, the bus and
    +3V3 and the three key lines open before first); 114 vias, none in a pad.
  - **Discant:** some thirty tries ended with 1 to 26 open; the best three times 1,
    always the bus to U3 (from J1 down the middle, along the upper row, down the left
    link and along the whole lower row to its right end: about 240 mm; a middle link
    down to the lower row did worse). The best of them was completed with
    `ROUTE_COMPLETE=SDA:U3:14 route.py discant/discant.kicad_pcb`: the board's copper
    goes into the maps, the pin's piece of SDA is joined to the rest, only the paths of
    other nets in the way come out and those nets are joined up again (10 nets
    touched round U3). The rest of `build.sh`'s steps (schematic, fab files, DRC,
    viewer, board.scad) were then run on it by hand. 344 vias, none in a pad.
  - KiCad's DRC on both: no unconnected items, no clearance errors or shorts; left are
    silkscreen, dangling vias (fan-outs the net reached elsewhere) and a few dangling
    track stubs. Channels (`channels.json`) unchanged, so the firmware's table holds.

## 6. Bass board [given: from the same description]

- **Keys:** 2 × 9 as `../bass/layout.scad`: front row x = −80 … 80 at y = 0, back
  row x = −70 … 90 at y = 16.
- **Flat, not tilted** [chosen]. The back row stands 10 mm higher; a board in
  that slope would be tilted 32°, and the collar would have to stop 1.4 mm
  earlier. Instead the board lies flat under both rows, and the back row's tubes
  and pins are 10 mm longer. Spring, stops and the magnet's distance to the sensor
  stay the same, so all keys behave alike (`riser` in ../switch_hall/key.scad).
- **Outline:** a parallelogram 176 × 32 mm, both ends slanting with the rows'
  10 mm offset, 8 mm beyond the outer keys.
- **Three ADS7128**, between the rows at x = −55 / 5 / 65, six keys each, by X;
  addresses 10h, 11h, 12h.
- **Own I²C bus:** the discant already uses 10h–15h, and the ADS7128 has only
  eight addresses, so the bass board goes to the ESP32's second I²C controller
  inside the bass box. Same 5-pin JST SH, at the −x end between the rows, where
  the bass boards' wires drop into the box today.
- **Screw holes:** as the discant's, every 40 mm: four 5 in front of the front row
  (x −50 … 70), four behind the back row (y 21, x −40 … 80), and four between the rows
  in the middle of three keys [given 2026-11-15], 4.88 up from the front row, 11.1 from
  the three axes (x −70 … 50; the line half way between two keys had a fifth at x 85,
  for which the board's slanted end leaves no room now).
- **Current:** 18 × 2–4 mA ≈ 55 mA.
- Replaces the two sawn switch boards and their PCAL9555A expanders (24h, 25h).
