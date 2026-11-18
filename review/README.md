# Board review before the JLCPCB order (2026-11-18)

Three independent reviews (Claude Fable agents), one per board family, checked against the
datasheets, LCSC and KiCad's DRC. They changed nothing in the project. Details, evidence
and page references are in the reports:

| Report | Boards | BLOCKER | MAJOR | MINOR | NOTE |
|---|---|---|---|---|---|
| [main_pcb.md](main_pcb.md) | main board (bass) | 0 | 3 | 6 | 11 |
| [hall_pcb.md](hall_pcb.md) | discant and bass key boards | 0 | 1 + 1 (same finding) | 3 + 2 | 12 + 8 |
| [contact_pcb.md](contact_pcb.md) | contact pin and pad boards | 0 | 2 | 5 | 6 |

No blocker: nothing found that keeps a board from working at all, except possibly the
charge light. The MAJOR findings should be fixed or consciously accepted before ordering.

## MAJOR, to decide

1. **Vias in SMD pads (all routed boards).** The routers (`route.py`) drop vias into or
   against SMD pads. Counted again after the reviews with a pcbnew script
   (via copper touching SMD pad copper): discant 182 of 285 vias, bass key board 72 of
   103, main board 150 of 206 (the rerouted board with the USB tab). Some are wanted
   (thermal pads); most are not: Hall sensor GND pads, 0402s, ADS7128 pins 9/12/13, J1's
   pads. Risk: solder wicks into the holes, weak joints, tombstoned 0402s, tilted
   sensors. Fix: a short neck from pad to via in the routers (outside thermal pads).
   One change in the shared routing approach, then rebuild all three boards.
2. **Main board: power tracks 0.127 mm.** Only BATP is 0.4 mm; VBUS, VBAT, VSYS, +3V3,
   L1/L2 are all 0.127 mm (confirmed on the rerouted board). The charge path carries
   0.9 A through about 145 mΩ, partly on an inner layer. Fix: a power netclass,
   0.4–0.5 mm on the outer layers. `spec.md` claims 0.4 mm; it is wrong as built.
3. **Main board: charge LED D1 wired wrong** (reviewer: high confidence for the middle
   pad, medium for the ends). `design.py` has pad 2 (middle) = VSYS as the anode; the
   LiteOn datasheet DS22-2000-287 p.1 calls the middle "reinforcing pin" the (green)
   cathode. Suggested: `{"1": "LED_R", "2": "LED_G", "3": "VSYS"}`. `design.py`
   already marks the pad assignment as unverified. Confirm with the datasheet drawing
   (or a diode test on one LED) before changing.
4. **Main board: TPS63001 layout.** Output caps C12/C13 on the far side of the IC (~5 mm),
   input cap C10 ~4.5 mm, L2's switch node through two vias. Noise on 3.3 V, which also
   feeds the DAC. Fix: place the caps at the pins (placement in `design.py`).
5. **Contact boards: spring pins can bottom out.** Working height 4.50 mm nominal,
   limit 4.20; copper/solder and tolerances (about 0.3–0.4 mm RSS) eat the margin. Then
   the pins carry force past the load cells. Fix: nominal about 4.65–4.7 mm
   (`bass/link.scad:66-68`) or a shim, and measure the first assembly.
6. **Contact boards: panel tabs too narrow.** 2 mm with mouse bites; JLCPCB asks for
   5 mm with mouse bites (`contact_pcb/gen_pcb.py:53-54`). Risk: DFM rejection or broken
   boards.

## MINOR (short)

- Main: VBUS sense 100k/100k gives 2.5 V against VIH min 2.475 V; R20 68k.
- Main: ESP32 decoupling C1/C2 about 20 mm from module pin 2.
- Main: BQ24074 thermal pad has a single via; charging throttles on heat.
- Main: charger takes 1 A from any USB port (PC ports promise 500 mA).
- Main: 100 µF headphone caps roll off below about 100–140 Hz into 16 Ω.
- Hall discant: no ESD protection behind the open contact pads (e.g. SRV05-4 at J1).
- Hall: +3V3 tracks 0.2 mm, not 0.4 mm as `spec.md` says (drop 46 mV worst case, works).
- Hall bass: `spec.md` puts the middle ADC at x = 5, the board at x = −15.
- Hall: NAU7802 sinks about 1.9 mA into the 1.5 kΩ pull-ups, specified only at 1 mA.
- Contacts: no silkscreen on the wire pads (mirrored when seen from the back).
- Contacts: mouse-bite holes outside the edge, stubs up to 0.25 mm against 0.1 mm
  pocket clearance; 1.0 mm milled gap at JLCPCB's minimum.
- Contacts: on unplugging, GND pins may break before 3.3 V; return current through I²C.
  33–100 Ω series resistors on SDA1/SCL1/INT1 on the main board.
- Contacts: no fixing or locating feature on either board.

## When ordering

- In JLCPCB's preview, check every part's rotation (the pos files carry KiCad's raw
  rotations). Critical: Hall sensors (180° swaps VCC and GND) and ADCs.
- Finish: key boards lead-free HASL (no nickel near the sensors); contact boards ENIG.
- Stock: LCSC had only 14 ESP32-S3-WROOM-1-N16R8 today; inductor C23894 gave no data.
- Bring-up: I²C rise times with a scope; DAC thermal pad and USB4105 footprint not
  checked pad by pad.

## State of the boards reviewed

- The main board review ran on the committed board (before the USB tab). The board was
  rerouted the same day with the tab (`main_pcb/spec.md`, Routing): DRC clean (0
  unconnected, no clearance or edge errors). Its findings on power widths and vias were
  rechecked on the new board and still hold; the J1 edge errors it mentions are gone.
- Nothing from these findings has been changed yet.
