// Bass lid: closes the box's open bottom (case.scad), flush with it, 0.2 inside the
// walls; two M2 countersunk screws into the case's bosses at its ends.
//
// make builds   openscad -o ../build/bass/lid.stl lid.scad

include <layout.scad>

wall = 2; corner_r = 4; lid_t = 2; boss_d = 7; clear = 0.2;
screw_d = 2.2; csk_d = 4.0;
$fa = 3; $fs = 0.3;

// the box's narrow, thin bottom (case.scad)
module footprint(d = 0) offset(r = corner_r - d) offset(delta = -corner_r)
    translate([bottom_x[0], plate_y[0]]) square([bottom_x[1] - bottom_x[0], box_back - plate_y[0]]);
module cavity2d() intersection() {   // as case.scad: side walls wall, back wall back_t
    footprint(back_t);
    translate([bottom_x[0] + wall, plate_y[1]]) square([bottom_x[1] - bottom_x[0] - 2 * wall, 100]);
}
function boss_xy() = [[bottom_x[0] + wall + boss_d / 2 - 0.5, (plate_y[1] + box_back - back_t) / 2],   // as case.scad
                      [bottom_x[1] - wall - boss_d / 2 + 0.5, (plate_y[1] + box_back - back_t) / 2]];

difference() {
    translate([0, 0, z_bot]) linear_extrude(lid_t) offset(delta = -clear) cavity2d();
    for (p = boss_xy()) translate([p[0], p[1], z_bot - 1]) {
        cylinder(d = screw_d, h = lid_t + 2);
        translate([0, 0, 1 - 0.01]) cylinder(d1 = csk_d + 0.2, d2 = screw_d, h = (csk_d - screw_d) / 2);
    }
}
