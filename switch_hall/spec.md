# Hall-sensor key — design record

The key of discant and bass. It replaced the earlier contact key (felt ring, washers on
copper half-rings; in the git history) and builds lower.
Tags: **[given]**, **[datasheet]**, **[chosen]**,
**[estimated]**, **[unverified]**.

`key.scad` is the source and asserts every check below; `viewer.html` (three.js)
rebuilds the same geometry from parameters copied at the top of its script.
**Change a value in both places.** `make` writes the parts to
`../build/switch_hall/`.

## 1. Requirements [given]

- Actuation point set by calibration, per key, **as early as possible** after the
  key leaves its rest (user, 2026-11-14): see §6.
- No click; force rising linearly with travel, like a spring.
- About 100 g at rest, "ideally not much more" at the bottom.
- Stroke 3 mm; it stays 3 mm (user, 2026-11-14, after a shorter stroke was
  offered for a steeper field at rest).
- As low as possible.
- A conventional spring under the cap (user, 2026-11-13). This replaced a
  first version with a pair of preformed CuBe2 leaves under the board: those
  reached 100 → 142 g at 19.6 mm height. It was never committed.

## 2. Principle [chosen]

The key works like a linear Hall-effect keyboard switch. Everything that moves
is above the board, and **the board has no key holes**.

- **Tube:** the cover plate (2.4 mm on the board's top, as in
  `../discant/cover.scad`) carries a fixed tube at every key, with a sintered bronze
  sleeve bearing (d3 × D5 × 4, oil-impregnated, stock) in it.
- **Plunger:** a stock dowel pin ISO 2338 ⌀3 h8 × 14, stainless A1 (× 24 in the bass's
  back row) [given 2026-11-21: stock lengths, no cutting], runs in the bushing; a printed collar on
  its lower end carries the magnet and the stop washer and touches nothing.
- **Bushing from below, against a rim** [given 2026-11-15]: the tube's lower bore
  (⌀5.1) lets the bushing slide in from below; it is pressed into its seat (⌀4.95) up
  against a 0.8 mm rim at the tube's top. At rest the spring pulls the collar up
  against the bushing (1.2 N, and a knock when a key is let go): the rim takes that
  by its shape, with no glue and no screw. Screwing from above, as on an acoustic
  Steirische, does not fit: the spring stands round the tube right up to the cap, so a
  plate over the tubes would cut through it.
- **Joints on the rod** [given 2026-11-15]: the rod is pressed and glued 2.7 mm deep
  into the cap (3.2 mm thick, 0.5 over the socket; 3 and 2.5 with the 13.8 mm rod cut
  from bar before 2026-11-21) and glued 1.5 mm deep into the collar (3 mm high, over
  the magnet's 1.5). Both carry the spring's force at rest.
- **Spring:** a stock compression spring stands on a seat round the tube and pushes
  the cap up.

**Assembly of one key**, before the cover is screwed onto the board:

1. Take a dowel pin 3 × 14 (3 × 24 in the bass's back row); its ends come chamfered.
   Roughen both ends over about 3 mm (240 grit; the ground surface holds glue
   poorly) and degrease them with isopropanol; keep the middle, which runs in the
   bushing, smooth and clean.
2. Press and glue the rod into the cap's socket, square, down to the bottom.

   **Adhesive** [chosen 2026-11-15]: a slow 2-component epoxy, e.g. UHU plus endfest
   (about 90 min to work, firm after 12 h), for both joints. Slow, because one mix then
   does a whole cover and the spring holds the collar while it cures (step 6), and
   slow epoxies are the stronger. Not cyanoacrylate: thin, it creeps along the rod into
   the bushing and the stop washer and fixes the key. A small drop with a toothpick
   into the hole (not on the rod), squeeze-out wiped off. Glued length 2.5 mm in the
   cap, 1.5 mm in the collar (where it also holds the magnet): about 24 and 14 mm²,
   some 50 N at a few N/mm² on PETG, against 1.2 N and a knock. [estimated]
3. Press the magnet into the collar from below; every key with the same pole down
   (check against a marked magnet).
4. Cover upside down: the bushing into the tube from below, up against the rim.
5. Cover the right way up: the spring round the tube onto its seat, the O-ring into
   the cap's counterbore, the rod with the cap from above through the bushing.
6. Cover turned over onto its caps (the springs keep the keys at rest): wipe the rod's
   lower end with isopropanol [2026-11-23: it has just passed the oil-impregnated
   bushing, and epoxy holds poorly on oily steel; this joint carries the spring at rest],
   let it dry, then the stop washer over the rod's end (it holds itself), then the collar
   glued on until the rod sits on the magnet. The spring pulls the collar against the
   bushing while the glue sets; no jig. No glue may reach washer or bushing: little glue, in the collar's hole
   only. Leave the cover on its caps until the glue is firm (12 h).
7. When all keys are in: the cover onto the board, the brass screws (27 on the discant); then each key
   calibrated once at rest and once pressed.
- **Sensor:** a linear ratiometric Hall sensor in SOT-23 (e.g. DRV5055A3,
  ±85 mT) sits on the board's **underside, exactly on the key's axis**, and
  senses through the board. A magnet magnetised along its axis is pressed into
  the collar's lower face.
- **Stops**, both soft, so nothing clicks [given: user chose O-ring below,
  sheet washer above, 2026-11-13]. They replaced felt, which sets over time and
  is not available in these sizes:
  - **Bottom:** a stock O-ring, 4 × 1.5 (silicone, about 50 Shore A, or NBR
    70), lies in a 0.5 mm counterbore (⌀7.2) in the cap's underside round the
    pin. It stands 1 mm out and lands on the tube's top after 3 mm. It also
    centres the spring's top coil.
  - **Rest:** a washer punched with hollow punches from 1 mm silicone or PU
    sheet, ⌀4.5 / ⌀2.5. It sits slightly tight on the ⌀3 rod, rests on the
    collar and bears on the bushing's lower face.
  - **Rest position drift:** if the washer sets over time, the key rests a
    little lower. The firmware should keep tracking each key's rest reading
    while the key is not pressed.

## 3. Geometry (key frame, at rest)

**One sensor board for the discant** [given, 2026-11-13]: `../hall_pcb/` lies in
the staircase's slope plane, tilted against every row by atan(3/16) = 10.6°.
`board_tilt` in key.scad lifts the collar by its radius × tan(tilt) = 0.43 mm, so
that its edge up the slope keeps 0.3 mm from the board, and lengthens the way to
the sensor through the board. The numbers below include it; the board is drawn
flat.

**Bass back row** [chosen]: the bass board lies flat under both rows
(`board_tilt = 0`) and the back row stands 10 mm higher. `riser` in key.scad
raises the spring seat, the tube top and everything above by that much; collar,
magnet, stop washer and bushing keep their place at the board. Only the rod is
10 mm longer (3 × 24): spring, stops, field and guide are the same as in the front row
(cap top 30.1 instead of 20.1 above the board's middle). The Makefile builds
both rows as `bass0_*` / `bass1_*`.

| | z | |
|---|---|---|
| Board, no hole | −0.8 … 0.8 | |
| Hall sensor, underside | −1.935 … −0.835 | element assumed 0.55 below its mounting face [unverified; the datasheet's Figure 6-5 gives 0.65 ± 0.08 in the SOT-23, about 0.1 mm off, not acted on] |
| Cover plate | 0.8 … 3.2 | |
| Spring seat, between tube and shroud | 4.25 (§5) | |
| Tube ⌀6.6: lower bore ⌀5.1, bushing seat ⌀4.95, rim with ⌀3.4 | 0.8 … 13.35; bushing 8.55 … 12.55, rim 12.55 … 13.35 | |
| Collar ⌀4.4 × 3 with magnet ⌀3 × 1.5 | 4.55 … 7.55 | 0.3 above the tilted board at its edge, lower stop |
| Rod ⌀3 × 14 (dowel pin) | 6.05 … 20.05 | 1.5 into the collar, 2.7 into the cap |
| Silicone washer ⌀4.5 / ⌀2.5 × 1 on the collar | 7.55 … 8.55 | upper stop |
| O-ring 4 × 1.5 in the cap | 16.35 … 17.85 | lands on the tube's top after 3 mm |
| Cap ⌀15 × 3.2, R0.5 | 17.35 … 20.55 | |

- **Height** from the cap top to the board's underside is **21.4 mm** on the discant
  (21.0 on the bass's flat board); 2.8 more than before the rim (0.8), the longer
  collar (1) and the thicker cap (1) [2026-11-15], and 0.2 for the 14 mm dowel pin
  [2026-11-21]. Only the sensor (1.1 mm) is below
  the board.
- For comparison, the switch key is 27.1 mm (cap top to its guide tube's bottom),
  and the leaf version was 19.6 mm.
- Relative to its own board, the cap top stands 6.6 mm higher than with the
  switch key. The housing under the boards no longer needs key guides, so the
  staircase can be built correspondingly flatter.

## 3a. Hidden spring [given: user, 2026-11-13]

- **Skirt:** one piece with the cap, ⌀12.4 / ⌀10.8, reaching 7.3 mm below the
  cap's underside.
- **Shroud:** on the cover plate, ⌀10.2 / ⌀8.6, up to z = 6.3.
- They never touch (0.3 mm radial gap). At rest the skirt overlaps the shroud
  by 1 mm, so the spring is never visible.
- At the lower stop the skirt stays 0.3 mm above the cover.
- No extra height; the cap's ⌀15 footprint is unchanged.

## 4. Guide

- **One bushing is the whole guide** [given 2026-11-14]: steel in oiled sintered bronze,
  μ about 0.1 [estimated]. A press jams only beyond bush_l / (2 μ) = 20 mm off the
  axis, and still beyond 8 mm dry (μ 0.25); the cap's edge is at 7.5.
- The collar runs in the ⌀5.1 bore with 0.35 mm round it and touches nothing.
- The tube's wall is 0.8 mm round the bushing and 0.75 round the lower bore, where
  the spring stands round it; that part carries no load.

## 5. Spring

**A standard part** [given 2026-11-15: stainless, a standard spring, not a custom one;
UY8-25 with the lowered seat]: **Misumi UY8-25**, SUS304-WPB stainless, ⌀8
outside × 0.45 wire × 25 free length, closed ends, inside ⌀7.1, 12 coils (solid 5.4).
Cold drawn 304 is weakly magnetic (Misumi says so), far less than spring steel; the
per-key calibration takes the rest out (§6).

- **Seat** [given 2026-11-15]: a level floor between the tube (⌀6.6) and the shroud
  (⌀8.6), 13.1 mm under the cap's underside (`spring_rest`), so the force stays as
  chosen whatever the heights below. Since the rim, the longer collar and the thicker
  cap raised the cap by 2.8 mm, the seat stands 1 mm above the plate's top (z 4.25),
  about 2.6 mm of material under it at its thinnest. It may not come lower than
  0.8 mm above the board at its outer edge up the discant's slope (`seat_floor`,
  asserted); that limit was reached when the seat was a groove in the plate.
- **O-ring counterbore** ⌀7.1 (0.05 round the O-ring instead of 0.1), so it stays
  inside the spring and the top coil keeps its seat.

| | |
|---|---|
| Rate | 0.098 N/mm ±10 % [catalogue] |
| Length at rest / at the bottom | 13.1 / 10.1 mm (shortest working length 6.25 [catalogue]) |
| Force at rest → at the bottom | **119 → 149 g (+25 %)**, both halves [from the catalogue's rate; ±10 %] |
| Shear stress at the bottom | 310 N/mm², uncorrected |

Misumi's light series have one rate per size and free lengths in 5 mm steps, so the
force cannot be tuned finely. With this spring the seat sets the force: as high as the
old floor 139 → 169 g; on the plate's top 126 → 156 g; lower the floor gets too thin.
The neighbours (⌀8, seat as now): C-UV8-25 (0.4 wire, 0.049 N/mm) 70 → 84 g; C-UY8-20
(0.4 wire) 69 → 99 g. No stock spring of any maker searched gives about 100 g
with a flat rise in this room (Gutekunst's 4536 and Misumi's sizes, 2026-11-15): that
needs a soft spring heavily preloaded, wire 0.4 on ⌀8 (index 19), which no catalogue
keeps. The custom alternative: 0.4 × ⌀8 × 25 in 1.4310 with 7 active coils, 104 → 126 g
(+22 %).

Before: a spring-steel ⌀8 × 0.4 × 25 with 8 coils, 105 → 128 g (+22 %).

## 6. Sensor [estimated, field of a cylinder magnet on its axis]

- **Magnet:** ⌀3 × 1.5 N52 in the collar. Its lower face is 6.0 mm from the
  sensor element at rest and 3.0 mm at the bottom (along the axis, through the
  tilted board).
- **Field:** 7.5 mT at rest, 39.3 mT at the bottom, inside the DRV5055A3's
  ±85 mT range.
- **Calibration:** the field rises monotonically but not linearly with travel.
  The firmware stores each key's rest and bottom readings and maps the reading
  back to travel. Switching itself does not use it [given 2026-11-20]: a key goes
  on a fixed number of ADC counts above its rest reading and off below a smaller one,
  so it switches at the top of the stroke whatever happens at the bottom (see Early
  actuation; `../firmware/spec.md` §3).
- **Early actuation:** at rest the field rises by 3.2 mT/mm; 0.1 / 0.2 / 0.5 mT
  above the rest reading are reached after 31 / 61 / 149 µm. One ADC step
  (12 bit, DRV5055A3 at 3.3 V) is about 0.05 mT, about 15 µm here. The limit is
  not the field but noise, temperature drift and how exactly the key returns to
  its rest on the soft washer: the firmware tracks each key's rest reading while
  the key is up and triggers a little above it, e.g. on at 0.15 mm and off at
  0.08 mm. How small this can be is to be measured on a prototype. [estimated]
- **Iron near the magnet:** spring, screws and the pads' finish bend the field a little,
  the same way at every press; the per-key calibration takes it out. To keep it small:
  a stainless spring (§5), brass screws in the key boards (`../hall_pcb/spec.md`), and
  HASL rather than ENIG (its nickel) on the sensor boards [chosen 2026-11-15].
- **Crosstalk:** pressing a neighbour on the same board (20 mm away) changes the
  reading by 0.04 mT, under 0.1 % of the swing. It can be ignored.
- **Supply:** the DRV5055 draws 2 mA typical, 4 mA maximum at 3.3 V, continuously
  [datasheet: SBAS640C, 5.5]: 64 sensors 130 … 260 mA, budgeted on the main board
  (`../main_pcb/spec.md`).
- **Noise:** 0.2 mT peak to peak at 3.3 V [datasheet], about 4 ADC steps or 60 µm of
  travel at rest; switch on the ADS7128's averaging (OSR) to trigger near rest.
- **Electronics:** each board needs 13 analog inputs, from an MCU or ADCs on the
  I²C bus, in place of the PCAL9555A. Still open.

## 7. Checks

**Asserts in key.scad:**
- Guide span against the cap's radius (jamming).
- Spring length at the bottom against its minimum; spring has preload.
- Tube against the spring's inside; tube walls.
- O-ring inside the spring, landing on the tube; washer meets the step and clears the bore.
- Magnet fits the collar; field within the sensor's range.
- Cap against the next board's front edge and against the next board's caps.

**Collision checks on the STLs:**
- **Within the key, at rest and at the lower stop:** the parts touch only at the
  two stops, as intended (the washer also grips the pin). The spring is clear
  of the tube, the plunger, the cap and the O-ring.
- **In the staircase:** cap, plunger, spring, tube with cover plate, sensor
  and board of one key were checked against every part of the keys at
  (±10, 16, 3) and (0 / ±20, 32, 6), each at rest and at the lower stop
  (540 pairs). Nothing overlaps.
- **Control:** a part against itself overlaps, as it should.
