# Discant and bass together

`assembly.scad` puts the discant into the bass's frame with `../bass/link.scad`'s
`to_bass()`: the discant turned 180° about z, so that the gauges' plates sit in the
discant's outer holders and the bass's inner holders, pointing along the bass's y and
sensing along its z [given]. The bass on top; the discant behind it and below, its
gauge pad facing the bass's hand plate.

`make` builds the discant and the bass first, then the discant's parts moved
(`../build/assembly/d_*.stl`), light keys for all 64 (stem, felt, cap; the full
buttons are on the two sides' own pages), and the 3D view `view3d.html`.

Checked by solid intersection (`../bass/spec.md` §4): the whole discant, mated,
touches none of the bass's parts.

## Stored [given: plugged like the old hinge's two positions; the bass covers the discant's keys]

The earlier design folded the two halves on hinges (../../pcb/README.md, eziach.png);
here the gauge plates are the plug and the bass has two sockets:

- **Playing:** the plates slide along the bass's y into the inner holders at the bottom
  of its back wall (as before).
- **Stored:** the discant turns 90° about x, its keys toward the box's thin back wall,
  and back by its own slope (rows climb 3 per 16: atan(3/16) = 10.62°) [given: use the
  slope], so that caps and housing lie parallel to the wall, 1 mm off it, 27.7 mm thick
  instead of 37.6. Its plates lie in the same slope plane [given: gauges in the slope's
  plane], so they point straight up the bass's z: the discant slides straight up until
  they sit 6 mm deep in a short socket in a pocket in the deck's underside [given: short
  socket]. The box, 265 wide at the bottom [given: widen it] and slanting in above, parallel to the discant's stepped ends [given], covers all 46 keys, 5 mm beyond the caps; the
  deck lies over the discant's back, the playing mount under its front edge.

With the gauges in the slope plane, the playing position too has the discant's slope
plane level (the plates still along the bass's y): the discant hangs 3.3 mm below the
bass's bottom instead of 16.6.

Below the stored discant's front edge (the cover's, with the thumb bar whole; discant/spec.md §3.2) stays 9.6 mm (the socket's 8.3 mm, 1 mm and 0.3 mm) above the playing mount's top (the latches' lugs), the travel to slide it on and off; for that the box is 9.8 mm longer than the hand plate [given: +3 mm, then the latch's 2.3, then the holders' thicker walls 2.3; then the lugs for the rod 2.1, 2026-11-15]. The bass's box below the deck is 11.2 thin [given: 4.8 thinner,
with a 6 mm battery], so the stored discant lies 4.8 closer; the deck's back face
(27.8) was then the package's back; the discant's shoulder strap eyes now stand 4.6
behind it (y 32.4; `../discant/spec.md` §2) [given 2026-11-22: the strap, with carabiners]. Checked:
clear of case, back cover, battery, wires and the bass's keys both seated and 9.6 mm lower; 2.7 mm of deck
stay under the back row's springs. Package **282.9 × 44.9 × 151.8 mm (1.9 L)**.
`../bass/link.scad`: `to_store()`, `store_socket()`, `store_pocket()`; the page's Stored
switch shows it.

## Latches [given: in both positions]

Both are in the inner holders (`../strain_gauge/inner_holder.scad`): a spring tongue in
each holder's top wall either side, its tooth in the plate's inner slot between web and
column, behind the slot's closed end. Sliding on, the tooth rides over the W's bottom
block and drops into the slot. It touches only the W, never the column or the fixed
arms, so the force still runs through the gauges' columns.

- **Playing** (mount on the box's back wall): square tooth, a positive lock that holds
  the strap's pull. To take the bass off, lift the rod with one finger and slide the
  bass off with the other hand. **Rod** [chosen 2026-11-15: the four lugs could not be
  lifted at once by hand; the bass prints standing on its hand face (y −12.5)]: a stock
  steel rod ⌀2 × 68 mm (stainless or silver steel, cut to length) pressed through the
  four latches' lugs after printing (`../bass/link.scad`, `latch_rod_body()`), 0.3 mm
  over the holders' top faces. The four tongues share their root line and length and
  both holders stand on the one mount, so their ends move alike and the rod bends none
  of them. Each lug rises from its tongue at 45° and carries an ear in a pocket of the
  slot's wall, which ends the lift (`../strain_gauge/spec.md`, Latch), so all of it
  prints in the bass's orientation without support. Lifting takes a few newtons; the
  rod bends about 0.03 mm under it [estimate]. Checked 2026-11-15 against the discant as
  played and the case: the rod is clear of the contacts' block, the discant's boss,
  outer holders and pad; rod and lugs lifted 2 mm (more than the stop's 1.8) are clear
  of everything; controls (rod moved against the lugs) overlap. Printed
  in PETG [given 2026-11-15].
- **Stored** (socket under the deck): 45° tooth, a detent; four of them hold about 15 N
  [estimate: tongue 3 × 1.2 mm, its tooth 9.2 mm from the root, PETG E 2000 MPa, 0.6 mm
  deflection, friction 0.3; the 1.0 mm tongue gave about half, so the detent's is 1.2
  (2026-11-15)]
  against the discant's weight (about 3.5 N [estimate]); a firm pull down releases it.

Checked: seated, teeth and plates clear; moved 0.3 mm in the pull-off direction, the
teeth of both positions meet the slots' ends.

## Overload stops [given 2026-11-20: adjustable screw stops]

Why: the cells take 3430 N·mm each at their rating, 150 % (5145 N·mm) without harm
[seller, `../strain_gauge/spec.md` §4a]. Playing hard is about 30–60 N on the hand plate
at 56 mm, 1700–3400 N·mm on the two [estimate]; a hard push, 100 N at 64–125 mm, is
6400–12 500 N·mm, and an off-centre one puts most of it on one cell.

What: beside each gauge, outboard, a tongue 8.4 × 9.6 × 5 mm stands out from the outer
holder's outboard face (the discant's housing, `../discant/gauge_link.scad`); the bass's
mount reaches forward round it with a slot 0.8 mm wider than the tongue above and below,
open to the holder (`../bass/link.scad`). The tongue stays within the holder's length, so
the stored discant's pocket in the deck keeps its depth. Per side:
- **S1:** grub screw M3 × 4 (ISO 4026, flat point) in a heat-set insert M3 (hole ⌀4.0,
  4 long) in the slot's floor, from below; its tip stops the tongue going down.
- **S2:** grub screw M3 × 6 in a heat-set insert in the tongue, from below through a slot
  in the bass's floor open to the front (the screw's foot slides in with the tongue); its
  tip against the slot's roof stops the tongue going up.
So 4 grub screws (2 × M3 × 4, 2 × M3 × 6), 4 inserts M3 [unverified: the insert bought,
hole and length to match]. Both screws are turned from below with a 1.5 mm key.

Setting, by load, once per side and direction (two people, or the console's `status`
called again and again):
1. Both screws backed off (tips under the surfaces); `tare` with nothing touched.
2. Load the bass the way it will be played, to the set force: **about 40 N at the hand
   plate's top edge** (push, through a kitchen scale under the palm), and **about 70 N on
   the strap** (pull, a luggage scale on the strap's middle); about 5000 N·mm, 1.5 × the
   hardest playing and half the cells' 150 % [chosen].
3. Holding it, turn one screw of the side in: the one whose turning makes that side's cell
   reading (`status`, cells) drop is the stop for this direction. Turn it until the
   reading has dropped a little, then back until it just stops changing; unloaded, the
   tip then stands its share of the gap off.
4. Secure the screw: a drop of medium threadlocker on the screw, kept off the plastic
   (anaerobic threadlockers crack PETG), or a second grub screw on top in the same insert
   as a lock.
5. Repeat for the other direction and the other side; then `tare` again.

Up to the set force the cells carry it all and read true; past it the screws take the
rest. A check: pressing harder than the set force, the reading stays nearly flat.

Checked (2026-11-20, solids, controls overlapping): played, the tongues are clear of the
bass's slots (shifted 0.85 in z they touch, from both sides) and of case, back cover,
boards, electronics, battery, wires, rod, pins and strap; the screws as set clear of tongue and roof
(0.05 off; shifted 0.2 they touch); stored, the discant is clear of all of them too.
Printing: the housing prints standing, holders up (`../discant/spec.md`, Printing); there
the tongue stands out sideways and has a 45° gusset under it, in front of the bass's block.

## Electronics split, contacts and power [given: power and I2C cross by contacts that close as the bass slides on; plugging for playing switches the system on; the bass charges by its own USB socket, also stored; the electronics moved from the discant to the bass]

- **Bass** (`../bass/elec.scad`): everything that is not key reading: the ESP32-S3, the
  audio DAC and the earphone jack, one USB-C (charging, firmware, MIDI), the battery
  with charger (the cell's own protection board, a fuse on the main board), the 3.3 V
  supply for both halves (`../main_pcb/spec.md`).
- **Key boards** (`../hall_pcb/`): one Hall-sensor board per half, read by ADS7128 ADCs
  on I²C, no controller. Two buses, 5 wires each (3.3 V, GND, SDA, SCL, INT): the
  discant's (ADCs 10h…15h, with the NAU7802) through the contacts, the bass's (10h…12h,
  with the DAC) inside the bass box. [superseded: a PCAL9555A expander on each of six
  switch boards, one bus]
- **Discant:** only the key board, which also carries the NAU7802 for the gauges
  [chosen 2026-11-15; the link board beside the gauges is gone].
- **Contacts** [chosen 2026-11-15: spring pins on a small board; blade and card-edge
  contacts were looked at and set aside, below]: two small boards, one panel
  (`../contact_pcb/`). The bass's carries three PG2541-03-003P strips (CHIN-BAN, LCSC
  C49451741: 3 spring pins each at 2.54 mm, SMD, gold, 1.2 N at the working height, 1 mm
  travel, 10 000 cycles [datasheet]), the strips 3.0 mm apart: nine pins. It sits in a
  pocket of a block on the bass's playing mount between the inner holders
  (`../bass/link.scad`), reaching between the discant's outer holders (5.8 mm off the
  middle; the block 5.5 there, wider behind their tips, where its walls locate the
  board); the pins press it onto the pocket's ledge. The discant's board carries nine
  gold pads ⌀2.2 on the same grid, on a boss on the discant's pad
  (`../discant/gauge_link.scad`, face at gauge y 85). They meet head on as the bass
  slides on, the pins 4.7 high when latched (0.8 pressed, not the working height 4.5:
  the tolerances of the stack, about ±0.35, then stay within the travel to the limit 4.2;
  bottomed out they would be a stiff force path past the gauges) [chosen 2026-11-18].
  **Fixing** [given 2026-11-20: glue only]: the pad board glued onto its boss, edges
  flush (that locates it; the pins' tips stay on the pads up to ±0.65 mm), with a thin
  layer of slow epoxy, wires soldered and led down the bore first, pressed flat until it
  sets (a glue line changes the pins' compression: keep it thin, 0.1 mm at most); the pin
  board held in its pocket by the pins' force while mated, and by a drop of
  neutral-curing silicone at two corners while apart (it comes off again). Pads: 3.3 V × 2, GND × 3,
  SDA, SCL, INT (the discant's ADCs, open drain, wired), DET. The NAU7802 is polled over
  I2C.
- **Not chosen** [2026-11-15]: blade contacts (a flat tab between two spring leaves,
  e.g. SAMZO 23E3/23E4, Kinghelm KH-A01M/F) wipe themselves, but their leaves press
  along the contact row, so the row would have to run along z to keep friction out of
  the measuring direction, and 6 contacts do not fit the 10.8 mm there; a card-edge
  socket's rigid slot would be the stiff second force path.
- **Why spring pins:** their few newtons act beside the gauges but stay constant (the
  latch fixes the position), so taring removes them; the plates move only micrometres.
  A cable or a rigid connector would be a second, stiff force path.
- **Power switched by plugging:** DET, pulled to ground by the discant's contact board,
  switches the bass's system supply on (ESP32, both halves' 3.3 V). Apart or stored only
  the charger works: the pins carry nothing, the battery is not drained. The nine pins
  are alike, so DET may close before the others: the discant's 3.3 V comes on 3–7 ms
  after DET and is fully on after about 12 ms (Q3's gate on the main board, R14 100k,
  C9 100 nF; `../main_pcb/spec.md` §3), so all pins touch first [chosen 2026-11-15].
- **Charging and data:** one USB-C in the bass's +x side wall, free both stored and
  played, with a charge LED and the earphone jack beside it; the charger has a power
  path, so it also runs the system while charging. Firmware goes in by this socket.

Checked (2026-11-15, the spring-pin boards): the block clears the discant's outer
holders, plates and pad board when mated, the pins 0.02 mm off the pads in the model
(control: the pad board 0.1 mm closer overlaps); the pin board sits in its pocket
(control: 0.2 mm larger overlaps); the stored discant's contact boss fits the deck's
pocket; the boards clear case, battery, back cover and covers.

Open: the latch tongue's root strain is 1.1–1.3 % [estimate, `../strain_gauge/spec.md`],
fine for PETG, too much for PLA. The wires are listed under Wiring.

## Wiring [chosen 2026-11-15: loose stranded wire, no FFC; the halves meet only at the spring pins]

Every run is loose wire, bundled and lightly twisted, soldered to pads except at the bass
Hall board's J1 (JST SH, 1.0 mm, 5 pins: INT, 3V3, SDA, SCL, GND). Model lengths are
echoed by `../bass/elec.scad` (`wires()`, `path_len()`) and `../discant/gauge_link.scad`
(`contact_pts()`, `lead_pts()`), so they follow the geometry. Cut length = model length
+ 20 mm per end (stripping, strain relief), rounded up to 10 mm.

| # | Half | From → to | Wires | Ends | Model | Cut |
|---|---|---|---|---|---|---|
| 1 | discant | — (gone 2026-11-15 with the link board) | | | | |
| 2 | discant | pad board's back pads → down the boss, through the channel at x = 0 → Hall board's J1, up through its pads | 5: 3V3, GND, SDA, SCL, INT (DET tied to GND on the pad board) | pads / pads | 28 mm | 70 mm |
| 3 | discant | gauge plates → along the pad's groove, through the channels at x = ∓12 → Hall board's J2 / J3 (NAU7802) | 2 half bridges, 3 each | pads / pads | 19 mm each | 60 mm each |
| 4 | bass | spring-pin board's back pads → main board's pads, out of the mount's cavity and bore, along the bottom | 9: 3V3 × 2, GND × 3, SDA, SCL, INT, DET | pads / pads | 94 mm | 140 mm |
| 5 | bass | bass Hall board J1 → down its shaft, over the strap bar's block, beside the battery → joins #4 → main board's pads | 5: 3V3, GND, SDA, SCL, INT | SH plug / pads | 279 mm (82 shared with #4) | 320 mm |
| 6 | bass | battery → main board (+ through the PTC, −, NTC to TS) | 3; 4 with a 2-wire cell and a taped-on NTC (its two wires to P17 TS and P16 GND, twisted) | the cell's leads / pads | about 50 mm [estimate, not modelled] | the cell's own leads, cut to fit |
| 7 | bass | earphone jack's lugs → P19–P21 | 3: tip, ring, sleeve | lugs / pads | about 15 mm [estimate: the jack lies over the board] | 50 mm |

- **Wire** [chosen]: AWG 30 stranded (7 × 0.1), PTFE thin wall, outside ⌀ ≤ 0.55 mm
  [unverified: the supplier's figure]. Five such wires bundle to about ⌀1.4 (2.70 d), nine
  to about ⌀2.0 (3.61 d) [circle packing], inside the modelled bundles (⌀1.8 for five,
  ⌀2.0 for nine) and the ⌀2.6 / ⌀3 bores and shafts. Silicone wire of the same gauge
  (⌀0.8–0.9) would make the five-wire bundles ⌀2.2–2.4: too thick for the ⌀1.8 ways.
- **One gauge, AWG 30** [chosen 2026-11-15]: AWG 32 would be thinner (conductor ⌀0.20
  instead of 0.26 mm, 0.032 instead of 0.051 mm², about 0.54 instead of 0.34 Ω/m, PTFE
  ⌀≈0.45 instead of 0.55) but breaks more easily at the joints and is harder to strip;
  electrically both would do. Run #2 fits AWG 30: the boss's bore is ⌀2.2, the pad's
  groove 1.5 deep × 3.2 high (`contact_bore`, `groove_d`, `groove_h`), the bundle is
  modelled ⌀1.4 (`contact_wire_d`). The groove carries each gauge's three leads only from
  the plate to its channel, apart from run #2, which goes straight through the channel
  at x = 0; the channels are 3 mm wide, about 1.9 high.
- **J1 plug (bass):** JST SHR-05V-S housing with SSH-003T-P0.2-H crimps (AWG 32–28
  [datasheet]); crimping needs the JST tool, so pre-crimped SH cables (5 pins, plug at
  one end or both, cut) are simpler. Their wire is often PVC AWG 28 (⌀≈0.8): cut the
  pigtail back to about 15 mm behind the plug and splice to the PTFE wire under heat
  shrink, so only the splice is thick (#5: in the deck's tunnel
  [unverified: room for a ⌀2.5 splice there]).
- **Discant key board:** runs #2 and #3 come up from under the board through plated
  holes (J1 bus, J2/J3 gauges) and are soldered on the top after the board is screwed
  in; the cover has a recess over the joints.
- **Colours** [chosen]: 3V3 red, GND black, SDA blue, SCL yellow, INT white, DET green;
  the contacts' second 3V3 and the extra GNDs the same colours.
- **Electrically:** I²C at 400 kHz over at most about 0.4 m per bus (bus 1: #2 + #4,
  about 0.13 m; bus 2: #5) with 2k2 pull-ups is well inside the 400 pF limit; 3V3 at about
  150 mA per half drops about 10 mV over 0.3 m of AWG 30 (0.34 Ω/m) [estimate]. No
  shielding, no twisted pairs needed.

**Order list** [estimate: quantities with spare]: AWG 30 PTFE stranded, 2 m each of red,
black, blue, yellow, white, 1 m green; 1 pre-crimped JST SH 5-pin cable (or SHR-05V-S + SSH-003T-P0.2-H
and the crimp tool); heat shrink ⌀1.5 and ⌀3 (2:1).
