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
wall       = 3;      // thickness above and below the plate
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
//   "lock"    retaining face square: holds the strap's pull; lift the lug on the
//             tongue's tip to release (playing position)
//   "detent"  retaining face at 45 deg: holds the discant's weight, a firm pull
//             releases it; no lug (the stored position's socket, inside the deck)
//   "none"    no latch
latch    = "lock";
tongue_t = 1.0;      // tongue thickness: the wall's inner layer
tongue_x = [4.2, 7.2];   // tongue, x; mirrored
tongue_y = [-15.5, -4.2];   // root (in the bridge) to tip
tooth_x  = [4.2, 5.2];   // in the inner slot (3 .. 6), 1.0 from the column's edge
tooth_y0 = -6.28;    // retaining face: the slot's arc end is at -6.33 .. -6.47 across the tooth
tooth_d  = 0.6;      // how far the tooth reaches into the plate's thickness
cut_w    = 0.5;      // the slot round the tongue
lug_h    = 1.0;      // the lock's lug: above the holder's top face

/* [Preview] */
show_plate = false;  // true also draws the flexure plate, for checking fits

use <strain_gauge_plate.scad>

$fa = 2; $fs = 0.2;

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
module latch_cuts() for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) difference() {
    translate([tongue_x[0] - cut_w, tongue_y[0], z_high - 0.01])
        cube([tongue_x[1] - tongue_x[0] + 2 * cut_w, tongue_y[1] - tongue_y[0] + cut_w, wall + 1]);
    translate([tongue_x[0], tongue_y[0] - 1, z_high - 0.02])
        cube([tongue_x[1] - tongue_x[0], tongue_y[1] - tongue_y[0] + 1, tongue_t + 0.02]);
}
module latch_parts() for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) {
    translate([tooth_x[0], tooth_y0, z_high - tooth_h]) tooth(tooth_x[1] - tooth_x[0], latch == "lock" ? 90 : 45);
    if (latch == "lock")
        translate([tongue_x[0] + 0.5, tongue_y[1] - 1, z_high + tongue_t - 0.01])
            cube([tongue_x[1] - tongue_x[0] - 1, 1, wall - tongue_t + lug_h]);
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
