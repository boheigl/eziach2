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
| `cover.scad`, `cover.stl`, `cover.js` | printed cover holding the four boards down |
| `main_pcb.scad`, `main_pcb.stl`, `pcb_cable.stl`, `.js` | main PCB with part bodies, the four FFCs to it, floor pockets, openings and pins for the housing |
| `gauge_link.scad`, `gauge_link.stl`, `.js` | two strain gauges (plates) with their pins, link board with its lid and the six wires from the main PCB; the outer holders, pad and pocket are in the housing (§7) |
| `array.html` | 3D viewer of the four boards with connectors, housing, cover and cables; X/Z section plane. Loads the `.js` geometry |
| `Makefile`, `stl2js.py` | `make` builds the files above into `build/discant/`; `stl2js.py` turns an STL into the `.js` geometry for `array.html` |
| `phone.html`, `embed_parts.py` | phone view of the assembly: boards, connectors, housing, cover, cables and one button, with Press, a section and gestures (Interact). `make` writes `build/discant/phone.html` with every part embedded by `embed_parts.py`, one file that loads nothing else, so it also works in the claude.ai viewer on a phone |

## 6. Main PCB [given: in the hole where the cables ran; ESP32-S3-WROOM-1, DAC, 74HC154]

`main_pcb/`: a KiCad project made from one table. `design.py` holds parts, nets and
placement; `gen_sch.py` writes the schematic, `gen_pcb.py` the board, `route.py`
routes it. **In the assembly** [given]: `main_pcb/export_3d.py` (run by make)
exports the routed board in the band frame: laminate and copper from KiCad, and one
body per part from its fabrication outline at the part's height, the ZIFs as
actuator bar, body and nails. No 3D models are installed, so the parts are these
boxes. `main_pcb.scad` imports them; its own boxes remain only as the housing's
pockets and openings. **Not ordered, not bench tested.**

Checked on the exported board: laminate, copper and parts touch neither housing,
cover, boards nor connectors; each film ends inside its ZIF; film 2's edge brushes
the rear top edge of USB-C's body (0.25 mm³, about 0.1 mm), left until the next
reroute. The locating pins stop 0.1 mm under the board's top face, clear of the
ZIFs, on ⌀2.3 pads.

**Board** [chosen]: 52 × 22.5 mm, 4 layers, 1.6 mm, parallel to the hole's floor,
underside 1.1 mm above it, with tabs between the hole-1 tubes for the ZIFs' fitting
nails. Layers: top, GND plane, column bus, bottom. Rules 0.127 / 0.127 mm, vias
0.45 / 0.2 mm.

**Height zones.** Under each cable's film about 1.2 mm is free on the top side:
only 0402 parts and diodes go there. The strip over the films' edge (Y > 8) and
the underside's pocket take the tall parts.

**Cables** [chosen]: all four land on the same **bottom-contact** ZIF, 1.0 mm, 14
way, 2.5 mm high (GCT FFC3B family; footprint JUSHUO AFA07-S14FCA-00), since each
film's conductors face the board after its bend. Bend R2.4, mouths at X = 11.2, 30.3,
49.5 and, underside, 54.9. The 21 mm actuator bar at the mouth is what limits them:
its corners must clear the hole-1 tubes. Close the ZIFs before the board goes in:
the bar moves towards the tube when opened. [unverified: which side the FFC3A20
contacts, so whether the films are same-side or opposite-side contact]

**Key scan** [chosen, 74HC154 given]: as the earlier eziach, the decoder pulls one
of 13 columns low and four inputs with 10 k pull-ups read the board commons. The
contacts are closed at rest, so each key needs its own diode, cathode on the column:
46 Schottky diodes, SOD-882. A hole has the same contact number on all four cables,
so each column is one straight line on the inner layer through all the ZIFs, and a
diode sits at each pin: staggered behind ZIFs 0, 1 and 3, in front of ZIF 2, where
the board ends. At rest a read row is low by the diode's drop, about 0.3 V.
[unverified: the chosen diode type; needs ≤ 0.5 V at 0.33 mA and low leakage, 12
reverse diodes share each pull-up]

**Module:** ESP32-S3-WROOM-1-**N16R8** [chosen]: 8 MB PSRAM and 16 MB flash for the
synthesizer and its soundfont; the earlier instrument used a 1.4 MB SF2 with
FluidSynth on a Pi. [unverified: that the S3 can play it; the firmware does not exist
yet] No radio [given]. On the underside, turned so its USB pins face the connector
and its short end the logic.

| Function | GPIO | | Function | GPIO |
|---|---|---|---|---|
| Rows 0–3 | 15, 16, 17, 18 | | I²C SDA, SCL | 9, 8 |
| Decoder A0–A3 | 47, 48, 21, 14 | | Link interrupt | 7 |
| I²S MCLK, BCLK, WCLK, DOUT | 10, 11, 12, 13 | | DAC reset | 6 |
| USB D−, D+ | 19, 20 | | Battery voltage | 1 (ADC) |

Free: GPIO 2, 3, 4, 5, 38–42, 45, 46. Not usable: 33–37 (PSRAM). Test pads for boot,
reset, TX and RX. No boot button: the housing is closed, so firmware goes over USB;
if a bad image blocks that, the boot pad needs the board out.

**Audio:** TLV320DAC3100 (VQFN-32) [proposed earlier, chosen]: its headphone driver
gives 20 mW into 32 Ω, 60 mW into 16 Ω [datasheet]. 3.3 V analog behind a ferrite,
1.8 V core, speaker supply at 3.3 V as the datasheet asks for it not below AVDD, the
speaker amplifier unused. Output AC coupled with 100 µF, 50 Hz at 32 Ω. MCLK is wired
so that nothing rests on running the PLL from BCLK. [unverified: unused pin handling
and decoupling values are not in the datasheet's text; taken from usual practice]

**Power** [chosen, assuming a 1S Li-ion battery in the bass module]: a P-MOSFET passes
the battery unless USB is present, a Schottky feeds from USB. TLV75533 to 3.3 V
(500 mA), TLV75518 to 1.8 V. The battery runs down to about 3.4 V before 3.3 V sags.
Battery voltage is read through a 1 M / 1 M divider.
[unverified: TLV755 pinout, taken from the family's usual order; check the datasheet]

**USB-C** [given: firmware]: GCT USB4105 at X = 36.2 … 45.2, just past the module: its
shield legs would otherwise land on the module's pads. 5.1 k on CC, ESD array.
**Jack** [given]: moved to X = 26.1, the same place in the staircase's 19.1 mm period.
**Wires:** the six to the link board and three to the jack solder to pads: an 8 mm wide
connector does not fit the 5 mm strip. Trade-off: desoldering to take the board out.

**Assembly** [given: no access from the bottom]: plug the cables into the
PCB, then the PCB's cables into the boards in the upside-down cover, and set
it all onto the housing. Four pins in the floor locate the board.
[unverified: that the board stays put; foam under the ribs proposed]

**State of the board** (route.py, then KiCad's DRC with the schematic):
- **Schematic:** 104 parts, ERC without errors. Every pin ends in a global label,
  so the drawing is the table, not a readable circuit diagram yet.
- **Placement:** every pad on the board. In the assembly the board, its parts and
  the cables touch neither housing, cover nor connectors.
- **Routing:** 1709 track segments and 185 vias on four layers; no clearance, hole or
  short errors; **17 connections still open**, all in the crowded patch round the
  DAC and the USB pins: GND (3), +3V3A (2), USB D+ (2), I²S WCLK and DOUT, SCL,
  +1V8, DAC reset, HPL, HPR, the jack's right channel, row 2 and column 12. The
  router has no rip-up; these are for KiCad by hand.
- **Known DRC items:** diodes 0.5 mm inside the ZIFs' courtyards (the diodes stand
  beside the tails, physically clear), the wire pads' courtyards overlap each other,
  four pads 0.002 mm under the 0.127 mm clearance at the USB connector's rear and
  its shield legs 0.002 mm inside the 0.25 mm edge clearance (both corrected in
  design.py, not yet rerouted), unconnected ZIF contacts named differently in the
  schematic and the board (38 parity warnings, no wrong connections).
- **Make it:** `python3 gen_pcb.py && python3 gen_sch.py && sh build.sh` (about 45
  minutes; six tries, keeps the best).

**Open:** power switch (none yet; it could sit in the bass module); charging;
whether the wire pads should become connectors; the items marked above.

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
- **Link board** [chosen]: beside the gauges, about 100 mm from the main PCB: NAU7802 for
  both half bridges, MCP23017 for the bass keys (9 lines as 3 × 6). Six wires reach it:
  battery +, ground, 3.3 V, SDA, SCL, interrupt. They run behind cable 3 to the
  hole's back corner and along a ⌀2.6 bore inside the back wall (2 mm of wall each
  side), straight into the board's pocket.
- **Pocket** [given: the readout housed, in the housing, no screws]: the board, 20.5
  × 13.5 mm, lies in a pocket in the back wall, x = −75.7 … −51.2, z = −6.85 … 7.25,
  y = 54 … 59.3, so nothing stands out of the back face. Walls left: 1.3 mm to the
  guides' line, 0.8 mm under board 3, 0.9 mm over the bottom plane, 1.2 mm to the
  pad's end. Corner ledges carry the board, ribs at its ends locate it, and a
  1.2 mm lid flush with the back face snaps in with a hook at each end and keeps
  it there. [chosen] [unverified: the hooks, printed] The gauges' leads leave the
  plates towards the pad and run in a 3.2 × 1.5 mm groove in it, into the pocket
  through a notch in its +x wall, which the wires to the connector leave by too.
  Under the plates' edges the groove runs behind a 1 mm
  strip, the plates' stop; elsewhere it is open to the pad's face or the holders.
- **Connector** [chosen]: 12 contacts: 9 keys, battery +, ground, a spare ground
  or sense. Spring pins on flat pads, two rows of 6. A separate lock with no play
  in either direction carries the load, not the contacts. [unverified: current
  rating] The wires from link board to connector cross the gauge as a soft loop.
- **Open:** overload stop; the lock (no play either way);
  charging; a diode at each of the 18 bass keys: the contacts are closed at rest, so without
  diodes the 3 × 6 matrix joins every row to every column and no key can be told
  apart. They would sit in the bass module, with no change to the connector.
  [unverified: not designed yet]

Checked by solid intersection: wires, plates, pins,
link board and lid touch nothing but what they are fixed to, and the paths of
plates and inner holders into the outer holders are free.
