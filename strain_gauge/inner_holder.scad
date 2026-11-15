// Inner holder for the strain-gauge flexure plate
//
// Slides onto the W-shaped inner part from below (+y in the top view) and grips
// it from above and below. The gauge leads run forward and leave through the
// mouth, in +y, towards the outer holder. It stays clear of the two outer arms, which are the
// fixed mounting points, so this holder can move with the loaded inner part.
//
// Coordinates: origin at the centre of the plate in all three axes, so the
// plate runs from z = -plate_t/2 to +plate_t/2 and this holder is symmetric
// about z = 0.
//
// Printing: stand it on the closed end (the bridge, -y) with the mouth facing
// up. The pocket is then a blind slot opening upwards, so nothing has to be
// bridged or supported, and both fitted dimensions lie in the machine's XY
// plane, where they behave the same way. Printed the other way up, the top
// plate has to bridge 18 mm and lands rough on the face that grips the plate.
//
// The W is the bottom block with its three upward prongs: the two webs at
// |x| = 6..9 and the central column at |x| < 3. The open slots at |x| = 9..12
// run from the bottom edge up to y = 6.5, which is what the side walls use to
// reach through the plate.

/* [Flexure plate — read from the STEP, do not edit] */
plate_t    = 2.5;    // plate thickness
web_outer  = 9;      // outer face of the webs = inner edge of the open slot
arm_inner  = 12;     // inner face of the outer arms = outer edge of the slot
plate_bot  = -12.5;  // bottom edge of the plate
web_tip    = 3.5;    // top of the two web prongs
slot_top   = 6.5;    // where the open slots close at the U-turn

/* [Holder] */
wall       = 4.5;    // thickness above and below the plate [given: thicker walls for strength;
                     //   was 3: bending stress in them about (3/4.5)^2 = 0.44 as much]
fit        = 0.3;    // clearance on the plate thickness, total (0.15 per face)
w_clear    = 0.2;    // clearance to the W — this is the sliding fit.
                     //   0.05  precision machined
                     //   0.1   milled / reamed
                     //   0.15  SLA / resin, or a well tuned FDM machine
                     //   0.2   FDM  (default — set for 3D printing)
                     // The walls guide along 17 mm of the webs, so too tight
                     // here binds rather than grips.
arm_clear  = 0.5;    // clearance to the fixed outer arms — must never touch
reach      = 1.0;    // how far past the web tips the holder covers
back       = 4;      // thickness of the closing bridge below the plate
corner_r   = 2;      // radius on the two vertical edges at the mouth corners,
                     // i.e. at (+x, y_front) and (-x, y_front)
side_walls = true;   // true: walls reach through the open slots (stiffer box)

/* [Lead-in] */
lead_in    = 1.5;    // length of the flared mouth, 0 disables it
lead_c     = 0.6;    // how much the mouth is flared, per side

/* [Gauge and cable recess] */
recess_d   = 1.0;    // depth, cut into the inner face of each plate
recess_w   = 9.0;    // width, centred on the column. The column is 6 mm wide
                     // and the inner slots run from |x| = 3 to 6, so 9 mm puts
                     // the recess edges mid-slot: 1.5 mm clear of the column,
                     // 1.5 mm clear of the webs it clamps on.
recess_back = -8.0;  // back end of the recess, just behind the gauge
gauge_y    = -3.5;   // gauge centre, for reference only

/* [Latch] */
// A spring tongue in the top wall each side, its tooth in the inner slot between web and
// column (|x| 3 .. 6), behind the slot's closed end (y -6.5): it rides over the W's
// bottom block while the holder slides on and drops into the slot at the end. It only
// touches the W, never the column or the fixed arms, so the force still runs through
// the column [given: latch in both positions]. The tongue bends into a relief in its
// own wall, so it needs no room outside the holder.
//   "lock"    retaining face square: holds the strap's pull; a lug on the tongue's end
//             carries a steel rod across all four tongues of the bass's two holders, which
//             lifts them at once (playing position; below, and ../bass/link.scad)
//   "detent"  retaining face at 45 deg: holds the discant's weight, a firm pull
//             releases it; no lug (the stored position's socket, inside the deck)
//   "none"    no latch
latch    = "lock";
// tongue thickness: the wall's inner layer. The detent's is thicker [chosen 2026-11-15]:
// in PETG (E about 2000 MPa) a 1.2 tongue holds the stored discant with about 15 N against
// its 3.5 N, twice the 1.0's, at 1.3 % strain at the root (see the echo)
tongue_t = latch == "detent" ? 1.2 : 1.0;
tongue_x = [4.2, 7.2];   // tongue, x; mirrored
tongue_y = [-15.5, -4.2];   // root (in the bridge) to tip
tooth_x  = [4.2, 5.2];   // in the inner slot (3 .. 6), 1.0 from the column's edge
tooth_y0 = -6.28;    // retaining face: the slot's arc end is at -6.33 .. -6.47 across the tooth
tooth_d  = 0.6;      // how far the tooth reaches into the plate's thickness
cut_w    = 0.5;      // the slot round the tongue
// [chosen 2026-11-15, PETG] Under the tongue's first 2.8 mm the bridge stood solid, so it
// bent only from the pocket's edge (y -12.7): 8.5 mm long, 1.25 % at the root, a sharp
// corner on the tension side. A slot under it frees its whole length (11.3 mm, 0.7 %);
// its end is round, and the corner above the root has a fillet.
under_h  = 0.4;      // the slot under the tongue's root, ending round at the root
root_r   = 0.5;      // fillet in the corner above the root
// The detent's stop: a bar across the slot over the tongue, under which the tongue lifts
// stop_gap and no further: the tooth needs 0.6 to clear the W. (The lock's stop is its
// ear, below.)
stop_gap = 0.85;
stop_y   = [-7.0, -5.6]; // behind the tongue's tip, over the tooth (the detent only, below)

// THE LOCK'S LUG AND ROD [chosen 2026-11-15: lift all four tongues at once; the bass is
// printed standing on its hand face, so the holders stand on their bridges and grow in
// +y]. Everything grows support-free in +y: the lug rises from the tongue at 45 deg and
// runs on past the tongue's tip, in the slot, which goes on to slot_end; at its end it
// carries a cross hole for a stock steel rod (rod_d) through the lugs of all four
// tongues (../bass/link.scad: latch_rod()). The rod is pressed in after printing. The
// lug makes the tongue rigid from lug_y0 on, so it bends over lug_y0 - tongue_y[0].
// The stop is an ear on the lug's outer side in a pocket in the slot's wall: the wall
// over it ends the lift (no bar over the tongue, so the lug can grow at 45 deg); the
// rod's slack in its holes is not counted.
rod_d    = 2.0;      // steel rod, e.g. stainless 2 mm, cut to length [stock]
rod_hole = 2.0;      // printed undersize by a little: a light press fit; ream if too tight
rod_gap  = 0.3;      // the rod's underside over the holder's top face
lug_wall = 0.8;      // round the hole
lug_y0   = -7.4;     // where the lug rises from the tongue: rigid from here on
ear_w    = 1.2;      // the ear: from the tongue's outer side (tongue_x[1]), 0.7 into the wall
ear_z    = [2.6, 3.3];
ear_c    = 0.4;      // the ear's clearance in its pocket (all sides but the lift)
lift_t   = 0.85;     // the tooth's lift at the stop (the W needs tooth_d)

/* [Preview] */
show_plate = false;  // true also draws the flexure plate, for checking fits

use <strain_gauge_plate.scad>

$fa = 2; $fs = 0.2;

top_z    = plate_t / 2 + fit / 2 + wall;          // the holder's top face (5.9)
z_low    = -plate_t / 2 - fit / 2;                // underside of the pocket
z_high   =  plate_t / 2 + fit / 2;                // top of the pocket
z_bot    = z_low - wall;                          // underside of the holder
height   = wall + fit + plate_t + wall;           // total height
outer_x  = side_walls ? arm_inner - arm_clear     // 11.5 — walls sit in the slots
                      : web_outer + 1;            // 10   — plates only, 2 mm clear
pocket_x = side_walls ? web_outer + w_clear       // 9.1  — inner face of the walls
                      : outer_x + 1;              // cut right through in x
y_front  = web_tip + reach;                       // front edge of the holder
y_mouth  = plate_bot - w_clear;                   // inner face of the bridge
y_back   = y_mouth - back;                        // outer face of the bridge

echo(str("inner holder  ", 2 * outer_x, " x ", y_front - y_back, " x ", height, " mm"));
echo(str("clearance to outer arm: ", arm_inner - outer_x, " mm"));
echo(str("slide fit on the W:     ", pocket_x - web_outer, " mm per side, ",
         fit / 2, " mm per face"));
echo(str("clearance above web tips: ", slot_top - y_front, " mm to the U-turn"));
echo(str("recess ", recess_w, " x ", y_front - recess_back, " x ", recess_d,
         " mm, opens at the mouth, remaining wall ", wall - recess_d, " mm"));
echo(str("clamped behind the recess from y = ", y_mouth, " to ", recess_back));
echo(str("mouth corners rounded R", corner_r, "; side wall there tapers from ",
         outer_x - pocket_x, " mm to nothing over the last ", corner_r, " mm"));

// Recess in one plate: clears the gauge and carries its leads forward, out of
// the mouth in +y. s = +1 cuts the top plate, s = -1 the bottom one.
module recess(s) {
    z0 = (s > 0) ? z_high : z_low - recess_d;
    translate([-recess_w / 2, recess_back, z0])
        cube([recess_w, y_front - recess_back + 1, recess_d]);
}

// Flared mouth: makes a printed holder start onto the plate instead of
// catching on the first layer's edge.
module mouth() {
    hull() {
        translate([-pocket_x, y_front - lead_in, z_low])
            cube([2 * pocket_x, 0.01, plate_t + fit]);
        translate([-pocket_x - lead_c, y_front, z_low - lead_c])
            cube([2 * (pocket_x + lead_c), 0.01, plate_t + fit + 2 * lead_c]);
    }
}

// Outer footprint: square at the closed end, the two corners at the mouth
// rounded. Extruded in z, so both vertical edges there carry the radius.
module outline() {
    hull() {
        translate([ outer_x - corner_r, y_front - corner_r]) circle(r = corner_r);
        translate([-outer_x + corner_r, y_front - corner_r]) circle(r = corner_r);
        translate([-outer_x, y_back]) square([2 * outer_x, 0.01]);
    }
}

// the tooth, x [0, w], in y-z: retaining face at y = 0 (square, or at 45 deg for the
// detent), the lead-in ramp towards +y, which the plate's edge meets first
tooth_h = z_high - (plate_t / 2 - tooth_d);       // from the pocket's ceiling down
module tooth(w, angle) {
    ret = tooth_h / tan(angle);                   // the retaining face's run
    rotate([90, 0, 90]) linear_extrude(w) polygon([
        [0, tooth_h], [ret, 0], [ret + 0.4, 0], [ret + 0.4 + 1.6, tooth_h]]);
}
// the lock's lug, rod and ear (see [Latch])
z_t      = z_high + tongue_t;                     // the tongue's top
rod_zc   = top_z + rod_gap + rod_d / 2;           // the rod's axis, z
lug_top  = rod_zc + rod_hole / 2 + lug_wall;
lug_r    = rod_hole / 2 + lug_wall;
rod_yc   = lug_y0 + (rod_zc - z_t) + lug_r * sqrt(2);   // its wall lug_wall off the 45 deg face
lug_y1   = rod_yc + lug_r;                        // the lug's end
slot_end = latch == "lock" ? lug_y1 + cut_w : tongue_y[1] + cut_w;
ear_y    = [tongue_y[1] + 0.5, tongue_y[1] + 3.0];   // just past the tongue's tip: the less it lifts there, the less pocket
// lifts along the tongue, per unit force over EI, for a load at xl from the root: bending
// up to the lug, rigid past it
lug_a = lug_y0 - tongue_y[0];
function defl(x, xl) = let(a = min(lug_a, xl)) x <= a ? x * x * (3 * xl - x) / 6
    : a * a * (3 * xl - a) / 6 + a * (2 * xl - a) / 2 * (x - a);
x_tooth = tooth_y0 - tongue_y[0];
x_rod   = rod_yc - tongue_y[0];
ear_gap = lift_t * defl(ear_y[1] - tongue_y[0], x_rod) / defl(x_tooth, x_rod);
rod_lift = lift_t * defl(x_rod, x_rod) / defl(x_tooth, x_rod);
// root strain = deflection x load distance x t / (2 defl)
function root_strain(d, x, xl) = 100 * d * xl * tongue_t / (2 * defl(x, xl));
// the rod in this holder's frame: [y, z of its axis, d]
function latch_rod() = [rod_yc, rod_zc, rod_d];
function latch_top() = lug_top;

module latch_cuts() for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) {
    difference() {
        translate([tongue_x[0] - cut_w, tongue_y[0], z_high - 0.01])
            cube([tongue_x[1] - tongue_x[0] + 2 * cut_w, slot_end - tongue_y[0], wall + 1]);
        translate([tongue_x[0], tongue_y[0] - 1, z_high - 0.02])
            cube([tongue_x[1] - tongue_x[0], tongue_y[1] - tongue_y[0] + 1, tongue_t + 0.02]);
        // the fillet above the root: left standing in the corner of tongue and wall
        translate([tongue_x[0] - cut_w - 0.01, tongue_y[0] - 0.01, z_high + tongue_t - 0.01]) difference() {
            cube([tongue_x[1] - tongue_x[0] + 2 * cut_w + 0.02, root_r + 0.01, root_r + 0.01]);
            translate([-0.01, root_r + 0.01, root_r + 0.01]) rotate([0, 90, 0])
                cylinder(r = root_r, h = tongue_x[1] - tongue_x[0] + 2 * cut_w + 0.04);
        }
        // the detent's stop: a bar over the tongue, stop_gap above it
        if (latch != "lock") translate([tongue_x[0] - cut_w - 0.02, stop_y[0], z_high + tongue_t + stop_gap])
            cube([tongue_x[1] - tongue_x[0] + 2 * cut_w + 0.04, stop_y[1] - stop_y[0], wall]);
    }
    // the lock's ear pocket in the slot's outer wall: the wall over it is the stop
    if (latch == "lock")
        translate([tongue_x[1] + cut_w - 0.01, ear_y[0] - ear_c, ear_z[0] - ear_c])
            cube([ear_w - cut_w + ear_c + 0.01, ear_y[1] - ear_y[0] + 2 * ear_c, ear_z[1] - ear_z[0] + ear_c + ear_gap]);
    // the slot under the root, from the pocket back to the root, its end round
    translate([tongue_x[0], tongue_y[0] + under_h / 2, z_high - under_h]) {
        cube([tongue_x[1] - tongue_x[0], y_mouth - tongue_y[0] - under_h / 2 + 0.01, under_h + 0.01]);
        translate([0, 0, under_h / 2]) rotate([0, 90, 0]) cylinder(d = under_h, h = tongue_x[1] - tongue_x[0], $fn = 16);
    }
}
// root strain when the W lifts the tooth tooth_d (load at the tooth) and at the stop
echo(latch == "lock"
    ? str("latch tongue (lock): bends over ", lug_a, " mm; root strain at the tooth's ", tooth_d, " mm lift ",
          round(10 * root_strain(tooth_d, x_tooth, x_tooth)) / 10, " %; rod at y ", round(100 * rod_yc) / 100,
          " z ", rod_zc, ", lifts ", round(100 * rod_lift) / 100, " mm to the stop (tooth ", lift_t, "), root strain there ",
          round(10 * root_strain(rod_lift, x_rod, x_rod)) / 10, " %; ear gap ", round(100 * ear_gap) / 100,
          "; lug top ", lug_top)
    : str("latch tongue (", latch, "): free ", tongue_y[1] - tongue_y[0], " mm, root strain at the tooth's ", tooth_d,
          " mm lift ", round(10 * root_strain(tooth_d, x_tooth, x_tooth)) / 10, " % (tongue ", tongue_t, ")"));
module latch_parts() for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) {
    translate([tooth_x[0], tooth_y0, z_high - tooth_h]) tooth(tooth_x[1] - tooth_x[0], latch == "lock" ? 90 : 45);
    if (latch == "lock") difference() {
        union() {
            // the lug in y-z: from the tongue at 45 deg up to its top, on to its end
            translate([tongue_x[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(tongue_x[1] - tongue_x[0])
                polygon([[lug_y0, z_t - 0.01], [lug_y0 + lug_top - z_t, lug_top], [lug_y1, lug_top],
                         [lug_y1, z_high], [tongue_y[1] - 0.01, z_high], [tongue_y[1] - 0.01, z_t - 0.01]]);
            // the ear: the stop, in its pocket
            translate([tongue_x[1] - 0.01, ear_y[0], ear_z[0]]) cube([ear_w + 0.01, ear_y[1] - ear_y[0], ear_z[1] - ear_z[0]]);
        }
        // the rod's hole, along x, pointed upwards in the print (+y)
        translate([tongue_x[0] - 1, rod_yc, rod_zc]) rotate([0, 90, 0]) linear_extrude(tongue_x[1] - tongue_x[0] + 2)
            hull() { circle(d = rod_hole); translate([0, rod_hole / 2 * sqrt(2)]) square(0.01, center = true); }
    }
}

module inner_holder() {
    difference() {
        translate([0, 0, z_bot]) linear_extrude(height = height) outline();

        // pocket the plate slides into, open towards +y
        translate([-pocket_x, y_mouth, z_low])
            cube([2 * pocket_x, y_front - y_mouth + 1, plate_t + fit]);

        recess(1);
        recess(-1);
        if (lead_in > 0) mouth();
        if (latch != "none") latch_cuts();
    }
    if (latch != "none") latch_parts();
}

inner_holder();

if (show_plate) %linear_extrude(height = plate_t) plate_profile();
