# Discant — design record

The discant (treble) side of the accordion: four switch boards as a staircase,
the printed housing under them, the cover over them and the FFCs to the back
outlet. The switch board and its button assembly (the key) are recorded in
`switch/spec.md`; references to its sections read "switch §n".

Numbers are tagged by where they come from: **[given]** stated by the user,
**[datasheet]** taken from a manufacturer's document, **[chosen]** a design
decision made here, **[estimated]** calculated rather than measured,
**[unverified]** still to be confirmed.

`housing.scad`, `cover.scad` and `array.html` copy the board numbers they need
from `switch/pcb.scad` (marked "as in pcb.scad"). **Change a value in both
places.**

---

## 1. Four-board array [given]

Four boards, parallel, as a staircase: board k (k = 0 … 3) is moved by
k × (10, 17, 4) mm. That is half the hole pitch along the row, 17 mm across it
and 4 mm up, so each board rises towards the connector (+Y) side. The z
direction was chosen by the user.

**Board k has 13 − k holes: 13, 12, 11, 10.** [given] It is the same board
with k holes sawn off at the +X end (`pcb.scad`, `cut_holes = k`). The cut
runs 12.3 mm past the last hole kept, at local x = 112.3 / 92.3 / 72.3, 2.3 mm
beyond that board's +x end screw hole and 2.7 mm clear of the first ring
removed. [chosen] With
the 10 mm shift, both ends of the staircase step in by 10 mm per board. The
saw cuts through the common bus on top, which still reaches every remaining
−Y half, and through the −Y-band tracks of the removed holes, which remain as
dead stubs on contacts 8, 9 and 10. Checked on the 10-hole version's exported
copper: holes 1 … 10 on their contacts, contact 1 on all ten −Y halves, no
copper beyond the cut.
**Deburr the cut edge:** the tracks there are only 0.2 mm apart. `array.scad` places the part STLs (boards `pcb.stl`, `pcb_12.stl`,
`pcb_11.stl`, `pcb_10.stl`), and `array.stl` is the same assembly written
directly from them. `array.html`
shows the four boards with their connectors and guide tubes, without the
buttons.

**Clashes: none.** The boards are 16.8 mm wide, so with the 17 mm step
neighbouring boards no longer overlap in plan: board k ends at y = 9.2 and
board k+1 begins at y = 9.4 (board k's frame). Grid sampling at 0.1 mm finds no overlap between
any two boards, with buttons, washers, sleeves, screws, springs and even the
old single guide tubes included. The button caps end 1.1 mm short of the
board above. Board k+1's connector ends 0.4 mm short of board k's edge in plan.

## 2. Housing for the staircase [given]

`housing.scad` → `housing.stl`: **one closed, 3D-printed body** under the four
boards. It is a single solid (CGAL: one volume) and replaces the four single
guide tubes.

- **Steps:** each board rests on its own step; the top of each step is the
  board's underside less 0.1 mm. [chosen] Where board k−1 reaches under board
  k, board k−1's step continues, so the body never rises between two boards
  and each board can be laid in from above.
- **Guides for every hole**, 13 + 12 + 11 + 10 = 46, each like the single
  guide tube: ⌀9.4 for the ⌀9 washers, ending in a ⌀8.6 × 1.5 pocket that
  centres the spring, spring seat 17.58 mm below the board's centre plane.
- **Bottom parallel to the step edges** [given]: one plane rising with the
  staircase, 4 mm in z per 17 mm in y (13.2°). Every spring seat lies
  17.58 mm below its board, so the seats lie on a parallel plane, and the
  bottom stays 1.5 mm below the deepest point of every bore [given].
  z = 0.235·y − 19.09: −20.3 at the front edge, −4.5 at the back face.
- **Connector pockets** around each vertical FFC connector at the board's −x
  end (turned with it, 0.3 mm clearance). **No FFC outlet through the floor**
  [given]: the cables hang into the hole behind the slanted face; their route
  out is still open.
- **FFC recess: on hold** [given]: cable routing is to be settled later, so
  for now there is no recess (`rec_h = 0`). The layout below stays in the
  code for then.
  **FFC recess** [given idea, layout chosen]: all four FFCs leave under the
  housing towards the back, flat, in one recess 3 mm deep above the bottom plane, open downwards.
  Each FFC runs down its slot, bends 90° to run +x lying flat in its own
  branch (y as its slot), and at the common strip (x −99.6 … −82.6, just +x
  of board 3's tab) is folded flat once along a 45° crease to run +y. In the
  strip the four lie stacked and leave at board 3's back face (y = 61.9).
  At most five layers (three passing FFCs and board 3's fold), about 1.5 mm
  plus the crease. The fold turns each FFC face down, so the far end needs the
  matching contact side. Laid in from below once the unit is on the housing,
  held with tape or a bottom plate. [unverified: retention] Replaces board 0's
  trough and fin (route `back_channel`, no longer used).
- **Filled under the cover** [given]: below the cover's walls the housing
  reaches out to the cover's outline, so the outside is flush. Under the end
  walls of steps 1–3 that is up to their lower edge, at the top of the step
  below. Under the back walls and the walls round the tabs, which only cover
  the board's thickness, it is up to the step. Inside step 0's front wall the
  housing is filled up to the step too. The gap between each step's (short)
  connector tab and the −x end of the step above is filled up to the step as
  well, so the hole behind the slanted face runs through it without leaving
  walls standing. Checked: no overlap with the cover.
- **Chamfered staircase ends** [given]: seen from above, the outer corners
  of the steps at each end lie on one line (10 mm in x per 17 mm in y), so each
  notch between two steps is closed by a slanted face from one corner edge to
  the next. Its top edge rises from the lower step's top to the upper one's.
  The housing fills the notch up to the lower step's top, and a wedge on the
  cover forms the sloped top above it. Checked: no overlap, both parts manifold.
- **Hole behind the slanted −x face** [given]: open to the top, closed below
  by a 3 mm floor parallel to the bottom [given], in a band parallel to the face. It runs from 1.2 mm inside the outer
  faces to the line through the hole-1 guides, 29.9 mm in. The connectors and
  the upper ends of the FFCs hang in it. What stays [chosen]:
  - the outer walls, 1.2 mm;
  - a 1 mm tube round each hole-1 guide, with its 1.5 mm spring floor;
  - a ⌀5 boss round each −x end screw pilot (1.7 mm wall, flattened by the
    connector pocket), from 1 mm below the pilot up, with 2.2 mm ribs over
    the same height: at right angles to the slanted wall (so parallel to the
    connector, beside its pocket), in −x to it, and in −y to the front wall
    (board 0) or straight to the hole-1 tube of the board below (boards 1–3,
    passing both connectors). They keep clear of the FFCs, which hang along
    each connector's centre line.
  These are cut from the body as it was, so they keep its clearances to the
  boards, connectors and cover.
- **Back outlet and the boards' cables** [given: one bend towards the
  cable's normal, then straight out of the back; rows 1–3 close to board 0's
  cable]: each FFC leaves its connector straight down (3.5 mm inside, then a
  straight lead) and is bent once, R 3, about its width towards its normal,
  i.e. towards the back, parallel to the slanted face. The bend is 101.5°: 90°
  plus the bottom's 11.5° rise along that direction, so the straight part runs
  parallel to the hole's floor. [chosen; at exactly 90° a straight cable
  would leave through the rising bottom under board 2] The four connectors
  lie in one vertical plane, each moved by a staircase step, which runs
  exactly along the straight parts, so **the four cables lie on one
  another**: board 0's lowest, each next 0.5 mm higher square to them (0.2 mm
  between the films). Only the lead differs: 3.53 / 3.02 / 2.51 / 2.0 mm for
  boards 0–3. Each cable comes down onto the ones below from above, so none
  crosses another. The stack runs 2.3 … 3.8 mm above the hole's floor (cable
  centres), below the connectors, screw bosses and ribs of boards 1–3, and
  0.8 mm beside the hole-1 tubes in plan. It leaves through row 3's back wall
  at x −99.6, z 0.8 … 2.4, 30.5° off the wall's normal (a flat cable cannot
  turn in its own plane), through a 16 × 3.5 mm slot along it. Free lengths
  from the connector face 89.3 / 68.6 / 48.0 / 27.4 mm. Checked: no two
  cables touch; every cable keeps ≥ 0.5 mm from the housing (0.4 mm beside it
  in the slot), clear of the cover; the boards and connectors only where each
  cable's end sits in its own connector. `back_cable.scad`
  (cables and `back_outlet()`, used by the housing) → `back_cable.stl`,
  `back_cable.js` for `array.html`.
- **Size:** 276.9 × 73.4 mm, z −20.44 … +11.07 (cover step 0 down to the same bottom plane).

**Thinnest walls:** about 0.7 mm, between each connector pocket and the guide
of the board's hole 1. Between the guides of board k+1 and the step of board k
there are now about 3.6 mm. Every guide is closed all round.

The viewer `array.html` shows the housing (toggle *Housing*; the single guide
tubes are off by default). It loads the geometry from `build/discant/housing.js`, which is
generated from `build/discant/housing.stl`.

## 3. Mounting the boards [given: cover clamping from above, niche at the next step]

1. **Niche.** Each board is pushed in +y into a niche behind its +y edge: in
   the riser of the next step for boards 0 … 2, a wall of its own for the top
   board and along each connector tab. The niche's back, 0.1 mm behind the
   board edge, locates the board in y; its lip, 0.6 mm over the board's top
   edge, holds that edge down and keeps 0.3 mm from the caps. [chosen]
2. **Ends, as short as reasonable** [given]. Since every screw passes through
   the board, nothing is needed beyond the board ends but the cover's end
   walls: their inner face sits 1.2 mm beyond each board end (room for the
   cover's −x end rib, 0.1 mm from the board end, the stop in x). Below the
   board level the housing reaches out to them. Cover step 0 is 276.9 mm long.
   Where board k's −x end overhangs the cover's wall round board k−1's tab,
   the housing under board k is cut back 0.3 mm clear of it. [chosen]
3. **Cover** (`cover.scad` → `cover.stl`): one printed part that closes the
   staircase so that **each step looks like a box** [given]:
   - top, 1.2 mm, on the board between the caps, over the tab and 1.2 mm
     beyond the board ends, with ⌀8 openings that guide the stems a second time;
   - flat round each opening: the **felt ring** under each cap (on the button,
     `switch/button.scad`) lands on it at the lower stop and damps it [given];
   - a full-length 1.2 mm **front wall** just in front of the board
     (y = −9.1 … −7.9), down onto the step below, for the bottom step down to
     the housing's flat bottom;
   - **end walls** at both ends and around the connector tab's bump, down to
     the level of the step below, also where no lower box lies under them, so
     the housing shows below them; only step 0's walls reach the bottom [given];
   - the back of each box is open into the housing's niche wall and the next
     step's front wall.
   The off-centre row keeps the board's own caps 0.4 mm behind its front wall
   and the caps of the board below 0.4 mm in front of it. Around every cap of
   the board below, the step above is **dented in** [given: ≥ 2 mm]: a vertical
   recess r = 9.5 (cap + 2 mm), down to the lower step's top, closed by a 1.2 mm
   ring wall (0.3 mm from the front rib above). Checked on cover.stl: every
   point of the cover above a cap's own plate keeps ≥ 2.0 mm from that cap.
   Held by **sixteen M2 countersunk self-tapping screws** (ISO 7046 / DIN 965
   heads, flush; 90° countersinks ⌀4 in the cover), four per board, all
   through the board on the row line into ⌀1.6 × 7 pilots in the housing: one
   near each end and two between (⌀2.2 clearance in cover and board). [chosen]

Checked by grid sampling: no cap touches the cover, at rest or pressed, on any
of the 46 holes. Housing and cover are each a single solid.

Assembly: buttons with washers, sleeve, screw and spring into the housing
guides; boards pushed into their niches against the −x stops, lowest first;
cover on, screws in.

## 4. Open points

1. **Thin housing wall** (§2), about 0.7 mm beside each connector pocket.

## 5. Files

The sources lie in `discant/`. `make` (or `make -j`) in `discant/` builds every
file below into `build/discant/` at the top of the repository (not under
version control), rebuilding only what changed; it first has `switch/` build
the key's parts that `array.scad` imports from `build/switch/`.

| File | Content |
|---|---|
| `array.scad`, `array.stl` | four boards with their button assemblies as a staircase, k × (10, 17, 4) mm, from the key's STLs |
| `housing.scad`, `housing.stl`, `housing.js` | printed body with 46 guides, a bottom parallel to the steps, the hole behind the slanted −x face and the back outlet |
| `cover.scad`, `cover.stl`, `cover.js` | printed cover holding the four boards down |
| `back_cable.scad`, `back_cable.stl`, `back_cable.js` | the four boards' FFCs to the back outlet, stacked, and the outlet slot (`back_outlet()`) |
| `array.html` | 3D viewer of the four boards with connectors, housing, cover and cables; X/Z section plane. Loads the `.js` geometry |
| `Makefile`, `stl2js.py` | `make` builds the files above into `build/discant/`; `stl2js.py` turns an STL into the `.js` geometry for `array.html` |
| `phone.html`, `embed_parts.py` | phone view of the assembly: boards, connectors, housing, cover, cables and one button, with Press, a section and gestures (Interact). `make` writes `build/discant/phone.html` with every part embedded by `embed_parts.py`, one file that loads nothing else, so it also works in the claude.ai viewer on a phone |
