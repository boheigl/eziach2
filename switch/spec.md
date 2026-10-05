# Switch board — design record

What was decided, and why. Numbers are tagged by where they come from:
**[given]** stated by the user, **[datasheet]** taken from a manufacturer's
document, **[chosen]** a design decision made here, **[estimated]** calculated
rather than measured, **[unverified]** still to be confirmed.

The model is parametric: `pcb.scad` (board, copper, connector) and
`button.scad` (button, washers, sleeve, screw, guide tube, spring) are the
sources, and `viewer.html` rebuilds the same geometry from parameters copied
at the top of its script. **Change a value in both places.** Both `.scad`
files assert their clearances and stop with an error if a change breaks one.

---

## 1. Coordinate system [chosen]

Origin at the centre of the board in all three axes. X runs along the row of
holes, Y across it, Z out of the top face. The laminate therefore runs
z = −0.8 … +0.8. The copper is on the underside, z = −0.835 … −0.8. The
connector tab is on the +Y side. Every part uses this frame.

## 2. Board

| | | |
|---|---|---|
| Thickness | 1.6 mm, FR4 | [given] |
| Holes | 13 × ⌀8 in one row, 20 mm pitch, centres x = −120 … +120 | [given]; ⌀8 since the switch to ⌀9 washers |
| Outline | 272.1 × 15.9 mm, x = −139.8 … +132.3, y = −5.3 … +10.6: the row of holes sits off centre towards −y | [chosen] |
| Screw holes | 10 × ⌀2.2 on the row line y = 0 [given]: x = −137.5 (−x end), −50, 50, 30, 10, −10 (middle), 130, 110, 90, 70 (+x end of the 13/12/11/10-hole board); each board uses four | [chosen] |
| Material between holes / hole to the −y, +y edge | 12 mm / 3.6, 5.2 mm | derived |
| Connector tab | x = −133.6 … −124.7, out to y = 14.6, carrying the connector's +y end | [chosen] |

The width is set by what lies across the board: the copper ring (to r = 5),
0.35 mm to the first track, the seven tracks of the −y band at 0.3 mm pitch and
0.3 mm to the edge make 7.6 mm on the −y side; the +y side has 9.2 mm. **The
row sits 0.8 mm off centre towards −y** [given] so that in the staircase a
1.2 mm cover wall fits in front of each board, 0.4 mm clear of its own caps and
of the caps of the board below (§11). Every screw passes through the board on
the row line [given]: at +x half a pitch past the last hole, the board ending
2.3 mm beyond (12.3 mm past the last hole); at −x just left of the connector
pads (0.5 mm clear), the board ending 2.3 mm beyond at x = −139.8, plus the
small tab. Further out at −x the next board up would lie over the tab.

## 3. Contacts: copper half-rings

Every hole is ringed **on the underside** by two half-rings of bare copper
(no solder mask). [given]

| | | |
|---|---|---|
| Inner edge | flush with the bore, ⌀8, no gap to the hole | [given] |
| Outer edge | ⌀10, so 0.5 mm beyond the ⌀9 washer all round | [given] rule, value derived |
| Width | 1.0 mm | derived |
| Gap between halves | 0.5 mm, parallel-sided, along the row axis; halves on +Y and −Y | [chosen] |
| Ring to ring / ring to the −y, +y edge | 10 mm / 2.6, 4.2 mm | derived |

All 13 rings are the same size, although only the middle hole carries a
washer. [chosen] The ⌀9 washer rests on a ring only 0.5 mm wide, which varies
from 0.3 to 0.7 mm with its 0.2 mm play in the guide. [unverified: contact
reliability]

## 4. Connector

**GCT FFC3A20-14-G** [given]: 14 contacts, 1.0 mm pitch, vertical SMT, ZIF
slide lock, single-sided contact, for 0.30 mm FFC, gold flash. It replaced the
OMRON XF3M(1)-1415-1B. Being vertical, it takes the cable at right angles to
the board, so **the FFC leaves downwards (−Z)**.

Land pattern and body from the GCT FFC3A20 drawing, for 14 contacts
[datasheet]:

| | |
|---|---|
| Pads | two rows of 14, 0.60 × 2.00 mm at 1.0 mm pitch; every contact has a pad in each row |
| First to last pad centre (B) | 13.0 mm |
| Rows | 5.50 mm over both, 1.50 mm between them |
| Housing | A = 21.0 mm long (D = 19.5 at the base), 4.50 mm deep, 5.50 mm high |
| Hold-down pads | none |

**Placement** [given, refined]: on the underside at the **−x end**, **turned
so that its long side runs along y**, as close to hole 1 as the guide bore
allows. The −x end lies under no higher board or guide in the staircase and is
never sawn off.

- Housing x = −130.2 … −125.7, 0.7 mm short of hole 1's copper ring, so a
  0.7 mm wall remains in the housing to hole 1's guide bore. [chosen]
- Housing y = −7.4 … 13.6: the −y end stays 0.4 mm clear of the board below
  in the staircase (its +y edge is at y = −7.8 in this frame), and the +y end
  sits on the tab. [chosen]
- Pad columns at x = −129.7 (outer) and −126.2 (inner); contacts along y,
  **contact 1 at the +y end (y = 9.6), contact 14 at the −y end (y = −3.4)**.
- The housing is assumed centred on the pad pattern. [unverified]

## 5. Tracks

Signal tracks on the underside, **0.15 mm wide with 0.15 mm clearance** (needed
for seven tracks on the narrower −y side; standard at common fabs); the common
on the top copper. [chosen] The board is **two-layer**.

- **Contact 1 is the common:** it joins the −Y halves of all 13 rings. [given]
- **Contacts 2 … 14** each take the +Y half of one ring. [given]

A pad can only be reached from its end, so each contact is fed from the right
(into the inner column) or from the left (into the outer column); every
contact has a pad in both.

- **Hole 1** runs straight from its own ring into the inner column.
  **Holes 2 … 6** run in the band between the rings and the +Y edge
  (y = 5.35 … 6.55; the nearer the hole, the lower), turn beside hole 1 and run
  left into the inner column: **hole h → contact 8 − h** (hole 1 → 7).
  Up-turning tracks stay above all others and turn first, the higher the
  further right; then the down-turning ones, the lower the further right.
- **Holes 7 … 13** leave their +Y half at its −X end, cross to the −Y side in
  the gap before the next ring and run in the band along the −Y edge
  (y = −5.35 … −7.15; the later a track joins, the nearer the rings), pass
  below the connector's lowest pad, turn up in a channel left of it
  (x = −131.2 … −133) and run right into the outer column, taking contacts
  14 … 8:
  **hole h → contact 21 − h**.
- **Common:** a via in the middle of every −Y half (y = −4.5, 0.35 mm of
  web to the bore), a straight bus on the top copper along y = −4.5 to the
  connector, up between the two
  pad columns to a via at contact 1, and a short bottom track into its pad.
  Vias ⌀0.3 drill / ⌀0.6 pad, tented.

**Checked on the exported copper of both layers:** every contact on the
intended ring halves, for the full board and the 10-hole sawn-off one, at
least 0.15 mm between any two nets. Rings and pads are bare copper; `pcb_mask.dxf` gives
the openings.

## 6. Button assembly (middle hole)

Button, washers, sleeve and screw move together along Z.

| Part | Dimensions | z range at rest | Source |
|---|---|---|---|
| Button stem | ⌀7.6 (0.2 mm clearance in the ⌀8 hole) × 5.6 | −0.835 … 4.765 | [given] |
| Button cap | ⌀15 × 2, upper edge R0.5 | 4.765 … 6.765 | [given] |
| Upper washer | M3 to ISO 7093 / DIN 9021: ⌀9 / ⌀3.2 × 0.8, metal | −1.635 … −0.835 | [given] |
| Spacer sleeve | ⌀6 / ⌀3.2 × 6, metal | −7.635 … −1.635 | [chosen], see §11 |
| Lower washer | the same | −8.435 … −7.635 | [given] |
| Screw | M3 × 12 self-tapping for plastics, head below the lower washer | head −10.835 … −8.435 | [given] type, [chosen] length |
| Pilot hole in the stem | ⌀2.5 blind, 5.4 deep, 1 mm past the screw tip | | [chosen] |

The z ranges include the 0.035 mm the assembly sits below the drawn
position at the upper stop (see §7). The screw engages 4.4 mm in the button,
2.2 mm of cap remains above the pilot hole, and the ⌀7.6 stem keeps 2.55 mm
of wall around it.

**The upper washer is the switch contact:** at rest it bears on both
half-rings of the middle hole and bridges them. It must stay metal and on top.
[given]

**Why a sleeve between two washers:** the assembly is guided at two points,
the stem in the board hole and the washers in the guide tube. With the two
washers stacked directly, those points were only about 3.2 mm apart overall.
The button could tilt about 7°, and a press more than 4–5 mm off centre could
jam it at the start of the stroke (friction taken as 0.3–0.4). With the 6 mm
sleeve they are about 9 mm apart. The tilt drops to about 2.5°, and jamming
would need a press 11–15 mm off centre, outside the cap. [estimated]

## 7. Travel

| | |
|---|---|
| Upper stop (rest) | upper washer on the copper rings; stem face 0.035 mm below the laminate |
| Lower stop | cap underside on the board's top face |
| Stroke | 3.965 mm (4 mm stem projection less 0.035 mm copper) |

`button.scad` takes `travel` (0 … stroke). The viewer has a slider and a
*Press* button.

## 8. Guide tube and spring

**Guide tube, 3D printed, fixed under the board** [given], ⌀13.4 / ⌀9.4
(0.2 mm clearance to the washers) [chosen], z = −0.835 … −19.08, so
18.25 mm long. It has a 1.5 mm floor (top at z = −17.58) and a 1.5 mm
centring collar for the spring, ⌀8.6 inside. Its top face rests on the board's
underside: the innermost 0.3 mm on the edge of the copper rings, the rest on
solder mask. The board has no fixing holes, so it has to be glued on or held
by whatever carries the board. [unverified: fixing method] In the staircase
the housing (§10) replaces it.

**Spring** [given]: ⌀8 outside, 0.4 mm wire (⌀7.2 inside), 25 mm free
length, 8 active coils. It stands on the floor inside the collar and pushes
the lower washer up. It surrounds the screw head.

| | | |
|---|---|---|
| End coils | one closed dead coil each end, 10 coils in all, solid ≈ 4 mm | [unverified] |
| Rate | ≈ 0.074 N/mm, spring steel G = 81 500 N/mm² | [estimated] |
| Initial force at the upper stop | 120 g = 1.18 N | [given] |
| Preload | 15.9 mm → 9.15 mm long at rest, 5.18 mm at the lower stop | derived |
| Force at the lower stop | 1.47 N = 150 g, +25 % over the stroke | [estimated] |

The user's aim is about 120 g at the start of the press that hardly rises
over the stroke. That calls for a soft spring, heavily preloaded. The floor,
and with it the tube length, is computed from the wanted initial force
(`spring_f0`). Each 0.1 N of error in the rate moves the floor by about
1.35 mm, so the tube should be re-checked once the real spring rate is known.

At the lower stop the spring is 1.2 mm clear of solid in all, about 0.15 mm
per gap. That is less than the DIN EN 13906-1 minimum length (≈ 6.25 mm), but
the coils do not touch.

Springs considered and rejected: ⌀10 × 1 × 20 (5 active coils, ≈ 4–15 N, far
too stiff); ⌀10 × 0.5 × 40 (needed a 38 mm tube); ⌀8 × 0.4 × 10 (too short
for 120 g); ⌀8 × 0.4 × 15 (5 active coils: goes solid at 120 g); 0.8 × 8 × 20
and 0.6 × 10 × 10 (too stiff, ≈ 330–1250 g at full stroke). In the
Federnfabrik Schmid catalogue of standard springs ("similar to DIN 2098"),
none combined the fit over the screw head, 120 g and a flat force curve.

## 9. Four-board array [given]

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
board above. Board k's tab ends 0.5 mm short of board k+1's −x end, and board
k+1's connector 0.4 mm short of board k's edge, both in plan.

## 10. Housing for the staircase [given]

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
- **Flat floor parallel to the step edges** [given]: one plane rising with
  the staircase, 4 mm in z per 17 mm in y (13.2°). Since
  every spring seat lies 17.58 mm below its board, the seats lie on a parallel
  plane, and the floor stays ≥ 1.5 mm below the deepest point of every bore.
  [chosen] z = 0.235·y − 19.09.
- **Connector pockets** around each vertical FFC connector at the board's −x
  end (turned along y, 0.3 mm clearance) and a 2 × 16 mm **FFC slot** below
  each, along y, straight down through the floor. [chosen] **Board 0's slot
  is closed** [given]: its FFC is to leave through a channel to the front
  wall instead; `ffc_slot` in `housing.scad`. **Board 0's FFC channel**
  [given]: a 15.8 × 0.8 mm slot from the connector pocket to the front wall
  (centre x −131.7, z −12, tilted −20° in x/z), twisting the cable 90°, with
  ≥ 0.6 mm wall to floor, end wall and hole 1's bore. Computed by the cable
  model (`cabling/routes.json`, route `housing_channel`; `cabling/channel.js`
  writes `ffc_channel.scad`, which `housing.scad` subtracts).
- **Size:** 263.2 × 74.2 mm, z −22.9 … +14.1.

**Thinnest walls:** about 0.7 mm, between each connector pocket and the guide
of the board's hole 1. Between the guides of board k+1 and the step of board k
there are now about 3.6 mm. Every guide is closed all round.

The viewer `array.html` shows the housing (toggle *Housing*; the single guide
tubes are off by default). It loads the geometry from `housing.js`, which is
generated from `housing.stl`.

## 11. Mounting the boards [given: cover clamping from above, niche at the next step]

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
     beyond the board ends, with ⌀15.6 openings for the ⌀15 caps (they pass through when
     pressed);
   - a full-length 1.2 mm **front wall** just in front of the board
     (y = −9.1 … −7.9), down onto the step below, for the bottom step down to
     the floor plane;
   - **end walls** at both ends and around the connector tab's bump, down onto
     the step below or the floor;
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

## 12. Open points

1. **Spacer sleeve.** ⌀6 / ⌀3.2 × 6 is a nominal size. Found alternatives:
   - RS PRO brass ⌀4.8 / ⌀3.2 × 6 fits directly.
   - A plastic M4 sleeve ⌀7 × 5 (bore ≈ 4.2) also works. The guide span drops
     to about 8 mm, and with an M3 × 12 the chip room must shrink to 0.5 mm to
     keep 1.5 mm of cap. Polyamide creeps under the clamp load, so tighten
     moderately and use medium thread-lock.
2. **Screw.** The real screw (`Screw.png`) has a cylinder head with hex
   socket and a coarse, sharp thread for plastics, which suits the button. It
   must be **at most 12 mm** under the head. The model still has a pan head
   (⌀5.6 × 2.4). A cylinder head (≈ ⌀5.5 × 3) would hang 0.6 mm lower and
   leave about 2.2 mm to the floor at the lower stop. Head dimensions and
   length still need confirming.
3. **Spring data.** The end-coil form and the actual rate are not confirmed.
4. **Guide tube fixing** (single board only); in the staircase the housing and
   cover hold everything (§11).
5. **Assembly order.** The tube floor is closed, so the screw has to be
   tightened before the tube goes on.
6. **Thin housing wall** (§10), about 0.7 mm beside each connector pocket.
7. **Washer contact** (§3): the ⌀9 washer rests on a ring only 0.3 … 0.7 mm
   wide.

## 13. Files

| File | Content |
|---|---|
| `pcb.scad` | board, copper (rings, pads, tracks), connector body |
| `pcb.stl`, `pcb_board.stl`, `pcb_copper.stl`, `pcb_connector.stl` | 3D, combined and by part |
| `pcb_12.stl`, `pcb_11.stl`, `pcb_10.stl` | sawn-off boards with 12, 11, 10 holes (`cut_holes` = 1, 2, 3) |
| `pcb.dxf`, `pcb_copper.dxf`, `pcb_copper_top.dxf`, `pcb_drill.dxf`, `pcb_mask.dxf` | outline, bottom copper, top copper, via holes, bottom solder mask openings (all seen from the top) |
| `button.scad` | button, washers, sleeve, screw, guide tube, spring; `travel` sets the position |
| `button.stl`, `washer.stl`, `sleeve.stl`, `screw.stl`, `guide.stl`, `spring.stl` | 3D, moving parts at the upper stop |
| `array.scad`, `array.stl` | four boards as a staircase, k × (10, 17, 4) mm |
| `viewer.html` | 3D viewer of one board with its button assembly: part toggles, travel slider, X/Z section plane, dimensions |
| `cover.scad`, `cover.stl`, `cover.js` | printed cover holding the four boards down; `cover.js` is the geometry for `array.html` |
| `housing.scad`, `housing.stl`, `housing.js` | printed body with 46 guides and an inclined flat floor; `housing.js` is the geometry for `array.html` |
| `array.html` | 3D viewer of the four boards with connectors, housing and cover, no buttons; X/Z section plane |
| `Screw.png` | photo of the screw in hand |

Sources: GCT FFC3A20 drawing (<https://gct.co/files/drawings/ffc3a20.pdf>) and
1.0 mm FFC specification (<https://gct.co/files/specs/1.0mm-ffc-spec.pdf>), via
DigiKey FFC3A20-14-G; Federnfabrik Schmid, *Normfedern* catalogue
(<https://federnfabrikschmid.com/assets/images/products/Federnfabrik-Schmid_Normfedern_Katalog.pdf>).
