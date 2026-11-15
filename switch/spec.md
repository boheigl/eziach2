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
connector sits at the −X end. Every part uses this frame.

## 2. Board

| | | |
|---|---|---|
| Thickness | 1.6 mm, FR4 | [given] |
| Holes | 13 × ⌀8 in one row, 20 mm pitch, centres x = −120 … +120 | [given]; ⌀8 since the switch to ⌀9 washers |
| Outline | 278.1 × 14.7 mm, x = −145.8 … +132.3, y = −5.3 … +9.4: the row of holes sits off centre towards −y | [chosen] |
| Screw holes | 10 × ⌀2.2 on the row line y = 0 [given]: x = −142.0 (−x end), −50, 50, 30, 10, −10 (middle), 130, 110, 90, 70 (+x end of the 13/12/11/10-hole board); each board uses four | [chosen] |
| Material between holes / hole to the −y, +y edge | 12 mm / 1.3, 5.4 mm | derived |
| Connector tab | x = −145.8 … −142.0, out to y = 10.6: carries the connector's highest corner past the +y edge | [chosen] |

The width is set by what lies across the board: on the +y side the copper
ring (to r = 5), 0.4 mm to the first track's centre, the thirteen tracks at
0.3 mm pitch and 0.3 mm to the edge make 9.4 mm; on the −y side the ring and
0.3 mm make 5.3 mm. With the 16 mm step that leaves 1.3 mm between neighbouring
boards. **The row sits off centre towards −y** so that in the staircase a
1.2 mm cover wall fits in front of each board, 0.4 mm clear of its own caps;
dents keep it from the caps of the board below (discant/spec.md §3). Every screw passes through the board on
the row line [given]: at +x half a pitch past the last hole, the board ending
2.3 mm beyond (12.3 mm past the last hole); at −x left of the turned
connector, 0.5 mm clear of its pads and 1.0 mm of its body. At −x the board
reaches to the connector body's corner, x = −145.8.

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
from y towards −x so that its long side lies exactly along the normal of the
housing's slanted −x face** [given], (−16, 10)/18.9: atan(16/10) = 58.0°, for
the cabling. The −x end lies under no higher board or guide in the staircase
and is never sawn off.

- Centre (−135.7, 2.47). Its lowest corner, at y = −5.0, stays 1.6 mm clear
  of the board below in the staircase (its +y edge is at y = −6.6 in this
  frame). [chosen]
- Its body keeps 5.7 mm from hole 1's centre: the ⌀9.4 guide bore, a 0.7 mm
  housing wall and 0.3 mm pocket clearance. [chosen]
- Body corners (−128.0, −5.0), (−125.6, −1.2), (−143.4, 9.9), (−145.8, 6.1):
  the board ends at its −x corner, and a tab 3.8 × 1.2 mm carries the corner
  at y = 9.9 past the +y edge. The tab ends at y = 10.6, so the slanted −x face
  of the staircase, the main PCB and the cables do not depend on the board's
  width.
- Two pad columns, 3.5 mm apart, turned with it; contacts along the long
  side, **contact 1 at the (−x, +y) end, contact 14 at the end nearest
  hole 1**. All pads lie on the board.
- The housing is assumed centred on the pad pattern. [unverified]

## 5. Tracks

Signal tracks on the underside, **0.15 mm wide on a 0.3 mm pitch**, so 0.15 mm
apart; the common on the top copper. [chosen] The board is **two-layer**.

- **Contact 1 is the common:** it joins the −Y halves of all 13 rings. [given]
- **Contacts 2 … 14** each take the +Y half of one ring. [given]

- **All thirteen signal tracks** run in the band between the rings and the +y
  edge (y = 5.4 … 9.0; the farther the hole, the higher). Each turns
  where its contact's line meets it and runs straight down that line into the
  outer end of its inner pad: **hole h → contact 15 − h**, so hole 1 takes
  contact 14, the one nearest it. The lower the track, the further right it
  turns (x = −126.2 … −138.1), so none cross; the slanted runs lie 1.0 mm
  apart and clear hole 1's ring by 3.0 mm. Straight runs have square ends,
  the slanted ones round ones.
- **Common:** a via in the middle of every −Y half (y = −4.5), a straight bus
  on the top copper along y = −4.5 to the connector's centre line, along it
  between the two pad columns to a via at contact 1, and a short bottom track
  into its pad. Vias ⌀0.3 drill / ⌀0.6 pad, tented.

**Checked on the exported copper of both layers:** at least 0.15 mm between any
two separate copper shapes, for the full board and the 10-hole sawn-off one;
the bottom copper falls into exactly the expected 41 shapes (13 signal nets,
14 unused outer pads, 13 −y halves with their vias, the common's pad 1).
Rings and pads are bare copper; `pcb_mask.dxf` gives the openings.

## 6. Button assembly (middle hole)

Button, washers, sleeve and screw move together along Z.

| Part | Dimensions | z range at rest | Source |
|---|---|---|---|
| Button stem | ⌀7.6 (0.2 mm clearance in the ⌀8 hole) × 6.835 | −0.835 … 6.0 | [given] |
| Button cap | ⌀15 × 2, upper edge R0.5 | 6.0 … 8.0 | [given] |
| Felt ring | ⌀15 (as the cap) / ⌀7 × 1, punched felt, pushed onto the stem from below against the cap; damps the lower stop | 5.0 … 6.0 | [given] felt, ≈ 1 mm [chosen] size |
| Upper washer | M3 to ISO 7093 / DIN 9021: ⌀9 / ⌀3.2 × 0.8, metal | −1.635 … −0.835 | [given] |
| Spacer sleeve | ⌀7 / ⌀4.2 × 5, plastic (M4 sleeve) | −6.635 … −1.635 | [given] ⌀7 × 5, bore assumed, see §9 |
| Lower washer | the same | −7.435 … −6.635 | [given] |
| Screw | M3 × 12 self-tapping for plastics, head below the lower washer | head −9.835 … −7.435 | [given] type, [chosen] length |
| Pilot hole in the stem | ⌀2.5 blind, 6.4 deep, 1 mm past the screw tip | | [chosen] |

The z ranges include the 0.035 mm the assembly sits below the drawn
position at the upper stop (see §7). The screw engages 5.4 mm in the button,
2.4 mm of cap remains above the pilot hole, and the ⌀7.6 stem keeps 2.55 mm
of wall around it.

**The upper washer is the switch contact:** at rest it bears on both
half-rings of the middle hole and bridges them. It must stay metal and on top.
[given]

**Why a sleeve between two washers:** the assembly is guided at two points,
the stem in the board hole and the washers in the guide tube. With the two
washers stacked directly, those points were only about 3.2 mm apart overall.
The button could tilt about 7°, and a press more than 4–5 mm off centre could
jam it at the start of the stroke (friction taken as 0.3–0.4). With the 5 mm
sleeve and the cover guide 1.2 mm above the board they are about 9.5 mm
apart. The tilt drops to about 2.5°, and jamming would need a press 11–15 mm off centre, outside the cap. [estimated]

## 7. Travel

| | |
|---|---|
| Upper stop (rest) | upper washer on the copper rings; stem face 0.035 mm below the laminate |
| Lower stop | felt ring under the cap on the cover's top face (1.2 mm above the board); the felt damps the stop [given] |
| Stroke | 2.965 mm to first felt contact (3 mm wanted [given]; the 1 mm felt and the unchanged stem give 2.965), then a little more as the felt gives |

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
the discant's housing (discant/spec.md §2) replaces it.

**Spring** [given]: ⌀8 outside, 0.4 mm wire (⌀7.2 inside), 25 mm free
length, 8 active coils. It stands on the floor inside the collar and pushes
the lower washer up. It surrounds the screw head.

| | | |
|---|---|---|
| End coils | one closed dead coil each end, 10 coils in all, solid ≈ 4 mm | [unverified] |
| Rate | ≈ 0.074 N/mm, spring steel G = 81 500 N/mm² | [estimated] |
| Initial force at the upper stop | 120 g = 1.18 N | [given] |
| Preload | 15.9 mm → 9.15 mm long at rest, 6.18 mm at the lower stop | derived |
| Force at the lower stop | 1.40 N = 142 g, +19 % over the stroke | [estimated] |

The user's aim is about 120 g at the start of the press that hardly rises
over the stroke. That calls for a soft spring, heavily preloaded. The floor,
and with it the tube length, is computed from the wanted initial force
(`spring_f0`). Each 0.1 N of error in the rate moves the floor by about
1.35 mm, so the tube should be re-checked once the real spring rate is known.

At the lower stop the spring is 2.18 mm clear of solid in all, about 0.27 mm
per gap. That is 0.07 mm short of the DIN EN 13906-1 minimum length
(≈ 6.25 mm); the coils do not touch.

Springs considered and rejected: ⌀10 × 1 × 20 (5 active coils, ≈ 4–15 N, far
too stiff); ⌀10 × 0.5 × 40 (needed a 38 mm tube); ⌀8 × 0.4 × 10 (too short
for 120 g); ⌀8 × 0.4 × 15 (5 active coils: goes solid at 120 g); 0.8 × 8 × 20
and 0.6 × 10 × 10 (too stiff, ≈ 330–1250 g at full stroke). In the
Federnfabrik Schmid catalogue of standard springs ("similar to DIN 2098"),
none combined the fit over the screw head, 120 g and a flat force curve.

## 9. Open points

1. **Spacer sleeve.** A plastic sleeve ⌀7 × 5 [given]; the bore (≈ 4.2, as
   an M4 sleeve) is assumed. Any bore from 3.2 to about 5 works: the washers
   centre the screw, and the sleeve only has to bear on their annulus.
   Polyamide creeps under the clamp load, so tighten moderately and use medium
   thread-lock.
2. **Screw.** The real screw (`Screw.png`) has a cylinder head with hex
   socket and a coarse, sharp thread for plastics, which suits the button. It
   must be **at most 12 mm** under the head. The model still has a pan head
   (⌀5.6 × 2.4). A cylinder head (≈ ⌀5.5 × 3) would hang 0.6 mm lower and
   leave about 2.2 mm to the floor at the lower stop. Head dimensions and
   length still need confirming.
3. **Spring data.** The end-coil form and the actual rate are not confirmed.
4. **Guide tube fixing** (single board only); in the staircase the housing and
   cover hold everything (discant/spec.md §3).
5. **Assembly order.** The tube floor is closed, so the screw has to be
   tightened before the tube goes on.
6. **Washer contact** (§3): the ⌀9 washer rests on a ring only 0.3 … 0.7 mm
   wide.

## 10. Files

The sources lie in `switch/`. `make` (or `make -j`) in `switch/` builds every
STL and DXF below into `build/switch/` at the top of the repository (not under
version control), rebuilding only what changed. The discant (`discant/`) uses
these parts: the boards, the connector body and the button assembly.

| File | Content |
|---|---|
| `pcb.scad` | board, copper (rings, pads, tracks), connector body |
| `pcb.stl`, `pcb_board.stl`, `pcb_copper.stl`, `pcb_connector.stl` | 3D, combined and by part |
| `pcb_12.stl`, `pcb_11.stl`, `pcb_10.stl` | sawn-off boards with 12, 11, 10 holes (`cut_holes` = 1, 2, 3) |
| `pcb_board_12.stl` … `pcb_copper_10.stl` | the same sawn-off boards, laminate and copper apart (for the discant's phone page) |
| `pcb.dxf`, `pcb_copper.dxf`, `pcb_copper_top.dxf`, `pcb_drill.dxf`, `pcb_mask.dxf` | outline, bottom copper, top copper, via holes, bottom solder mask openings (all seen from the top) |
| `button.scad` | button, felt ring, washers, sleeve, screw, guide tube, spring; `travel` sets the position |
| `button.stl`, `felt.stl`, `washer.stl`, `sleeve.stl`, `screw.stl`, `guide.stl`, `spring.stl` | 3D, moving parts at the upper stop |
| `viewer.html` | 3D viewer of one board with its button assembly: part toggles, travel slider, X/Z section plane, dimensions |
| `Makefile` | builds the files above into `build/switch/` |
| `Screw.png` | photo of the screw in hand |

Sources: GCT FFC3A20 drawing (<https://gct.co/files/drawings/ffc3a20.pdf>) and
1.0 mm FFC specification (<https://gct.co/files/specs/1.0mm-ffc-spec.pdf>), via
DigiKey FFC3A20-14-G; Federnfabrik Schmid, *Normfedern* catalogue
(<https://federnfabrikschmid.com/assets/images/products/Federnfabrik-Schmid_Normfedern_Katalog.pdf>).

## I2C expander on every key board [given] (`ioexp = true`, the default)

Each key board (4 in the discant, 2 in the bass) gets its own expander at the connector
(tab) end; the 14-way FFC becomes a 5-wire bus cable (3.3 V, GND, SDA, SCL, INT),
plugged into each board (JST SH). The discant's key board in the hole (discant/main_pcb/, two
PCAL6524) and the bass's key board and its 15 mm FFC tunnels then go.

Part: **NXP PCAL9555A** (datasheet Rev. 2, 19 Dec 2014): 16 I/Os (a board has at most
13 keys), 100 kΩ pull-up/down selectable per pin (typ.; 50–150 kΩ), open-drain INT,
address 0100 A2 A1 A0 = 20h…27h (A0–A2 straight to VDD or VSS: eight boards possible,
set per board by solder jumpers). Package HWQFN24 (PCAL9555AHF, SOT994-1, 4 × 4 ×
0.75 mm; centre pad = VSS) or TSSOP24 (PCAL9555APW, SOT355-1). HWQFN24 pins: P0_0–P0_7
1–8, VSS 9 (+ centre pad), P1_0–P1_7 10–17, A0 18, SCL 19, SDA 20, VDD 21, INT 22,
A1 23, A2 24.

**Layout** (`ioexp_layout.py` writes `ioexp.scad`, which `pcb.scad` includes; `make`
fails on a clearance violation): the chip on the bottom face at (−130.3, 1.0), where the
FFC connector was; seen from the top its pins run clockwise. The thirteen key tracks
come from the +y band as before: the four lowest (holes 1–4) round the chip's east side
to its south pins, the next five (5–9) into its east pins, the four highest (10–13)
down into its north pins; nothing crosses. Unused: P0_0, P0_1, P1_7.

**Bus connector** [given: connectors instead of soldered wires]: **JST SH, 5 pins, 1.0
mm pitch, vertical SMT, BM05B-SRSS-TB**, on the bottom face west of the chip, footprint
centre (−137.9, −2.8), pins along x (land pattern as KiCad's: pads 0.6 × 1.55 at 1.325
from the centre towards +y, two fixing pads 1.2 × 1.8 at ±3.3). Pins from −x: 1 INT,
2 3.3 V, 3 SDA, 4 SCL, 5 GND. The header is 4.25 mm high; its plug (SHR-05V-S, crimp
contacts SSH-003T-P0.2 for AWG 32–28, or a ready-made lead) comes in from below, so the
cable leaves downwards, 5.85 mm under the board [unverified: the mated height, taken as
header + 1.6]. The west pins SCL, SDA, VDD, INT run straight west and down into pins
4…1; GND by a via under the header to the top copper.

Three solder jumpers set the address (A2, A1 north-west of the chip, pads along y; A0
south of it, pads along x; the middle pad is the pin, bridged to VDD or GND); a 100 nF
0402 beside A2. VDD to the jumpers on the top copper from a via on the bus's VDD run.
GND on the top copper: the common bus along y −4.5 goes on to the connector's GND via,
to a via in the centre pad and to the jumpers' GND vias. Clearances: 0.15 everywhere
(the closest pairs are the band's parallel tracks), 0.3 to the board edge, 0.5 to the
screw holes. The outline, tab included, stays as for the FFC connector (the housings
depend on it). The housings have a pocket under each board's −x end for the chip and
the jumpers (3 mm) and for the header with its plug (7.7 × 3.6, 7.85 mm deep). `ioexp =
false` builds the FFC version.

Not updated: `viewer.html` still shows the FFC version.
