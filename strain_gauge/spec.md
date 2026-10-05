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

## 2. The plate

| | | |
|---|---|---|
| Envelope | 30 × 25 × 2.5 mm | [given], confirmed [STEP] |
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

## 5. Inner holder — `inner_holder.scad`

Grips the W-shaped inner part and introduces the load. **23 × 21.2 × 8.8 mm**,
3152.6 mm³.

| Decision | Value | Why |
|---|---|---|
| Slides on from −y | mouth faces +y | the slots are open at that edge |
| Wall above and below | 3 mm | [given] |
| Closed box | side walls run inside the open slots at \|x\| = 9.2…11.5 | far stiffer than a bare C, and the slots are the only through-opening available |
| Fit to the W | 0.2 mm per side, 0.15 mm per face | FDM; the walls guide along 17 mm of web, so tighter binds rather than grips |
| Clearance to the outer arms | 0.5 mm | must never touch — they are the fixed side |
| Mouth corners | R2 on the two vertical edges | [given] |
| Lead-in flare | 0.6 mm over 1.5 mm | printed parts catch on the first layer otherwise |

**Gauge recess:** 9 × 12.5 × 1 mm in the inner face of each plate, from y = −8
forward, opening at the mouth. 9 mm wide puts its edges mid-slot — 1.5 mm clear
of the column and 1.5 mm clear of the webs — so the inner holder never touches the
member being measured. That member stays free to bend; clamping is left to the
webs and the bottom block, which the inner holder still holds over y = −12.7 … −8.

**Note on the mechanics:** because the inner holder clamps the webs, they no longer
act as cantilevers. The flexing members become the column and the arms. The
gauge placement is unaffected — the column flexes either way.

## 6. Outer holder — `outer_holder.scad`

Takes the two fixed arms. One piece. **38.4 × 26.2 × 10.8 mm**, 4190.0 mm³.

| Decision | Value | Why |
|---|---|---|
| Slides on from −y | same side as the inner holder | [given] |
| Material above, below, outboard | 4 mm | [given] |
| Jaw inner face | x = 12 | flush with the arm, 0.5 mm clear of the inner holder |
| Two yokes | over and under the plate, y = 5.5…12.5, z = ±2.4…±5.4 | [given]; a pair rather than one ties the jaws symmetrically. Depth follows from keeping 1 mm back from the inner holder |
| Lead gap between yokes | 4.8 mm, 1.15 mm clear of each plate face | the leads pass through here |
| Stop wall at −y | 1 mm | [given]; only takes the push of assembly, not the measured load |
| Plate fits | as the inner holder | same process |

The yokes sit **across** the plate rather than beyond it, so nothing projects
past the +y edge. In y they occupy the one stretch of plate that neither the
inner holder (ends at y = 4.5) nor the arm pockets claim, holding 1 mm back from it.

Earlier alternatives, and why they were dropped: a yoke beyond the +y edge
projects past the plate; a yoke behind the −y edge reverses the assembly order
and lengthens the part; two separate jaws avoid the order constraint but give
up the cross-tie.

## 7. Assembly

1. **Outer holder first.** Its yokes pass over and under the bare plate, but
   cannot pass the inner holder, which stands 8.8 mm tall where the gap is 4.8.
2. **Inner holder second**, onto the W from −y.
3. Leads leave in +y: along the recesses, out of the inner holder's mouth, across the
   plate, through the gap between the yokes, standing **2 mm proud** of the
   outer holder's +y face. Two per gauge, ⌀0.7, which clears the recess ceiling and
   the yokes by about 0.45 mm. [chosen]

This order is forced by the geometry, not a preference.

## 8. Manufacturing [given]

Both holders are FDM printed. All plate clearances are set for that: 0.2 mm per
side, 0.15 mm per face. For precision machining use 0.05–0.1 mm per side; for
SLA, 0.15.

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

- Mounting features on the outer holder — no holes or threads yet.
- Force introduction on the inner holder — nothing to attach a loading rod to.
- Gauge polarity, by test.
- Material choice and an FEA or strain survey to replace the beam estimate.
- Lead wires appear in `viewer.html` only, as straight runs for clearance — they are not a manufactured part and have no `.scad`.
