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

The discant's button unchanged (`../switch/button.scad`): cap ⌀15, felt ring, stem ⌀7.6,
two washers on the board's copper rings, spacer sleeve, M3 screw, spring in a guide.
Closed at rest. The felt lands on the 1.2 mm cover after 2.965 mm.

## 3. Case, cover, boards (`case.scad`, `cover.scad`)

- **Boards:** the discant's board sawn to 9 holes (`../switch/pcb.scad`, `cut_holes = 4`),
  one per row: front board moved x + 40, back board x + 50, y + 16. The back row stands
  **10 mm higher**, so that its caps reach the example's 21 mm with the standard button:
  board tops at z = 3.835 and 13.835. Neighbouring boards stand 1.3 mm apart in plan.
- **Case** [given: nicer and closed]: a closed box, one print, open only at the back
  (behind the battery and boards), which the back cover closes; the bottom is closed.
  On top the key deck, its full depth (y −12.5 … 27.8). Below it the box is **11.2 mm thin**
  [given: thinner; then 4.8 thinner still, so that the stored discant comes closer]
  (y −12.5 … −1.3): front wall 3, back wall 1.6, a 6 mm battery between, so that under the deck, behind the box, a step opens
  where the gauges sit [given: integrated]. At the bottom its sides are
  **265 mm** apart [given: widened so that the box covers the stored discant's keys;
  replaces the earlier taper towards the −z end]; from z −90.7 up they slant in, parallel
  to the stored discant's stepped ends [given], 10 in x per 16.28 (31.6°), 5 mm off the
  rows' end caps, to 172.1 mm under the deck, which stands out over them. It reaches 5.3 mm below the hand plate (z −128.5) [given: room for the
  stored discant's travel, then for the socket's latch]. Vertical edges rounded (r 4); the cover follows them. The
  front wall is 3 mm thick; the hand plate is a 1 mm recess in it with rounded corners
  (r 6); the front caps keep 2 mm from its inner face [given: ≥ 2 mm].
- **Stiffness** [given: the plate must not bend; very important]: the hand bends the
  front wall locally, between its edges, as the cavity is empty; the box section does
  not help there. (Corrected: the earlier 0.05 mm took the box as a beam and missed that;
  a plain 3 mm wall between clamped edges gives about 0.5 mm at 50 N mid-plate.) So the
  front wall carries **ribs** inside, 1.6 thick, across the cavity to 0.2 short of the
  back cover: upright at x −90, −50.75, 47.25, 90 (beside the battery and outside), across
  over the battery (z −56.5), at z −36 right of the key board, at z −90 and −110 left of
  the battery and at z −88 over the power board; notches leave the wires' way along the
  bottom and up left of the battery. The largest field left is over the battery, 91 × 62
  mm: about **0.15 mm** at 50 N there, less elsewhere and under a palm [estimate: clamped
  plate, point load, PLA, E = 3500 MPa]. The front wall stays one piece with sides, bottom
  and deck [given: the cover on the side away from the hand, for stiffness].
- **Deck:** the discant's housing for two rows, each board resting on it 0.1 above its
  underside, a guide for every key (⌀9.4, ⌀8.6 spring pocket, floor 1.5 under it,
  z = −15.1), M2 pilots for the cover's screws; the back block begins at y = 11, behind the
  cover's wall up the step. Both boards' FFC connectors stand partly over the step: their
  pockets have a 1.5 mm floor, and a tunnel inside the deck (18 × 3.5 mm) leads each cable
  forward, along the front wall inwards to x −75.8 (above the slanted side the box is
  narrower than the deck) and down into the box; the FFC folds at each turn.
- **Stored discant** (../assembly/spec.md): a pocket in the deck's underside takes the
  stored discant's gauge ends (x −46.4 … 42.9, y 13.1 … 24.7, up to z −6.4), with a
  short socket (the inner holder's last 8.3 mm and its bridge, with the latch as a
  detent) for each plate, printed with the case; 2.7 mm of deck stays under the back row's springs over it.
- **Back cover** [given: inside, on the side away from the hand]: the back wall from
  z −116 up to the deck, with the side walls' last 1.6 mm, one 1.6 mm plate following the
  box's outline. Two tongues at its bottom edge hook in behind the mount's strip (which
  stays with the case: the gauges' and contacts' load never passes the cover); three M2
  pan-head screws at z −21 (x −45, 0, 45), above the stored discant's caps, into pillars
  from the front wall. It rests on the side walls' ends, the ribs and the pillars.
  Assembly with it off: battery, both boards (screwed from the back into the front
  wall's pilots; the power board goes in 2 mm to the left and slides right into the
  port), the FFCs from the deck and the contacts' wires, all in reach. [unverified: screw
  type]
- **Battery** [given]: a 1S Li-ion pouch, 606090 (6 × 60 × 90 mm, about 4 Ah [unverified:
  type, capacity]) [given: 6 mm, for the thinner box; it was a 9 mm 906090 of about 6 Ah],
  between front wall and back cover, 0.3 clear each side: a shelf under it, stops at its ends, a lip
  over its top.
- **Electronics** (`elec.scad`) [given: charging in the bass by its own USB socket; the
  contacts switch the battery on]: a power board at the bottom on the +x side (USB-C
  in the side wall at z −104.5 with a charge LED beside it, charger with power path,
  protection and fuse, the P-FET switched by DET, a 3.3 V LDO) and a key board at the top
  on the −x side, where the FFCs come down (their two connectors, a 24-input I2C port
  expander: one input per key, no matrix, no diodes). Both lie on the front wall's
  inside on two pads with M2 pilots, outside the hand plate's recess. Wires [not
  modelled]: pins → mount's cavity → back wall bore → below the battery's shelf → power
  board → beside the battery up to the key board. `../assembly/spec.md`, Contacts.
- **Size:** 211.1 × 40.3 mm at the deck; below it 11.2 mm deep and 265 mm wide, 149.5 mm
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
- **Size:** 211.1 × 40.3 mm at the deck (x −107.3 … 103.8, y −12.5 … 27.8, z −128.5 … 15.04);
  beside the plate the deck's front face stands 2 mm behind the plate's.

## 4. Gauges: the bass's inner holders (`link.scad`)

- **Split** [given]: each gauge is three parts: the outer holder, printed with the
  discant's housing; the flexure plate; and the inner holder, printed with the bass.
  Both inner holders stand on one mount (76 × 6 × 10.8 mm, where the discant's link plate
  was) on the back of the hand plate at the bass's −z end, flush with its lower edge and
  centred on it, one print with the case.
- **Orientation** [given: the gauges point along the bass's y and sense along its z]: the
  discant is turned 180° about z, its y pointing back into the bass and its z staying the
  bass's z; the plates stand in the step behind the thin box; the gauges reach 11 mm past the
  deck's back line, which a thinner battery would shorten.
- **Joining:** the bass goes on by sliding its inner holders onto the plates' W, as the
  holder is meant to, and comes off the same way. [open: what keeps them on; the holder
  only grips the W across z] [unverified: the holder's 0.15 mm fits, printed as part of
  the large case, not standing on its bridge as `../strain_gauge` recommends]
- **Contacts:** nine spring pins in a block on the mount between the inner holders,
  against the discant's contact board; a cavity behind them and a ⌀2.6 bore through
  the back wall take the wires into the box (`link.scad`, `../assembly/spec.md`).
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
| `elec.scad` → `elec.stl` | the power and key boards, the charging port, the contacts' plungers (placeholders) |
| `link.scad` | the gauges' inner holders on their mount, and the discant's side (plates, pins, outer holders: `discant_link.stl`) |
| `cover.scad` → `cover.stl` | the cover, one piece |
| `keys.scad` → `keys.stl` | the 18 keys at rest |
| `array.scad`, `lam.scad` | the boards, their copper and connectors |
| `phone.html` → `../build/bass/phone.html` | the assembly in 3D, made by `make` |
| `ref/` | the example case, for measuring |
