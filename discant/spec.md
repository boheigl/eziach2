# Discant — design record

The discant (treble) side of the accordion: 46 Hall-sensor keys on one board, the
printed housing (a thin tray) under it, the cover plate with the keys' tubes and the
thumb bar over it, and the strain gauges with the contacts that link it to the bass.
The key itself is recorded in `../switch_hall/spec.md`, the board in
`../hall_pcb/spec.md`, the electronics in the bass (`../main_pcb/`, `../bass/spec.md`).

Numbers are tagged by where they come from: **[given]** stated by the user,
**[datasheet]** taken from a manufacturer's document, **[chosen]** a design
decision made here, **[estimated]** calculated rather than measured,
**[unverified]** still to be confirmed.

The board's outline, holes, wire pads and part bodies are not copied by hand: they
come from the routed KiCad board through `../hall_pcb/discant/board.scad` (written by
`../hall_pcb/export_scad.py`), which `hall.scad` includes for every part here.

The previous design (four stepped push-button boards, a housing with 46 guides and a
cover of four boxes) is in the git history.

---

## 1. Key layout [given]

**46 keys in four rows of 13, 12, 11 and 10**, 20 mm apart along a row. Row k is moved
by k × (10, 16, 3) mm: half a pitch along the row, 16 mm across it and 3 mm up, so the
rows climb towards +y. [given: the key positions of the earlier DiscantCase,
../shape/OrderOnShape20260107]

**One Hall-sensor board under all 46 keys** [given 2026-11-13] (`../hall_pcb/discant/`),
in the rows' slope plane: tilted up by atan(3/16) = 10.62° about x. Its top copper meets
every key's axis at the same height relative to the key (`key_ztop`, `hall.scad`), so
every key sees the same board under it, with a DRV5055 on its axis. Outline a trapezoid,
265.8 mm along the front edge, 186.2 along the back, 64.8 deep in its plane; 27 screw
holes on a 40 mm grid.

`hall.scad` defines the **slab frame** (X along the rows, Y up the slope in the board's
plane, W out of its top face) and maps it into the discant's frame (row 0, z up) with
`on_slab()`. Housing and cover are built in the slab frame.

The keys (`../switch_hall/`) stand entirely above the board: rod in a bronze bushing in
the cover's tube, cap on top, the magnet's collar below, spring round the tube.
`keys.scad` places all 46 at rest and pressed for the assembly and the phone page.

## 2. Housing [given 2026-11-13: the cases as small as possible]

`housing.scad` → `housing.stl`: **one printed tray** under the board, in the slab frame
(`hall.scad`):

- **Floor** 1.2 mm thick, its top 0.3 mm under the tallest part on the board's
  underside [chosen]. Parts deeper than the rest stand into the floor, which is thinner
  under them: on this board the NAU7802 (`deep_parts`).
- **Rim** round the board up to its top face: 0.3 mm fit, 1.2 mm wall.
- **What carries the board:** a ledge along its edge and a ⌀4.4 boss at every screw hole,
  from the floor up to the board's underside, clear of the parts' bodies. The bosses
  carry the ⌀1.7 pilots for the cover's screws (§3).
- **Thumb bar shelf** [given 2026-11-14: stiff enough]: along the tray's front face, at its
  bottom, a ledge 2.5 mm deep and 1.6 high. The thumb bar's back sits on it, so pressed
  down the bar bears on the tray, not only on the cover plate; pressed back, on the
  tray's front face.
- **Gauge pad** on the back face, with both gauges' outer holders growing out of it, and
  the channels for the wires (§7).
- **Size** (built STL, discant frame): x −135.6 … 135.6, y −11.3 … 88.4 including the
  gauge holders.

## 3. Cover and mounting [given 2026-11-13: variant A, one flat plate on the tilted board]

`cover.scad` → `cover.stl`: a plate 2.4 mm thick [given 2026-11-14: 1.2 before] over board
and rim, in the slab frame. Nothing of it goes below the board's top face.

- At every key it carries the key's **tube and shroud** (`../switch_hall/key.scad`
  `tube_body()` / `tube_cut()`): the tube guides the plunger, the shroud hides the spring
  under the cap's skirt, and inside the shroud a level floor is the spring's seat,
  whatever the plate's tilt. A bore under each tube lets the bushing in from below.
- A 0.8 mm **recess over the wire pads** J1 … J3 for the solder joints (§6).
- **Assembly** (`../switch_hall/spec.md`): the cover lies on a jig whose pins reach into
  the tubes from below; plungers in from below, springs from above, caps pressed on.
  Off the jig the springs hold every plunger against its step, so the cover is one unit
  with all 46 keys. It goes onto the board in the housing.
- Held by **27 M2 × 6 countersunk brass machine screws** (DIN 965 CuZn, near the
  magnets [given 2026-11-15]; heads flush in 90° countersinks ⌀4 in the cover) on the
  board's 40 mm grid (`../hall_pcb/spec.md`), through cover (2.4) and board (1.67),
  ⌀2.2 clearance in both, into ⌀1.7 pilots in ⌀4.4 bosses of the housing. The screw
  cuts its own thread there, about 1.9 mm deep (bosses 1.65 plus the floor; the pilot
  stops 0.4 above the outside, M2 × 8 would go through). [chosen]
  - **Loads:** the springs push between seat and bushing, both in the cover, so they
    load no screw; a press pushes cover and board onto the bosses. Only the thumb
    bar's side loads (shear, spread over 27 screws) and lifting the discant by its
    cover pull or shear them. Pull-out about 100 … 200 N per screw [estimated].
  - **Pilot ⌀1.7, not the M2 tap drill 1.6** [given 2026-11-15]: printed holes come out
    0.1 … 0.2 under size, and soft brass would tear in its slot cutting a full thread.
  - **Tightening:** with two fingers on a small screwdriver, stop when the head is
    flush; the thread in the plastic strips long before the brass breaks. When
    reopened, turn each screw back until it drops into its thread before driving it,
    or every assembly cuts a new one.

### 3.2 Thumb bar [given: on the −y side]

Part of the cover, along its whole front edge. Its section is
`../thumb-bar/profile.scad`'s `thumb_profile()` (a straight back; one curve with two
lobes and a waist touching the back). Its parameters and place come from the thumb bar
of the earlier DiscantCase (`../shape/OrderOnShape20260107/DiscantCase - Case.step`,
converted with FreeCAD, cut at x −60). That section was put into row 0's frame by
matching the first row's cap tops (old caps tilted by atan(3/16); old cap top centre to
z 8 over hole 1), then the profile was fitted to its outer contour from the top down to
z −19 (the old foot below, which held the old cover, left out): 0.2 mm rms, 0.9 mm max.

- Profile: back 21.7, back angle 86.1°, small radius 1.2, large radius 20.6 (blend
  0.8). The defaults in `profile.scad` (40, 57°, 4, 15) only serve its own preview.
- Place, relative to the first row as fitted (hole axis y 0, caps ⌀15 with their front
  edge at y −7.5 and their top at z 8): the back upright at y −13.9, z −18.8 … +2.9 (top
  5.1 below the caps' top); the lobes out to y −15.0 at z +1.0 and −17.1; the waist
  touches the back at z −7.9. From the back to 0.4 mm in front of the caps (y −7.9) it
  is solid, so it overlaps the cover plate along its whole length.
- **It follows the keys' tops** [given 2026-11-13]: the Hall keys' caps stand higher
  (`key.scad` `key_cap_top()`), so the bar moves up with them by `tb_dz`.
- **Never cut** [given 2026-11-14]: it keeps its whole profile over its whole length;
  the bass makes room for it (its box is longer, `../bass/layout.scad`).
- Its back sits on the housing's shelf (§2); the tray and the board stay whole, the bar
  ends at their front face.
- Printing: the bar makes the cover's front heavier; the lobes overhang when the cover
  prints top down [unverified: supports needed].

## 4. Open points

1. **Plate fit** in the outer holders, 0.15 mm, printed in the housing (§7) [unverified].
2. **Thumb bar lobes:** supports when printing the cover (§3.2) [unverified].

## 5. Files

The sources lie in `discant/`. `make` (or `make -j`) in `discant/` builds every file
below into `build/discant/` at the top of the repository (not under version control),
rebuilding only what changed; it first has `../switch_hall/` build the key's parts and
`../strain_gauge/` the gauge's.

| File | Content |
|---|---|
| `hall.scad` | the board in the discant's frame (slab frame, `on_slab()`), the tray's dimensions and the thumb bar's shelf; shared by all parts here |
| `housing.scad`, `housing.stl` | the tray under the board: floor, rim, ledge and bosses, the shelf, the gauge pad with the outer holders and the wires' channels |
| `cover.scad`, `cover.stl` | the cover plate with the 46 keys' tubes and shrouds, the screw countersinks, the pads' recess and the thumb bar (§3.2) |
| `board.scad`, `board.stl`, `board_parts.stl` | the board's laminate with its holes, and the parts' bodies on its underside |
| `keys.scad`, `keys.stl`, `keys_down.stl` | the 46 keys in place, at rest and pressed (springs left out) |
| `gauge_link.scad`, `gauge_link.stl` | two strain gauges (plates) with their pins, the contact board, and the wires from contacts and gauges to the board's pads; the outer holders, pad, groove and channels are in the housing (§7) |
| `phone.html`, `embed_parts.py`, `viewer_nav.js` | phone view of the discant: board, parts, housing, cover, link and the keys, with Press, a section and gestures. `make` writes `build/discant/phone.html` with every part embedded by `embed_parts.py`, one file that loads nothing else, so it also works in the claude.ai viewer on a phone |
| `Makefile` | builds the files above |

## 6. The key board's bus [given 2026-11-13: one Hall-sensor board for all 46 keys; the electronics in the bass]

The four key boards, their 14-way FFCs, the per-board expanders (PCAL9555A,
20h…23h) and the hole behind the slanted face are gone; their last state is in the
git history.

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
  the plates' W and off again. The contacts are the spring-pin boards between the
  outer holders (below, and `../contact_pcb/`).
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
- **Contacts** [given: closing as the bass slides on; chosen 2026-11-15: the pad half of
  `../contact_pcb/`]: a boss on the pad between the outer holders (10 × 9 mm, to y = 83.4
  in the gauge frame) carries a 1.6 mm board, 10 × 9 mm, with nine gold pads ⌀2.2, 3 × 3
  at 2.54 across and 3.0 up, facing the bass's spring pins: 3.3 V × 2, GND × 3, SDA, SCL,
  INT, DET (tied to GND on the board: switches the bass's system on). Five wires (3V3,
  GND, SDA, SCL, INT) are soldered to its back pads, in a 7.2 × 7.2 × 1.5 mm recess of the
  boss, and a ⌀2.2 bore down the boss leads them (a 1.3 mm bundle) into the
  pad's groove and straight on through the channel at x = 0 to the key board's J1
  (28 mm). The board is glued onto the boss, its edges flush with the boss's (the same
  outline): that locates it within a few tenths, and the pins' tips stay on the pads up
  to ±0.65 mm [given 2026-11-20: glue only; review/contact_pcb.md MINOR 5].
  The latches in the inner holders carry the load, not the contacts.
  `../assembly/spec.md`, Contacts.
- **Overload:** no stop needed [2026-11-15]: the bought load cells are rated 490 N with 150 % overload; 100 N is a fifth of that (`../strain_gauge/spec.md` §4a).

Checked by solid intersection (2026-11-15, with the NAU7802 on the board; control pair
overlapping): the wires touch only the pads they end at; housing, board, its parts and
cover are clear of each other. The paths of plates and inner holders into the outer
holders were checked before and are unchanged.
