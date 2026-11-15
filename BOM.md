# Bill of materials (without the boards' assembly)

Everything to buy, print or make for one instrument, apart from the parts JLCPCB
places on the boards (those are in each board's `fab/*-bom.csv`). The boards
themselves are listed. Collected 2026-11-15 from the specs named in each section;
[open] and [unverified] mark what they leave open.

## Keys: 64 (46 discant, 18 bass) — `switch_hall/spec.md`

| Part | Per key | Total | Source / type |
|---|---|---|---|
| Compression spring **Misumi C-UY8-25** (stainless, ⌀8 × 0.45 × 25) | 1 | 64 | stock |
| Sleeve bearing, sintered bronze, oil-impregnated, d3 × D5 × 4 | 1 | 64 | stock |
| Rod ⌀3 h6, ground stainless: 13.8 mm (bass back row 23.8 mm) | 1 | 55 × 13.8 + 9 × 23.8 ≈ 1 m | bar stock, cut to length |
| Magnet ⌀3 × 1.5, N52, magnetised axially | 1 | 64 | stock |
| O-ring 4 × 1.5 (silicone about 50 Shore A, or NBR 70) | 1 | 64 | stock |
| Stop washer ⌀4.5 / ⌀2.5 | 1 | 64 | punched from 1 mm silicone or PU sheet |
| Cap, collar | 1 each | 64 + 64 | printed |
| Adhesive for the rod in cap and collar | | | [open: type] |

## Discant — `discant/spec.md`

| Part | Count | |
|---|---|---|
| Housing (with the outer holders and the contacts' boss), cover | 1 + 1 | printed |
| Countersunk screw M2 × 6, **brass**, DIN 965 CuZn | 27 | cover through the board into the housing |
| Hall board, discant (assembled) | 1 | `hall_pcb/discant` |
| Pad board | 1 | half of the contacts' panel, `contact_pcb` |

## Gauges: 2 — `strain_gauge/spec.md`

| Part | Count | |
|---|---|---|
| Flexure plate | 2 | [open: material and making; the sizing is for steel] |
| Strain gauge | 4 (2 per plate, half bridge) | [open: 120 or 350 Ω] |
| Dowel pin ⌀1.5 × 10, ISO 2338 | 4 | hold the plates in the outer holders |

## Bass — `bass/spec.md`

| Part | Count | |
|---|---|---|
| Case (with inner holders, latches, contacts' block), cover, back cover | 1 + 1 + 1 | printed, PETG |
| Latch rod ⌀2 × 68, stainless or silver steel | 1 | bar stock, cut to length, pressed into the lugs |
| Countersunk screw M2, brass (as the discant's) | 12 | cover through the board into the case [open: length] |
| Countersunk screw M2 × 6, DIN 965 | 3 | back cover |
| Screw M2 | 3 | main board [unverified: type] |
| Li-ion cell 1S, pouch 606090 (6 × 60 × 90 mm, about 4 Ah) | 1 | [unverified: type, capacity] |
| Panel jack **Switchcraft 35PRM3** | 1 | |
| Hand strap, leather 40 × 2–3 mm, with buckle | 1 | [assumed] |
| Main board, Hall board bass (assembled) | 1 + 1 | `main_pcb`, `hall_pcb/bass` |
| Pin board (assembled) | 1 | half of the contacts' panel, `contact_pcb` |
| Adhesive for the pin board | a drop | against falling out while apart |

## Wiring — `assembly/spec.md`, Wiring

| Part | Amount | |
|---|---|---|
| Stranded wire AWG 30, 7 × 0.1, thin-wall PTFE (⌀ ≤ 0.55) | about 3.7 m cut (runs 2–5 and 7) | several colours [unverified: outside ⌀] |
| JST SH cable, 5 pins, pre-crimped | 1 | the bass Hall board's J1 plug, spliced to PTFE wire |
| Heat shrink for the splice | about 3 cm | |

## Boards to order (their parts: each board's `fab/*-bom.csv`)

| Board | |
|---|---|
| Main board | `main_pcb` |
| Hall board, discant | `hall_pcb/discant` |
| Hall board, bass | `hall_pcb/bass` |
| Contacts' panel (pin board + pad board), ENIG, V-cut | `contact_pcb` |
