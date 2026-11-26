# Bill of materials (without the boards' assembly)

Everything to buy, print or make for one instrument, apart from the parts JLCPCB
places on the boards (those are in each board's `fab/*-bom.csv`). The boards
themselves are listed. Collected 2026-11-15 from the specs named in each section;
[open] and [unverified] mark what they leave open.

## Keys: 64 (46 discant, 18 bass) — `switch_hall/spec.md`

| Part | Per key | Total | Source / type |
|---|---|---|---|
| Compression spring **Misumi UY8-25** (stainless, ⌀8 × 0.45 × 25) | 1 | 64 | stock: 20 ordered 2026-11-26 from Misumi; **44 still to order** [open] |
| Sleeve bearing, sintered bronze, oil-impregnated, d3 × D5 × 4 | 1 | 64 | stock: ordered 2026-11-21 from the Bambu Lab store, "Oil Impregnated Bronze Bushings" ED002 3 × 5 × 4 (packs of 20); else 123kugellager.de BMG03-05-04 (about 5 € each); the bought ones measure D5.05: the tube's way in is ⌀5.2, its seat ⌀5.0 [2026-11-26] |
| Rod: dowel pin ISO 2338 ⌀3 h8 × 14, stainless A1 (bass back row × 24) | 1 | 55 × 14 + 9 × 24 | stock: the 55 × 14 ordered 2026-11-21 from MBO Oßwald (mbo-osswald.de, 3 h8 × 14, 1.4305); **the 9 × 24 for the bass's back row still to order** [open] (3 h8 × 24, the same steel); not m6, not ISO 8734 (hardened, magnetic) |
| Magnet ⌀3 × **1**, N52, magnetised axially | 1 | 64 | stock: 200 ordered 2026-11-23 from yourmagnets.net; the collar takes ⌀3 × 1 under a 0.5 web [2026-11-23; ⌀3 × 1.5 before, ordered 2026-11-21 from magnethandel.de]; they measure ⌀3.1; its pocket is ⌀3.25, the magnet glued (slow epoxy) [2026-11-26] |
| O-ring 4 × 1.5 (silicone about 50 Shore A, or NBR 70) | 1 | 64 | stock: ordered 2026-11-26 |
| Stop washer ⌀4.5 / ⌀2.5 | 1 | 64 | punched from 1 mm silicone or PU sheet; or a stock O-ring 2.5 × 1 (NBR 70 or silicone) instead [2026-11-23], `switch_hall/spec.md` §2 |
| Cap, collar | 1 each | 64 + 64 | printed |
| Adhesive for the rod in cap and collar: slow 2-component epoxy, e.g. UHU plus endfest | a drop each | 1 pack | ordered 2026-11-26; not cyanoacrylate (creeps into the bushing); `switch_hall/spec.md` §2. Or, nothing to mix: a one-part MS polymer (e.g. UHU Max Repair), cured 1–2 days; try it on the prototype first [2026-11-23] |

## Discant — `discant/spec.md`

| Part | Count | |
|---|---|---|
| Housing (with the outer holders, the contacts' boss and the shoulder strap's eyes), cover | 1 + 1 | printed |
| Countersunk screw M2 × 6, **brass**, DIN 965 CuZn | 27 | cover through the board into the housing |
| Hall board, discant (assembled) | 1 | `hall_pcb/discant` |
| Pad board | 1 | half of the contacts' panel, `contact_pcb` |
| Shoulder strap for the right shoulder, with a carabiner at each end (wire up to 4 mm, gate 6 mm or more) | 1 | [assumed]; clipped into the housing's eyes, `discant/spec.md` §2 |

## Gauges: 2 — `strain_gauge/spec.md`

| Part | Count | |
|---|---|---|
| Half-bridge load cell, 50 kg, 1000 Ω per gauge (2 kΩ red–black, yellow the middle), 1.0 mV/V, 3 wires (the bathroom-scale cell: plate with its gauges; plate 30 × 23.3 × 2.5) | 2 | from a bathroom-scale set of 4 plates: 2 used, 2 spare [given 2026-11-26]; `strain_gauge/spec.md` §4a |
| Dowel pin ⌀1.5 × 10, ISO 2338 | 4 | hold the plates in the outer holders |

## Overload stops: 2 sides — `assembly/spec.md`, Overload stops

| Part | Count | |
|---|---|---|
| Heat-set insert M3, for a ⌀4.0 hole, 4 long | 4 | in stock (M3 × 4) [given 2026-11-26]; one per side in the bass's block floor (S1), one in the discant's tongue (S2), both from below [unverified: the hole the bought ones want; ⌀4.0 assumed] |
| Grub screw **M3 × 4**, ISO 4026, flat point | 2 | S1, its tip against the tongue (push down) |
| Grub screw **M3 × 6**, ISO 4026, flat point | 2 | S2, its tip against the slot's roof (push up) |
| Medium threadlocker | a drop each | on the screw only, kept off the plastic (anaerobic threadlockers crack PETG); or a second grub screw as a lock in the same insert |

## Bass — `bass/spec.md`

| Part | Count | |
|---|---|---|
| Case (with inner holders, the cam's shoes and lugs, contacts' block), cover, back cover, cam lever | 1 + 1 + 1 + 1 | printed, PETG; the lever upside down |
| Cam lever's axle ⌀2 × 73, **silver steel** (hardened, e.g. 115CrV3 h8) | 1 | bar stock, cut to length, through the four lugs and the lever; soft stainless bends [estimate, `assembly/spec.md` Latches] |
| Grub screw **M2 × 3**, ISO 4026, flat point | 2 | in the cams' shoes (tapped M2), sets the clamping force |
| Countersunk screw **M2 × 6**, DIN 965, brass (as the discant's) | 12 | cover (2.4) and board (1.67) into ⌀1.7 pilots in the case: 1.9 mm of thread, the tip 0.5 above the pilot's end; × 8 would be too long |
| Countersunk screw M2 × 6, DIN 965 | 3 | back cover |
| Pan head screw **M2 × 3**, ISO 7045, stainless A2 | 3 | main board: board (1.0) and pad (0.47) into ⌀1.7 pilots 2 mm into the front wall: 2.0 mm of thread, the tip 0.5 above the pilot's end, 1 mm of wall left to the hand's face; × 4 would go too deep. Head ⌀4 × 1.6 in the ⌀4.4 copper keepout, 3.5 short of the back cover |
| LiPo cell 1S, pouch 606090, 4000 mAh, with PCM and 10k NTC, 3 wires (e.g. DNK606090; 92 × 60 × 6.0 with the PCM) | 1 | [checked 2026-11-15: datasheet] |
| or: the same cell with 2 wires (e.g. EREMIT 606090), and Kapton tape | 1 | variant, `bass/spec.md`; no 3-wire cell found [2026-11-26], so this one |
| NTC **MF52-103, B 3950** (10 kΩ at 25 °C, epoxy bead ⌀2–2.5), for the 2-wire cell | 1 | chosen 2026-11-26; taped to the cell's top edge (`bass/spec.md`, variant). B 3950 instead of the design's 3435: the charger's TS window moves from 0 … 50 °C to about 4 … 46 °C (computed), inside the cell's 0 … 45 °C |
| Panel jack **Switchcraft 35PRM3** | 1 | screwed into the case's tapped hole, its nut unused; tap **M6 × 0.75** (fine) for the ⌀5.3 hole, threadlocker |
| Hand strap, leather 40 × 2–3 mm, with buckle | 1 | [assumed] |
| Main board, Hall board bass (assembled) | 1 + 1 | `main_pcb`, `hall_pcb/bass` |
| Pin board (assembled) | 1 | half of the contacts' panel, `contact_pcb` |
| Adhesive for the pin board | a drop | against falling out while apart |

## Wiring — `assembly/spec.md`, Wiring

| Part | Amount | |
|---|---|---|
| Stranded wire AWG 30, 7 × 0.1, thin-wall PTFE (⌀ ≤ 0.55) | about 3.7 m cut (runs 2–5, 7 and the NTC's) | by the metre: red 1 m, black 2 m, blue, yellow, green, white, purple 1 m each [2026-11-26; `assembly/spec.md`, Order list] [unverified: outside ⌀] |
| JST PH 2-pin pair, pre-crimped, leads AWG 26 or 28 at least 130 mm | 1 | the cell's plug's counterpart; its leads are the battery's tail + and − to P15 / P12 [chosen 2026-11-26, no AWG 26 by the metre] |
| JST SH 2-pin pair, pre-crimped | 1 | the NTC's plug |
| JST SH cable, 5 pins, pre-crimped | 1 | the bass Hall board's J1 plug, spliced to PTFE wire |
| Heat shrink for the splice | about 3 cm | |

## Boards to order (their parts: each board's `fab/*-bom.csv`)

| Board | |
|---|---|
| Main board | `main_pcb` |
| Hall board, discant | `hall_pcb/discant` |
| Hall board, bass | `hall_pcb/bass` |
| Contacts' panel (pin board + pad board), 16 × 25, ENIG, milled gaps and tabs with mouse bites | `contact_pcb` |
