# Open items (2026-11-15, updated 2026-11-25)

Collected from the specs and the battery check. Each item names the files it touches.

## Battery and charger (checked 2026-11-15)

Cell found: a 606090 LiPo of 4000 mAh, e.g. DNK606090 ([datasheet](https://www.dnkpower.com/wp-content/uploads/2023/11/DNK606090-3.7V-4000mAh-Lipo-Battery-Specification.pdf)):
92 × 60 × 6.0 mm with its PCM (others list 92.5), charge 4.2 V at 0.2 C recommended
(0.5 C max), 0–45 °C while charging. The PCM trips at 4.275 V overcharge, 2.5 V
over-discharge, 3–5 A overcurrent, and on a short. 3-wire variants carry a 10k NTC on
JST-PH ([example](https://zaitronics.com.au/products/3-7v-4000mah-lipo-battery-lithium-polymer-606090-3-pin)).

1. ~~**Cradle 90 → 93 mm**~~ done 2026-11-15 (`bass/case.scad`, specs, BOM).
2. ~~**R8 (TMR) 75k → 68k**~~ done (C36871); routed 2026-11-16.
3. ~~**NTC on TS**~~ done: P17 = TS, R5 gone, P16 the NTC's return for a taped-on NTC;
   main board routed 2026-11-16, all nets, no clearance errors.

## Electronics

4. ~~**Discant Hall board routing**~~ done 2026-11-15: finished by hand, 0 open, no copper
   errors (`hall_pcb/spec.md` §5). A new `build.sh discant` would lose the hand edits.
5. ~~**Bass Hall board routing**~~ done 2026-11-16: finished by hand, 0 open.
6. ~~**The discant's 3.3 V ramp after DET**~~ done 2026-11-15: R14 10k → 100k, Q3 on
   3–7 ms after DET, fully after about 12 ms (`main_pcb/spec.md` §3). In the main board's
   routing run with the NTC changes.
7. ~~**Strain gauges**~~ done 2026-11-15: bought half-bridge load cells, 50 kg, 1000 Ω, 1 mV/V
   (`strain_gauge/spec.md` §4a). Measured against the STEP and E+/E−: #19, #20.

## Mechanics

8. ~~**Flexure plates**~~ done: the load cell's own plate.
9. ~~**Overload stop**~~ done 2026-11-20: the cells are rated by moment (490 N × 7 mm),
   a hand's 100 N far out exceeds it, so adjustable M3 grub screw stops beside the gauges
   (`assembly/spec.md`, Overload stops; `discant/spec.md` §7). Set on the instrument.
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
    bass print. Print the discant's test piece first (`discant/`: `make bambu`,
    `holder_test_x2d.3mf`, with the bass's two inner holders and their latches, about
    46 min, 15 g; 2026-11-22).
16. Stiffness of the PETG inner holders: if they yield, the calibration shifts.
17. Latches: root strain (1.1–1.3 %, estimated) and the stored hold (about 15 N,
    estimated).
18. Room for the JST cable's splice in the bass's tunnel.
18a. Standing print of the discant housing: stable at 101 mm on its front edge
     (`discant/spec.md`, Printing).
18b. Supports under the thumb bar's lobes when printing the cover (`discant/spec.md` §3.2).
18c. Bass back cover and earphone jack (`bass/spec.md`, Back cover and Electronics):
     - the cover slides in from −x over its 45° ramp, past pillars and ribs (0 and 0.2
       clear), and hits nothing on the way;
     - the jack goes in from behind, 5 mm short of the wall and 2.4–3.0 mm above its
       place, drops into the saddle and slides into the hole (the window is narrow);
     - the cover's rib sits about 0.3 mm over the jack body: if it binds on the lugs,
       sand it; if it rattles, tape on the body;
     - pulled towards the main board the jack has only the 1.5 mm wall (about 45 MPa at
       20 N, estimated): try it by hand on the print.

## To measure on the bought parts

19. ~~**Load cell plate**~~ measured 2026-11-21: 30 × 23.3 × 2.5 (the STEP 25), the arms
    1.7 shorter; the lead glued along the column, 4 thick, 1.5 proud of one face, the
    glue 7.1 wide and 19 long from the top edge. Plate
    model, inner holder's recess (1.8 deep) and the outer holder's lead gap (6.4)
    follow. `strain_gauge/spec.md` §1, §5, §6.
20. ~~**Load cell resistance**~~ measured 2026-11-21: red–yellow and black–yellow 1 kΩ,
    black–red 2 kΩ: 1000 Ω per gauge, yellow the middle, 1.65 mA per cell.
    `strain_gauge/spec.md` §4a, `hall_pcb/spec.md` §3a.
21. **Load cell drift** in play: zero over 30 min with a hand on it and from a cold
    start (the seller: 1.5 N per 10 °C); decides how often the firmware re-tares.
    On the assembled instrument at bring-up (#26) [2026-11-21: the real heat path
    through hand plate and holders, the real NAU7802 and divider]: `force track off`,
    `force log on`, capture the console, `grep '^F,'`; a known weight checks the
    estimated 2190 counts/N on the way. `firmware/spec.md` §4, §6.
22. **Spring force** of a built key: 119 g at rest, 149 g at the bottom [from the
    catalogue's rate, ±10 %]. `switch_hall/spec.md` §5.
23. **Battery NTC**: about 10 kΩ from P17 to GND at room temperature, falling when warmed.
    `main_pcb/spec.md` §2.
24. **Discant 3.3 V on plugging**: with a scope on DET and the contacts' 3.3 V, check that
    Q3 comes on only after all pins touch (expected 3–7 ms after DET, fully at about
    12 ms). `main_pcb/spec.md` §3.

## On the instrument

25. **Overload stops**: set S1/S2 at about 40 N on the hand plate's top edge (kitchen
    scale) and about 70 N on the strap (luggage scale). `assembly/spec.md`.
26. **Firmware bring-up**: builds, never run on hardware. Check the key direction old →
    new, the force sign, the synth's load at full polyphony and the latency.
    `firmware/spec.md`.

## Ordering

27. Main board, Hall boards and contact panel at JLCPCB; buy PG2541-03-003P ahead.
    Unverified: whether the contact panel's second design costs extra.
    `contact_pcb/spec.md`.
