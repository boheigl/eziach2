# Bill of materials (without the boards' assembly)

Everything to buy, print or make for one instrument, apart from the parts JLCPCB
places on the boards (those are in each board's `fab/*-bom.csv`). The boards
themselves are listed. Collected 2026-11-15 from the specs named in each section;
[open] and [unverified] mark what they leave open.

## Keys: 64 (46 discant, 18 bass) — `switch_hall/spec.md`

| Part | Per key | Total | Source / type |
|---|---|---|---|
| Compression spring **Misumi C-UY8-25** (stainless, ⌀8 × 0.45 × 25) | 1 | 64 | stock |
| Sleeve bearing, sintered bronze, oil-impregnated, d3 × D5 × 4 | 1 | 64 | stock: e.g. Bambu Lab store "Oil Impregnated Bronze Bushings" ED002 (packs of 20), 123kugellager.de BMG03-05-04 (about 5 € each) [found 2026-11-21, unverified] |
| Rod: dowel pin ISO 2338 ⌀3 h8 × 14, stainless A1 (bass back row × 24) | 1 | 55 × 14 + 9 × 24 | stock (screw dealers); not ISO 8734 (hardened, m6, magnetic) |
| Magnet ⌀3 × 1.5, N52, magnetised axially | 1 | 64 | stock |
| O-ring 4 × 1.5 (silicone about 50 Shore A, or NBR 70) | 1 | 64 | stock |
| Stop washer ⌀4.5 / ⌀2.5 | 1 | 64 | punched from 1 mm silicone or PU sheet |
| Cap, collar | 1 each | 64 + 64 | printed |
| Adhesive for the rod in cap and collar: slow 2-component epoxy, e.g. UHU plus endfest | a drop each | 1 pack | not cyanoacrylate (creeps into the bushing); `switch_hall/spec.md` §2 |

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
| Half-bridge load cell, 50 kg, 1000 Ω, 1.0 mV/V, 3 wires (the bathroom-scale cell: plate with its gauges) | 2 | sold as 4 with an HX711 board (unused); `strain_gauge/spec.md` §4a |
| Dowel pin ⌀1.5 × 10, ISO 2338 | 4 | hold the plates in the outer holders |

## Bass — `bass/spec.md`

| Part | Count | |
|---|---|---|
| Case (with inner holders, latches, contacts' block), cover, back cover | 1 + 1 + 1 | printed, PETG |
| Latch rod ⌀2 × 68, stainless or silver steel | 1 | bar stock, cut to length, pressed into the lugs |
| Countersunk screw **M2 × 6**, DIN 965, brass (as the discant's) | 12 | cover (2.4) and board (1.67) into ⌀1.7 pilots in the case: 1.9 mm of thread, the tip 0.5 above the pilot's end; × 8 would be too long |
| Countersunk screw M2 × 6, DIN 965 | 3 | back cover |
| Pan head screw **M2 × 3**, ISO 7045, stainless A2 | 3 | main board: board (1.0) and pad (0.47) into ⌀1.7 pilots 2 mm into the front wall: 2.0 mm of thread, the tip 0.5 above the pilot's end, 1 mm of wall left to the hand's face; × 4 would go too deep. Head ⌀4 × 1.6 in the ⌀4.4 copper keepout, 3.5 short of the back cover |
| LiPo cell 1S, pouch 606090, 4000 mAh, with PCM and 10k NTC, 3 wires (e.g. DNK606090; 92 × 60 × 6.0 with the PCM) | 1 | [checked 2026-11-15: datasheet] |
| or: the same cell with 2 wires (e.g. EREMIT 606090) plus a 10k NTC, B 3435, bead ⌀1.5–2 or 0603, and Kapton tape | 1 | variant, `bass/spec.md` |
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
| Contacts' panel (pin board + pad board), 16 × 25, ENIG, milled gaps and tabs with mouse bites | `contact_pcb` |
