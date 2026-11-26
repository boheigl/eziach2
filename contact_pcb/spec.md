# Contact boards (bass ↔ discant)

The spring contacts that join the two halves when the bass is plugged for playing
[given: power and I2C cross by contacts that close as the bass slides on; chosen
2026-11-15: spring pins on a small board]. Two boards, made as one panel and broken out
after assembly: the **pin board** goes into the bass (`../bass/link.scad`),
the **pad board** onto the discant (`../discant/gauge_link.scad`). Why spring pins and
not blade or card-edge contacts: `../assembly/spec.md`, Contacts.

| | |
|---|---|
| Panel | 17.2 × 22.8 mm, 2 layers, 1.6 mm, **ENIG** (the pads are contacts): both boards in a 2 mm frame, 1.6 mm milled gaps round them (1.0 before 2026-11-19: JLCPCB's least slot; 1.6–2 advised), each held by a 5 mm tab on either side (JLCPCB's minimum with mouse bites; 2 mm before 2026-11-18, review/contact_pcb.md) with seven ⌀0.5 mouse-bite holes at 0.75 along the board's edge, the nearest 0.68 mm from a via's copper (the tabs in the boards' middle) [given 2026-11-15: tabs, not V-cut] |
| Each board | 10.0 × 7.0 mm [2026-11-25: 10 × 9 with nine pins] |
| Grid | 2 × 3: 2.54 mm across (x), 3.0 mm up (z), the rows at ±1.5; the strips are 2.5 wide, so 3.0 leaves them 0.5 apart [2026-11-25: six pins, one per net; was 3 × 3, the 3.3 V doubled and GND tripled, so nine wires ran to the main board] |
| Pads | ⌀2.2 on both boards (the strip's recommended pad) |
| Vias | 0.45 / 0.2, in the gaps between four pads (0.64 mm clear of each) or beside the middle row; tented |
| Tracks | 0.2, supply 0.3; clearance 0.15 |
| Wire pads | 1.2 × 1.4 mm on the back, at z ±1.6 (to ±2.3), so the joints sit in the cavity (bass) or recess (discant) behind the board; each net's name below its pad on the back silkscreen, mirrored so it reads from the back [2026-11-19, review MINOR 1] |

## Pin board (bass)

| Part | Count | |
|---|---|---|
| PG2541-03-003P (CHIN-BAN), LCSC **C49451741** | 2 (J1, J2) | 3 spring pins each at 2.54, SMD; plunger ⌀0.9, barrel ⌀1.5; free height 5.5, working height 4.5 (1.0 travel), limit 4.2; 120 ± 20 gf there; used at 4.7 (0.8 pressed, about 100 gf), so the stack's tolerances stay clear of the limit (`../bass/link.scad`, pin_h) [2026-11-18]; gold over nickel; 10 000 cycles; 1 A [datasheet]. 50 in stock 2026-11-15, $0.53 each |

Six wire pads on the back, one per pin (`../main_pcb/design.py`, WIRES). Each pin has
its via beside it (the outer columns, x ±4.1) or between the rows (the middle column,
x ±1.27).

**Supply** [checked 2026-11-15 at lcsc.com]: 50 in stock, enough for 16 instruments. Buy
what the planned instruments need now (into JLCPCB's private parts library, so the
assembly can use them later). The same pin comes in CHIN-BAN's 2-pin strip
**PG2541-02-001P** (C49451493, 897 in stock, $0.30): ⌀0.9 / ⌀1.5, free 5.5, working 4.5,
limit 4.2, 120 ± 20 gf, SMD, ⌀2.4 pads [datasheet]; it is not a drop-in (5.2 long for two
pins, so no three at 2.54 in a row), it would need a new grid, e.g. five strips of two
(one pin spare). The 5-pin PG2541-05-004P is a through-hole part of another height, the
2-pin PG2541-02-002P a 13.7 mm long one: neither fits.

## Pad board (discant)

Six bare pads on the front. On the back DET is tied to GND, the pad above it in the +x
column (switches the bass's system on), and five wire pads carry 3V3, GND, SDA, SCL and
INT to the Hall board's J1.

## Pin assignment

Seen from the discant, looking at the bass's pins (x to the right, z up); the pad
board, seen from the bass, shows it mirrored.

| z \ x | −2.54 | 0 | +2.54 |
|---|---|---|---|
| +1.5 | 3V3 | SCL | GND |
| −1.5 | INT | SDA | DET |

[2026-11-26; was 3V3 SDA SCL / GND DET INT] Chosen so that the wires, modelled one by one
(`../strands.scad`), come from the wire pads (the same grid, z ±1.6) into the bores'
bundles without crossing on both boards: searched over the assignments with DET next to
GND for the least overlap of the wires' fans (none on either board; was 3.4 mm³ in
eleven pairs). The main board's P1–P6 follow (`../main_pcb/design.py`, WIRES).

## Open

- **Built from `gen_pcb.py` only on a machine with KiCad** (its Python module `pcbnew` and
  `kicad-cli`): the six-pin boards [2026-11-25] are written but not yet built or checked by
  DRC; run `build.sh` and look at the DRC line.
- **One GND pin** [2026-11-25: there were three]: as the discant comes off, its ground may
  part before its 3.3 V, and the return current then runs through the bus; the 33 R in
  the bus lines on the main board limit it (`../main_pcb/spec.md`, review/contact_pcb.md
  MINOR 4). Before, two more GND pins made that less likely.
- DET closes no later than the other pins: all six pins are alike. The main board turns
  the discant's 3.3 V on 3–7 ms after DET, fully after about 12 ms, which covers the pins'
  spread as the bass slides on (`../main_pcb/spec.md` §3).
- **Ordering** [checked 2026-11-15, jlcpcb.com]: JLCPCB cuts V-grooves only in panels of
  70 × 70 mm or more, and its economic assembly takes boards from 10 × 10 mm; each board
  alone is 10 × 9. Hence the panel with milled gaps and tabs: in the order "Panel by
  Customer", different designs 2 [unverified: whether JLCPCB charges for the second
  design], edge rails none, ENIG, economic assembly of the top side. The mouse bites are
  in the drill file (non-plated).
- **Breaking out:** bend each board out over its tabs; the tabs break through their
  holes and leave half holes and little stubs on the boards' sides (x). Those sides
  locate the pin board in the bass's pocket (0.1 clearance), so file them flush.
- **Fixing** [given 2026-11-20: glue only, no holes or pegs on the boards]: the pad board
  glued onto the discant's boss (edges flush), the pin board kept in its pocket by a
  drop of silicone (`../assembly/spec.md`, Contacts).
- The strip's housing height is estimated in the model (`contact_pins()`), only its
  overall heights are from the datasheet.

## Files

| File | |
|---|---|
| `gen_pcb.py` | writes `contact.kicad_pcb`: footprints, pads, tracks and vias, the panel's outline, gaps, tabs and mouse bites |
| `build.sh` | runs it, KiCad's DRC (`drc.json`), and writes `fab/`: gerbers, drill, `contact-pos.csv`, `contact-bom.csv` |
