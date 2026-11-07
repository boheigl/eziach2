// Strain gauges and link to the bass module, on the discant's +y side
//
// Force path [given]: discant -> gauges -> detachable connector -> bass module.
// Two gauges side by side [given], which also holds against torsion, their plates
// in the x/y plane [given], so they sense force along z. Fixed side: the outer
// holders, on a bracket screwed to the housing's back face. Moving side: the
// inner holders, tied by one rigid link plate [given: a plate for the bass side,
// part of the connector], which stays on the gauges when the bass comes off.
//
// Each bridge reads moment at its column, so force times the arm from the gauges
// to where the force acts. The sum follows the force, the difference the twist.
//
// The gauges sit at the middle of the row, about 130 mm from the main PCB. So a
// link board beside them holds the bridges' ADC (NAU7802) and an I2C port expander
// (MCP23017) for the bass keys. Only six wires then run the long way: battery +,
// ground, 3.3 V, SDA, SCL, interrupt. They go from the main PCB behind cable 3 to
// the hole's back corner and along a bore inside the housing's back wall, which
// is solid and 6.6 mm thick behind the guides.
//
// Part bodies are boxes; sizes [unverified] until the parts are chosen.
//
// make builds   openscad -o ../build/discant/gauge_link.stl gauge_link.scad
// housing.scad uses gauge_housing_cuts().

use <main_pcb.scad>

/* [From cover.scad / housing.scad, do not edit here] */
back_y   = 59.3;                 // the housing's back face
screw_pilot = 1.6;

/* [Gauge, from ../strain_gauge/] */
plate_top = 12.5;                // the +y edge of plate and outer holder, plate frame
inner_end_abs = 16.7;            // the inner holder's far end from the plate frame's origin

/* [Placement] */
gauge_x  = 0;                    // the row's middle hole; the outline's middle is x = -6.7
gauge_z  = 1.6;                  // middle of the back face, z -7.77 .. 11.03
gauge_dx = 25;                   // each gauge's centre from gauge_x: 11.6 between the holders
half_h   = 5.4;                  // the holders' half thickness
bracket_t = 3;
bracket_x = 49;                  // half length
screw_x  = [-46.6, 0, 46.6];     // the wall behind is solid
screw_depth = 5;
plate_y0 = back_y + bracket_t + plate_top;   // the plate frame's origin on discant y; turned 180 deg

/* [Link plate on both inner holders, the discant half of the connector] */
link_t   = 6;
link_x   = 38;                   // half width: over both inner holders
pins_w   = 16;                   // spring pins, two rows of 6
pins_h   = 6;
pins_d   = 3;

/* [Link board] */
board_x  = [-63.5, -50];         // beyond the bracket's -x end
board_y  = [back_y + 0.5, back_y + 21];
board_t  = 3;                    // board and parts

/* [Six wires] */
bundle_d = 1.8;
bore_d   = 2.6;
bore_y   = 56;                   // in the back wall: 2 from the back face, 2 from the guides' line
bore_x   = [-88, -57];           // from inside the hole to behind the link board
bore_z   = -1.4;

$fa = 2; $fs = 0.2;

gz = gauge_z;
module box(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

module gauge() for (d = [-1, 1]) translate([gauge_x + d * gauge_dx, plate_y0, gz]) rotate(180) {
    import("../build/strain_gauge/outer_holder.stl");
    import("../build/strain_gauge/inner_holder.stl");
    import("../build/strain_gauge/strain_gauge_plate.stl");
}
module bracket() box([gauge_x - bracket_x, gauge_x + bracket_x], [back_y, back_y + bracket_t], [gz - half_h, gz + half_h]);
link_y = plate_y0 + inner_end_abs;   // the plate's -y face
module link_plate() {
    box([gauge_x - link_x, gauge_x + link_x], [link_y, link_y + link_t], [gz - half_h, gz + half_h]);
    box([gauge_x - pins_w / 2, gauge_x + pins_w / 2], [link_y + link_t, link_y + link_t + pins_d], [gz - pins_h / 2, gz + pins_h / 2]);
}
module link_board() box(board_x, board_y, [gz - board_t / 2, gz + board_t / 2]);

// the bundle: main PCB, behind cable 3, the hole's back corner, along the bore
function bundle_pts() = concat(
    [for (p = [[50, 11.7, 4.6], [53.5, 11.7, 4.6], [57, 10.9, 4.4], [60, 9.4, 4]]) from_band(p)],
    [[-113, bore_y, bore_z + 1], [-100, bore_y, bore_z], [bore_x[0], bore_y, bore_z], [bore_x[1], bore_y, bore_z],
     [bore_x[1], back_y + 2, bore_z]]);
module bundle() {
    p = bundle_pts();
    for (i = [0 : len(p) - 2]) hull() {
        translate(p[i]) sphere(d = bundle_d, $fn = 12);
        translate(p[i + 1]) sphere(d = bundle_d, $fn = 12);
    }
}

module gauge_link() { gauge(); bracket(); link_plate(); link_board(); bundle(); }

// cut from the housing: the bore for the wires and the bracket's pilots
module gauge_housing_cuts() {
    translate([bore_x[0], bore_y, bore_z]) rotate([0, 90, 0]) cylinder(d = bore_d, h = bore_x[1] - bore_x[0]);
    translate([bore_x[1], bore_y, bore_z]) sphere(d = bore_d);
    translate([bore_x[1], bore_y, bore_z]) rotate([-90, 0, 0]) cylinder(d = bore_d, h = back_y - bore_y + 1);
    for (x = screw_x) translate([gauge_x + x, back_y + 1, gz]) rotate([90, 0, 0])
        cylinder(d = screw_pilot, h = screw_depth + 1);
}

echo(str("plate frame y 0 at discant y = ", plate_y0, "; link plate y = ", link_y, " .. ", link_y + link_t,
         "; bracket ", 2 * bracket_x, " long"));

gauge_link();
