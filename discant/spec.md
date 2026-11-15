# Discant — design record

The discant (treble) side of the accordion: four switch boards as a staircase,
the printed housing under them, the cover over them and the main PCB with its
FFCs. The switch board and its button assembly (the key) are recorded in
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
k × (10, 16, 3) mm. That is half the hole pitch along the row, 16 mm across it
and 3 mm up, so each board rises towards the connector (+Y) side. [given: the
key positions of the earlier DiscantCase, ../shape/OrderOnShape20260107: 46
keys, the same rows and pitch, 16 mm and 3 mm measured in the key plane]

**Board k has 13 − k holes: 13, 12, 11, 10.** [given] It is the same board
with k holes sawn off at the +X end (`pcb.scad`, `cut_holes = k`). The cut
runs 12.3 mm past the last hole kept, at local x = 112.3 / 92.3 / 72.3, 2.3 mm
beyond that board's +x end screw hole and 2.7 mm clear of the first ring
removed. [chosen] With
the 10 mm shift, both ends of the staircase step in by 10 mm per board. The
saw cuts through the common bus on top, which still reaches every remaining
−Y half, and through the band tracks of the removed holes, which remain as
dead stubs on contacts 2, 3 and 4. Checked on the 10-hole version's exported
copper: holes 1 … 10 on their contacts, contact 1 on all ten −Y halves, no
copper beyond the cut.
**Deburr the cut edge:** the tracks there are only 0.15 mm apart. `array.scad` places the part STLs (boards `pcb.stl`, `pcb_12.stl`,
`pcb_11.stl`, `pcb_10.stl`), and `array.stl` is the same assembly written
directly from them. `array.html`
shows the four boards with their connectors and guide tubes, without the
buttons.

**Clashes: none.** The boards are 14.7 mm wide, so with the 16 mm step
neighbouring boards are 1.3 mm apart in plan: board k ends at y = 9.4 and
board k+1 begins at y = 10.7 (board k's frame). Solid intersection finds no
overlap between boards, connectors and all 46 keys, at rest and pressed. The
button caps end 3.2 mm short of the board above. Board k+1's connector ends
1.6 mm short of board k's edge in plan.

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
  staircase, 3 mm in z per 16 mm in y (10.6°). Every spring seat lies
  17.58 mm below its board, so the seats lie on a parallel plane, and the
  bottom stays 1.5 mm below the deepest point of every bore [given].
  z = 0.1875·y − 18.89: −19.9 at the front edge, −7.8 at the back face.
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
  connector tab and the −x end of the step above is closed by the cover and
  filled below it up to the step as well, so the hole behind the slanted face runs through it without leaving
  walls standing. Checked: no overlap with the cover.
- **Chamfered staircase ends** [given]: seen from above, the outer corners
  of the steps at each end lie on one line (10 mm in x per 16 mm in y), so each
  notch between two steps is closed by a slanted face from one corner edge to
  the next. Its top edge rises from the lower step's top to the upper one's.
  The housing fills the notch up to the lower step's top, and a wedge on the
  cover forms the sloped top above it. Checked: no overlap, both parts manifold.
  At +x the last face ends at y = 58.1; the top step's end wall runs straight on
  for the 1.2 mm to the back face at y = 59.3, which stays one plane because the
  top step's back wall reaches out to the wall round its tab. [chosen]
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
- **No back outlet** [given: all cabling through the connector]: the
  boards' cables end on the main PCB (§6), the back wall stays closed.
- **Size:** 282.9 × 68.4 mm, z −20.6 … +11.04 (cover step 0 down to the same bottom plane),
  without the gauge pad and outer holders on the back face (§7).

**Thinnest walls:** about 0.7 mm, between each connector pocket and the guide
of the board's hole 1. Between the guides of board k+1 and the outer face of
the cover's back wall on board k (y = 10.1 in board k's frame) stay 1.2 mm of
housing. Every guide is closed all round by the housing alone.

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
   - a 1.2 mm **front wall**, broken by the dents, just in front of the board
     (y = −9.1 … −7.9), down onto the step below, for the bottom step down to
     the housing's flat bottom;
   - **end walls** at both ends and around the connector tab's bump, down to
     the level of the step below, also where no lower box lies under them, so
     the housing shows below them; only step 0's walls reach the bottom [given];
   - the back of each box is open into the housing's niche wall and the next
     step's front wall.
   The off-centre row keeps the board's own caps 0.4 mm behind its front wall.
   The caps of the board below stand where that wall would run. Around every cap of
   the board below, the step above is **dented in** [given: ≥ 2 mm]: a vertical
   recess r = 9.5 (cap + 2 mm), down to the lower step's top, closed by a 1.2 mm
   ring wall, which merges with the front rib above (1.1 mm thick there). Checked on cover.stl: every
   point of the cover above a cap's own plate keeps ≥ 2.0 mm from that cap.
   Held by **sixteen M2 countersunk self-tapping screws** (ISO 7046 / DIN 965
   heads, flush; 90° countersinks ⌀4 in the cover), four per board, all
   through the board on the row line into ⌀1.6 × 7 pilots in the housing: one
   near each end and two between (⌀2.2 clearance in cover and board). [chosen]

Checked by grid sampling: no cap touches the cover, at rest or pressed, on any
of the 46 holes. Housing and cover are each a single solid.

Assembly: as `cover.scad` says, the boards and buttons go together in the
upside-down cover and onto the housing as one unit. (This section's niche
wording predates that and §3.1 needs revisiting.) The main PCB is plugged to
the unit on the bench first, see §6.

### 3.2 Thumb bar [given: on the −y side]

Part of the cover, along step 0's front wall over its whole length (x −149.9 … 133.0).
Its section is `thumb-bar/profile.scad`'s `thumb_profile()` (a straight back; one curve
with two lobes and a waist touching the back). Its parameters and place come from the
thumb bar of the earlier DiscantCase (`../shape/OrderOnShape20260107/DiscantCase -
Case.step`, converted with FreeCAD, cut at x −60). That section was put into board 0's
frame by matching the first row's cap tops (old caps tilted by atan(3/16); old cap top
centre to z 8 over hole 1), then the profile was fitted to its outer contour from the
top down to z −19 (the old foot below, which held the old cover, left out):
0.2 mm rms, 0.9 mm max.

- Profile: back 21.7, back angle 86.1°, small radius 1.2, large radius 20.6 (blend
  0.8). The defaults in `profile.scad` (40, 57°, 4, 15) stay as they were.
- Place, relative to the first row (hole axis y 0, caps ⌀15 with their front edge at
  y −7.5 and their top at z 8): the back upright at y −13.9, z −18.8 … +2.9 (top 5.1
  below the caps' top); the lobes out to y −15.0 at z +1.0 and −17.1; the waist
  touches the back at z −7.9. The 4.8 mm between the back and the front wall
  (y −9.1) are solid.
- Cut back over the bass's playing mount [given: stored position higher, bar flatter in
  the middle]: stored, the discant slides 9.3 mm up onto its socket past the mount,
  and the full bar (5.5 mm below the cover's front edge in that direction) ran up to
  4.8 mm into it. The stored position went 1.2 mm up (as far as the socket allows
  under the bass's back-row keys); for |x| < 38 the bar keeps only what stays above
  that level (y cos t + z sin t ≥ −13.94, t = atan(3/16)): 4.3 mm off its lobes there,
  45° ramps at both ends (`tb_cut_x`, `tb_cut_d`).
- Checked: clear of the bass in both positions and over the whole insertion travel
  (swept in 0.5 mm steps; only the socket's detent tooth, 0.6 mm, meets the plates, as
  it should); the stored package is unchanged (282.9 × 40.3 × 147.2).
- Printing: the bar makes the cover's front heavier; the lobes overhang when the cover
  prints top down [unverified: supports needed].

## 4. Open points

1. **Thin housing wall** (§2), about 0.7 mm beside each connector pocket.
2. **Main PCB** (§6): parts unchosen, so bodies are assumed; fixing against
   USB plug forces; strain gauge position along the −y side.

## 5. Files

The sources lie in `discant/`. `make` (or `make -j`) in `discant/` builds every
file below into `build/discant/` at the top of the repository (not under
version control), rebuilding only what changed; it first has `switch/` build
the key's parts that `array.scad` imports from `build/switch/`.

| File | Content |
|---|---|
| `array.scad`, `array.stl` | four boards with their button assemblies as a staircase, k × (10, 16, 3) mm, from the key's STLs |
| `housing.scad`, `housing.stl`, `housing.js` | printed body with 46 guides, a bottom parallel to the steps, the hole behind the slanted −x face, the main PCB's pockets and the wires' bore |
| `cover.scad`, `cover.stl`, `cover.js` | printed cover holding the four boards down, with the thumb bar on its front (§3.2; profile from `../thumb-bar/profile.scad`) |
| `main_pcb.scad`, `main_pcb.stl`, `pcb_cable.stl`, `.js` | main PCB with part bodies, the four FFCs to it, floor pockets, openings and pins for the housing |
| `gauge_link.scad`, `gauge_link.stl` | two strain gauges (plates) with their pins, the contact board, and the wires from contacts and gauges to the key board's pads; the outer holders, pad, groove and channels are in the housing (§7) |
| `array.html` | 3D viewer of the four boards with connectors, housing, cover and cables; X/Z section plane. Loads the `.js` geometry |
| `Makefile`, `stl2js.py` | `make` builds the files above into `build/discant/`; `stl2js.py` turns an STL into the `.js` geometry for `array.html` |
| `phone.html`, `embed_parts.py` | phone view of the assembly: boards, connectors, housing, cover, cables and one button, with Press, a section and gestures (Interact). `make` writes `build/discant/phone.html` with every part embedded by `embed_parts.py`, one file that loads nothing else, so it also works in the claude.ai viewer on a phone |

## 6. The key board's bus [given 2026-11-13: one Hall-sensor board for all 46 keys; the electronics in the bass]

The hole behind the slanted face, its board, the four 14-way FFCs and the per-board
expanders (PCAL9555A, 20h…23h) are gone; their last state is in the git history
(`main_pcb.scad`'s `bus_wires()`, four bundles to a splice, is that old way and no
longer part of the build's design).

- **The Hall-sensor board** (`../hall_pcb/discant/`) reads all keys with six ADS7128 at
  10h…15h, and the gauges with a NAU7802 at 2Ah [chosen 2026-11-15]. No connector: at
  the middle of its back edge three rows of wire pads, J1 (bus: INT, 3V3, SDA, SCL,
  GND) at X 0, J2 and J3 (each gauge's E+, middle, E−) at X ∓12.
- **Wires:** from the contacts and the gauges, through channels under the board's back
  edge and up through the pads, soldered on the top (`gauge_link.scad`: `contact_pts()`,
  `lead_pts()`). Lengths: the Wiring section of `../assembly/spec.md`.

## 7. Gauge and link to the bass module

`gauge_link.scad`. **Not final:** bodies are assumed sizes [unverified].

- **Bass module** [given]: separate, 2 × 9 keys (same closed contacts), with the
  battery, joined by a detachable connector that carries all cabling.
- **Force path** [given]: discant → gauges → connector → bass. Two gauges side by
  side [given], which also holds against torsion, central on the +y side [given]:
  x = ±25 [chosen; the outline's middle is −6.7]. Plates in the slope's plane
  [given; earlier the x/y plane]: tilted up by atan(3/16) = 10.62° about x, as the rows
  climb and the housing's bottom runs, about the middle of the pad's face; they sense
  force normal to that plane. So stored (`../assembly/spec.md`) they point straight up
  the bass, and played the discant's slope plane lies level.
- **Fixed side** [given: part of the 3D-printed housing, no screws]: a gauge pad,
  96 × 10.8 mm on the back face, a wedge whose face turns with the plates (4 mm thick at
  the bottom, 2 at the top), with both outer holders growing out of it,
  so housing, pad and holders are one print, out to y = 89.6. They reach past the
  bottom plane, which ends at the back face. Each plate slides into its holder from
  the far end, leads ahead of it, until its edge lands on the pad; then the inner
  holder; then a dowel pin ⌀1.5 × 10 across each jaw, four in all, keeps it in.
  [chosen] [unverified: the 0.15 mm plate fit, printed in the housing]
- **Inner holders** [given: the gauge is three parts; the inner holder is the bass's]:
  printed with the bass on one mount (`../bass/link.scad`); the bass slides them onto
  the plates' W and off again. The link plate and its spring pins are gone; the 12
  contacts need their own connector [open].
- **Reading:** each bridge reads moment, force × arm from the gauges (7 mm as
  designed; on the bass the hand's push acts about 56 mm away, `../bass/spec.md` §4). The sum follows the force, the difference the twist. Arm and the bass
  module's weight therefore enter the reading. [estimated: with two gauges full
  scale is about 2 × 1400 N·mm, so about 35 N at an 81 mm arm]
- **Readout** [given: housed, in the housing, no screws; chosen 2026-11-15: on the
  Hall-sensor board]: the NAU7802 for both half bridges sits on the key board's
  underside at the middle of its back edge (`../hall_pcb/spec.md` §3a); the link board
  in a pocket beside the pad, its lid and the plug from J1 are gone. Analog beside the
  board's digital parts is checked there. The pad now runs x = −46 … 46.
- **Wire ways:** the gauges' leads leave the plates towards the pad and run in a
  3.2 × 1.5 mm groove in it, from each plate's middle to a channel at x = ∓12 (about
  19 mm each). Each channel (3 mm wide) runs from the groove through pad and back wall
  under the board's back edge, from 0.3 into the floor to just under the board: the
  gauge plane lies at the gap under the board, so the channels run straight in, and
  the wires go up through the pads J2 / J3 and are soldered on the top. Under the
  plates' edges the groove runs behind a 1 mm strip, the plates' stop; elsewhere it
  is open to the pad's face or the holders. The cover has a 0.8 mm recess over the
  pad rows for the joints. The NAU7802 (1.75 high) stands 0.4 into the tray's floor
  (0.8 left under it; `hall.scad` `deep_parts`).
- **Contacts** [given: closing as the bass slides on]: a boss on the pad between the
  outer holders (10.4 × 10 mm, to y = 83.2 in the gauge frame) carries a 0.8 mm board
  with nine gold pads, 3 × 3 at 2.54, facing the bass's spring pins: VBAT × 2, GND × 3,
  SDA, SCL, INT, DET (tied to GND on the board: switches the bass's battery on). A ⌀2.2
  bore down the boss leads the wires (VBAT, GND, SDA, SCL, INT: a 1.3 mm bundle) into the
  pad's groove and straight on through the channel at x = 0 to the key board's J1
  (28 mm).
  The latches in the inner holders carry the load, not the contacts.
  `../assembly/spec.md`, Contacts.
- **Open:** overload stop.

Checked by solid intersection (2026-11-15, with the NAU7802 on the board; control pair
overlapping): the wires touch only the pads they end at; housing, board, its parts and
cover are clear of each other. The paths of plates and inner holders into the outer
holders were checked before and are unchanged.
