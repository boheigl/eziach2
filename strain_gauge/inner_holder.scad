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

/* [Flexure plate — read from the STEP, do not edit; plate_bot the bought cell's] */
plate_t    = 2.5;    // plate thickness
web_outer  = 9;      // outer face of the webs = inner edge of the open slot
arm_inner  = 12;     // inner face of the outer arms = outer edge of the slot
plate_bot  = -10.8;  // bottom edge of the plate: the bought cell's [measured 2026-11-21;
                     //   -12.5 in the STEP] (strain_gauge_plate.scad, shorter)
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
back       = 5.7;    // thickness of the closing bridge below the plate: 4 below the STEP's
                     //   edge, and the 1.7 the bought cell is shorter, so that the holder's
                     //   back (y -16.7), the tongue's root in the bridge and the bass's socket
                     //   stay where they were
corner_r   = 2;      // radius on the two vertical edges at the mouth corners,
                     // i.e. at (+x, y_front) and (-x, y_front)
side_walls = true;   // true: walls reach through the open slots (stiffer box)

/* [Lead-in] */
lead_in    = 1.5;    // length of the flared mouth, 0 disables it
lead_c     = 0.6;    // how much the mouth is flared, per side

/* [Gauge and cable recess] */
recess_d   = 1.8;    // depth, cut into the inner face of each plate. The bought cell's lead
                     //   is glued along the whole column, across its width, 4 thick on the
                     //   plate's 2.5: 1.5 proud of one face [measured 2026-11-21]; 1.8 and
                     //   the 0.15 fit leave it 0.45 (was 1.0, for the STEP's bare plate).
                     //   The glue is 7.1 wide at most and runs from the +y edge to y -6.5:
                     //   0.95 to the recess's sides, 1.5 to its back end (recess_back)
                     //   Both faces, so the plate goes in either way up
recess_w   = 9.0;    // width, centred on the column. The column is 6 mm wide
                     // and the inner slots run from |x| = 3 to 6, so 9 mm puts
                     // the recess edges mid-slot: 1.5 mm clear of the column,
                     // 1.5 mm clear of the webs it clamps on.
recess_back = -8.0;  // back end of the recess, just behind the gauge
gauge_y    = -3.5;   // gauge centre, for reference only

/* [Latch and clamp] */
// [2026-11-25: the test print showed the plate rattling in the holder, across and
// sideways, the holder tipping on the W, and the spring tongue's latch neither clicking in
// nor holding; tongue and tooth were small and limp.]
//   "cam"     the playing position: a pressure shoe in the top wall over the W's bottom
//             block and the webs, pressed onto them by a cam: no play across the plate, and
//             the clamp's friction on both faces holds the holder on. [2026-11-25: a U across
//             the plate, its legs over the webs to y shoe_y1 and its middle clear of the lead,
//             longer against tipping than the first shoe over the block alone (to -6.6)]
//             The cam is one of a lever's (../bass/link.scad: cam_lever(), one part for both
//             of the bass's holders) on a steel axle (rod_d) through two lugs on the rails; an M2 grub screw in the
//             shoe, under the cam, sets the clamping force, so the print's tolerances do not.
//             (A tooth as well was given up: it needs 0.7 of travel, the clamp 0.25, and a
//             shoe hinged at its back tips by 10 deg over 0.7 and bears on its front edge.)
//   "detent"  the stored position's socket: a spring tongue each side, its tooth in the
//             inner slot between web and column (|x| 3 .. 6), its retaining face at 45 deg
//             behind the slot's closed end: it rides over the bottom block and drops in,
//             holds the discant's weight, a firm pull releases it
//   "none"    neither
latch    = "cam";
// CRUSH RIBS [2026-11-25: the 0.2 / 0.15 fits rattled]: half-round ribs along y on the
// pocket's faces, rib_p proud, so they stand rib_p - clearance into the plate's way and give
// as it goes in: on both side walls (0.05 into the 0.2), and for the detent on the floor
// over the webs (0.1 into the 0.15; the cam's shoe presses the plate onto the floor instead)
rib_r    = 0.4;
rib_p    = 0.25;
rib_in   = 1.5;      // their run-in from the mouth: they start at nothing

// --- the detent's tongue
// tongue thickness 1.5 [2026-11-25: 1.2 was limp in the test print]: in PETG (E about
// 2000 MPa) about twice the 1.2's hold, 1.6 % at the root (see the echo)
tongue_t = 1.5;
tongue_x = [4.2, 7.2];   // tongue, x; mirrored
tongue_y = [-15.5, -4.2];   // root (in the bridge) to tip
tooth_x  = [4.2, 5.2];   // in the inner slot (3 .. 6), 1.0 from the column's edge
tooth_y0 = -6.28;    // retaining face: the slot's arc end is at -6.33 .. -6.47 across the tooth
tooth_d  = 0.6;      // how far the tooth reaches into the plate's thickness
cut_w    = 0.5;      // the slot round the tongue, and round the cam's shoe
under_h  = 0.4;      // the slot under the tongue's root (and the shoe's), ending round at the root
root_r   = 0.5;      // fillet in the corner above the root
// the detent's stop: a bar across the slot over the tongue, under which the tongue lifts
// stop_gap and no further: the tooth needs 0.6 to clear the W [2026-11-25: 0.85 with the 1.2 tongue]
stop_gap = 0.75;
stop_y   = [-7.0, -5.6]; // behind the tongue's tip, over the tooth

// --- the cam's shoe, lugs and axle
shoe_x   = 8.5;      // half width: over the webs (6 .. 9) to 0.6 short of the side walls; the
                     //   top wall's rails outside (|x| 9 .. 11.5) stay whole and carry the lugs
flex_x   = 5.5;      // the flexure's half width (narrower: less of the screw's force goes into it)
shoe_y1  = -4.0;     // its front: the legs over the webs (to 3.5); in the middle the U's top
                     //   bridges the lead's clearance
shoe_gap = 0.1;      // at rest its underside stands this over the pocket's ceiling: the
                     //   cam's stroke onto the plate is shoe_gap + fit / 2 = 0.25
shoe_top = 4.6;
flex_t   = 0.8;      // the strip it hangs from, back to the bridge (tongue_y[0])
// the screw [2026-11-25: an M3 at y -9.3 left 0.2 behind the thread's root to the shoe's
// back, and its thread broke into the clearance over the lead; the shoe is solid only
// from y_mouth to shoe_clr]
scr_d    = 1.6;      // tap drill for the M2 grub screw (M2 x 3, ISO 4026), from the top
shoe_clr = -7.0;     // the shoe's clearance over the lead from here (the top wall's from
                     //   recess_back, -8): the glue reaches y -6.5 at most, 0.5 behind
scr_keep = 0.6;      // shoe left under the screw's hole: the screw never reaches the plate
scr_proud = 0.5;     // the screw's top over the shoe's at rest, where the cam meets it
rod_d    = 2.0;      // steel axle, e.g. stainless 2 mm, cut to length [stock]
rod_hole = 2.0;      // printed undersize by a little: the axle a light fit; ream if tight
ax_z     = 7.2;      // the axle's height
lug_wall = 0.8;      // round the axle's hole: lug top 9.0, the old lugs' (link.scad hold_hi)
lug_x    = [9.0, 11.5];   // on the rails, outside the shoe
cam_rel  = 0.3;      // released, the cam this far over the screw

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
// --- the detent's tongue (see [Latch and clamp])
z_t      = z_high + tongue_t;                     // the tongue's top
slot_end = tongue_y[1] + cut_w;
// lifts along the tongue, per unit force over EI, for a load at xl from the root
function defl(x, xl) = x <= xl ? x * x * (3 * xl - x) / 6 : xl * xl * (3 * x - xl) / 6;
x_tooth = tooth_y0 - tongue_y[0];
// root strain = deflection x load distance x t / (2 defl)
function root_strain(d, x, xl) = 100 * d * xl * tongue_t / (2 * defl(x, xl));
module detent_cuts() for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) {
    difference() {
        translate([tongue_x[0] - cut_w, tongue_y[0], z_high - 0.01])
            cube([tongue_x[1] - tongue_x[0] + 2 * cut_w, slot_end - tongue_y[0], wall + 1]);
        translate([tongue_x[0], tongue_y[0] - 1, z_high - 0.02])
            cube([tongue_x[1] - tongue_x[0], tongue_y[1] - tongue_y[0] + 1, tongue_t + 0.02]);
        // the fillet above the root: left standing in the corner of tongue and wall
        translate([tongue_x[0] - cut_w - 0.01, tongue_y[0] - 0.01, z_t - 0.01]) difference() {
            cube([tongue_x[1] - tongue_x[0] + 2 * cut_w + 0.02, root_r + 0.01, root_r + 0.01]);
            translate([-0.01, root_r + 0.01, root_r + 0.01]) rotate([0, 90, 0])
                cylinder(r = root_r, h = tongue_x[1] - tongue_x[0] + 2 * cut_w + 0.04);
        }
        // the stop: a bar over the tongue, stop_gap above it
        translate([tongue_x[0] - cut_w - 0.02, stop_y[0], z_t + stop_gap])
            cube([tongue_x[1] - tongue_x[0] + 2 * cut_w + 0.04, stop_y[1] - stop_y[0], wall]);
    }
    // the slot under the root, from the pocket back to the root, its end round
    translate([tongue_x[0], tongue_y[0] + under_h / 2, z_high - under_h]) {
        cube([tongue_x[1] - tongue_x[0], y_mouth - tongue_y[0] - under_h / 2 + 0.01, under_h + 0.01]);
        translate([0, 0, under_h / 2]) rotate([0, 90, 0]) cylinder(d = under_h, h = tongue_x[1] - tongue_x[0], $fn = 16);
    }
}
module detent_parts() for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0])
    translate([tooth_x[0], tooth_y0, z_high - tooth_h]) tooth(tooth_x[1] - tooth_x[0], 45);
if (latch == "detent") echo(str("detent tongue: free ", tongue_y[1] - tongue_y[0], " mm, root strain at the tooth's ",
    tooth_d, " mm lift ", round(10 * root_strain(tooth_d, x_tooth, x_tooth)) / 10, " % (tongue ", tongue_t, "), at the stop ",
    round(10 * root_strain(stop_gap, x_tooth, x_tooth)) / 10, " %"));

// --- the cam's shoe (see [Latch and clamp])
shoe_bot = z_high + shoe_gap;                     // its underside at rest
scr_y    = (y_mouth + shoe_clr) / 2;              // the screw and the axle: midway in the
                                                  //   shoe's solid part (-11 .. shoe_clr)
scr_top  = shoe_top + scr_proud;                  // the screw's top at rest, where the cam meets it
stroke   = shoe_gap + fit / 2;                    // onto the plate
lug_r    = rod_hole / 2 + lug_wall;
lug_top  = ax_z + lug_r;
lug_y0   = scr_y - lug_r - (ax_z - top_z) - 0.1;  // the lug's underside rises at 45 deg from here
// the cam, for the lever (../bass/link.scad): [axle y, z, d, the hub's half width between
// the lugs, the cam's radius under the axle released and locked (onto the plate, no
// force: the screw sets that)]
function cam_axle() = [scr_y, ax_z, rod_d, lug_x[0] - 0.3,
                       ax_z - scr_top - cam_rel, ax_z - (scr_top - stroke)];
function latch_top() = latch == "cam" ? lug_top : top_z;
// the shoe's room through the top wall: the flexure's from its root, the shoe's from
// cut_w behind the bridge's face to past its front
module shoe_cuts() {
    translate([-flex_x - cut_w, tongue_y[0], z_high - 0.01])
        cube([2 * (flex_x + cut_w), y_mouth - tongue_y[0] + 0.01, wall + 1]);
    translate([-shoe_x - cut_w, y_mouth - cut_w, z_high - 0.01])
        cube([2 * (shoe_x + cut_w), shoe_y1 + 2 * cut_w - y_mouth, wall + 1]);
    // the slot under the flexure, back to its root, its end round
    translate([-flex_x, tongue_y[0] + under_h / 2, shoe_bot - under_h]) {
        cube([2 * flex_x, y_mouth - tongue_y[0] - under_h / 2 + 0.01, under_h + 0.01]);
        translate([0, 0, under_h / 2]) rotate([0, 90, 0]) cylinder(d = under_h, h = 2 * flex_x, $fn = 16);
    }
}
module shoe_parts() {
    difference() {
        union() {
            translate([-shoe_x, y_mouth, shoe_bot]) cube([2 * shoe_x, shoe_y1 - y_mouth, shoe_top - shoe_bot]);
            translate([-flex_x, tongue_y[0] - 0.01, shoe_bot]) cube([2 * flex_x, y_mouth - tongue_y[0] + 0.02, flex_t]);
            // the fillet above the flexure's root
            translate([-flex_x, tongue_y[0] - 0.01, shoe_bot + flex_t - 0.01]) difference() {
                cube([2 * flex_x, root_r + 0.01, root_r + 0.01]);
                translate([-0.01, root_r + 0.01, root_r + 0.01]) rotate([0, 90, 0]) cylinder(r = root_r, h = 2 * flex_x + 0.02);
            }
        }
        // the U's inside: over the recess it clears the glued lead as the top wall does, when pressed down
        translate([-recess_w / 2, shoe_clr, shoe_bot - 0.01]) cube([recess_w, 10, z_high + recess_d + stroke - shoe_bot + 0.01]);
        // the screw's tapped hole, blind: scr_keep left under it
        translate([0, scr_y, shoe_bot + scr_keep]) cylinder(d = scr_d, h = 10, $fn = 24);
    }
    // the lugs on the top wall's rails, the axle's hole along x pointed upwards in the
    // print (+y); their underside rises at 45 deg from the top face (grown in +y)
    for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) difference() {
        translate([lug_x[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(lug_x[1] - lug_x[0])
            polygon([[lug_y0, top_z - 0.01], [lug_y0 + lug_top - top_z, lug_top], [scr_y + lug_r, lug_top], [scr_y + lug_r, top_z - 0.01]]);
        translate([lug_x[0] - 1, scr_y, ax_z]) rotate([0, 90, 0]) linear_extrude(lug_x[1] - lug_x[0] + 2)
            hull() { circle(d = rod_hole); translate([0, rod_hole / 2 * sqrt(2)]) square(0.01, center = true); }
    }
}
if (latch == "cam") echo(str("cam: axle at y ", scr_y, " z ", ax_z, ", lug top ", lug_top, "; the cam's radius under the axle ",
    cam_axle()[4], " released, ", cam_axle()[5], " locked; stroke ", stroke, "; flexure ", y_mouth - tongue_y[0], " long, ", flex_t, "; the screw's walls ", scr_y - scr_d / 2 - y_mouth, " / ", shoe_clr - scr_y - scr_d / 2, " to its tap drill"));

// --- crush ribs (see [Latch and clamp]): along y from the back to the mouth, rib_in to come up
module rib(p, axis) hull() {   // p: a point on the face it stands on; axis: its outward normal (x or z, +-1)
    for (e = [[y_mouth, 1], [y_front - lead_in - rib_in, 1], [y_front - lead_in, 0]])
        translate([p[0] + axis[0] * (rib_r - rib_p * e[1]), e[0], p[1] + axis[1] * (rib_r - rib_p * e[1])])
            rotate([-90, 0, 0]) cylinder(r = rib_r, h = 0.01, $fn = 16);
}
module ribs() {
    for (s = [-1, 1]) rib([s * pocket_x, 0], [s, 0]);   // side walls
    if (latch == "detent") for (s = [-1, 1]) rib([s * (web_outer - 1.5), z_low], [0, -1]);   // floor, over the webs
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
        if (latch == "detent") detent_cuts();
        if (latch == "cam") shoe_cuts();
    }
    if (latch == "detent") detent_parts();
    if (latch == "cam") shoe_parts();
    intersection() { ribs(); translate([0, 0, z_bot]) linear_extrude(height = height) outline(); }
}

inner_holder();

if (show_plate) %linear_extrude(height = plate_t) plate_profile();
