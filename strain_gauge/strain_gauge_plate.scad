// Strain-gauge flexure plate
//
// Geometry taken from StrainGauge.step (Onshape AP242 export, "Part Studio 1 -
// Part 1"). The STEP profile is reproduced segment for segment, so this model
// and the CAD file describe the same solid.
//
// Envelope 30 x 25 x 2.5 mm. Two hairpin slots, 3 mm wide, open at the bottom
// edge, run up the plate, turn across the top and return to a closed end. Arms
// and webs are also 3 mm wide, and every free end is a half-round cap of that
// diameter. All corners are R1.5 except the two top corners at R3.
//
// Coordinates: origin at the centre of the part in all three axes, so the
// material runs from z = -thickness/2 to +thickness/2. The STEP file itself
// places the plate from z = 0 upwards — this model is shifted down by 1.25 mm
// against it, everything else is identical.

/* [Size] */
thickness = 2.5;     // mm, as modelled in the STEP

/* [Output] */
export_2d = false;   // true renders the flat profile only

/* [Resolution] */
arc_step = 3;        // degrees per tessellated arc segment

// Profile loop as exported from the STEP, in mm:
//   ["L", start, end]
//   ["A", start, end, centre, radius, counter-clockwise]
profile = [
  ["A", [-7.5, -12.5], [-9, -11], [-7.5, -11], 1.5, false],
  ["L", [-9, -11], [-9, 2]],
  ["A", [-9, 2], [-6, 2], [-7.5, 2], 1.5, false],
  ["L", [-6, 2], [-6, -5]],
  ["A", [-6, -5], [-3, -5], [-4.5, -5], 1.5, true],
  ["L", [-3, -5], [-3, 5]],
  ["A", [-3, 5], [-4.5, 6.5], [-4.5, 5], 1.5, true],
  ["L", [-4.5, 6.5], [-10.5, 6.5]],
  ["A", [-10.5, 6.5], [-12, 5], [-10.5, 5], 1.5, true],
  ["L", [-12, 5], [-12, -11]],
  ["A", [-12, -11], [-15, -11], [-13.5, -11], 1.5, false],
  ["L", [-15, -11], [-15, 9.5]],
  ["A", [-15, 9.5], [-12, 12.5], [-12, 9.5], 3, false],
  ["L", [-12, 12.5], [12, 12.5]],
  ["A", [12, 12.5], [15, 9.5], [12, 9.5], 3, false],
  ["L", [15, 9.5], [15, -11]],
  ["A", [15, -11], [12, -11], [13.5, -11], 1.5, false],
  ["L", [12, -11], [12, 5]],
  ["A", [12, 5], [10.5, 6.5], [10.5, 5], 1.5, true],
  ["L", [10.5, 6.5], [4.5, 6.5]],
  ["A", [4.5, 6.5], [3, 5], [4.5, 5], 1.5, true],
  ["L", [3, 5], [3, -5]],
  ["A", [3, -5], [6, -5], [4.5, -5], 1.5, true],
  ["L", [6, -5], [6, 2]],
  ["A", [6, 2], [9, 2], [7.5, 2], 1.5, false],
  ["L", [9, 2], [9, -11]],
  ["A", [9, -11], [7.5, -12.5], [7.5, -11], 1.5, false],
  ["L", [7.5, -12.5], [-7.5, -12.5]]
];

function ang(c, p) = atan2(p[1] - c[1], p[0] - c[0]);

function seg_points(s) =
    s[0] == "L" ? [s[1]]
    : let (c = s[3], r = s[4], ccw = s[5],
           a1 = ang(c, s[1]),
           a2raw = ang(c, s[2]),
           a2 = ccw ? (a2raw <= a1 ? a2raw + 360 : a2raw)
                    : (a2raw >= a1 ? a2raw - 360 : a2raw),
           n = max(2, ceil(abs(a2 - a1) / arc_step)))
      [for (i = [0 : n - 1])
          let (a = a1 + (a2 - a1) * i / n)
          [c[0] + r * cos(a), c[1] + r * sin(a)]];

function outline() = [for (s = profile) for (p = seg_points(s)) p];

module plate_profile() { polygon(outline()); }

if (export_2d) plate_profile();
else linear_extrude(height = thickness, center = true) plate_profile();
