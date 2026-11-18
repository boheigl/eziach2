# Review: Hall-sensor key boards (hall_pcb/discant, hall_pcb/bass)

Reviewer: independent check before the JLCPCB order, 2026-11-18. Read-only: nothing in
the project was changed. Scripts and datasheet extracts are in the session scratchpad
(`review_hall/`); none of them is needed to read this report.

Datasheets used (downloaded and text-extracted, page images checked where needed):
- ADS7128 SBAS868A (May 2020), the copy supplied.
- DRV5055 SBAS640C (rev. June 2026), ti.com/lit/ds/symlink/drv5055.pdf.
- NAU7802 Nuvoton data sheet **Rev 1.7** (nuvoton.com). design.py and nau7802.c cite
  "Rev 2.6"; I could not get a Rev 2.6. Everything below refers to Rev 1.7.
- LCSC product pages for all 16 LCSC numbers (title = manufacturer part number).
- JLCPCB capability pages (assembly size and side limits, via plugging rules).

## Summary

**Discant (46 keys, 6 × ADS7128, NAU7802):** the circuit is correct. Every pin of every
IC matches its datasheet, all 46 sensors sit exactly on their computed key positions,
and every key's sensor output reaches the ADC input that channels.json names. The
addresses are 10h–15h plus 2Ah. DRC: 0 unconnected, 0 clearance errors, and the zone
fill is up to date. The one real problem is manufacturing: the router put
**181 vias in or against SMD pads**: every sensor's GND pad, most 0402 GND pads, and the
toes of the ADS7128's SCL/INT/GND pins. That needs fixing or an explicit decision before
ordering.

**Bass (18 keys, 3 × ADS7128, JST SH):** same verdict. The circuit, placement and
channel table are correct, and DRC is clean. It has the same via-in-pad problem
(**64 vias**), including in 4 of the 5 signal pads and both MP pads of the J1 connector.

| Severity | Discant | Bass |
|---|---|---|
| BLOCKER | 0 | 0 |
| MAJOR | 1 | 1 |
| MINOR | 3 | 2 |
| NOTE | 12 | 8 |

(One finding that applies to both boards is counted once per board.)

## Findings

### F1. MAJOR, both boards: vias placed in SMD pads (solder wicking)

- **What:** the auto-router changes layer, and puts the "GND pad gets a via to the plane
  first" via, directly on pad cells (route.py, GND vias and layer changes at any cell).
  The hand finishing kept them. All vias are 0.6/0.3 mm, tented on both sides
  (`(tenting front back)`). A via inside a pad's solder-mask opening is open on the
  bottom, the side being soldered.
- **Where / evidence** (pcbnew, drill circle colliding with the pad copper of the same
  net):
  - Discant, 181 in total:
    - DRV5055 pin 3 (GND) on **all 46 sensors**, drill fully inside the 1.48 × 0.6 pad.
    - DRV5055 pin 1 on U107, U115, U134 and U135.
    - 0402 parts: 53 × 100n, 29 × 1u, R2, R3, R4, R11, R13, R22, R24, R28 and R30, plus
      C1 and C2.
    - NAU7802 U7 pins 1, 7, 8, 9, 13, 14 and 15.
    - ADS7128: the 6 EP vias are fine (normal for a thermal pad). However, on each of
      U1–U6, vias sit **0.006–0.13 mm beyond the toe** of the 0.25 mm-wide pin pads, so
      the 0.3 mm drill cuts into the pad: pin 13 SCL on all six, pin 9 GND on all six,
      pin 12 INT on U2, U4, U5 and U6, pin 1 KEY0_8 on U2, and pin 4 KEY0_9 on U3.
  - Bass, 64 in total:
    - DRV5055 pin 3 on all 18 sensors, and pin 1 on U114.
    - 19 × 100n, 12 × 1u, R2, R3, R12, R13 and C1.
    - **J1 BM05B pins 2, 3, 4 and 5 and both MP pads.**
    - ADS7128 pin 13 SCL and pin 9 GND on U1–U3, and pin 12 INT on U3. The drill edge is
      0.04–0.12 mm into the pad.
  - Scale of the problem: a 0.3 × 1.6 mm hole holds about 0.11 mm³ of solder. A stencil
    print on an 0402 pad is about 0.04 mm³, so the hole can take all of it. The usual
    results are starved joints, tombstoned 0402s and tilted SOT-23s.
- **Why it matters here:** a starved SCL joint on any ADC silences it. On the bass, SCL
  is shared, so all three ADCs would be at risk. A tilted DRV5055 changes the
  magnet-to-element distance and the in-plane position from key to key. J1 is a
  connector that takes plug forces, so its pads need full fillets.
- **Fix (preferred):** in KiCad, pull each via off its pad with a short neck (a
  "dog-bone"), so that solder mask separates the via from the pad's opening. JLCPCB's
  own rule for plugged vias asks for at least 0.35 mm between a via and a mask opening.
  Do this at least for:
  1. the ADS7128 pin toes (SCL, INT, GND, KEY0_8, KEY0_9);
  2. all J1 pads on the bass;
  3. the DRV5055 pads.

  The 0402 decoupling caps are the least critical. At their GND end, a via just outside
  the pad also keeps the ground return short.
- **Alternatives:**
  - Accept the risk and ask JLCPCB to review it in their DFM check. JLCPCB's plugged/capped
    via-in-pad service is listed only for 4+ layer boards (capabilities page); for
    2-layer boards their "plugged via" option forbids mask openings near the via.
  - Leave the ADS7128 EP vias as they are; vias in a thermal pad are normal.

### F2. MINOR, discant: no ESD protection on the discant's side of the contacts

- **What:** when the halves are apart, the discant's contact pads lead directly to J1
  and from there to the SDA, SCL and INT pins of six ADS7128s and the NAU7802, and to the
  board's +3V3. The SRV05-4 (main_pcb design.py, U8) protects only the bass side.
- **Evidence:** ADS7128 ESD rating ±2000 V HBM and ±500 V CDM (SBAS868A §7.2). NAU7802
  passes ±4 kV HBM (Rev 1.7 §7.5.3). The pads are exposed whenever the instrument is
  stored or handled apart.
- **Fix:** add a 4-line TVS array (the same SRV05-4, LCSC C85364, SOT-23-6) next to J1 on
  the discant board: SDA, SCL, INT, with VDD to +3V3 and GND. Alternatively, put it on the
  contact board on the discant side.

### F3. MINOR, both boards: +3V3 is routed in 0.2 mm everywhere (spec says 0.4 mm where it fits)

- **Where:** every track on every net is 0.2 mm (discant 3253 mm of track, bass
  1241 mm). spec.md §5 says "3.3 V 0.4 mm where it fits".
- **Evidence:** a resistive solve of the real +3V3 copper (pcbnew geometry, 35 µm Cu,
  each sensor at its 4 mA maximum (SBAS640C §5.5: 2 mA typical, 4 mA maximum at 3.3 V),
  current fed in at J1 pin 2) gives:
  - **Discant:** worst sensor U144 at −46 mV (192 mA in total). ADC AVDD pins sit between
    −8.6 mV (U5) and −45.9 mV (U6), within about 1 mV of their own sensors.
  - **Bass:** worst −14 mV (72 mA). At typical current the drops are half these values.
- **Effect:** DRV5055 VCC stays far above its 3.0 V minimum. The ratiometric error
  between a sensor and its ADC is about half the local difference, under 1–2 LSB, and
  static, so the calibration absorbs it. It works as built.
- **Fix:** correct spec.md, or widen the +3V3 trunk if anything is re-routed anyway.

### F4. MINOR, bass: spec.md §6 gives ADC positions that the board does not have

- spec.md §6 says the three ADS7128 sit "at x = −55 / 5 / 65". On the board they are at
  **−55, −15 and 65** (U1–U3, pcbnew). The middle group's keys centre on x = 5. The slots
  at −15 and 25 are equally far from it, and `min()` picks −15 (design.py lines 151–156).
- This changes nothing electrically, and the channel table is correct. Fix the text.

### F5. MINOR, discant: NAU7802 low-level output is specified only at 1 mA; the bus pull-up asks for about 1.9 mA

- **Evidence:** Rev 1.7 §7.2 gives VOL (SCLK, SDIO, DRDY) ≤ 0.2 DVDD at IOL = 1 mA. Bus 1
  pull-ups are 2k2 (main board, to +3V3_D) in parallel with 4k7 (discant): 1.50 kΩ, so
  (3.3 − 0.4) / 1.5k = 1.93 mA. The ADS7128 is specified for 3 mA at 0.4 V (§7.5), so it
  is fine.
- **Assessment:** the NAU7802 offers a selectable 1.6 kΩ internal "strong" pull-up
  (§7.2), so it is clearly meant to sink about 2 mA. The risk is low, but the datasheet
  does not guarantee it.
- **Check:** at bring-up, look at VOL during the NAU7802's ACK and data bits. If it is
  above about 0.6 V, leave R12/R13 unfitted on the discant (the rise time then has to be
  re-checked, see F6).

### NOTE items

- **N1 (both): JLCPCB placement rotations: check every part type in JLCPCB's 3D/DFM
  preview before paying.** All parts are on the bottom. The pos rotations are:
  - DRV5055 (SOT-23): 0° or 180° (example: U101 0°, U114 180°). The sensors face two
    ways, so check one of each.
  - ADS7128 (WQFN-16): 45°, all of them.
  - NAU7802 (SOIC-16): −90°.
  - Bass J1 (JST SH): 0°.

  What to look for:
  - **SOT-23:** pin 3 (the single pin) must land on the pad netted GND, and pins 1/2 on
    +3V3/KEY. A 180° error swaps VCC and GND and destroys the sensor (abs. max. VCC
    −0.3 V, SBAS640C §5.1).
  - **WQFN at 45°:** the pin-1 dot must point to the pin-1 corner. A 90° error shifts
    every pin by 4.
  - **SOIC-16:** pin 1 must be towards the back edge (pins 1–8 on the edge side).
  - **JST SH:** check pin 1 (INT) against the silk; a 180° error swaps INT↔GND and
    3V3↔SCL.

  Choose **bottom-side** assembly. Economic PCBA allows single-sided placement and
  boards up to 470 × 500 mm (the discant is 265.8 × 64.8), so it qualifies.
- **N2 (both): the mounting-face-to-element distance is 0.65 mm, not 0.55.** SBAS640C
  Fig. 6-5 (page 14, side view) dimensions the element 650 ± 80 µm above the leads'
  seating plane, which is the board face here. SENS_DY would become −0.422 instead of
  −0.403 mm (0.019 mm), and the element sits 0.1 mm further from the magnet. Both are
  negligible. The element is centred in the body to ±50 µm, and the footprint origin is
  the body centre (checked: pad centroid = origin).
- **N3 (discant): NAU7802 XIN/XOUT left open is fine, but unverified.** Rev 1.7 says
  nothing about terminating them. The internal RC oscillator is the power-on default
  (REG0x00 bit 6 OSCS = 0, §11.1), and nau7802.c never sets OSCS. DRDY (pin 12) is a
  CMOS output (§6), so leaving it open is fine.
- **N4 (discant): firmware constraints that follow from this circuit.** All of them are
  met by today's nau7802.c, and they should stay that way:
  - AVDDS (REG0x00 bit 7) must stay 0. The pin is fed from outside through FB1, and the
    LDO's default VLDO is 4.5 V (REG0x01 bits 5:3 = 000), more than DVDD.
  - PGA_CAP_EN (REG0x1C bit 7) must stay 0. It connects a capacitor across VIN2P/VIN2N
    (§11.15), and channel 2 is gauge B here.
- **N5 (discant): NAU7802 common mode.** The bridge middles are at AVDD/2 = 1.65 V. The
  window at gain 128 is AVSS + 1.5 to AVDD − 1.5 V (§7.2), which is 1.5–1.8 V at 3.3 V,
  so the margin is 0.15 V each side. Divider ratio error (0.1 %) and the cells' zero
  (±0.3 mV/V, strain_gauge/spec.md) add only a few mV, so this is fine. The full scale at
  gain 128 is ±12.9 mV. The worst offset is about 2.7 mV plus 3.3 mV at 490 N, which
  fits.
- **N6 (both): unused ADS7128 inputs are left floating.** The discant has two (13h AIN5
  and 14h AIN4); the bass has six (AIN4 and AIN5 of each ADC). That is allowed: they power
  up as analog inputs (SBAS868A pin table). keyio.c samples all 8 channels
  (AUTO_SEQ_CH_SEL = 0xFF) and drops them through the keymap. Leaving them out of the
  sequence would only make each scan faster.
- **N7 (both): I²C rise time is unverified, as spec.md already says.** SBAS868A §7.6
  lists tR ≤ 120 ns in the one column covering standard, fast and fast-mode plus. With
  1.5 kΩ, that holds up to about 94 pF (t_r ≈ 0.85 RC). The bus capacitance is an
  estimate (80–120 pF). Measure SCL and SDA on both buses with a scope, as spec.md plans.
- **N8 (both): KiCad DRC.**
  - Discant: 7 starved_thermal errors, 45 silk_overlap and 22 silk_over_copper.
  - Bass: 3 starved_thermal, 14 silk_overlap, 7 silk_over_copper and 1
    silk_edge_clearance (J1's reference).

  Every starved pad also has its own via or track, and DRC finds 0 unconnected items, so
  all of these are cosmetic. The schematic-parity warnings (6 and 7) are only KiCad's
  `unconnected-(…)` names on the pins left open on purpose: U1 ADDR, the spare AINs, and
  XIN/XOUT/DRDY.
- **N9 (both): select HASL (lead-free), not ENIG, at order time.** switch_hall/spec.md
  chose it to keep nickel away from the sensors. hall_pcb/spec.md does not mention it,
  and nothing in the fab files carries it.
- **N10 (both): stock.** LCSC stock on 2026-11-18 was ADS7128IRTER 730, DRV5055A3QDBZR
  6826 and NAU7802SGI 906 (LCSC pages). One instrument needs 9 / 64 / 1. JLCPCB's own
  stock can differ; check in the BOM step.
- **N11 (discant): INT1 floats at the ESP32 when the discant is unplugged.** The only
  INT pull-up for bus 1 is R11 (10k) on the discant board (main_pcb design.py has none on
  INT1). This is not a key-board fault, but the firmware should ignore INT1 or enable the
  ESP32's internal pull-up while the discant is absent.
- **N12 (both): DRV5055 output noise.** SBAS640C §7.1.3 says never to put a capacitor
  directly on OUT, only after a resistor. The board has none, which is correct. Output
  noise is 3 mVpp at full bandwidth (§5.5), about 4 LSB. If the readings are too noisy,
  ADS7128 averaging (OSR_CFG, which keyio.c sets to 0) is the cheap remedy; no board
  change is needed.

## Checked and OK

The Pinout, Placement, Power and Manufacturing groups below are the evidence for F1–F5
and N1–N12.

### Pinout

- **DRV5055A3QDBZR:** SOT-23 pins 1 VCC, 2 OUT, 3 GND, as in design.py line 122.
  Evidence: SBAS640C Table 4-1. The VCC cap is 100 nF against the required ≥ 10 nF
  (§7.4), 2.3–3.7 mm from the pin (pcbnew).
- **DRV5055 operating point:** recommended VCC 3.0–3.63 V (§5.3). At 3.3 V: 15 mV/mT,
  ±88 mT linear range. The field from switch_hall (7.5–39 mT) is inside it.
- **ADS7128IRTER pinout:** pins 1–4 AIN2–5, 5 AIN6, 6 AIN7, 7 AVDD, 8 DECAP, 9 GND,
  10 DVDD, 11 ADDR, 12 ALERT, 13 SCL, 14 SDA, 15 AIN0, 16 AIN1, thermal pad to GND. This
  matches design.py lines 129–132 and 157–158 and the board pads (pcbnew). Evidence:
  SBAS868A §6.
- **ADS7128 decoupling:** 1 µF on each of AVDD, DECAP and DVDD (§10.1, Figure 160;
  DECAP allows 0.1–4.7 µF, §7.5). Pad-to-pin distances are 1.6, 2.0 and 1.8 mm.
- **ADS7128 address resistors:** none → 10h; to GND 11k/33k/100k → 11h/12h/13h; to DECAP
  100k/33k → 14h/15h. This matches SBAS868A Table 2 (R1 to DECAP, R2 to GND, ±5 %
  tolerance; the parts are 1 %). Each R1–R6 was checked on the board between ADDRn and
  GND or DECAPn, and U1 pin 11 has no net. The ADDR maximum is 2.1 V (§7.1); DECAP is
  1.8 V (§7.5).
- **ALERT:** open drain is the default (§8.3.11). All six (discant) and three (bass)
  pin-12s are on INT, with a 10k pull-up. keyio.c leaves ALERT_PIN_CFG at its default.
- **NAU7802SGI pinout:** pins 1 REFP … 16 AVDD, as design.py lines 218–225. Evidence:
  Rev 1.7 §6.
- **NAU7802 supplies:** AVDD from outside with the LDO off is a documented mode (pin 16
  description; §8.2 "off (high-Z output, default power-on setting)"). AVDD ≤ DVDD is
  required (§7.2) and holds: AVDD = +3V3 less the FB1 drop.
- **NAU7802 VBG:** 100 nF X7R, as §8.7 asks.
- **NAU7802 reference:** REFP = AVDD and REFN = GND. VREF must be 1.5 V to AVDD + 0.1 V
  (§7.2), which it is.
- **NAU7802 input filter:** 47 R + 47 R with 100 nF across, as in §9.4.
- **NAU7802 address:** 2Ah, fixed (§8.3).

### Footprints and BOM

- **Packages vs footprints:** ADS7128 RTE0016C has a 1.68 mm exposed pad (SBAS868A
  mechanical drawing), matching the WQFN-16 EP1.68 footprint. NAU7802 is SOP-16 150 mil
  (Rev 1.7 §12.1), matching SOIC-16 3.9 × 9.9. DRV5055 DBZ matches KiCad SOT-23 (same
  JEDEC pin order).
- **LCSC numbers:** all 16 match their parts (LCSC product pages):
  - C266128 DRV5055A3QDBZR, C2867992 ADS7128IRTER, C2614351 NAU7802SGI (SOP-16).
  - C190095 RT0402BRD0710KL, C25118 0402WGF470JTCE (47 R), C76884 BLM15AG601SN1D.
  - C15525 CL05A106MQ5NUNC, C160391 BM05B-SRSS-TB, C1525 CL05B104KO5NNNC,
    C52923 CL05A105KA5NQNC, C15850 CL21A106KAYNNNE.
  - C25744 10k, C25900 4k7, C25749 11k, C25779 33k (0402WGF3302TCE), C25741 100k.
- **pos files match the boards:** every row (discant 144, bass 55) matches the footprint
  position on the board to within 0.01 mm. The wire-pad connectors J1–J3 on the discant
  are left out of BOM and pos, which is correct (no part fitted).

### Placement and channel table

- **Sensor placement:** a pcbnew script (scratchpad `scripts/check.py`) compared every
  DRV5055 with design.py.
  - Discant: all 46 sensors are at (−120 + 20(h−1) + 10k, k × 16.279 − 0.403). Bass: all
    18 are at (−80 + 20(h−1) + 10k, 16k).
  - The maximum deviation is 0.0000 mm on both boards, and every sensor is on the bottom
    side.
- **Board frame:** not mirrored. KiCad y = 100 − Y; outline, holes, keys and the
  housing's board.scad all come from the same frame.
- **Channel table:** for every ADC and every AIN pin, the pad's net equals
  KEY<row>_<key> as given in `<board>/channels.json`, with no mismatch on either board.
  Each KEY net has exactly two pads (sensor OUT and one ADC pin). All 46 and 18 keys have
  a channel, and each sensor's OUT pad carries its own key's net.
- **Netlist on the boards vs design.py:** every footprint's pad nets match design.py
  (apart from the AIN pins, which gen_pcb assigns, verified above). There are no extra
  footprints, values and footprint IDs match, and all parts are on B.Cu.

### Buses and addresses

- **I²C addresses:** bus 1 has 10h–15h plus 2Ah; bus 2 has 10h–12h plus 18h (the DAC
  address is taken from main_pcb/spec.md; its datasheet was not checked). Both buses are
  unique and clear of the reserved 00h–07h and 78h–7Fh.
- **Pull-ups:** 4k7 on each key board in parallel with the main board's 2k2 gives
  1.50 kΩ. The ADS7128 sinks 3 mA at 0.4 V (§7.5), more than the 1.93 mA needed.

### Power

- **Sensor current:** 46 × 2–4 mA = 92–184 mA, and 18 × 2–4 mA = 36–72 mA (SBAS640C
  §5.5). The IR drop is computed in F3.
- **NAU7802 AVDD path:** FB1 BLM15AG601SN1D is rated 300 mA (LCSC listing). The load is
  about 6.6 mA of bridges plus about 2 mA for the chip.

### Manufacturing

- **DRC** (`kicad-cli pcb drc --schematic-parity --severity-all`): 0 unconnected items,
  and no clearance, short or edge errors on either board. Zones were re-filled on a
  scratch copy with the project rules: the fill area is unchanged and DRC is identical,
  so the committed fill is current.
- **Mounting holes:** discant 27, bass 12, at the design.py positions and ⌀2.2 (milled
  Edge.Cuts circles).
- **Parts vs holes:** the closest part edge is 2.1 mm from a hole edge (R22 and R28 on
  the discant, R11 on the bass). The housing boss (⌀4.4, discant/housing.scad) reaches
  1.1 mm beyond the hole edge, so it is clear.
- **Copper vs edges:** copper stays 0.30 mm or more from every Edge.Cuts outline,
  including the holes.
- **Parts at the board edge:** discant J1–J3 wire pads are 1.8 mm inside the back edge;
  bass J1's courtyard is 0.9 mm from the front edge. No SMD part is closer than 3.6 mm to
  an edge.
- **Board size:** within JLCPCB Economic PCBA (10 × 10 to 470 × 500 mm, single-sided
  placement), so no edge rails or fiducials are needed.

## Not checked

- **The JLCPCB preview itself:** the actual rotation offsets their system applies to
  KiCad 9 bottom-side pos files. This cannot be done offline (see N1).
- **NAU7802 Rev 2.6** (the revision the project cites) could not be obtained; Rev 1.7
  was used. Register-level claims in nau7802.c were checked only for AVDDS, OSCS,
  PGA_CAP_EN and REG0x15.
- **TLV320DAC3100 address 18h:** taken from main_pcb/spec.md, not checked against its
  datasheet.
- **Solder-mask expansion** at the via/pad overlaps (how much of each drill is actually
  exposed): F1 counts copper-level overlap only.
- **The schematic as a drawing** (only its parity with the board was checked). JLCPCB
  does not use it.
- **Off-board signal integrity:** bus-wire capacitance through the bellows and the
  spring contacts' resistance. The values are taken from the assembly and main_pcb specs.
- **Magnetic influence of the ferrite FB1** (5.7 mm from the nearest sensor) and of the
  MLCC nickel terminations: these are the same for every key except near FB1, and
  static, so the calibration covers them. Not quantified.
