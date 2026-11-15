# Contact boards (bass ↔ discant)

The spring contacts that join the two halves when the bass is plugged for playing
[given: power and I2C cross by contacts that close as the bass slides on; chosen
2026-11-15: spring pins on a small board]. Two boards, made as one panel and split
along a V-cut after assembly: the **pin board** goes into the bass (`../bass/link.scad`),
the **pad board** onto the discant (`../discant/gauge_link.scad`). Why spring pins and
not blade or card-edge contacts: `../assembly/spec.md`, Contacts.

| | |
|---|---|
| Panel | 10.0 × 18.0 mm, 2 layers, 1.6 mm, **ENIG** (the pads are contacts), V-cut at the middle (drawn on User.1) |
| Each board | 10.0 × 9.0 mm |
| Grid | 3 × 3: 2.54 mm across (x), 3.0 mm up (z); the strips are 2.5 wide, so 3.0 leaves them 0.5 apart |
| Pads | ⌀2.2 on both boards (the strip's recommended pad) |
| Vias | 0.45 / 0.2, in the gaps between four pads (0.64 mm clear of each) or beside the middle row; tented |
| Tracks | 0.2, supply 0.3; clearance 0.15 |
| Wire pads | 1.2 × 1.4 mm on the back, within ±3.4 mm, so the joints sit in the cavity (bass) or recess (discant) behind the board |

## Pin board (bass)

| Part | Count | |
|---|---|---|
| PG2541-03-003P (CHIN-BAN), LCSC **C49451741** | 3 (J1–J3) | 3 spring pins each at 2.54, SMD; plunger ⌀0.9, barrel ⌀1.5; free height 5.5, working height 4.5 (1.0 travel); 120 ± 20 gf there; gold over nickel; 10 000 cycles; 1 A [datasheet]. 50 in stock 2026-11-15, $0.53 each |

Nine wire pads on the back, one per pin, because the main board takes nine wires
(`../main_pcb/design.py`, WIRES).

## Pad board (discant)

Nine bare pads on the front. On the back: the 3.3 V pair, the three GND and DET are
tied (DET to GND: switches the bass's system on), and five wire pads carry 3V3, GND,
SDA, SCL and INT to the Hall board's J1. The left GND pad joins the middle one on the
front, so its via would not cut the 3.3 V pair's track.

## Pin assignment

Seen from the discant, looking at the bass's pins (x to the right, z up); the pad
board, seen from the bass, shows it mirrored.

| z \ x | −2.54 | 0 | +2.54 |
|---|---|---|---|
| +3 | 3V3 | SDA | SCL |
| 0 | GND | GND | GND |
| −3 | 3V3 | INT | DET |

## Open

- DET closes no later than the other pins: all nine pins are alike. The main board ramps
  the discant's 3.3 V up after DET; that ramp should cover the pins' spread as the bass
  slides on (about 10 ms; now about 1 ms) (`../assembly/spec.md`).
- JLCPCB's minimum size for assembly, believed to be 10 × 10 mm, is why the two boards
  are one panel [unverified]. The V-cut on User.1 must be named in the order.
- The strip's housing height is estimated in the model (`contact_pins()`), only its
  overall heights are from the datasheet.

## Files

| File | |
|---|---|
| `gen_pcb.py` | writes `contact.kicad_pcb`: footprints, pads, tracks and vias, outline and V-cut |
| `build.sh` | runs it, KiCad's DRC (`drc.json`), and writes `fab/`: gerbers, drill, `contact-pos.csv`, `contact-bom.csv` |
