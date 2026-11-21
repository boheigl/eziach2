# Bass — specification

The bass (left-hand) side of the accordion: 2 × 9 keys with the discant's key
mechanism. Markers as in `../discant/spec.md`: **[given]** stated by the user,
**[chosen]** a decision made here, **[unverified]** not checked against a part or a test.

## 1. Taken from the example [given: only these]

The earlier case, `../../shape/OrderOnShape20260107/BassCase - Part BassCase.step`
(converted to `ref/bass_case_example.stl` by `ref/convert.py`, for measuring only):

- **Key arrangement:** two staggered rows, 20 mm pitch, the back row 16 mm behind and
  10 mm to the side; caps 11 mm high in front, 21 mm at the back. Front row x = −80 … 80
  at y = 0, back row x = −70 … 90 at y = 16. The example has 8 per row; **2 × 9**
  [given]: the front row's 9th sits where the example has a half-closed well (x = −80),
  the back row's at x = 90 [chosen].
- **Hand plate:** the flat middle part of the plate the hand presses against, 263 × 171 mm
  in the example, here **half as wide and 25 % lower** [given]: **131.5 × 128.3 mm**, 2 mm
  thick, centred on the deck (x −67.5 … 64.0, the hand on y = −12.5; z −123.2 up to the
  front cover's top, 5.04). Strap ears, hinge tube, key wells and the
  example's other features are not taken over.

## 2. Keys [given: the discant's mechanism]

The discant's Hall key (`../switch_hall/`, `key.scad` and spec): a ground stainless rod
⌀3 in a sintered bronze bushing in the cover's tube, the cap on top, a printed collar
with the magnet (⌀3 × 1.5 N52) below, a stock stainless spring (Misumi C-UY8-25) round
the tube, an O-ring as the bottom stop and a punched washer as the rest stop; the
board's DRV5055 senses the magnet on the key's axis. The board lies flat under both
rows, and the back row stands 10 mm higher on a 10 mm longer rod (dowel pin 3 × 24 instead of 3 × 14);
spring, stops and field are the same in both rows (`bass0_*`, `bass1_*`). Parts for all
keys: `../BOM.md`.

## 3. Case, cover, boards (`case.scad`, `cover.scad`)

- **Board** [given 2026-11-13]: one Hall-sensor board under both rows (`../hall_pcb/bass/`,
  its data from the routed KiCad board), lying flat. The back row's keys stand **10 mm
  higher** on the same board (`key.scad` `riser`), so that their caps reach the example's
  21 mm. Its bus connector J1 hangs in front of the front row, over the box: the plug
  comes from below and the wires drop straight into the box.
- **Case** [given: nicer and closed]: a closed box, one print, open only at the back
  (behind the battery and boards), which the back cover closes; the bottom is closed.
  On top the key deck, its full depth (y −12.5 … 27.8). Below it the box is **11.2 mm thin**
  [given: thinner; then 4.8 thinner still, so that the stored discant comes closer]
  (y −12.5 … −1.3): front wall 3, back wall 1.6, a 6 mm battery between, so that under the deck, behind the box, a step opens
  where the gauges sit [given: integrated]. Its sides are
  straight and flush with the deck's ends: deck and box are **one rectangular block,
  211 mm wide** [given 2026-11-14: a rectangular footprint, replacing the sides that
  slanted in along the stored discant's ends], set by the strap's slots. It reaches 9.8 mm below the hand plate (z −141.0) [given: room for the stored discant's travel, then for the socket's latch, then for the inner holders' thicker walls; then 2.1 mm for the latches' lugs and rod, 2026-11-15]. Vertical edges rounded (r 4); the cover follows them. The
  front wall is 3 mm thick; the hand plate is its flat face [given 2026-11-15: no
  recess; it was 1 mm deep with rounded corners (r 6)]; the front caps keep 2 mm from
  the wall's inner face [given: ≥ 2 mm].
- **Stiffness** [given: the plate must not bend; very important]: the hand bends the
  front wall locally, between its edges, as the cavity is empty; the box section does
  not help there. (Corrected: the earlier 0.05 mm took the box as a beam and missed that;
  a plain 3 mm wall between clamped edges gives about 0.5 mm at 50 N mid-plate.) So the
  front wall carries **ribs** inside, 1.6 thick, across the cavity to 0.2 short of the
  back cover: upright at 83 mm either side of the middle (x −84.75, 81.25) and beside the battery
  (x −50.75, 47.25), across
  over the battery (z −56.5), at z −36 right of the key board, at z −90 and −110 left of
  the battery and at z −88 over the power board; notches leave the wires' way along the
  bottom and up left of the battery. The largest field left is over the battery, 91 × 62
  mm: about **0.15 mm** at 50 N there, less elsewhere and under a palm [estimate: clamped
  plate, point load, PLA, E = 3500 MPa]. The front wall stays one piece with sides, bottom
  and deck [given: the cover on the side away from the hand, for stiffness].
- **Hand strap** [given: the heel of the hand presses about 11 cm below the bass keys;
  the strap at least 40 mm wide]: a strap across the back of the hand, level with its
  middle (z −67; the heel at about z −105, the knuckles just below the deck). Each end
  goes through a pair of upright slots in the front wall, as far out as the front face
  allows over their height (4 × 42 mm, inner edges 87 mm from the middle, the outer slot
  ending 100 mm out, 1.5 mm inside the face's rounded edge where the box is narrowest; a
  5 mm bar between) [given: further out, so the hand slides far enough along the rows]: in through the
  inner one, round the bar inside the box, out through the outer one, folded back and
  buckled [assumed: 40 × 2–3 mm leather, buckle on the strap]. It lies flat on the front
  face, untwisted (slots and strap stand upright), adds nothing to the package, and is
  threaded with the back cover off; about 174 mm between the inner slots (the hand plate
  is 131.5 wide), so the hand can slide along the rows. The bar is the front wall between the slots and a block behind
  it, 5 × 6.5 mm; a 100 N pull on each end puts 200 N round it: about 30 MPa [estimate,
  PETG]. The outer upright ribs stand at 83 mm from the middle, inside the slots; the back
  cover's tongues sit between the ribs. (Bars on the slanted side
  walls, tried first, would have twisted a level strap by 31.6° and took only 25 mm.)
  `strap.stl` shows it on the page.
- **Strength under a strong push** [given: statically stable] (estimates, 100 N; PLA/PETG
  about 50 MPa; not FEA): the push's moment at the gauges is F × 64 mm (plate's middle)
  to F × 125 mm (its top). It reaches them through the mount at the box's bottom. A thin
  floor and back wall would carry it in bending (about 100 MPa), so behind the mount the
  box is a solid **foot** from the battery's shelf down to 2.65 mm above the floor (x
  −51.6 … 48.1), joined to front and back wall, with the wires' slot under it; the ribs
  reach the back wall in the mount's strip. The moment goes into the walls as tension
  and compression: a few MPa. The inner holders' walls are 4.5 mm [given: thicker], their
  bending stress about 44 % of before (15–25 MPa). Hand plate about 8 MPa at 200 N under a
  palm. The gauge plates: 100 N is 0.9–1.8 × the bought cells' rated moment (2 × 3430 N·mm), up
  to 1.2 × their 150 %, more on one cell off centre; **overload stops** beside the mount
  take what passes a set force (`../assembly/spec.md`, Overload stops).
- **Deck** [given 2026-11-13: one Hall-sensor board, the cases as small as possible]: a
  thin tray round the flat board, as the discant's (`../discant/spec.md` §2): a rim up to
  the board's top, a floor 0.3 under the parts, a ledge along the board's edge and a boss
  at each screw hole under it, M2 pilots for the cover's screws. The keys stand entirely
  above the board, in the cover (`cover.scad`). J1 and its plug go straight down through
  the tray's floor into the box. The front wall ends at the board's top; the cover
  reaches over it to the hand's face, flush with the hand plate's top.
- **Stored discant** (../assembly/spec.md): a pocket in the deck's underside takes the
  stored discant's gauge ends (x −46.4 … 42.9, y 13.1 … 24.7, up to z −5.2), with a
  short socket (the inner holder's last 8.3 mm and its bridge, with the latch as a
  detent) for each plate, printed with the case; 1.5 mm of deck stays under the back
  row's springs over it. [given: higher, thumb bar flatter in the middle] The stored
  discant sits 1.2 mm higher than before the thumb bar (link.scad `front_d`): as high as
  the socket can rise, 0.4 under the back row's middle guide floors (z −3.6).
- **Back cover** [given: inside, on the side away from the hand]: the back wall from
  z −116 up to the deck, with the side walls' last 1.6 mm, one 1.6 mm plate following the
  box's outline. Two tongues at its bottom edge hook in behind the mount's strip (which
  stays with the case: the gauges' and contacts' load never passes the cover): 24 mm
  wide left of the battery, 7 mm wide and 3.2 thick (2 mm more, inwards [given
  2026-11-15]) between the battery's rib and the main board
  [given 2026-11-15: over the board it sat 0.6 mm above the ESP32 module, and tilting
  the cover to hook it in swung it onto the module beyond about 9°]. Checked: both
  tongues swing clear of board, wires and battery up to 20° of tilt; three M2 × 6
  countersunk screws (DIN 965, modelled: `cover_screws.stl`) at z −21 (x −45, 0, 45),
  above the stored discant's caps, flush in 90° countersinks (⌀4.0, 0.9 deep, 0.7 of the
  plate left under them), 4.4 mm into ⌀1.7 pilots in pillars from the front wall. It rests on the side walls' ends, the ribs and the pillars.
  Assembly with it off: battery, the main board (screwed from the back into the front
  wall's pilots; it goes in 2 mm to the left and slides right into the
  port), the key board's bus wires from J1 and the contacts' wires, all in reach. Screws
  [chosen 2026-11-15]: main board 3 × M2 × 3 pan head (ISO 7045, A2): through board
  (1.0) and pad (0.47), 2.0 mm into the 2 mm pilots in the 3 mm front wall, 1 mm left to
  the hand's face; the key board 12 × M2 × 6 countersunk brass (DIN 965), 1.9 mm into
  the case as on the discant.
- **Battery** [given: 6 mm, for the thinner box; it was a 9 mm 906090 of about 6 Ah]: a
  1S LiPo pouch 606090 of 4000 mAh with its protection board (PCM) and a 10k NTC, three
  wires (e.g. DNK606090 [datasheet]; 3-wire variants with JST-PH are sold). With the PCM it
  is 92 × 60 × 6.0 (some list 92.5); the cradle takes 93 [chosen 2026-11-15; was 90].
  Between front wall and back cover, 0.3 clear each side: a shelf under it, stops at its
  ends, a lip over its top. Clear of case, board, wires, back cover and screws (the
  control, a 93 mm cell in the old 90 mm cradle, overlapped by 255 mm³). Not modelled:
  where the leads leave the PCM.
  - **Variant: a 2-wire cell with a taped-on NTC** [chosen 2026-11-15]: a 10k NTC
    (B 3435) on the cell's top edge, 3–5 mm from the end away from the PCM. That is the
    only place with room: the broad faces have 0.3 to front wall and back cover, the
    middle of the top edge has the lip 0.3 over it, but the last 10 mm at either end
    are clear of the lip, about 2.9 mm up to the rib over the battery, 6.6 wide.
    Wires (AWG 30, joints in heat-shrink, twisted) extended first, then the NTC laid
    flat and held by Kapton tape, the wires taped to the cell as strain relief; no glue
    or solder on the pouch. Its two wires run with the cell's to the main board (P17,
    P16).
- **Electronics** (`elec.scad`) [given: charging in the bass by its own USB socket; the
  contacts switch the system on; the electronics moved from the discant to the bass]:
  - **Main board**, 45.5 × 33 mm at the bottom on the +x side, between the outer rib and
    the side wall, under the strap's bar: the ESP32-S3-WROOM-1 (antenna at the board's
    bottom edge, away from the battery), the DAC TLV320DAC3100, the charger BQ24074
    with power path and a fuse (the cell brings its own protection), the system switch
    (DET) and the 3.3 V supply (TPS63001) for both halves; four layers, parts on the
    side towards the back cover (`../main_pcb/`, whose `board.scad` this file reads).
    In the side wall: USB-C (z −104.5; charging, firmware, MIDI; the board's tab under
    the socket in a 0.95 mm pocket of the wall; outside, a 0.2 mm recess round the port (12.85 × 7.0, for the USB Type-C spec's largest overmold, 12.35 × 6.5) so a plug's overmold reaches the socket's face [given 2026-11-20: 0 mm], leaving 0.85 mm of wall over the pocket; see
    `../main_pcb/spec.md`), the charge light (red charging or battery low, green full) and
    the earphone jack [given 2026-11-15: a panel jack in the case, a bulge in the back
    cover allowed]: Switchcraft 35PRM3, from inside through the side wall (⌀6.2, the
    wall 1.5 at a ⌀10.5 counterbore for its knurled nut), its body over the main board
    and wired to it. 1.0 mm over the board. The back cover bulges 5.7 mm round it (⌀13.3 about the jack's axis,
    from the side wall 24 mm inwards); the bulge is the cover's, down past z_split,
    but the side wall round the hole stays the case's, so the cover comes off with
    the jack in place. Checked: clear of case, cover, board, battery and wires, and
    of the discant both played and stored (stored, it stays 10 mm above the bulge).
  - **No key electronics in the box:** the bass's Hall-sensor board reads its own keys
    (`../hall_pcb/bass/`); only its bus comes down, from J1 (JST SH, the plug from below)
    straight into the box to the main board.
  The main board lies on the front wall's inside on three pads with M2 pilots,
  screwed from the back with the back cover off. Its lowest screw lies below the cover's
  bottom edge, behind the case's strip: the strip's piece in front of it (7 × 7 mm) is
  the cover's, so a screwdriver reaches it [given 2026-11-15: all screws reachable].
  Checked with a 3 mm shaft and a 16 mm handle: all three main board screws, the bass's
  12 and the discant's 27 key board screws are reachable (the keys in place).
- **Wires** (`elec.scad`: `wires()`, `wires.stl`): the nine pins' wires leave the mount's
  cavity through the back wall's ⌀2.6 bore as one bundle and run along the bottom, under
  the battery's shelf, through notches in the ribs, right to the main board. The
  notches are 3 deep at the ribs' back edges, open to the back cover (the wires go in
  from there), so 3.4 mm of every rib stays whole along the front wall [given
  2026-11-15: the wires' way cut the ribs through, the cross ribs beside the battery
  and the upright ribs at the floor]; at a notch the rib with its share of the front
  wall would keep about 40 % of its bending stiffness, cut through it kept 16 %; so at
  each notch the rib is 6 mm thick instead of 1.6, 3 mm beyond the notch on either side
  [given 2026-11-15], and keeps about 84 % [estimated: T-section, 20 mm of wall]. The bundles run 1.2 mm under the back cover (`wire_y`). The two
  bass boards' bus wires (3.3 V, GND, SDA, SCL, INT) go down their shafts into the deck's
  tunnel, forward, down its drop, along the box's top over the left strap bar's block,
  down beside the battery (x −55.5) and join the first bundle at the bottom. Checked:
  clear of case, back cover, battery, boards and electronics. Lengths, wire and plugs: the Wiring section of `../assembly/spec.md`
  (runs #4 to #7).
- **Size:** 211.1 × 40.3 mm at the deck; below it 11.2 mm deep and 265 mm wide, 151.8 mm
  high in all; the gauges' mount and holders stand in the step (y −1.3 … 25.9).
- **Cover: one piece** [given]: a slab on each board, the board in a pocket underneath
  (0.3 round it), a ⌀8 opening over each key (the stem's second guide). The front slab
  runs from the hand plate to y = 11; a 1.2 mm wall rises up the step, its face at y = 9.8,
  2.3 mm from the front caps [given: ≥ 2 mm], and carries the back slab, which runs to the
  back face (y = 27.8, 0.9 of wall behind the back board's tab). The front board's
  connector tab lies in the front slab's pocket. Three M2 countersunk screws per board,
  through cover and board into the case.
- **Length in x: as short as the boards allow** [given]: their ends (the front board's
  connector end, the back board's saw cut), 0.3 fit and a 1.2 end wall, x = −107.3 … 103.8.
  The keys alone would need less: the boards reach 25.8 beyond their first hole for the
  connector.
- **Size:** 211.1 × 40.3 mm at the deck (x −107.3 … 103.8, y −12.5 … 27.8, z −130.8 … 15.04);
  beside the plate the deck's front face stands 2 mm behind the plate's.

## 4. Gauges: the bass's inner holders (`link.scad`)

- **Split** [given]: each gauge is three parts: the outer holder, printed with the
  discant's housing; the flexure plate; and the inner holder, printed with the bass.
  Both inner holders stand on one mount (76 × 6 × 10.8 mm, where the discant's link plate
  was) on the back of the hand plate at the bass's −z end, flush with its lower edge and
  centred on it, one print with the case. Beside it, outboard of each inner holder, a
  block with the overload stop's slot reaches forward round the discant's tongue
  (`../assembly/spec.md`, Overload stops).
- **Orientation** [given: the gauges point along the bass's y and sense along its z]: the
  discant is turned 180° about z, its y pointing back into the bass and its z staying the
  bass's z; the plates stand in the step behind the thin box; the gauges reach 11 mm past the
  deck's back line, which a thinner battery would shorten.
- **Joining:** the bass goes on by sliding its inner holders onto the plates' W, as the
  holder is meant to, and comes off the same way. Latches keep them on: locked for playing, released by
  one steel rod through all four lugs; a detent when stored (`../assembly/spec.md`,
  Latches). Printed with the bass standing on its hand face [given 2026-11-15], so the
  holders stand on their bridges as `../strain_gauge` recommends. [unverified: the
  holder's fits, printed as part of the large case]
- **Contacts** [chosen 2026-11-15]: the pin half of `../contact_pcb/` (three strips of
  three spring pins) in a pocket of a block on the mount between the inner holders,
  against the discant's pad board. Its nine wires are soldered to its back first and
  threaded through the cavity behind it and the ⌀2.6 bore through the back wall into
  the box; then the board goes into the pocket from the front, where the pins' force
  (about 8.5 N, 0.8 mm pressed) holds it on the ledge round the cavity; a drop of
  neutral-curing silicone at two corners keeps it in while the halves are apart
  [given 2026-11-20: glue only, no detent; review/contact_pcb.md MINOR 5]
  (`link.scad`, `../assembly/spec.md`).
- **Reading** [given: the gauges are bent by the push, which works]: the hand pushes the
  plate along y, above the gauges, so the push bends their flexure plates as a force
  along z would; each bridge reads the moment at its column, push × arm. Pressed at the
  plate's middle the arm is about 56 mm, so the two gauges' full scale (2 × 1400 N·mm,
  `../discant/spec.md` §7) is about 50 N [estimated]. The reading follows where the hand
  presses: about twice at the plate's top, nearly nothing at its lower edge; to calibrate,
  or a defined pressing area. The bass's weight and any force along z add in. Push and
  pull read with opposite sign.

**Checked by solid intersection:** the whole discant, mated, touches none of the bass's
parts; case, cover, boards with connectors and all 18 keys
touch nothing at rest and pressed 2.9 mm.

## 5. Open

- The wires inside the box [not modelled]; the electronics' parts [unverified].

## 6. Files

| File | |
|---|---|
| `layout.scad` | key arrangement, heights, boards, plate: shared by all |
| `case.scad` → `case.stl`, `back_cover.stl`, `battery.stl` | the box: deck, hand plate with its ribs, battery cradle, cable tunnels, the gauges' inner holders and the contacts' block; the back cover; the battery |
| `elec.scad` → `elec.stl` | the power and key boards, the charging port |
| `link.scad` | the gauges' inner holders on their mount with the contacts' block, the latches' rod (`latch_rod.stl`), the spring-pin board (`contact_pins.stl`), and the discant's side (plates, pins, outer holders: `discant_link.stl`) |
| `cover.scad` → `cover.stl` | the cover, one piece |
| `keys.scad` → `keys.stl` | the 18 keys at rest |
| `array.scad`, `lam.scad` | the boards, their copper and connectors |
| `phone.html` → `../build/bass/phone.html` | the assembly in 3D, made by `make` |
| `ref/` | the example case, for measuring |
