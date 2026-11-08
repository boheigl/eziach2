// Strain gauges and link to the bass module, on the discant's +y side
//
// Force path [given]: discant -> gauges -> bass module. Each gauge is three parts
// [given]: the outer holder (the discant's), the plate, the inner holder (the bass's).
// Two gauges side by side [given], which also holds against torsion, their plates
// in the slope's plane [given]: tilted up by atan(3/16) = 10.62 deg about x, as the
// rows climb (3 per 16) and as the housing's bottom runs, so they sense force normal to
// it. The tilt turns about the middle of the pad's face (gauge_tilt_frame()); the pad's
// face turns with it, so the pad is a wedge, 4 at the bottom, 2 at the top. Fixed side: the outer
// holders, printed as part of the housing [given], growing out of the gauge pad on
// its back face. Each plate slides into its holder from the far end, until its edge
// lands on the pad, and a dowel pin across each jaw keeps it in. Moving side: the
// inner holders, printed with the bass on one mount [given] (../bass/link.scad); the
// bass comes off by sliding them off the plates.
//
// Each bridge reads moment at its column, so force times the arm from the gauges
// to where the force acts. The sum follows the force, the difference the twist.
//
// The gauges sit at the middle of the row, about 130 mm from the main PCB. So a
// link board beside them holds the bridges' ADC (NAU7802); the bass keys' port expander
// is in the bass now, behind the contacts (../bass/elec.scad). Only six wires then run
// the long way: battery + (from the bass), ground, 3.3 V, SDA, SCL, interrupt. They go from the main PCB behind cable 3 to
// the hole's back corner and along a bore inside the housing's back wall, which
// is solid and 6.6 mm thick behind the guides.
//
// The link board is housed [given]: it lies flat in a pocket in the back wall, closed
// by a lid flush with the back face, which snaps in: no screws. Corner ledges carry
// the board, ribs at its ends locate it, the lid keeps it on the ledges. The six
// wires reach the pocket's -x end straight along the bore. The gauges' leads leave
// the plates towards the pad and run along a groove in it into the pocket, through
// a notch in its +x wall, which the wires to the connector leave by too. Where a
// plate's edge lands the groove runs under a 1 mm strip, which is the plate's stop.
//
// Part bodies are boxes; sizes [unverified] until the parts are chosen.
//
// make builds   openscad -o ../build/discant/gauge_link.stl gauge_link.scad
// housing.scad uses gauge_housing_pads(), gauge_holders() and gauge_housing_cuts().

use <main_pcb.scad>

/* [From cover.scad / housing.scad, do not edit here] */
back_y   = 59.3;                 // the housing's back face

/* [Gauge, from ../strain_gauge/] */
plate_top = 12.5;                // the +y edge of plate and outer holder, plate frame
inner_end_abs = 16.7;            // the inner holder's far end from the plate frame's origin

/* [Placement] */
gauge_x  = 0;                    // the row's middle hole; the outline's middle is x = -6.7
gauge_z  = 1.6;                  // middle of the back face, z -7.77 .. 11.03
gauge_dx = 25;                   // each gauge's centre from gauge_x: 11.6 between the holders
half_h   = 5.4;                  // the holders' half thickness
pad_t    = 3;                    // the gauge pad on the back face
pad_x    = [-50, 46];            // from the box to past the far holder
groove_h = 1.6;                  // lead groove in the pad: half height
groove_d = 1.5;                  //   and depth, behind the strips
strip_t  = 1;                    // the plate's stop in front of the groove
strip_in = 9.6;                  // strips from strip_in to strip_out either side of a gauge's middle,
strip_out = 15.4;                //   so under the plate's edge; open between them for the leads
pin_x    = 13.5;                 // dowel pins, as in outer_holder.scad
pin_y    = -13.3;
pin_d    = 1.5;
pin_l    = 10;
plate_y0 = back_y + pad_t + plate_top;   // the plate frame's origin on discant y; turned 180 deg
gauge_tilt = atan(3 / 16);               // the slope's plane [given]
pivot_y  = back_y + pad_t;               // the tilt's axis: the pad face's middle, at gz


/* [Link board, in its pocket in the back wall] */
board_w  = 20.5;                 // along x
board_h  = 13.5;                 // along z
board_t  = 3;                    // board and parts
pk_x     = [-75.7, -51.2];       // pocket: 1.2 of wall to the pad's end; beyond the board's ends
                                 //   room for the wires (-x) and the lid's hooks
pk_z0    = 0.2;                  // its middle: 0.8 under the board above, 0.9 over the bottom plane
pk_y     = 54;                   // its floor: 1.3 from the guides' line
pk_fit   = 0.3;                  // board to the walls, in z
ledge    = 1;                    // floor to the board: room for the wires' joints
lid_t    = 1.2;                  // as the cover
lid_fit  = 0.1;
hook_z   = [[-4.4, -1.4], [1.8, 4.8]];   // the +x and -x hook: beside the notch, and beside the bore
hook_t   = 1;
barb     = 0.4;                  // the hook's catch into the wall

/* [Contacts to the bass, between the outer holders] */
// [given: power and I2C cross by contacts that close when the bass slides on]: a boss
// between the outer holders (5.8 clear either side of the middle) carries a small board
// with nine gold pads, 3 x 3 at 2.54, facing the bass's spring pins (../bass/link.scad).
// Pads: VBAT x 2, GND x 3, SDA, SCL, INT, DET; DET is tied to GND on this board, which
// switches the bass's battery on (../assembly/spec.md). A bore down the boss's middle
// takes the wires into the pad's lead groove, on to the link board.
contact_y  = 84;                 // the pads' face, gauge frame (the outer holders' tips: 89.6)
contact_t  = 0.8;
contact_hw = 5.2;                // half width (x) and half height (z) of boss and board
contact_hh = 5.0;
contact_p  = 2.54;
contact_bore = 2.2;

/* [Six wires] */
bundle_d = 1.8;
bore_d   = 2.6;
bore_y   = 56;                   // in the back wall: 2 from the back face, 2 from the guides' line
bore_x   = [-88, -75];           // from inside the hole into the pocket
bore_z   = -1.4;

$fa = 2; $fs = 0.2;

gz = gauge_z;
module box(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

// the gauge frame: the discant's frame tilted into the slope's plane about the pad face's
// middle; in it the plates point along y as before, and plate_y0, link_y keep their meaning
module gauge_tilt_frame() translate([0, pivot_y, gz]) rotate([gauge_tilt, 0, 0]) translate([0, -pivot_y, -gz]) children();
module gauge_untilt() translate([0, pivot_y, gz]) rotate([-gauge_tilt, 0, 0]) translate([0, -pivot_y, -gz]) children();
function gauge_tilt() = gauge_tilt;
module at_gauge(d) gauge_tilt_frame() translate([gauge_x + d * gauge_dx, plate_y0, gz]) rotate(180) children();
// the plates and their pins; the inner holders are the bass's (../bass/link.scad) [given]
module gauge() for (d = [-1, 1]) at_gauge(d) {
    import("../build/strain_gauge/strain_gauge_plate.stl");
    for (s = [-1, 1]) translate([s * pin_x, pin_y, -pin_l / 2]) cylinder(d = pin_d, h = pin_l);
}
// part of the housing: added after its bottom plane, which they reach past; with them
// the contacts' boss
module gauge_holders() {
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/outer_holder.stl");
    gauge_contact_boss();
}
pk_h = board_h / 2 + pk_fit;                    // the pocket's half height
pk_zz = [pk_z0 - pk_h, pk_z0 + pk_h];
bd_x = [pk_x[1] - 1.5 - board_w, pk_x[1] - 1.5];   // the board
bd_y = pk_y + ledge;
lid_y = back_y - lid_t;
link_y = plate_y0 + inner_end_abs;   // the inner holders' backs: where the bass's mount begins
module link_board() box(bd_x, [bd_y, bd_y + board_t], [pk_z0 - board_h / 2, pk_z0 + board_h / 2]);
// flush with the back face; a hook at each end snaps behind a catch in the wall
module lid() {
    box([pk_x[0] + lid_fit, pk_x[1] - lid_fit], [lid_y, back_y], [pk_zz[0] + lid_fit, pk_zz[1] - lid_fit]);
    for (s = [0, 1]) let(e = pk_x[1 - s] + (s == 0 ? -lid_fit : lid_fit), d = s == 0 ? -1 : 1) {
        box([min(e, e + d * hook_t), max(e, e + d * hook_t)], [lid_y - 1.2, lid_y + 0.1], hook_z[s]);
        box([min(e, e - d * (barb - lid_fit)), max(e, e - d * (barb - lid_fit))], [lid_y - 1.15, lid_y - 0.5], hook_z[s]);
    }
}

// the bundle: main PCB, behind cable 3, the hole's back corner, along the bore
function bundle_pts() = concat(
    [for (p = [[50, 11.7, 4.6], [53.5, 11.7, 4.6], [57, 10.9, 4.4], [60, 9.4, 4]]) from_band(p)],
    [[-113, bore_y, bore_z + 1], [-100, bore_y, bore_z], [bore_x[0], bore_y, bore_z], [bore_x[1], bore_y, bore_z],
     [bore_x[1] + 0.5, bd_y, bore_z]]);
module bundle() {
    p = bundle_pts();
    for (i = [0 : len(p) - 2]) hull() {
        translate(p[i]) sphere(d = bundle_d, $fn = 12);
        translate(p[i + 1]) sphere(d = bundle_d, $fn = 12);
    }
}

// the contact board, gauge frame; pads as thin discs on its face
module contact_board() gauge_tilt_frame() {
    box([-contact_hw, contact_hw], [contact_y - contact_t, contact_y - 0.035], [gz - contact_hh, gz + contact_hh]);
    for (i = [-1 : 1], j = [-1 : 1]) translate([i * contact_p, contact_y - 0.035, gz + j * contact_p])
        rotate([-90, 0, 0]) cylinder(d = 1.8, h = 0.035, $fn = 20);
}
// part of the housing, added after its bottom plane like the holders: the boss under
// the contact board, with the wires' bore
module gauge_contact_boss() gauge_tilt_frame() difference() {
    box([-contact_hw, contact_hw], [back_y + pad_t - 0.5, contact_y - contact_t], [gz - contact_hh, gz + contact_hh]);
    translate([0, back_y + pad_t - 1, gz]) rotate([-90, 0, 0]) cylinder(d = contact_bore, h = contact_y - back_y);
}

// the contacts' wires (VBAT, GND, SDA, SCL, INT; DET stays on the board): down the boss's
// bore, along the pad's groove and through its notch to the link board's +x end
module contact_wires() gauge_tilt_frame() {
    p = [[0, contact_y - contact_t - 0.2, gz], [0, 60.55, gz], [-50.6, 60.55, gz], [-50.6, 56.9, gz], [-51.95, 56.9, gz]];
    for (i = [0 : len(p) - 2]) hull() { translate(p[i]) sphere(d = 1.3, $fn = 12); translate(p[i + 1]) sphere(d = 1.3, $fn = 12); }
}

module gauge_link() { gauge(); link_board(); lid(); bundle(); contact_board(); contact_wires(); }

// added to the housing: the gauge pad, a wedge from the back face to its tilted face
module gauge_housing_pads() hull() {
    box([gauge_x + pad_x[0], gauge_x + pad_x[1]], [back_y - 1, back_y + 0.5], [gz - half_h, gz + half_h]);
    gauge_tilt_frame() box([gauge_x + pad_x[0], gauge_x + pad_x[1]], [back_y + pad_t - 1, back_y + pad_t], [gz - half_h, gz + half_h]);
}

// cut from the housing: the bore for the wires, the pocket, the groove
module gauge_housing_cuts() {
    difference() {
        box(pk_x, [pk_y, back_y + 1], pk_zz);
        // corner ledges under the board
        for (x = [bd_x[0], bd_x[1] - 3], z = [pk_zz[0] - 1, pk_zz[1] - 2])
            box([x, x + 3], [pk_y - 1, bd_y], [z, z + 3]);
        // ribs at the board's ends, beside the hooks and the bore
        for (s = [-1, 1]) let(z = pk_z0 + s * 6)
            box([pk_x[0] - 1, bd_x[0] - 0.1], [pk_y - 1, bd_y + board_t], [z - 1.2, z + 1.2]);
        for (s = [-1, 1]) let(z = pk_z0 + s * 6)
            box([bd_x[1] + 0.1, pk_x[1] + 1], [pk_y - 1, bd_y + board_t], [z - 1.2, z + 1.2]);
    }
    // the catches for the lid's hooks
    box([pk_x[1] - 0.01, pk_x[1] + barb], [lid_y - 1.2, lid_y - 0.45], hook_z[0]);
    box([pk_x[0] - barb, pk_x[0] + 0.01], [lid_y - 1.2, lid_y - 0.45], hook_z[1]);
    g_y = back_y + pad_t - strip_t;                 // the groove's front, behind the strips
    g_x = [pk_x[1] - 0.1, gauge_x + gauge_dx + strip_in];
    // groove and strips follow the pad's tilted face
    gauge_tilt_frame() {
        box(g_x, [g_y - groove_d, g_y + 0.01], [gz - groove_h, gz + groove_h]);
        // open to the pad's face between the strips: to the box, between and inside the plates
        for (o = [[g_x[0], -gauge_dx - strip_out], [-gauge_dx - strip_in, -gauge_dx + strip_in],
                  [-gauge_dx + strip_out, gauge_dx - strip_out], [gauge_dx - strip_in, gauge_dx + strip_in]])
            box([o[0], o[1]], [g_y, back_y + pad_t + 1.2], [gz - groove_h, gz + groove_h]);
    }
    // the notch from the groove into the pocket, past the lid's +x edge; 2 below the lid,
    // so the contacts' wires (1.3 bundle) pass from it into the pocket under the lid
    box([pk_x[1] - 0.1, pad_x[0] + 0.1], [lid_y - 2, g_y], [gz - groove_h - 0.9, gz + groove_h + 0.9]);
    translate([bore_x[0], bore_y, bore_z]) rotate([0, 90, 0]) cylinder(d = bore_d, h = bore_x[1] - bore_x[0]);
    // the contacts' wires: from the boss's bore through the pad into the groove
    gauge_tilt_frame() translate([0, g_y - groove_d, gz]) rotate([-90, 0, 0]) cylinder(d = contact_bore, h = pad_t + 2);
}

echo(str("plate frame y 0 at discant y = ", plate_y0, "; the inner holders' backs at y = ", link_y,
         "; pad x = ", pad_x, "; pocket x = ", pk_x, ", z = ", pk_zz, ", y from ", pk_y));

gauge_link();
