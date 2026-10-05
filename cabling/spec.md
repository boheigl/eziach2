# FFC routing — design record

How a flat flexible cable runs from a clamped start (a connector) to an outlet
it has to pass, both at any position and orientation. Numbers are tagged as in
`switch/spec.md`: **[given]** stated by the user, **[datasheet]** from a
manufacturer's document, **[chosen]** a design decision made here,
**[estimated]** calculated rather than measured, **[unverified]** still to be
confirmed.

`ffc.js` is the single source of the model; `route.js` (node) and
`viewer.html` (browser) both load it. The switch housing is deliberately left
out for now [given]: nothing checks the cable against other parts yet.

---

## 1. Cable

| | | |
|---|---|---|
| Type | FFC, 14 contacts, 1.0 mm pitch | [given] |
| Width | (N + 1) × 1.0 = 15.0 mm ± 0.10 | [datasheet] GCT FFC3A20 drawing |
| Thickness at the contacts | 0.30 ± 0.03 mm (stiffened end) | [datasheet] |
| Film thickness elsewhere | 0.15 mm, only used for drawing and the twist stiffness (§3) | [unverified] |
| Exposed contact length | ≥ 3.0 mm, stiffener ≥ 4.0 mm | [datasheet] |
| Smallest bend radius allowed | 2.0 mm (`rMin`) | [chosen], to be checked against the cable maker's data |

## 2. Poses and frames

A pose is a point and two directions: **t** along the cable (start → outlet)
and **w** across the width **towards contact 1**; **n = t × w** is the film
normal. Coordinates are the switch board frame (`switch/spec.md` §1), so the
cable fits the switch models without conversion.

- **Start** = the connector face, t pointing out of it. Default: board 0's
  GCT FFC3A20-14-G, centre (−133.15, 4.5) from `pcb.scad`, face 5.5 mm below the
  bottom copper (z = −6.335), cable leaving in −z, contact 1 at +y. [chosen]
- **Outlet** = the middle of the slot the cable passes, t pointing through it.
  Any position and orientation. [given]

Along the cable, from the connector:

| Part | Length | Shape |
|---|---|---|
| inside the connector | `insert` 3.5 mm | straight | 
| lead, beyond the face | `lead` 2.0 mm | straight (stiffener) |
| **free length** | `L` | solved (§3) |
| through the outlet wall | `slotDepth` 2.0 mm | straight, centred on the outlet pose |
| tail, drawn beyond | `tail` 10 mm | straight |

`insert` is [estimated] from the 5.5 mm housing height; `lead`, `slotDepth`
and `tail` are [chosen]. The cable length end to end is the sum.

## 3. Model

The film is about 100 times wider than thick, so it behaves like a paper strip
[chosen model]:

- It does not stretch and **cannot bend in its own plane**.
- It bends about w (curvature κ) and twists about t (twist τ).
- It can twist cheaply only while bent: bent and twisted at once, the film
  forms a developable surface with straight rulings across it. Twisting flat
  film stretches its edges, which costs a lot.

Energy per length, in units of the bending stiffness:

    e = κ² + 2τ² + τ⁴ / (κ² + κr²)

With κr = 0 this is Sadowsky's energy (κ² + τ²)² / κ² of a developable strip.
κr = √60 · t / w² stands for the edge stretching of a pure twist
(E t w⁵ τ⁴ / 1440); it is 0.0052 /mm for 0.15 × 15 mm. [estimated]

**The cable takes the shape of least energy** that joins the two clamped
poses with the given free length: its resting shape (static equilibrium,
gravity neglected). Discretised as N segments (default 48) with κ and τ
constant on each; every segment is integrated exactly (screw motion), so a
circular arc comes out exact (test: R 20 arc, κ = 0.050000 on every segment).
The six end-pose equations are solved together with the energy minimum
(Gauss–Newton on the KKT system, Levenberg damping, line search). A solve
starts from a slightly wavy cable and moves the end gradually from where that
cable ends to the outlet (continuation).

**Several resting shapes.** A given length and pair of poses often allows more
than one equilibrium (e.g. a flat U-turn and a twisted one). A fresh solve
tries three starts (untwisted, twisted either way) and keeps the one of least
energy. While you drag in the viewer, the shape follows from the previous one,
like a real cable; *Re-solve from scratch* looks for the lowest one again.

**Shortest length.** `"length": "auto"` finds by bisection the shortest free
length whose resting shape keeps `rMin`, then adds `slack` (default 3 mm).

Reported per route: free and total length, length from the connector to the
outlet centre, smallest bend radius (the film's curvature across its rulings,
(κ² + τ²)/|κ|) and where it is, largest twist (°/mm), and the largest ruling
tilt η = τ/κ (tan of the angle between the rulings and w).

### Limits of the model

1. **Drawn as a ribbon.** The film is drawn with its edges at ±w/2 along w.
   Where it bends and twists at once, the real film forms cones, and its
   edges lie off the drawn ones by up to the ruling tilt.
2. **Narrow-strip energy.** Sadowsky's energy neglects the width. For a 15 mm
   film in bends of a few mm that is a simplification (Wunderlich's width
   correction would stiffen the twisted parts). The curvature sign may jump
   where the film twists (κ passes ±τ), as in a real paper strip.
3. **No contact.** Nothing stops the cable passing through itself, the
   connector, the outlet wall or other parts. Gravity and friction are
   neglected.
4. **No folds.** Creased folds (e.g. a 45° fold that turns the cable 90° in
   its plane) are not modelled yet.

## 4. Files

| File | Content |
|---|---|
| `ffc.js` | the model: poses, solver, shortest length, mesh, STL writer |
| `routes.json` | routes: start, outlet, length (mm or `"auto"` + `slack`), cable overrides |
| `route.js` | `node route.js [routes.json] [name …]`: solves, prints a report, writes `<name>.stl` |
| `viewer.html` | 3D: drag start and outlet (move/turn handles) or type poses; length slider, *Shortest + slack*, STL download, route JSON for `routes.json`; `#preset=n` picks a preset |
| `<name>.stl` | generated cable solids (not in git) |

Sources: GCT FFC3A20 drawing (<https://gct.co/files/drawings/ffc3a20.pdf>);
M. Sadowsky (1930) and W. Wunderlich (1962) on the developable (paper) strip,
as summarised by Starostin & van der Heijden, *Nature Materials* 6 (2007).
