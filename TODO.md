# Open items (2026-11-15)

Collected from the specs and the battery check. Each item names the files it touches.

## Battery and charger (checked 2026-11-15)

Cell found: a 606090 LiPo of 4000 mAh, e.g. DNK606090 ([datasheet](https://www.dnkpower.com/wp-content/uploads/2023/11/DNK606090-3.7V-4000mAh-Lipo-Battery-Specification.pdf)):
92 × 60 × 6.0 mm with its PCM (others list 92.5), charge 4.2 V at 0.2 C recommended
(0.5 C max), 0–45 °C while charging. The PCM trips at 4.275 V overcharge, 2.5 V
over-discharge, 3–5 A overcurrent, and on a short. 3-wire variants carry a 10k NTC on
JST-PH ([example](https://zaitronics.com.au/products/3-7v-4000mah-lipo-battery-lithium-polymer-606090-3-pin)).

1. **Cradle 90 → 93 mm**: `bass/case.scad`, `bat = [90, 6, 60]` → `[93, 6, 60]`. A
   93 mm cell is clear of case, elec and wires with the longer cradle; the control
   (93 mm cell against the present cradle) overlaps by 255 mm³. Then update the
   battery in `bass/spec.md`, `main_pcb/spec.md` and `BOM.md`. Not modelled yet: where
   the cell's leads leave the PCM and how they run to the main board.
2. **R8 (TMR) 75k → 68k**: `main_pcb/design.py`, with its LCSC number. The BQ24074
   specifies TMR only for 18–72 kΩ ([datasheet](https://www.ti.com/lit/ds/symlink/bq24074.pdf), K_TMR 36/48/60 s/kΩ).
   68k gives t_MAXCHG = 10 × 68 × 48 s ≈ 9.1 h (6.8–11.3 h), against about 5–6 h for a
   full charge at 0.89 A. Fix the "about 10 h" in `main_pcb/spec.md` too.
3. **NTC on TS**: choose a 3-wire cell (10k NTC), add a third battery pad to TS and
   remove R5 (the fixed 10k): `main_pcb/design.py`, `main_pcb/spec.md` (the
   "[unverified] no thermistor in the cell"), `assembly/spec.md` Wiring run 6 (3 wires).
   The charger then stops outside 0–50 °C (the cell allows 0–45).
   Unchanged: ISET 1k ≈ 0.89 A (0.22 C) and ILIM 1.5k ≈ 1.0 A both fit.

## Electronics

4. ~~**Discant Hall board routing**~~ done 2026-11-15: finished by hand, 0 open, no copper
   errors (`hall_pcb/spec.md` §5). A new `build.sh discant` would lose the hand edits.
5. **Bass Hall board routing**: 2 open, both stubs of 0.02 and 0.06 mm (+3V3 at U1,
   KEY1_9 at U3). `hall_pcb/bass`.
6. ~~**The discant's 3.3 V ramp after DET**~~ done 2026-11-15: R14 10k → 100k, Q3 on
   3–7 ms after DET, fully after about 12 ms (`main_pcb/spec.md` §3). In the main board's
   routing run with the NTC changes.
7. ~~**Strain gauges**~~ done 2026-11-15: bought half-bridge load cells, 50 kg, 1000 Ω, 1 mV/V
   (`strain_gauge/spec.md` §4a). Still: measure one against the STEP and its E+/E−.

## Mechanics

8. ~~**Flexure plates**~~ done: the load cell's own plate.
9. ~~**Overload stop**~~ done: not needed, 100 N is a fifth of the cells' 490 N.
10. ~~**Gauge polarity**~~ done: a firmware sign, set once by pressing.

## Parts and ordering

11. ~~**Adhesive**~~ done 2026-11-15: slow 2-component epoxy (e.g. UHU plus endfest), rod ends
    roughened; not cyanoacrylate. `switch_hall/spec.md` §2, `BOM.md`.
12. ~~**Screws**~~ done 2026-11-15: bass key board 12 × M2 × 6 DIN 965 brass; main board
    3 × M2 × 3 ISO 7045 A2. `BOM.md`, `bass/spec.md`, `main_pcb/spec.md`.
13. ~~**PG2541-03-003P**~~ settled 2026-11-15: 50 in stock = 16 instruments; buy ahead into
    JLCPCB's private library. Fallback: the same pin as 2-pin strip PG2541-02-001P
    (C49451493, 897 in stock), with a new contact grid. `contact_pcb/spec.md`.
14. ~~**Contacts' panel**~~ done 2026-11-15: JLCPCB's V-cut needs a 70 × 70 panel, so the
    panel is now 16 × 25 with milled gaps and tabs with mouse bites (economic assembly
    from 10 × 10 fits). `contact_pcb/spec.md`, `gen_pcb.py`.

## To check on the printed parts

15. Plate fits: 0.15 mm in the discant housing, and the inner holders in the large
    bass print.
16. Stiffness of the PETG inner holders: if they yield, the calibration shifts.
17. Latches: root strain (1.1–1.3 %, estimated) and the stored hold (about 15 N,
    estimated).
18. Room for the JST cable's splice in the bass's tunnel.

## To measure on the bought parts

19. **Load cell plate** against `strain_gauge/StrainGauge.step` (30 × 25 × 2.5, slots and
    arms 3 mm), before the holders are printed. `strain_gauge/spec.md` §4a.
20. **Load cell resistance**: E+ to E− (the largest of the three), and each to the
    middle: is the seller's 1000 Ω the whole bridge or one gauge (3.3 or 1.65 mA per
    cell at 3.3 V)? `strain_gauge/spec.md` §4a, `hall_pcb/spec.md` §3a.
21. **Load cell drift** in play: zero over 30 min with a hand on it and from a cold
    start (the seller: 1.5 N per 10 °C); decides how often the firmware re-tares.
22. **Spring force** of a built key: 119 g at rest, 149 g at the bottom [from the
    catalogue's rate, ±10 %]. `switch_hall/spec.md` §5.
23. **Battery NTC**: about 10 kΩ from P17 to GND at room temperature, falling when warmed.
    `main_pcb/spec.md` §2.
24. **Discant 3.3 V on plugging**: with a scope on DET and the contacts' 3.3 V, check that
    Q3 comes on only after all pins touch (expected 3–7 ms after DET, fully at about
    12 ms). `main_pcb/spec.md` §3.
