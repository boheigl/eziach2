# Review: contact boards (contact_pcb/) before ordering

Reviewer: independent check, 2026-11-18. Sources: `contact_pcb/` (spec.md, gen_pcb.py,
contact.kicad_pcb, fab/), `bass/link.scad`, `discant/gauge_link.scad`, `assembly/spec.md`,
`main_pcb/design.py` + `spec.md`, `hall_pcb/design.py`; the CHIN-BAN PG2541-03-003P
drawing (LCSC datasheet PDF, REV 1.0, 1 sheet, downloaded 2026-11-18); JLCPCB's PCB
capabilities page (jlcpcb.com/capabilities/pcb-capabilities, fetched 2026-11-18).
Nothing in the project was modified; the board was regenerated only into the scratchpad
to confirm `contact.kicad_pcb` matches `gen_pcb.py` (it does: same pads, nets, tracks, vias).

## Summary

The electrical design is right: the 9 positions mirror correctly between pin and pad
board, the nets agree with main_pcb (WIRES) and hall_pcb (J1), DET is tied to GND on the
pad board, the footprint matches the datasheet's recommended layout, and DRC is clean.
The two real risks are mechanical: the pins are set to sit only ~0.2 mm from their
compression limit once copper, solder and board-thickness tolerance are counted, and the
panel's 2 mm mouse-bite tabs are well under JLCPCB's stated minimum (5 mm with mouse bites).
Fix or consciously accept those two before ordering; the rest are small.

Counts: BLOCKER 0, MAJOR 2, MINOR 5, NOTE 6.

## Findings

### MAJOR 1 — Spring pins can bottom out: only ~0.2 mm from the limit height

- **What:** The mechanics put the pin board's front exactly 4.50 mm (the working height)
  from the pad face. The datasheet's limit height ("极限尺寸", maximum compression) is
  4.20, i.e. 1.3 mm max travel, 0.3 mm beyond the nominal 1.0. The model ignores the
  pin board's copper (0.035) and the solder under the Ø2.0 cup (~0.05–0.1), so the real
  nominal height is ≈ 4.40 and the margin ≈ 0.2 mm. Tolerances in the stack (y):
  both boards' thickness (JLCPCB 1.6 ±10 % = ±0.16 each, and *both* count: the pin board
  is pressed back onto its ledge, so its front = ledge − T; the pad board lies on its
  boss, so the pad face = boss + T), the printed block/pocket ledge and boss positions
  (FDM ±0.1–0.2 each), the latch position. RSS ≈ 0.3–0.4 mm, worst case ≈ 0.7 mm: well
  over 0.2.
- **Why it matters:** bottomed plungers turn the nine pins into a rigid strut between
  bass and discant — exactly the "stiff second force path" assembly/spec.md (Contacts)
  rules out for the gauges — and datasheet note 5 says not to exceed the maximum allowed
  compression (pin damage, SMD joints and the printed ledge loaded).
- **Where:** `bass/link.scad:66-68` (`pin_work = 4.5; pcb_y = pad_y + pin_work`),
  `bass/link.scad:77` (ledge at `pcb_y + pcb[2]`), `discant/gauge_link.scad:76-77`.
- **Evidence:** PG2541-03-003P drawing, side view: 5.50±0.15 free, "4.50 工作高度"
  (working height), "4.20 极限尺寸" (limit); note 4: "Spring force: 120g±20g at normal
  working height (travel 1.0mm)"; note 5: "...shall not exceed the maximum allowed
  compression".
- **Fix:** set the nominal tip height to ~4.65–4.7 (compression ~0.8, counting copper
  and solder), so the band 0.45–1.15 mm stays inside 0…1.3; or make the gap adjustable
  (shim behind the pin board / under the pad board) and measure the first assembly.
  This is a change in the scad, not on the PCB, but decide it before the boards are
  ordered in quantity.

### MAJOR 2 — Panel tabs are 2 mm; JLCPCB states 5 mm minimum with mouse bites

- **What:** each board hangs on two tabs 2.0 mm wide (z) × 1.0 mm long; the three Ø0.5
  bites at 0.75 pitch span the full 2.0 mm (outer holes tangent to the milled slot
  edges), leaving 2 webs × 0.25 mm per tab, i.e. 1.0 mm of FR4 in total holding a board.
- **Evidence:** `gen_pcb.py:53-54` (`TAB, TAB_Z = 2.0, 2.25`, `BITE_D, BITE_P, BITE_N =
  0.5, 0.75, 3`); bites at u = ±5.25, v = ±6.5/7.25/8.0, tab v = 6.25…8.25 (from the
  board via pcbnew). JLCPCB capabilities page, Panelization: "Breakaway tab minimum
  width: 4 mm (5 mm with mouse-bites)"; "Mouse-bite diameter: 0.5–0.8 mm, with
  0.2–0.3 mm between bites" (the bite size/spacing here is fine).
- **Risk:** DFM rejection or a "we changed your panel" hold; boards breaking out during
  routing, E-test, stencil printing or reflow (a lost pad board is a lost instrument set
  given only ~50 pins on the market).
- **Fix:** make the tabs as wide as the board sides allow (~4–5 mm along z; the pin
  board's sides are 9 mm and the only copper near the x edges is the vias at x = ±4.4,
  z = middle row, and ±3.81 at z ±1.5 from the rows), e.g. one 4–5 mm tab centred per
  side with 5 bites, keeping the vias ≥ 0.5 mm from the bite holes; or ask JLCPCB
  support whether they accept 2 mm tabs on a 16 × 25 panel before ordering.

### MINOR 1 — Wire pads on the backs are unlabelled

- **What:** 9 identical 1.2 × 1.4 pads on the pin board's back and 5 on the pad board's
  back, no silkscreen at all on B.Silkscreen (the gerber holds only a header, 15 lines),
  no pin-1 mark. Seen from the back, the layout is mirrored against spec.md's table —
  the classic mirrored-pinout error simply moves to the soldering bench, and a swap of
  DET/3V3/GND wires on the pin board shorts the switched 3.3 V or keeps the system off.
- **Where:** `gen_pcb.py:121-131` (wire pads), `fab/contact-B_Silkscreen.gbo`.
- **Fix:** add B.Silkscreen labels next to each wire pad (3V3, GND, SDA, SCL, INT, DET;
  mirrored text on the back), at least on the boards themselves, not on the rails. There
  is room in the z gaps between wire pads only for ~0.6 mm text; otherwise put a
  one-letter code per pad.

### MINOR 2 — Mouse-bite holes sit outside the board edge, leaving 0.25 mm stubs

- **What:** bite centres at |u| = 5.25, board edge at 5.0, holes tangent to the edge.
  Breaking along the hole line leaves web stubs up to 0.25 mm proud of the board side;
  the 1 mm router also leaves r ≈ 0.5 fillets in the cut-out corners at the tab roots.
  The pin board's x sides locate it in the bass's pocket with 0.1 mm clearance, so the
  stubs must be filed exactly flush, by hand, and the filing sets the board's position.
- **Fix:** put the bite centres on the board edge or 0.1–0.15 mm inside it (the
  usual practice), so the break line lies in the outline and no filing is needed. Copper
  near the tabs is ≥ 1 mm away, so there is room.

### MINOR 3 — Milled gap 1.0 mm is at the limit of JLCPCB's process

- **What:** gaps between boards and frame are 1.0 mm (`gen_pcb.py:52`, `GAP = 1.0`).
  JLCPCB lists non-plated slot width min 1.0 mm and panel board spacing "1.6 or 2 mm".
- **Fix:** 1.6–2.0 mm gaps if the panel may grow (16 × 25 → about 18 × 28), or accept and
  confirm in DFM.

### MINOR 4 — Hot unplug: all three GND pins may break before the 3.3 V pins

- **What:** all nine pins are alike. When pulling apart, if the three GND pins lose
  contact while a 3V3 pin still touches (per-pin height spread ±0.15 plus solder),
  the discant's ~100–200 mA load loses its return and its GND rises; the only return
  left is through the discant ICs' ESD diodes into SDA/SCL/INT, into the ESP32 pins
  (driven low during a transfer) — the main board has no series resistors on SDA1/SCL1/
  INT1, and the discant's 3.3 V stays on while the pins separate (gate rises
  with τ ≈ 100 ms through R15, `main_pcb/spec.md` §3), so the bus may be mid-transfer. Pure board tilt cannot cause it (the middle-left GND lies
  between the two 3V3 pins), only random per-pin height, so it is rare, but it repeats
  with every unplug. DET, by contrast, is safe: it only pulls low through a GND pin.
- **Fix (cheap, main board):** 33–100 Ω series resistors in SDA1/SCL1/INT1 near the
  SRV05-4; or firmware that pauses bus 1 as soon as DET rises. Nothing to change on
  the contact boards themselves.

### MINOR 5 — Neither board has a fixing or locating feature

- **What:** no holes, slots or notches on either board. The pin board sits in an
  open-front pocket (`bass/link.scad:89`) held back only by the pins' force while
  mated; apart, only 0.1 mm clearance friction and its nine wires keep it in. The pad
  board lies on a boss of its own outline (`discant/gauge_link.scad:132-136`), with no
  edge, pocket or pin to locate it in x/z; its lateral position decides where the pins
  land (pad Ø2.2 vs tip Ø0.9 gives about ±0.65 mm for the tip to stay on the pad's flat).
  Neither spec says glue.
- **Fix:** decide now (it changes the PCB if holes are wanted): e.g. glue both, with a
  shallow pocket or two printed edge stops on the boss for the pad board, and a lip or
  glue for the pin board; or one Ø1.0 NPTH per board for a printed pin.

### NOTE 1 — ENIG must be chosen in the order; consider 2 µ" gold

The gerber job file says `"Finish": "None"` (`fab/contact-job.gbrjob`), so ENIG exists
only in spec.md: select it on the order form. The pins carry "2 micro-inch minimum Au
over 50 micro-inch nickel" (datasheet note 2); JLCPCB's standard ENIG is thin flash gold
[unverified: thickness options not on the capabilities page]. Head-on, non-wiping contact
at 120 gf will not wear it quickly, but if JLCPCB offers 2 µ" ENIG, take it.

### NOTE 2 — No fiducials or tooling holes

JLCPCB's capabilities page says edge rails are not necessary for economic PCBA, but one
of its help articles calls fiducials / tooling holes essential for economic PCBA
[conflicting sources, unverified which applies]. The 2 mm rails can carry 1 mm fiducials
(2 mm mask opening) at two corners. Check the DFM result; add them if asked.

### NOTE 3 — Two designs in one panel will probably be charged extra

JLCPCB help article 96 (PCB Panelization): with several designs in one Gerber "we will
usually charge more for this". spec.md marks this [unverified]; it is now confirmed as
likely. It does not change the design.

### NOTE 4 — Part supply

LCSC C49451741 still shows 50 in stock (2026-11-18), price now $0.25 (spec says $0.53).
JLCPCB lists it as an extended part ("componentLibraryType": "expand", presale quantity
48), so one extended-part fee per order. Each panel uses 3 strips → 16 panels from 50.

### NOTE 5 — Check the CPL rotation in JLCPCB's DFM preview

`contact-pos.csv` gives J1–J3 at rot 0 with the strip along x. The part is symmetric
(identical pins, centre notches on both long sides, no pegs), so only a 90° error
matters; confirm the preview shows the strips along the pad rows.

### NOTE 6 — Strip housing height (model estimate) vs datasheet

The drawing shows the Ø2.0 solder cup 0.50 below the PA46 housing and the housing 1.50
tall, so the housing occupies 0.5–2.0 mm above the board; `bass/link.scad:109` models
it 0–1.5. Clearance to the pad board stays ≥ 2.4 mm, so no consequence found; update the
model if you rerun the clash checks.

## Checked and OK

- Mirror/pinout: pin at (x, z) meets pad at (x, z) for all nine positions (pcbnew dump:
  pin board u = x, pad board u = −x; e.g. pin 3V3_A (−2.54, +3) ↔ pad 1 D_3V3 at
  u = +2.54; DET (+2.54, −3) ↔ pad 9 D_GND at u = −2.54). Facing directions verified in
  the scad frames: pad face at y 85 looks +y, pin board front at y 89.5 looks −y; KiCad
  top views as generated are correct for both. Matches spec.md's table.
- Net set vs main board: WIRES has +3V3_D ×2, GND ×3, SDA1, SCL1, INT1, DET
  (`main_pcb/design.py:223-226`) = the pin board's nine pads.
- Pad board's five wires vs hall_pcb J1 {INT, +3V3, SDA, SCL, GND}
  (`hall_pcb/design.py:203`); assembly/spec.md wiring rows 2 and 4 agree.
- DET tied to GND on the pad board: pad 9 → via → back track to the GND wire pad
  (`gen_pcb.py:135`, verified in the board dump); 3V3 pads tied on the back; three GND
  pads tied. DET needs a GND pin in contact to pull low — safe by construction.
- DET line on the main board: 1M to VSYS, 100k + 100 nF into the gates, delay 3–7 ms
  (`main_pcb/design.py:143-170`); matches datasheet note 6 ("adaptor start to power
  supply after connector mated fully").
- Footprint: 3 × Ø2.2 at 2.54, matches "RECOMMEND PCB LAYOUT ... Ø2.20 ... ±0.05";
  fab outline 7.6 × 2.5 = housing 7.60±0.10 × 2.50±0.10; strips 3.0 apart leave 0.5
  between housings; courtyards don't overlap. No polarity, no locating pegs on the
  drawing.
- Datasheet values in spec.md (Ø0.9/Ø1.5, 5.5 free, 4.5 working, 120±20 gf, 10 000
  cycles, 1 A, Au over Ni) all match the drawing.
- Current: 1.0 A max per pin. Contacts carry only the discant's load (46 Hall sensors
  2–4 mA + NAU7802 + ADCs, ≈ 100–200 mA, `main_pcb/spec.md` l.110, 166-168); even the
  whole 650 mA system peak would be 0.33 A per 3.3 V pin. Contact resistance ≤ 50 mΩ.
- Pin landing: tip Ø0.9 on Ø2.2 pads, ±0.65 mm before the tip's edge leaves the pad;
  sliding is along the pin axis (head-on), so no pin scrapes across a neighbour's pad.
- Wire pads: 1.2 × 1.4 on B.Cu, at x ±2.54, z ±2.65 → extent ±3.14 × ±3.35, inside the
  bass cavity (±3.6, `bass/link.scad:77`) and the discant recess (±3.6,
  `discant/gauge_link.scad:83`); 1.25–1.34 mm between pads.
- Copper to edge: nearest copper is the vias at x ±4.4 (edge 4.625) → 0.375 mm to the
  board side; pads 0.4 mm from the z edges; JLCPCB min 0.2 for routed edges.
- Vias 0.45/0.2: JLCPCB 2-layer min 0.15/0.25; 0.2-hole surcharge applies only below
  0.45 mm diameter; diameter − hole = 0.25 ≥ 0.1 (0.15 preferred).
- Tracks 0.2/0.3, clearance 0.15: above JLCPCB minimums.
- Mouse-bite holes Ø0.5 NPTH, 0.25 mm webs: within JLCPCB's 0.5–0.8 / 0.2–0.3.
- Panel 16.05 × 25.05 (gbrjob) ≥ 10 × 10 (economic PCBA single/panel minimum, JLCPCB
  capabilities page via search) and ≥ 3 × 3 (bare FR4 minimum).
- Paste only on the strips' pads (pad board: no paste); BOM has LCSC C49451741 × 3.
- `contact.kicad_pcb` is what `gen_pcb.py` writes (regenerated into the scratchpad,
  identical pads/nets/tracks/vias, different order only).
- DRC (`kicad-cli pcb drc --severity-all`, KiCad 9.0.9): 0 errors, 0 unconnected, 3
  warnings, all "footprint library 'contact_pcb' not in configuration" (expected,
  generated footprints).

## Not checked

- JLCPCB ENIG gold thickness options and whether fiducials are mandatory for economic
  PCBA of a customer panel (sources conflict; see NOTE 1, 2).
- Whether JLCPCB would accept the 2 mm tabs anyway (only the published minimum checked).
- The strip's limit-height tolerance and the force–travel curve (only the 120 gf point
  is given), so the low-compression contact force is unknown.
- Printing tolerances of the block, pocket and boss: estimated (FDM ±0.1–0.2), not
  measured.
- Clash checks were not rerun (no rebuilding allowed); assembly/spec.md's 2026-11-15
  results taken as given.
