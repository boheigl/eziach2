# Strain-gauge load cell — design record

What was decided, and why. Numbers are tagged by where they come from:
**[STEP]** read from the CAD file, **[given]** stated by the user, **[chosen]**
a design decision made here, **[unverified]** still to be confirmed.

---

## 1. Source geometry

`StrainGauge.step` (Onshape AP242 export) is the authoritative geometry. It was
read segment by segment — 28 profile segments, 14 lines and 14 arcs — and
rebuilt in `strain_gauge_plate.scad`.

`StrainGauge.png` is only a render of the same part. It views it **turned 90°**
from the CAD orientation and shows lead wires the STEP does not carry. It is
not a dimensional source; an earlier reconstruction from it had the right
topology but none of the right dimensions.

**Coordinate system [chosen]:** origin at the centre of the plate in all three
axes, so the plate runs z = −1.25 … +1.25. This is 1.25 mm below the STEP,
which places the plate from z = 0 upwards. Geometry is otherwise identical.
Both holders use the same frame.

**The bought cell differs [measured 2026-11-21]:** 30 × **23.3** × 2.5. Its arms and the
W's bottom block end 1.7 mm earlier at the open edge, so the plate runs y = −10.8 …
+12.5; the slots' closed ends and the top are as in the STEP, and the origin stays
the STEP's centre. `strain_gauge_plate.scad` models the bought cell (`shorter = 1.7`;
0 gives the STEP). Its lead is glued along the whole column, across its full width:
**4 mm thick there, 1.5 proud of one face**; the glue at most 7.1 wide, 19 long from
the +y edge, so over y = −6.5 … +12.5: the bridge and the column down to the inner
slots' closed ends (photo, measured 2026-11-21). In the inner holder's recess (9 wide,
from y = −8) it keeps 0.95 to each side and 1.5 behind its end; it touches no web.

## 2. The plate

| | | |
|---|---|---|
| Envelope | 30 × 25 × 2.5 mm in the STEP; the bought cell 30 × 23.3 × 2.5 | [given], confirmed [STEP]; [measured 2026-11-21] |
| Slot width, arm width, web width | 3.00 mm — all three | [STEP] |
| Corner radii | R1.5 throughout, R3 at the two +y corners | [STEP] |
| Volume | 1337.93 mm³ | [STEP] |

Two hairpin slots open at the −y edge, run up the plate, turn across at y = 5
and return to a closed end at y = −5. Slot walls at x = ±3, ±6, ±9, ±12; outer
edges at ±15. Mirror-symmetric about the vertical centre line.

Every free end is a half-round of the 3 mm module, flush with the envelope —
the whole part is built on that one dimension.

## 3. Load case [given]

Outer arms (|x| = 12…15) fixed. Force applied **normal to the plate face** at
the inner ends — the web tips at (±7.5, +3.5).

## 4. Strain gauges

**Half bridge, two gauges back to back on the central column, centred at
y = −3.5** — one on each face, directly opposite. [chosen]

Why that arrangement:

- The two faces of a bending member strain equally and opposite, so the pair
  adds in adjacent bridge arms without relying on any dimensional coincidence.
- The column is on the symmetry axis, so uneven load sharing between the two
  webs cannot bias it.
- An axial component strains both faces alike and therefore cancels — the
  bridge reads pure bending.
- Both gauges sit at the same point, so they track thermally.

Why that station: moment in the column is M(y) = P·(3.5 − y). It is zero level
with the load at y = +3.5 and peaks at the lower root, y = −6.5. Sitting at
y = −3.5 keeps about 70 % of the peak while staying ~3 mm clear of the slot end
and its stress concentration.

First-order sizing, steel: σ ≈ 1.12·P MPa, so roughly 5.6·P µε (16·P in
aluminium). ~1100 µε full scale lands near 200 N. [unverified — ignores the
fillet concentration and block compliance]

**Open:** gauge polarity follows from the fold but has not been measured.
Confirm by loading the part and watching both gauges before committing the
bridge wiring. [unverified]

A half bridge needs three leads (E+, E−, mid-tap). The render shows two, which
cannot drive one — assume the render is schematic.

## 4a. The bought load cell [given 2026-11-15]

The plate with its gauges is a stock part: the half-bridge load cell of bathroom
scales, from a bathroom-scale set of four plates (two used, two spare)
[given 2026-11-26]. The seller's data:

| | |
|---|---|
| Range | 50 kg (490 N); overload 150 % (735 N) |
| Bridge | half bridge, 3 wires (E+, middle, E−); 1000 ± 10 Ω |
| Output | 1.0 ± 0.15 mV/V at full range; zero ±0.3 mV/V |
| Linearity, hysteresis, repeatability | 0.2, 0.2, 0.1 % F.S. |
| Creep | 0.1 % F.S. in 3 min |
| Zero drift, span drift | 0.3 % F.S. per 10 °C each |
| Excitation | 5–10 V DC (3.3 V here, see below) |
| Temperature | −10 … +40 °C |
| Leads | 45 cm (cut to 19 mm here) |

What follows from it:

- **Material and making** need no choice: steel and gauges come made. §4's beam
  estimate (1100 µε at about 200 N) is replaced by the seller's 1 mV/V at 490 N, about
  2 µε/N. The bought cell's plate is 30 × 23.3 × 2.5, its arms 1.7 shorter than the
  STEP's, its lead glued 1.5 proud on the column [measured 2026-11-21; §1].
- **Signal at 3.3 V excitation** (AVDD, ratiometric): 3.3 mV at 490 N, **6.7 µV/N**.
  Playing forces of 20–40 N give 0.13–0.27 mV; the NAU7802's 150 nV at 80 SPS
  resolves about 0.02 N, over a thousand steps in 30 N. Below the seller's 5 V, but a
  bridge has no lower limit; only the signal scales.
- **Overload:** the rating is a moment: 490 N at the cell's 7 mm arm, 3430 N·mm, and
  150 % is 5145 N·mm. On the instrument the hand acts 56–125 mm away: 100 N there is
  6400–12 500 N·mm on the two cells, past the 150 % at the top of the hand plate and on
  one cell off centre. [2026-11-20; it read "a fifth of the range, no stop" before,
  comparing forces.] Hence the overload stops (`../assembly/spec.md`).
- **Resistance [measured 2026-11-21]:** red–yellow 1 kΩ, black–yellow 1 kΩ, black–red
  2 kΩ: yellow is the middle, red and black are E+ and E− (which is which is the
  firmware's sign), and the seller's 1000 Ω is **per gauge**.
- **Current:** 1.65 mA per cell at 3.3 V across its 2 kΩ.
- **Drift is the weak point:** 0.3 % F.S. per 10 °C is 1.5 N per 10 °C, as much as a
  soft note. The firmware tares at start and keeps re-taring while no key is pressed
  and the force is steady; the hand warms the cells slowly. Measured on the assembled
  instrument (`../firmware/spec.md` §4: `force track off`, `force log on`), TODO 21.
- **Polarity:** find the leads by resistance (E+ to E− is the largest), wire them to
  E+, middle, E−; which way a push goes is the firmware's sign, set once by pressing.
  Nothing in the hardware depends on it.

## 5. Inner holder — `inner_holder.scad`

Grips the W-shaped inner part and introduces the load. **23 × 21.2 × 11.8 mm**.

| Decision | Value | Why |
|---|---|---|
| Slides on from −y | mouth faces +y | the slots are open at that edge |
| Wall above and below | 4.5 mm | [given: thicker for strength under a strong push; was 3] |
| Closed box | side walls run inside the open slots at \|x\| = 9.2…11.5 | far stiffer than a bare C, and the slots are the only through-opening available |
| Fit to the W | 0.2 mm per side, 0.15 mm per face, and crush ribs | FDM; the walls guide along 17 mm of web, so tighter binds rather than grips. [2026-11-25: the test print rattled across and sideways and the holder tipped on the W] Half-round ribs (r 0.4) along y, 0.25 proud, on both side walls (0.05 into the plate's way) and, for the detent, on the floor over the webs (0.1); they give as the plate goes in. Across, the cam's shoe clamps the plate (Latch) |
| Clearance to the outer arms | 0.5 mm | must never touch — they are the fixed side |
| Mouth corners | R2 on the two vertical edges | [given] |
| Lead-in flare | 0.6 mm over 1.5 mm | printed parts catch on the first layer otherwise |

**Gauge recess:** 9 × 12.5 × 1.8 mm in the inner face of each plate, from y = −8
forward, opening at the mouth. 9 mm wide puts its edges mid-slot — 1.5 mm clear
of the column and 1.5 mm clear of the webs — so the inner holder never touches the
member being measured. That member stays free to bend; clamping is left to the
webs and the bottom block, which the inner holder still holds over y = −11.0 … −8.
The depth is the bought cell's glued lead [measured 2026-11-21]: 1.5 proud of one face
along the whole column, 0.45 clear with the 0.15 fit; in both faces, so the plate goes
in either way up (1.0 before, for the bare plate). 2.7 mm of wall stays over it.
The bought cell's bottom block is 1.7 shorter, so the bridge is 5.7 thick instead of 4:
the holder's back (y = −16.7), the latch tongue's root and the bass's socket stay put.

**Note on the mechanics:** because the inner holder clamps the webs, they no longer
act as cantilevers. The flexing members become the column and the arms. The
gauge placement is unaffected — the column flexes either way.

**Latch and clamp** [given: in both positions of the bass; 2026-11-25: the test print's
spring tongues neither clicked in nor held, tongue and tooth small and limp, and the plate
rattled; given: a lever or cam, by hand]. `latch`:
- **`"cam"`, playing:** a pressure shoe in the top wall, a **U across the plate** (x ±8.5,
  y −11.0 … −4.0): solid over the W's bottom block, its legs over the webs (|x| 4.5 … 8.5)
  and its middle bridging the clearance over the glued lead. It hangs back to the bridge
  on a 0.8 mm flexure, narrower (x ±5.5, 4.5 long, its root at y −15.5, a 0.4 slot under it,
  R0.5 above); the top wall's rails either side (|x| 9 … 11.5) stay whole and join the side
  walls to the front. At rest its underside stands 0.1 over the pocket's ceiling; a cam
  pushes it 0.25 onto the plate and clamps block and webs between shoe and floor over 7 mm
  of their length: no play across, and the holder cannot tip on the W. [2026-11-25: the
  first shoe (x ±5.5, to y −6.6) clamped the block alone, over 4.4 mm.] The cam presses on an **M2 × 3 grub screw** (ISO 4026) in a
  ⌀1.6 tap drill in the shoe at y −9.0 (0.6 of shoe left under it, so it never reaches the
  plate; its top 0.5 over the shoe's): its height sets the clamping force, so the print's
  tolerances do not. [2026-11-25: an M3 at y −9.3 left 0.2 of wall behind its thread's root
  to the shoe's back and broke into the clearance over the lead; the shoe is solid from
  y −11.0 to −7.0, the M2's tap drill 1.2 from either end.] The cam is one of the bass's
  lever (`../bass/link.scad`) on a ⌀2 steel axle through two lugs on the rails (|x| 9 … 11.5,
  axle at y −9.0, z 7.2, top 9.0),
  their underside rising at 45°, the hole pointed upwards in the print. Over the glued lead
  the shoe is cut back as the top wall is, by the 0.25 stroke more, but only from y −7.0
  (the top wall's recess from −8): the glue reaches −6.5 at most. Over the recess the
  shoe clears the lead by 0.45 when pressed. A tooth as well was given up: it needs 0.7 of
  travel, the clamp 0.25, and a shoe hinged at its back tips by 10° over 0.7 and then
  bears on its front edge. So the playing joint holds by friction [estimates: the screw set
  for about 45 N, PETG on steel μ 0.3, both faces: about 27 N per holder against pulling
  off, 55 N for both; the flexure 0.6 % at the stroke; the lugs about 3 MPa].
- **`"detent"`, stored:** a spring tongue in the top wall each side (3 × **1.5** mm
  [2026-11-25: was 1.2], from its root in the bridge at y −15.5 to its tip at −4.2, in a
  0.5 mm slot, bending into a relief in its own wall), its tooth (1 × 1.3 mm, 0.6 mm into
  the plate's thickness) at x = 4.2 … 5.2 in the inner slot between web and column, its
  retaining face at 45°, y = −6.28, just ahead of the slot's closed end. Sliding on, a
  ramp lifts it over the bottom block; at the end it drops into the slot. It touches only
  the W (1.0 mm clear of the column), so the measured path is unchanged. A bar across the
  slot 0.75 over the tongue is its stop [2026-11-25: 0.85]. Root strain 1.6 % at the
  tooth's 0.6 lift, 1.95 % at the stop [estimate: cantilever loaded at the tooth, 9.2 mm
  from the root; PETG takes about 2–3 % repeated]. Four hold the stored discant with
  about 30 N [estimate: twice the 1.2 tongue's 15 N, (1.5 / 1.2)³] against its 3.5 N
  weight. With the floor's crush ribs it sits without play.
- `"none"`: neither.

Checked 2026-11-25 (solids): in the bass, the plates touch the holders only at the crush
ribs (0.05 at the sides; the floor's 0.1 in the stored socket); the lever clear of case,
discant, axle and back cover from locked to 90° up. **Material: PETG** [given 2026-11-15].

## 6. Outer holder — `outer_holder.scad`

Takes the two fixed arms. One piece. **38.4 × 26.1 × 10.8 mm**, 0.5 of the length
inside the pad. **Printed as part of the discant's housing** [given]: its +y end
grows out of the gauge pad on the back face (`discant/gauge_link.scad`), so
nothing fixes it there, and it cannot slide on. The plate slides in instead.

| Decision | Value | Why |
|---|---|---|
| Plate slides in from −y, +y edge first | same side as the inner holder; the jaws are open channels | follows from being part of the housing [given] |
| Material above, below, outboard | 4 mm | [given] |
| Jaw inner face | x = 12 | flush with the arm, 0.5 mm clear of the inner holder |
| Two yokes | over and under the plate, y = 5.5…12.5, z = ±3.2…±5.4 (2.2 thick) | [given]; a pair rather than one ties the jaws symmetrically. Depth follows from keeping 1 mm back from the inner holder |
| Lead gap between yokes | 6.4 mm, 1.95 mm clear of each plate face | the leads pass through here; the bought cell's glued lead (1.5 proud of one face) runs under them, 0.45 clear [measured 2026-11-21; was 4.8] |
| Stop | the plate's +y edge on the pad, on strips either side of each jaw | replaces the earlier stop wall at −y |
| Retention | a dowel pin ⌀1.5 × 10 (ISO 2338) across each jaw, 0.05 mm beyond the arm's tip | [chosen]; keeps the plate from pulling out |
| Plate fits | as the inner holder, with crush ribs | same process. [2026-11-25: the test print rattled] Half-round ribs (r 0.4) along y in each jaw, 0.25 proud: on the floor under the arm (0.1 into the plate's way) and on the outboard face (0.05); they start at nothing where the plate enters |

The yokes sit **across** the plate rather than beyond it, so nothing projects
past the +y edge. In y they occupy the one stretch of plate that neither the
inner holder (ends at y = 4.5) nor the arm pockets claim, holding 1 mm back from it.

Earlier alternatives, and why they were dropped: a yoke beyond the +y edge
projects past the plate; a yoke behind the −y edge reverses the assembly order
and lengthens the part; two separate jaws avoid the order constraint but give
up the cross-tie.

## 7. Assembly

1. **Plate first**, into the outer holder from −y, leads ahead of it, until its
   +y edge lands on the pad. It passes between the yokes, which the inner holder,
   11.8 mm tall where the gap is 6.4, cannot do.
2. **Inner holder second**, onto the W from −y.
3. **Dowel pins**, one across each jaw.
4. Leads leave in +y: along the recesses, out of the inner holder's mouth, across the
   plate, through the gap between the yokes, into the groove in the pad, which takes
   them to the link board (`discant/gauge_link.scad`). On the bought cell the lead is
   glued along the column, 1.5 proud of one face; it clears the recess ceiling and the
   yokes by 0.45 mm. [measured 2026-11-21]

This order is forced by the geometry, not a preference.

## 8. Manufacturing [given]

Both holders are FDM printed. All plate clearances are set for that: 0.2 mm per
side, 0.15 mm per face, and crush ribs take up the play [2026-11-25: the test print on
the X2D rattled with the clearances alone]. For precision machining use 0.05–0.1 mm per
side and no ribs; for SLA, 0.15.

**Print the inner holder standing on its closed end, mouth up.** The pocket is
then a blind slot opening upwards — nothing to bridge or support — and both
fitted dimensions lie in the machine's XY plane. Printed the other way up, the
top plate has to bridge 18 mm and lands rough on the face that grips the plate.

**Open:** whether PLA/PETG is stiff enough. The inner holder carries the test
force; if it yields, the calibration shifts. [unverified]

## 9. Verification

Every STL was checked watertight (zero non-manifold edges) and its volume
compared against the analytic value from the parameters — all agree to within
the facetting error (≤ 0.35 mm³).

The plate model was checked against the STEP independently: FreeCAD meshes the
STEP solid at 1337.9286 mm³ against our 1337.908 mm³, surface-to-surface
deviation below 0.001 mm, both meshes watertight.

## 10. Still open

- Force introduction on the inner holder — nothing to attach a loading rod to.
- Lead wires appear in `viewer.html` only, as straight runs for clearance — they are not a manufactured part and have no `.scad`.

## 11. Files

The `.scad` files are the sources. `make` in `strain_gauge/` builds
`strain_gauge_plate.stl`, `inner_holder.stl` and `outer_holder.stl` into
`build/strain_gauge/` at the top of the repository (not in git), rebuilding
only what changed. `make` at the top builds this project and `switch/`.
