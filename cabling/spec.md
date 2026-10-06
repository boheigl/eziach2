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
| Maximum bending, as smallest bend radius | 2.0 mm (`rMin`, set in `routes.json` → `cable`) | [given]; to be checked against the cable maker's data |

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
(Gauss–Newton on the KKT system, Levenberg damping, line search on an
augmented Lagrangian, which keeps full steps and fast convergence near the
solution). A fresh solve starts from a single, almost straight line (radius
10 m, so it can move sideways from the first step) and moves its end
gradually from where that line ends to the outlet (continuation).

**Several resting shapes.** A given length and pair of poses can allow more
than one equilibrium. Without obstacles the solve keeps the one its
continuation reaches. While you drag in the viewer, the shape follows from the
previous one, like a real cable; *Re-solve from scratch* starts over.

**Maximum bending.** `rMin` is a limit the solver enforces, not only a
check: the film's curvature across its rulings may not exceed 1/`rMin`. It is
a penalty that is stiffened (×10 at a time) until the smallest radius is within
0.5 % of `rMin`. Where the free shape would bend tighter, the cable lies on the
limit radius instead, like a cable laid over a former. `rMin = 0` switches the
limit off. Test: an S-bend (6 mm offset, parallel ends) with R 2 has the
shortest free length 14.377 mm by hand (two 2 mm arcs and a straight); the
solver finds 14.378 mm with the smallest radius at 1.993 mm.

**Shortest length.** `"length": "auto"` finds by bisection the shortest free
length for which a shape within the bending limit exists, then adds `slack`
(default 3 mm). At the shortest length the cable reaches `rMin`; with the
slack it usually relaxes away from it.

**Obstacles.** Any number of obstacles, each a signed distance function
(negative inside): `cylinder` {p, axis, r, h}, `box` {p, size, x?, y?},
`sphere` {p, r}, or in JS any `sdf(point)` function. Along the cable at
points at most 1 mm apart, five points across its width (edges, quarters,
centre) must stay half the film thickness plus `clearance` (0.5 mm [chosen])
away from every obstacle. (Checking at the nodes alone, 3.4 mm apart with 32
segments, let the gap shrink to 0.15 mm between nodes round ⌀6 cylinders.)
This is a penalty like the bending limit, stiffened until no point is more
than 0.02 mm inside the gap. **Self-contact:** where there are obstacles, the
cable also keeps `selfGap` (film centre to film centre; default thickness +
clearance) from every part of itself more than 5 mm away along it, checked at
three points across the width; reported as the smallest self-distance.

**Topological options.** Each obstacle can lie on either side of the cable,
so k obstacles give 2^k ways through (enumerated for up to 12 obstacles;
any beyond stay on the side they come to). The solver searches them as a
tree:

1. The free shape, with the obstacles off.
2. Per obstacle, a direction across the cable: at the cable point nearest to
   it (or deepest inside it), the way out of the obstacle, square to the
   cable.
3. The obstacles go in one after another, in the order the free cable passes
   them, and each splits the search in two (its two sides). An obstacle is
   moved along its direction until it is clear of the cable (to the far side
   if it has to cross it, not at all if it is already clear on its side),
   then slid back in steps of at most 1 mm, pushing the cable ahead; waiting
   obstacles are out of the way. Combinations sharing their first choices
   share that work. A branch that gets stuck is dropped with everything below
   it, and so is one that reaches an arrangement already explored.
   `budget_s` (per route) stops the search after that many seconds.
4. Each option is solved to the end and labelled by the side of the film each
   obstacle ends up on, `+n` or `−n` (n = t × w, the film normal). The best
   option (within the limits first, then least energy) is the default; all
   are kept in `.options`.

`route.js` lists every option and writes one STL per option it found to
`build/cabling/` (`<name>_optk.stl`, best first) plus `<name>_obstacles.stl`. With
`"length": "auto"`, every option gets its own shortest length. Example
`two_cylinders` (90 mm): all four options found, energies 0.099 / 0.177 /
0.359 / 0.556, each 0.50 mm clear. An option may come out "not found" if
sliding gets stuck, e.g. when the cable is too short for that way round.
Example `grid_3x3`: nine ⌀6 × 300 mm cylinders on a 14 mm grid, 110 mm free
length; 16 options in the first 4 minutes, more exist (search stopped).

**Housing channel to the front (withdrawn).** A 15.8 × 0.8 mm channel from
board 0's connector to a slot in the front wall (x −131.7, z −12, −20°) was
generated and cut, then withdrawn: the slot sits where the housing has 1.4 mm
to spare, the cable twists 14 °/mm, and a twisted closed tunnel is hard to
thread. Lessons kept: half-space obstacles, the push-out mode, and
self-contact (a 40 mm path to a later end point looped back within 0.8 mm of
itself, which no wall could separate). Board 0's FFC now runs with a
kink after the connector, on edge in an open trough to the back (below).

**Kink and planar motion.** `"kink": {lead, crease, side}` folds the cable
`lead` mm below the connector face along a crease at `crease` degrees to its
length (45°: it turns 90°, along ±w): a rotation by 180° about the crease,
the folded part one film thickness on top. `"planar": true` holds the twist
at zero, so after the fold the cable only bends about its width and stays in
one plane. Drawn and cut as two overlapping pieces (the strip down past the
crease, the band from before it), which together cover the fold.
`"waypoints"` (plan x, y) give a planar route its starting path
(`FFC.planarGuess`: lifted onto the plane, a smooth curve through them, its
heading changes as κ); `"length": "guide"` takes the free length from it.

**Housing trough to the back** (route `back_channel`) [given: kink after the
connector, flat in a plane, to the back face, open from the top, fin under
the housing]. Board 0's FFC leaves its connector straight down and is folded
8.6 mm below it with a 51.6° crease, so the band stands on edge in a plane
parallel to the floor (13.2°, the floor's slope) and keeps its height above
the floor. It runs to the back face (y = 61.9, x −97.6), between the guides
of holes 1–2 of every row, the connector pockets and floor slots of boards
1–3, the cover screw pilots and the cover walls round the tabs, with ≥ 0.6 mm
wall to all of them: free length 80.1 mm, cable 98.2 mm end to end, tightest
bend 3.57 mm, no twist, ≥ 4.7 mm from itself. The trough (15.8 × 0.8 mm) is
open upwards along the cable's width (`open_top`), so the cable is laid in
from above before the boards go on. Heights: a single plane cannot dip under
board 0's connector, so the whole plane sits 5.6 mm lower than the floor
would allow; the band's top then clears the connector by 0.2 mm and the
board undersides everywhere, and its bottom runs up to 5.7 mm below the
floor. A fin under the housing (the trough's 0.6 mm wall where it is below
the floor, `wall`) carries it, down to z −24.6.

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
3. **Contact only with the obstacles listed.** Nothing stops the cable
   passing through itself, the connector or the outlet wall; obstacles are
   checked at the nodes only (1–2 mm apart), and only the free length is
   checked. Gravity and friction are neglected.
4. **Sides, not every route.** The options are the 2^k combinations of sides.
   Wrapping round an obstacle more than once, or threading between obstacles
   in an order the slide-in does not reach, is not enumerated.
5. **No folds.** Creased folds (e.g. a 45° fold that turns the cable 90° in
   its plane) are not modelled yet.

## 4. Files

| File | Content |
|---|---|
| `ffc.js` | the model: poses, solver, shortest length, mesh, STL writer |
| `routes.json` | routes: start, outlet, length (mm or `"auto"` + `slack`), cable overrides, obstacles |
| `channel.js` | `node channel.js routes.json <name> [--force]`: solves a route with a `channel` {width, thick, out, open_top?, wall?} and writes module `<name>()` (the slot, open upwards to `open_top`) and `<name>_wall()` (slot + wall, to the outlet) as OpenSCAD polyhedra; refuses a path outside the limits. Route `back_channel` → `build/cabling/back_channel.scad` (no longer used by the housing) |
| `route.js` | `node route.js [--out <dir>] [routes.json] [name …]`: solves, prints a report, writes `<name>.stl` to `build/cabling/` (or `<dir>`) |
| `Makefile` | `make` solves every route into `build/cabling/`, `make <name>` one; the report goes to `<name>.log` there. A route is solved again when `routes.json`, `ffc.js` or `route.js` change; solving takes minutes per route |
| `viewer.html` | 3D: drag start and outlet (move/turn handles) or type poses; length slider, *Shortest + slack*, STL download, route JSON for `routes.json`; `#preset=n` picks a preset |
| `build/cabling/<name>.stl`, `<name>_optk.stl`, `<name>_obstacles.stl` | generated cable solids per route and option, and the obstacles (not in git) |

Sources: GCT FFC3A20 drawing (<https://gct.co/files/drawings/ffc3a20.pdf>);
M. Sadowsky (1930) and W. Wunderlich (1962) on the developable (paper) strip,
as summarised by Starostin & van der Heijden, *Nature Materials* 6 (2007).
