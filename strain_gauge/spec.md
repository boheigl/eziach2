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
| Wall above and below | 4.5 mm | [given: thicker for strength under a strong push; was 3] |
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

**Latch** [given: in both positions of the bass]: a spring tongue in the top wall each
side (3 × 1 mm, from its root in the bridge at y = −15.5 to its tip at −4.2, in a
0.5 mm slot, bending into a relief in its own wall), its tooth (1 × 1.3 mm, 0.6 mm into
the plate's thickness) at x = 4.2 … 5.2 in the inner slot between web and column, its
retaining face at y = −6.28, just ahead of the slot's closed end (−6.33 … −6.47 across
the tooth). Sliding on, a ramp lifts it over the bottom block; at the end it drops into
the slot. It touches only the W (1.0 mm clear of the column), so the measured path is
unchanged. Variants (`latch`): `"lock"`, square face and a lug for a rod (below; the bass's playing
mount); `"detent"`, 45° face, no lug (the stored
position's socket, `../build/strain_gauge/inner_holder_detent.stl`); `"none"`.
Checked: seated, clear of the plate; 0.3 mm towards pull-off, the teeth meet the plate.
**Material: PETG** [given 2026-11-15]. **Root and stop** [chosen 2026-11-15]: the bridge
used to stand solid under the tongue's first 2.8 mm, so it bent only from the pocket's
edge (8.5 mm, about 1.25 % at the root, at a sharp corner on the tension side). A 0.4 mm
slot under the root now frees all 11.3 mm; the slot ends round and the corner above the
root has an R0.5 fillet. Root strains [estimate: cantilever loaded where it is lifted,
the tooth 9.2 mm from the root; PETG takes about 2–3 % repeated; corrected 2026-11-15,
earlier figures took the tip's 11.3 mm and came out about 1.5 times too low]:
- **Detent:** tongue 1.2 mm thick; 1.3 % at the tooth's 0.6 mm lift, 1.8 % at its stop,
  a bar across the slot 0.85 mm over the tongue. Four hold the stored discant with about
  15 N [estimate: 2.0 N spring force per tooth, 45°, friction 0.3] against its 3.5 N
  weight [chosen 2026-11-15: 1.2, the 1.0 tongue gave half].
- **Lock** [chosen 2026-11-15: one rod lifts all four lugs of the bass's mount; the bass
  prints standing on its hand face, so the holder stands on its bridge and grows in +y]:
  tongue 1.0 mm. Its lug rises from the tongue at 45° from y −7.4, runs on past the tip
  in the slot (lengthened to y 2.3) and carries a ⌀2.0 cross hole at y 0, z 7.2 for a
  stock ⌀2 steel rod through all four lugs (`../bass/link.scad`), pressed in; its top is
  at z 9.0. The tongue bends over its first 8.1 mm, rigid past the lug's foot: 1.1 % at
  the tooth's 0.6 mm lift. The stop is an ear on the lug's outer side (1.2 mm, 0.7 into
  the wall) in a pocket of the slot's wall, 1.6 mm under the wall's ledge: the rod lifts
  1.8 mm and the tooth 0.85 before it stops, 1.3 % at the root. No bar over the tongue,
  so the lug can grow at 45°; everything prints without support standing on the bridge
  (overhangs at most 0.7 mm, bridges at most 4 mm). Checked again 2026-11-15: seated clear, 0.3 mm towards pull-off the teeth
meet the plate (lock and detent), the bass's case clear of plates and outer holders;
the lock's tongue with lug and ear clear of the holder at rest and lifted 1.5 mm, the
ear meeting its ledge at 2.0 mm (control).

## 6. Outer holder — `outer_holder.scad`

Takes the two fixed arms. One piece. **38.4 × 27.3 × 10.8 mm**, 0.5 of the length
inside the pad. **Printed as part of the discant's housing** [given]: its +y end
grows out of the gauge pad on the back face (`discant/gauge_link.scad`), so
nothing fixes it there, and it cannot slide on. The plate slides in instead.

| Decision | Value | Why |
|---|---|---|
| Plate slides in from −y, +y edge first | same side as the inner holder; the jaws are open channels | follows from being part of the housing [given] |
| Material above, below, outboard | 4 mm | [given] |
| Jaw inner face | x = 12 | flush with the arm, 0.5 mm clear of the inner holder |
| Two yokes | over and under the plate, y = 5.5…12.5, z = ±2.4…±5.4 | [given]; a pair rather than one ties the jaws symmetrically. Depth follows from keeping 1 mm back from the inner holder |
| Lead gap between yokes | 4.8 mm, 1.15 mm clear of each plate face | the leads pass through here |
| Stop | the plate's +y edge on the pad, on strips either side of each jaw | replaces the earlier stop wall at −y |
| Retention | a dowel pin ⌀1.5 × 10 (ISO 2338) across each jaw, 0.05 mm beyond the arm's tip | [chosen]; keeps the plate from pulling out |
| Plate fits | as the inner holder | same process |

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
   8.8 mm tall where the gap is 4.8, cannot do.
2. **Inner holder second**, onto the W from −y.
3. **Dowel pins**, one across each jaw.
4. Leads leave in +y: along the recesses, out of the inner holder's mouth, across the
   plate, through the gap between the yokes, into the groove in the pad, which takes
   them to the link board (`discant/gauge_link.scad`). Two per gauge, ⌀0.7, which clears the recess ceiling and
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

- Force introduction on the inner holder — nothing to attach a loading rod to.
- Gauge polarity, by test.
- Material choice and an FEA or strain survey to replace the beam estimate.
- Lead wires appear in `viewer.html` only, as straight runs for clearance — they are not a manufactured part and have no `.scad`.

## 11. Files

The `.scad` files are the sources. `make` in `strain_gauge/` builds
`strain_gauge_plate.stl`, `inner_holder.stl` and `outer_holder.stl` into
`build/strain_gauge/` at the top of the repository (not in git), rebuilding
only what changed. `make` at the top builds this project and `switch/`.
