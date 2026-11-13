# Hall-sensor key — design record

An alternative to the contact key in `../switch/`, with a lower build height.
Tags as in `../switch/spec.md`: **[given]**, **[datasheet]**, **[chosen]**,
**[estimated]**, **[unverified]**.

`key.scad` is the source and asserts every check below; `viewer.html` (three.js)
rebuilds the same geometry from parameters copied at the top of its script.
**Change a value in both places.** `make` writes the parts to
`../build/switch_hall/`.

## 1. Requirements [given]

- Actuation point set by calibration, per key.
- No click; force rising linearly with travel, like a spring.
- About 100 g at rest, "ideally not much more" at the bottom.
- Stroke 3 mm.
- As low as possible.
- A conventional spring under the cap (user, 2026-11-13). This replaced a
  first version with a pair of preformed CuBe2 leaves under the board: those
  reached 100 → 142 g at 19.6 mm height. It was never committed.

## 2. Principle [chosen]

The key works like a linear Hall-effect keyboard switch. Everything that moves
is above the board, and **the board has no key holes**.

- **Tube:** the cover plate (1.2 mm on the board's top, as in
  `../discant/cover.scad`) carries a fixed tube at every key.
- **Plunger:** it runs in the tube. A collar at its lower end slides in the
  tube's wider lower bore, and a pin above it in the narrower upper bore. Collar
  and pin are the two guide points.
- **Assembly:** the plunger goes into the tube from below before the cover is
  screwed onto the board. The step between the two bores then holds it captive.
  The cap is pressed onto the pin from above.
- **Spring:** a stock compression spring stands on the cover plate round the
  tube and pushes the cap up.
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
    sheet, ⌀4.5 / ⌀3.5. It sits slightly tight on the ⌀3.6 pin, rests on the
    collar and bears on the step between the bores. Its contact ring with the
    step is 0.35 mm wide, so it carries about 0.23 N/mm² at rest. [estimated]
  - **Rest position drift:** if the washer sets over time, the key rests a
    little lower. The firmware should keep tracking each key's rest reading
    while the key is not pressed.

## 3. Geometry (key frame as in ../switch/pcb.scad, at rest)

**One sensor board for the discant** [given, 2026-11-13]: `../hall_pcb/` lies in
the staircase's slope plane, tilted against every row by atan(3/16) = 10.6°.
`board_tilt` in key.scad lifts the collar by its radius × tan(tilt) = 0.43 mm, so
that its edge up the slope keeps 0.3 mm from the board, and lengthens the way to
the sensor through the board. The numbers below include it; the board is drawn
flat.

| | z | |
|---|---|---|
| Board, no hole | −0.8 … 0.8 | |
| Hall sensor, underside | −1.935 … −0.835 | element assumed 0.55 below its mounting face [unverified] |
| Cover plate, spring seat | 0.8 … 2.0 | |
| Tube ⌀6.6, lower bore ⌀4.8 / upper ⌀3.8 | 0.8 … 9.066, step at 7.566 | |
| Collar ⌀4.6 × 2 with magnet ⌀3 × 1.5 | 4.566 … 6.566 | 0.3 above the tilted board at its edge, lower stop |
| Pin ⌀3.6 | 6.566 … 14.566 | 1.5 into the cap |
| Silicone washer ⌀4.5 / ⌀3.5 × 1 on the collar | 6.566 … 7.566 | upper stop |
| O-ring 4 × 1.5 in the cap | 12.066 … 13.566 | lands on the tube's top after 3 mm |
| Cap ⌀15 × 2, R0.5 | 13.066 … 15.066 | as in ../switch [given] |

- **Height** from the cap top to the board's underside is **15.9 mm** (15.5 mm on a board square to the keys). Only the
  sensor (1.1 mm) is below the board.
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

- **Fit:** 0.1 mm radial play for both the collar and the pin.
- **Guide span at rest** (collar's lower edge to the tube's top): 4.5 mm. It
  grows as the key goes down.
- **Jamming:** a key in a two-point guide jams when it is pressed further off
  centre than span / (2 μ). With μ = 0.25 (POM, greased) [estimated] that is
  9 mm, beyond the cap's 7.5 mm radius.
- The tube's wall is 0.9 mm round the lower bore and 1.4 mm round the upper bore.

## 5. Spring

The stock spring of `../switch/` [given]: ⌀8 × 0.4 × 25, 8 active coils, one
closed dead coil at each end assumed (switch §8).

| | |
|---|---|
| Rate | 0.074 N/mm [estimated] |
| Length at rest / at the bottom | 11.1 / 8.1 mm (minimum working length about 6.25 mm) |
| Force at rest → at the bottom | **105 → 128 g (+22 %)** [estimated] |
| Shear stress at the bottom | 380 N/mm², uncorrected |

**For exactly 100 g at rest:** use a spring about 10 % softer (9 active coils),
or install this one 1.2 mm longer, which adds 1.2 mm of height.

## 6. Sensor [estimated, field of a cylinder magnet on its axis]

- **Magnet:** ⌀3 × 1.5 N52 in the collar. Its lower face is 6.0 mm from the
  sensor element at rest and 3.0 mm at the bottom (along the axis, through the
  tilted board).
- **Field:** 7.5 mT at rest, 39.3 mT at the bottom, inside the DRV5055A3's
  ±85 mT range.
- **Calibration:** the field rises monotonically but not linearly with travel.
  The firmware stores each key's rest and bottom readings and maps the reading
  back to travel. The actuation point and hysteresis are then set as fractions
  of the stroke.
- **Crosstalk:** pressing a neighbour on the same board (20 mm away) changes the
  reading by 0.04 mT, under 0.1 % of the swing. It can be ignored.
- **Supply:** a linear Hall sensor draws about 6 mA continuously. For all keys,
  either budget for that or switch the sensors on in groups. [unverified]
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
