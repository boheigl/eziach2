# Review: main_pcb (ESP32-S3 main board in the bass)

Independent pre-order review, 2026-11-18. Inputs: `main_pcb/design.py` (working tree, including the
uncommitted USB tab), `spec.md`, `fab/*-bom.csv`, `fab/*-pos.csv`, `pins.json`, and the **committed**
`main_pcb.kicad_pcb` + `.kicad_pro` (HEAD; the board was being regenerated with the tab during
the review). Datasheets were read from PDFs. LCSC numbers were looked up live on lcsc.com.

## Summary

The schematic is in good shape. Every IC pinout I could check against a datasheet matches
`design.py`, the firmware pin table matches, and there are no I2C address conflicts. There are
two real problems. First, the **charge LED's pads are wired wrong**, so the light will never come
on. Second, **every power net is routed as a 0.127 mm track** (spec.md says 0.4 mm). That includes
0.9 A of charge current on a 0.5 oz inner layer, plus the buck-boost's switch-node and capacitor
loops. Fix both before ordering. Nothing I found stops the board from booting or charging.

**Counts:** BLOCKER 0, MAJOR 3, MINOR 6, NOTE 11.

## Findings

### MAJOR 1 — D1 (LTST-S326KGJRKT): pad-to-net mapping is wrong; the charge light never lights
- **Where:** `design.py` D1: `{"2": "VSYS", "1": "LED_G", "3": "LED_R"}` (pinfo assumes pad 2 = anode).
- **Evidence:** LiteOn DS22-2000-287 rev. E.
  - p.1, "Package Dimensions": the bottom/rear view labels one end "Anode" and the other end
    "C1" with the round cathode mark. The **middle feature is the "REINFORCING PIN (CATHODE)" = "C2"**.
  - Pin table: Green = C2, Red = C1. The polarity diagram shows a common anode, C1 = red, C2 = green.
  - p.6 §6.2 land pattern: the 0.9 × 0.9 middle pad sits at the back, and the two 1.5 × 0.9 pads
    sit at the ends. This is KiCad's `LED_LiteOn_LTST-S326` (pad 2 in the middle at x −0.65,
    pads 1/3 at y ∓1.375).
  - So **pad 2 is the green cathode**, not the anode.
  - In the tape drawing (p.6 §6.3, parts seen from the top, lens to the right), the "CATHODE"
    arrow points at the upper end. That puts C1 (red) on pad 1 (y −1.375) and the anode on pad 3.
- **Effect:** with the current mapping, VSYS sits on the green cathode and the anode sits on
  LED_R. There is no forward path from VSYS, so neither colour lights. Nothing is damaged: the
  reverse voltage is at most 4.4 V, below the 5 V rating.
- **Fix:** `{"1": "LED_R", "2": "LED_G", "3": "VSYS"}`.
  - Confidence: high that the middle pad is a cathode (C2); medium on which end is the anode (it
    rests on the tape drawing).
  - Before ordering, look at the part in JLCPCB's placement preview against the LCSC/EasyEDA
    footprint for C125116.
  - Or diode-test one loose LED (anode = the end without the round mark on the back).

### MAJOR 2 — All power nets are routed with 0.127 mm tracks, some on 0.5 oz inner layers
- **Where:** the committed board.
  - Per net (track width → total length per layer): VBUS 0.127 only (F 4.1, B 25.5, In2 3.0 mm);
    VSYS 0.127 (F 6.9, B 12.0, **In2 20.4**); VBAT 0.127 (F 5.8, B 8.0, **In2 10.3**); +3V3 0.127;
    +3V3_D 0.127 (In2 9.8); L1/L2 0.127 (L2 through two vias to B.Cu).
  - Only BATP got 0.4 mm.
  - spec.md §1 claims "power 0.4 mm where it fits", but in practice the router used the default
    netclass (`gen_pcb.py` sets only one netclass, 0.127 mm).
- **Evidence:** pad-to-pad resistance computed from the track geometry (Cu 35 µm outer,
  17.5 µm inner, which is JLCPCB's 4-layer default; script in the scratchpad):

| Path | Resistance | Current | Drop / loss |
|---|---|---|---|
| U3 BAT → F1 | **145 mΩ** | 0.9 A charge, ~0.8 A discharge at low battery | 0.13 V, 0.12 W in the trace |
| J1 VBUS → U3 IN | 54 mΩ | up to 1.0 A (ILIM) | |
| U3 OUT → U5 VIN | 51 mΩ | | |
| U5 VOUT → U1 pin 2 | 256 mΩ | | |
| Q3 → contacts' 3.3 V pad P1 | 253 mΩ | about 0.2 A for the discant's sensors | about 50 mV before the spring contacts |
| U5 L2 → L1 pad 2 | 38 mΩ | | |
| U5 L1 → L1 pad 1 | 13 mΩ | | |

  - IPC-2221 allows a 0.127 mm trace about 0.16 A for a 10 °C rise on a 0.5 oz inner layer, and
    about 0.5 A on a 1 oz outer layer.
  - At 0.9 A for hours of charging, the 10 mm of VBAT on In2 runs at a current density of about
    400 A/mm². Expect a large temperature rise there.
- **Fix:** give the power nets their own netclass before routing: VBUS, VSYS, VBAT, BATP, +3V3
  trunk, L1, L2, GND stitching. Use ≥ 0.4–0.5 mm on the outer layers (or local pours), and
  several vias wherever a power net changes layer. At minimum, keep VBAT and VSYS off the inner
  layers. Alternatively, order 1 oz inner copper; that halves the inner-layer problem but does
  not fix it.

### MAJOR 3 — TPS63001's input and output capacitors are far from its pins
- **Where:** `design.py` positions; pad coordinates from the board.
  - U5 VOUT (pin 1) is at X 18.4, but C12/C13 (22 µF) sit at X 23.4 on the other side of the IC.
    Path resistance 55 / 27 mΩ through 0.127 mm tracks.
  - Input cap C10 is 4.5 mm away (55 mΩ to VIN, 70 mΩ to PS/SYNC/VIN pin 7).
  - The switch node L2 detours through two 0.2 mm vias to B.Cu.
- **Evidence:** TPS6300x datasheet SLVS520C §8.2.2.3: input cap "placed as close as possible to
  the VIN and PGND pins"; output "small ceramic capacitors placed as close as possible to the VOUT
  and PGND pins". The converter switches at 2.5 MHz. In boost mode (VSYS < 3.3 V, i.e. a battery
  below about 3.4 V) the output current is pulsed, so the output cap's loop matters most.
- **Effect:** more ripple and ringing on +3V3, which feeds the ESP32, the DAC's IOVDD/SPKVDD and
  (through FB1) AVDD/HPVDD. The control loop may misbehave. Audible noise in the headphones is
  the likely symptom.
- **Fix:**
  - Place one 22 µF right at pins 1/3, and the 10 µF input cap right at pins 5/3.
  - Route L1/L2 short and wide on F.Cu; the inductor is already next to the IC.
  - Stitch PGND/EP with several vias. The EP currently has only one via.

### MINOR 1 — VBUS sense into IO41 sits on the ESP32's VIH threshold
- **Where:** R20/R21 100k/100k → IO41 (a digital-only pin; ADC exists only on GPIO1–20).
  Firmware: `power_usb()` = `gpio_get_level(PIN_VBUS)`.
- **Evidence:** ESP32-S3-WROOM-1 datasheet v1.8, Table 6-3: VIH min = 0.75 × VDD = 2.475 V.
  VBUS/2 = 2.50 V at 5.00 V, 2.375 V at 4.75 V (USB minimum), and lower after cable drop.
- **Effect:** USB is read wrongly or flickers. The red low-battery light can then come on while
  plugged in.
- **Fix:** R20 = 68k (already in the BOM). That gives 2.83 V at 4.75 V and 3.13 V at 5.25 V.

### MINOR 2 — ESP32 decoupling is about 20 mm from the module's 3V3 pin
- **Where:** C1 (22 µF) at (24.0, 8.4) and C2 (100 nF) at (25.1, 12.4). Module pin 2 (3V3) is at
  (44.05, 9.26), on the module's far side. Measured 290–300 mΩ of track between them.
- **Evidence:** ESP32-S3-WROOM-1 datasheet, peripheral schematic: 22 µF + 0.1 µF at the 3V3 pin.
  The firmware uses no radio (no WiFi/BT in `firmware/main`), so the load is about 100 mA and the
  drop about 30 mV. That is tolerable, but the caps do little where they are.
- **Fix:** move C2 (and ideally C1) next to pin 2 (X ≈ 44, Y ≈ 9), or route a wider +3V3 to pin 2.

### MINOR 3 — BQ24074 heat: one via in the thermal pad
- **Where:** U3 EP (pad 17, 1.6 × 1.6) has one via.
- **Evidence:** SLUS810N, Abs. max note (2) and the layout guidelines: the thermal pad is the main
  heat path; thermal regulation cuts the charge current at TJ 125 °C. Dissipation with USB:
  (5.0 − 4.4 V) × ~1 A + (4.4 − 3.6 V) × 0.89 A ≈ 1.3 W. RθJA is 44.5 °C/W on a JEDEC board,
  and worse here. The board sits in a closed box.
- **Fix:** put 4–5 vias (0.2 mm) into the EP (and do the same for U5). Otherwise accept slower
  charging.

### MINOR 4 — Input current 1 A regardless of the USB source
- **Where:** EN2 = VBUS, EN1 = GND, ILIM 1.5k → 1.03 A (SLUS810N Table 7-2 and Eq. 1,
  K_ILIM = 1550 AΩ).
- **Effect:** CC uses only Rd, so the board draws up to 1 A from any port, including a PC port
  that only promises 500 mA (default USB power). Most ports survive this, but some cut off,
  which also drops USB-MIDI.
- **Fix (optional):** accept it and document it. Or read CC1/CC2 voltage (Rp advertisement) with a
  spare ADC pin and drive EN1/EN2 from the ESP32.

### MINOR 5 — Headphone coupling caps: the bass is cut
- **Where:** C22/C23 100 µF 0805 6.3 V X5R (GRM21BR60J107ME15L).
- **Evidence:**
  - fc = 1/(2π R C): 99 Hz into 16 Ω, 50 Hz into 32 Ω.
  - The DAC's output common mode is 1.35–1.65 V (SLAS671C §6.3.10.12.1). At that DC bias an
    0805 6.3 V 100 µF keeps roughly 60–70 %, so fc ≈ 140 Hz into 16 Ω.
  - The accordion's bass fundamentals lie around 40–100 Hz.
- **Fix:** 2 × 100 µF per channel or 220 µF (1206/1210 if the jack zone height allows), or
  prefer 32 Ω phones.

### MINOR 6 — Power-net widths are not stated in `design.py`, and spec.md describes them wrongly
- spec.md §1 says "power 0.4 mm where it fits". The board has 0.127 mm on every net except BATP.
  The fix belongs with MAJOR 2; also correct the spec text.

### NOTE 1 — ESP32-S3-WROOM-1-N16R8 (C2913202): LCSC stock was **14** today
Check JLCPCB's own stock for the assembly order. Reserve parts or order the module separately
before committing the order.

### NOTE 2 — JLCPCB rotations: the pos file carries KiCad's raw rotations, uncorrected
Check each of these in JLCPCB's placement preview (pin-1 dot against the silkscreen):

| Part | Rotation | Check |
|---|---|---|
| U1 ESP32 module | 180 | antenna must face the board's bottom edge, Y = 0 |
| U3 VQFN-16 | 0 | |
| U5 VSON-10 | 0 | |
| U7 VQFN-32 | 90 | |
| U2, U8 SOT-23-6 | 90, 0 | |
| U6 SOT-23-5 | 0 | |
| Q2, Q3, D2 SOT-23 | 0 | JLC models are often 180° off from KiCad |
| Q4, Q5 SOT-523 | 90 | |
| J1 USB-C | −90 | |
| D1 side LED | 180 | lens must face −X, toward the wall |

The CPL header is KiCad's (`Ref,Val,Package,PosX,PosY,Rot,Side`). JLCPCB normally maps it;
otherwise rename the columns to Designator / Mid X / Mid Y / Rotation / Layer.

### NOTE 3 — EN2 and the TPS63001 EN see VBUS directly
BQ24074 IN works up to 10.5 V (OVP), but EN2's abs. max is 7 V (SLUS810N §8.1). TPS63001 EN
(via the BAT54C) also has a 7 V abs. max (SLVS520C §6.1). Fine with USB-C 5 V (Rd only), but a
faulty or non-USB supply above 7 V destroys both. Optional fix: feed EN2 from VSYS instead
(OUT ≤ 4.4 V), or add a resistor and clamp.

### NOTE 4 — The earphone side of C22/C23 has no DC path
Without a bleed resistor (10k to GND on EAR_L/EAR_R), the caps' outer plates float. Plugging
in pops. Optional.

### NOTE 5 — Q4 gate leakage can make the red LED glow faintly when the charge is done
Q4's gate is pulled up only through the red LED and R9. DMG1012T IGSS is up to ±1 µA at 4.5 V
(Diodes DS31783). If the part is near that limit, about 1 µA flows through red. It is visible
in the dark. Typical leakage is far lower. Optional fix: a 1M from CHG to VSYS in parallel.

### NOTE 6 — GPIO3 is floating
ESP32-S3-WROOM-1 datasheet §4.4: GPIO3 has no internal pull and "must be controlled by the
external circuit". With the default eFuses (EFUSE_STRAP_JTAG_SEL = 0) GPIO3 is ignored, so this
is fine as long as nobody burns that eFuse. GPIO0 has R2 10k up, GPIO45/46 are open (internal
pull-downs: VDD_SPI 3.3 V, normal boot), and IO35–37 are unused. All correct.

### NOTE 7 — Only SDA1/SCL1/INT1 have ESD protection at the contacts
DET and +3V3_D also reach the spring contacts unprotected. DET goes through R14 100k to two
MOSFET gates (AO3401A VGS ±12 V), and +3V3_D has Q3 and C14. That is probably acceptable. If
there is room, a spare SRV05-4 channel (pin 6 is unused) could take DET.

### NOTE 8 — The VBAT divider is high-impedance (1M/1M)
IO1 leakage (IIL/IIH ≤ 50 nA, Table 6-3) × 500 kΩ ≤ 25 mV, i.e. ≤ 50 mV error on VBAT. C8 handles
the sampling charge. This is fine for a low-battery threshold.

### NOTE 9 — The committed board still has J1's shell pads on the edge
DRC on HEAD: `copper_edge_clearance` 0.0 mm at J1 S1 (2×). The tab now being added is meant to
fix this. Re-run DRC on the regenerated board and confirm 0 clearance/edge errors and 0
unconnected items. Also check that JLCPCB routes the 0.8 × 11 mm tab (its inside corners get
the router's radius, ≈ 0.5–1 mm, so the pocket in elec.scad needs that clearance).

### NOTE 10 — L1 (Sunlord SWPA252012S2R2MT, C23894) is a marginal choice
Isat is 2.07 A, but the rated current is only 1.15–1.25 A and DCR is up to 216 mΩ (DigiKey and
LCSC listings; I found no Sunlord datasheet). The peak of 0.82 A at VSYS 3.0 V / 650 mA fits, but
the inductor loses about 0.1 W at that point. If space allows, a 2520 or 3015 part with a lower
DCR would help. The LCSC API returned no data for C23894, so check in JLCPCB's BOM tool that it
is still orderable.

### NOTE 11 — TLV320DAC3100 power-up order and exposed pad
- **Power-up:** AVDD/HPVDD (via FB1) and IOVDD/SPKVDD come up together with +3V3; DVDD follows
  through the LDO. SLAS671C §6.3.1 recommends SPKVDD → IOVDD → DVDD → AVDD/HPVDD, while §8 says
  the device is "extremely tolerant". RESET is held low by R22 until the firmware releases it,
  as §6.3.2 recommends, so this is acceptable.
- **Exposed pad:** I could not compare the footprint's EP (3.1 × 3.1) with TI's RHB land pattern;
  the mechanical pages are not in the downloaded datasheet.

## Checked and OK

- **U1 module pinout:** all 41 pads against the ESP32-S3-WROOM-1 datasheet v1.8 pin table. USB
  D−/D+ on pins 13/14 (IO19/IO20).
- **U1 octal PSRAM:** IO35–37 are left unconnected (datasheet note b).
- **U1 IO47/IO48:** at 3.3 V on the N16R8; only the R16V variants run them at 1.8 V (note c).
- **U1 strapping:** GPIO0 pulled up, GPIO45/46 at their default pull-downs, GPIO3 see NOTE 6
  (datasheet Table 4-1).
- **U1 EN RC:** 10k/1 µF, as the datasheet recommends (§ peripheral schematic).
- **U1 VBAT input:** IO1 = ADC1_CH0, matching the firmware's `ADC_CHANNEL_0`.
- **U1 antenna:** the module body spans Y 0.45 … 26.05, so the antenna lies at the board's bottom
  edge. The rule area (X 24.6 … 45.5, Y 0 … 6.6, all four layers) contains no tracks, vias or
  zone fill (checked on the board).
- **Firmware pins:** `firmware/main/pins.h` matches `design.py` for all 15 GPIOs (9, 14, 21, 47,
  48, 38, 10–13, 39, 40, 41, 1, 42).
- **U3 BQ24074:**
  - Pins 1–17 match SLUS810N Table 7-1 (pin 15 is ITERM on the '74, open = 10 %).
  - CE low, EN2 = 1 / EN1 = 0 selects the ILIM mode (Table 7-2).
  - ILIM 1.5k gives 1.03 A (K_ILIM 1550); ISET 1k gives 0.89 A (K_ISET 890).
  - TMR 68k is within 18–72k: t_MAXCHG 9.1 h (6.8–11.3 h).
  - TS with 75 µA and a 10k NTC trips at 0/50 °C (VCOLD 2.1 V, VHOT 0.3 V).
  - OUT VO(REG) is 4.4 V, inside the TPS63001's 5.5 V maximum.
  - IN/OUT/BAT caps are within 1–10 µF and 4.7–47 µF. CHG/PGOOD sink 1.6 mA (abs. max 15 mA).
- **U5 TPS63001:**
  - Pins match SLVS520C's pin table; FB is tied to VOUT (fixed version).
  - PS/SYNC high (forced PWM); VINA through 100 Ω + 100 nF, as in Table 1.
  - EN/PS abs. max 7 V. Cin 10 µF ≥ 4.7 µF; Cout 2 × 22 µF ≥ 15 µF nominal (but see MAJOR 3).
  - Inductor peak at 3.0 V / 650 mA is 0.82 A by Eq. 4.
- **U6 TLV75518P:** DBV pins 1 IN, 2 GND, 3 EN, 4 NC, 5 OUT (SBVS320D Table 4-1). 1 µF in and out,
  with effective capacitance above 0.47 µF.
- **U7 TLV320DAC3100:**
  - All 32 pins + EP match SLAS671C's pin table.
  - I2C address 0011000b = 18h. RESET is active low with a pull-down.
  - Supplies are within the ROC: AVDD/HPVDD 3.3 V, DVDD 1.8 V, IOVDD 3.3 V, SPKVDD 3.3 V ≥ AVDD.
  - HP outputs are AC-coupled, as the datasheet requires. Unused SPK, AIN, MICBIAS,
    VOL/MICDET and GPIO1 pins are left open.
- **I2C addresses:** ADS7128 Table (SBAS868) gives 10h–17h from the ADDR resistors; bus 1 uses
  10h–15h plus NAU7802 2Ah, bus 2 uses 10h–12h plus DAC 18h. No conflicts.
- **I2C pull-ups:** ADS7128 ALERT is open-drain by default. Pull-ups are 2k2 here ∥ 4k7 on each
  key board (about 1k5, about 2.2 mA sink), and the INT pull-ups are on the key boards
  (hall_pcb/spec.md).
- **Bus 1 when the discant is apart:** the firmware checks DISC_ON before using bus 1
  (`app_main.c:114`).
- **U2 USBLC6-2SC6:** pinout 1/6 I/O1, 3/4 I/O2, 2 GND, 5 VBUS (ST layout, confirmed by vendor
  datasheets via search). It sits in the flow-through path connector → U2 → ESP32. D+ = A6/B6 →
  pin 1 ↔ 6 → IO20; D− = A7/B7 → pin 3 ↔ 4 → IO19.
- **USB-C:** CC1/CC2 have 5.1k each to GND (a sink); SBU is unused; the shell is on GND.
- **U8 SRV05-4:** 1/3/4/6 I/O, 2 GND, 5 VCC (several vendor datasheets; ProTek calls pin 5
  "REF"). VP on +3V3 is at or above the lines' 3.3 V_D.
- **Discretes:**
  - AO3401A: SOT-23 1 G, 2 S, 3 D (AOS datasheet). VGS(th) −0.5 … −1.3 V; RDS(on) < 85 mΩ at
    −2.5 V. Q3 sees VGS ≈ −2.9 V.
  - DMG1012T: SOT-523 G/S/D = 1/2/3 (Diodes DS31783). VGSS ±6 V; Q4's VGS is at most about 3 V.
  - BAT54C: SOT-23 common cathode on pin 3 (onsemi case 318 style 9). Nexperia part C37704.
- **System switch logic:**
  - Q3's body diode faces the right way (no back-feed from 3.3 V into the contacts when off).
  - DET open: Q2/Q3 have VGS ≥ 0, so both are off. DET closed: gate ≈ 0.09 × VSYS, so both are
    fully on.
  - USB alone: EN_SYS = VBUS − Vf, and +3V3_D stays off.
- **LCSC part numbers** (live lcsc.com lookups): every BOM line resolves to the stated
  manufacturer part, package and value/voltage, except C23894 (see NOTE 10).
  - Capacitor voltage ratings: 22 µF 25 V, 10 µF 0805 25 V, 10 µF 0603 10 V, 10 µF 0402 6.3 V,
    4.7 µF 16 V, 1 µF 25 V, 100 nF 16 V, 100 µF 6.3 V.
  - Others: PTC SMD1206P150TF (1.5 A hold / 3 A trip, 6 V, 25 mΩ); FB1 BLM15AG601SN1D (300 mA,
    0.52 Ω); TPS63001DRCR VSON-10; BQ24074RGTR QFN-16; DAC RHB 5 × 5; TLV75518PDBVR SOT-23-5;
    SRV05-4-P-T7 SOT-23-6.
- **Footprint vs package:** BQ24074 EP 1.68 (datasheet RGT drawing) vs 1.6 in the footprint, OK.
  The ESP32 footprint origin is at the module centre.
- **Screw heads:** no F.Cu tracks, vias or pads within ⌀4.4 of any screw hole.
- **DRC on HEAD** (with its `.kicad_pro`): 0 unconnected items, 0 clearance errors, 0 shorts.
  Remaining: J1 edge clearance (NOTE 9), 1 starved thermal (U6 GND), silkscreen and courtyard
  items. The courtyard items come from KiCad's ESP32 courtyard, which includes the antenna
  keep-out; no part lies under the module body.
- **Fab options:** 1.0 mm 4-layer, 0.127/0.127 mm track/space and 0.45/0.2 mm vias are within
  JLCPCB's 4-layer capabilities. Check whether 0.2 mm via drills add a surcharge.

## Not checked

- **USB tab / regenerated board:** the board file was being rewritten during this review. All
  layout checks are on HEAD (without the tab); repeat DRC and the power-net measurements on the
  new board.
- **D1 anode end:** pad 1 vs pad 3 rests on the tape drawing only (see MAJOR 1). The EasyEDA
  footprint could not be fetched (HTTP 403).
- **USB4105-GF-A footprint vs GCT drawing:** not compared pad by pad. KiCad's footprint is GCT's
  own family footprint, and the LCSC part matches.
- **Sunlord inductor datasheet:** values come from distributor listings only.
- **TLV320DAC3100 RHB land pattern / EP size:** not in the downloaded datasheet.
- **Mechanics:** how the board fits in `bass/elec.scad` (jack zone heights, tab pocket); the
  owner's clash check covers these.
- **Thermal and acoustic performance:** estimated only (MINOR 3, MAJOR 3); not simulated.
