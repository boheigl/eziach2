# Discant and bass together

`assembly.scad` puts the discant into the bass's frame with `../bass/link.scad`'s
`to_bass()`: the discant turned 180° about z, so that the gauges' plates sit in the
discant's outer holders and the bass's inner holders, pointing along the bass's y and
sensing along its z [given]. The bass on top; the discant behind it and below, its
gauge pad facing the bass's hand plate.

`make` builds the discant and the bass first, then the discant's parts moved
(`../build/assembly/d_*.stl`), light keys for all 64 (stem, felt, cap; the full
buttons are on the two sides' own pages), and the phone page `phone.html`.

Checked by solid intersection (`../bass/spec.md` §4): the whole discant, mated,
touches none of the bass's parts.

## Stored [given: plugged like the old hinge's two positions; the bass covers the discant's keys]

The earlier design folded the two halves on hinges (../../pcb/README.md, eziach.png);
here the gauge plates are the plug and the bass has two sockets:

- **Playing:** the plates slide along the bass's y into the inner holders at the bottom
  of its back wall (as before).
- **Stored:** the discant turns 90° about x, its keys toward the box's thin back wall,
  and back by its own slope (rows climb 3 per 16: atan(3/16) = 10.62°) [given: use the
  slope], so that caps and housing lie parallel to the wall, 1 mm off it, 27.8 mm thick
  instead of 37.6. Its plates lie in the same slope plane [given: gauges in the slope's
  plane], so they point straight up the bass's z: the discant slides straight up until
  they sit 6 mm deep in a short socket in a pocket in the deck's underside [given: short
  socket]. The box, 265 wide at the bottom [given: widen it] and slanting in above, parallel to the discant's stepped ends [given], covers all 46 keys, 5 mm beyond the caps; the
  deck lies over the discant's back, the playing mount under its front edge.

With the gauges in the slope plane, the playing position too has the discant's slope
plane level (the plates still along the bass's y): the discant hangs 3.3 mm below the
bass's bottom instead of 16.6.

Below the stored discant's front edge (the cover's, 1.2 mm under it the thumb bar where it is cut back over the playing mount; discant/spec.md §3.2) stays 9.6 mm (the socket's 8.3 mm, 1 mm and 0.3 mm) above the playing holders' tops, the travel to slide it on and off; for that the box is 7.6 mm longer than the hand plate [given: +3 mm, then the latch's 2.3, then the holders' thicker walls 2.3]. The bass's box below the deck is 11.2 thin [given: 4.8 thinner,
with a 6 mm battery], so the stored discant lies 4.8 closer; the deck's back face
(27.8) is then the package's back. Checked:
clear of case, back cover, battery, wires and the bass's keys both seated and 9.6 mm lower; 2.7 mm of deck
stay under the back row's springs. Package **282.9 × 40.3 × 151.8 mm (1.7 L)**.
`../bass/link.scad`: `to_store()`, `store_socket()`, `store_pocket()`; the page's Stored
switch shows it.

## Latches [given: in both positions]

Both are in the inner holders (`../strain_gauge/inner_holder.scad`): a spring tongue in
each holder's top wall either side, its tooth in the plate's inner slot between web and
column, behind the slot's closed end. Sliding on, the tooth rides over the W's bottom
block and drops into the slot. It touches only the W, never the column or the fixed
arms, so the force still runs through the gauges' columns.

- **Playing** (mount on the box's back wall): square tooth, a positive lock that holds
  the strap's pull. To take the bass off, lift the lug on each tongue's tip (four in
  all, from above, between box and discant) and slide.
- **Stored** (socket under the deck): 45° tooth, a detent; four of them hold about 9 N
  [estimate: tongue 3 × 1 × 11 mm, PLA, E 3500 MPa, 0.6 mm deflection, friction 0.3]
  against the discant's weight (about 3.5 N [estimate]); a firm pull down releases it.

Checked: seated, teeth and plates clear; moved 0.3 mm in the pull-off direction, the
teeth of both positions meet the slots' ends.

## Electronics split, contacts and power [given: power and I2C cross by contacts that close as the bass slides on; plugging for playing switches the system on; the bass charges by its own USB socket, also stored; the electronics moved from the discant to the bass]

- **Bass** (`../bass/elec.scad`): everything that is not key reading: the ESP32-S3, the
  audio DAC and the earphone jack, one USB-C (charging, firmware, MIDI), the battery
  with charger (the cell's own protection board, a fuse on the main board), the 3.3 V
  supply for both halves (`../main_pcb/spec.md`).
- **Key boards** (`../hall_pcb/`): one Hall-sensor board per half, read by ADS7138 ADCs
  on I²C, no controller. Two buses, 5 wires each (3.3 V, GND, SDA, SCL, INT): the
  discant's (ADCs 10h…15h, with the NAU7802) through the contacts, the bass's (10h…12h,
  with the DAC) inside the bass box. [superseded: a PCAL9555A expander on each of six
  switch boards, one bus]
- **Discant:** only the key boards and the link board with the NAU7802 at the gauges.
- **Contacts:** nine spring pins, 3 × 3 at 2.54 mm, in a block on the bass's playing mount
  between the inner holders (`../bass/link.scad`), reaching between the discant's outer
  holders (5.8 mm clear either side of the middle); against them a small board with
  nine gold pads on a boss on the discant's pad (`../discant/gauge_link.scad`). They
  meet head on as the bass slides on, 1 mm compression when latched [unverified: pin
  type, e.g. Mill-Max 0906]. Pads: 3.3 V × 2, GND × 3, SDA, SCL, INT (the discant's
  expanders, open drain, wired), DET. The NAU7802 is polled over I2C.
- **Why spring pins:** their few newtons act beside the gauges but stay constant (the
  latch fixes the position), so taring removes them; the plates move only micrometres.
  A cable or a rigid connector would be a second, stiff force path.
- **Power switched by plugging:** DET, pulled to ground by the discant's contact board,
  switches the bass's system supply on (ESP32, both halves' 3.3 V). Apart or stored only
  the charger works: the pins carry nothing, the battery is not drained. DET's pin is
  the shortest, so it closes last and opens first.
- **Charging and data:** one USB-C in the bass's +x side wall, free both stored and
  played, with a charge LED and the earphone jack beside it; the charger has a power
  path, so it also runs the system while charging. Firmware goes in by this socket.

Checked: the block clears the discant's outer holders, plates and contact board when
mated (pins 0.02 mm off the pads in the model), the stored discant's contact boss fits
the deck's pocket, the boards clear case, battery, back cover and covers.

Open: the tongue's strain on bending is about 0.7 % [estimate], fine for PETG, at the
limit for PLA; the parts' choice. The wires are listed under Wiring.

## Wiring [chosen 2026-11-15: loose stranded wire, no FFC; the halves meet only at the spring pins]

Every run is loose wire, bundled and lightly twisted, soldered to pads except at the two
Hall boards' J1 (JST SH, 1.0 mm, 5 pins: INT, 3V3, SDA, SCL, GND). Model lengths are
echoed by `../bass/elec.scad` (`wires()`, `path_len()`) and `../discant/gauge_link.scad`
(`bundle_pts()`, `contact_pts()`), so they follow the geometry. Cut length = model length
+ 20 mm per end (stripping, strain relief), rounded up to 10 mm.

| # | Half | From → to | Wires | Ends | Model | Cut |
|---|---|---|---|---|---|---|
| 1 | discant | Hall board J1 → link board's −x end | 5: 3V3, GND, SDA, SCL, INT | SH plug / pads | 10 mm | 50 mm |
| 2 | discant | contact board → link board's +x end, down the boss, along the pad's groove | 5: 3V3, GND, SDA, SCL, INT (DET tied to GND on the contact board) | pads / pads | 78 mm | 120 mm |
| 3 | discant | gauge plates → link board (NAU7802), along the pad's groove | 2 half bridges, 3 each | pads / pads | 26 mm (near), 76 mm (far) to the pocket [estimate: plate middle to the pocket's +x end] | 70, 120 mm |
| 4 | bass | spring-pin block → main board's pads, out of the mount's bore, along the bottom | 9: 3V3 × 2, GND × 3, SDA, SCL, INT, DET | pin tails / pads | 94 mm | 140 mm |
| 5 | bass | bass Hall board J1 → down its shaft, over the strap bar's block, beside the battery → joins #4 → main board's pads | 5: 3V3, GND, SDA, SCL, INT | SH plug / pads | 279 mm (82 shared with #4) | 320 mm |
| 6 | bass | battery → main board (+ through the PTC, −) | 2 | the cell's leads / pads | about 50 mm [estimate, not modelled] | the cell's own leads, cut to fit |
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
  modelled ⌀1.4 (`contact_wire_d`). From the near gauge to the pocket the groove carries
  run #2 and both gauges' leads, 11 wires, about 3.2 mm² packed in 4.8 mm², two thirds
  full [estimate]: the gauges' leads should be no thicker than AWG 30 [open: the
  gauges' leads].
- **J1 plugs:** JST SHR-05V-S housing with SSH-003T-P0.2-H crimps (AWG 32–28
  [datasheet]); crimping needs the JST tool, so pre-crimped SH cables (5 pins, plug at
  one end or both, cut) are simpler. Their wire is often PVC AWG 28 (⌀≈0.8): cut the
  pigtail back to about 15 mm behind the plug and splice to the PTFE wire under heat
  shrink, so only the splice is thick (#1: within the pocket; #5: in the deck's tunnel
  [unverified: room for a ⌀2.5 splice there]).
- **Colours** [chosen]: 3V3 red, GND black, SDA blue, SCL yellow, INT white, DET green;
  the contacts' second 3V3 and the extra GNDs the same colours.
- **Electrically:** I²C at 400 kHz over at most about 0.4 m per bus (bus 1: #1 + #2 + #4,
  about 0.2 m; bus 2: #5) with 2k2 pull-ups is well inside the 400 pF limit; 3V3 at about
  150 mA per half drops about 10 mV over 0.3 m of AWG 30 (0.34 Ω/m) [estimate]. No
  shielding, no twisted pairs needed.

**Order list** [estimate: quantities with spare]: AWG 30 PTFE stranded, 2 m each of red,
black, blue, yellow, white, 1 m green; 2 pre-crimped JST SH 5-pin cables (or SHR-05V-S + SSH-003T-P0.2-H
and the crimp tool); heat shrink ⌀1.5 and ⌀3 (2:1).
