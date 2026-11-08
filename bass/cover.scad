// Bass cover: one piece [given]. A slab on each board, the board in a pocket
// underneath (0.3 round it) and a d8 opening over each key, the stem's second guide;
// the felt ring under each cap lands on it at the lower stop, as on the discant. The
// front slab runs from the hand plate to the step, a 1.2 wall rises up the step (its
// face 2.3 clear of the front caps [given: >= 2]) and carries the back slab, which
// runs to the back face. Three M2 countersunk screws per board, through cover and
// board into the case (case.scad).
//
// make builds   openscad -o ../build/bass/cover.stl cover.scad

include <layout.scad>

open_d  = 8;
screw_d = 2.2; csk_d = 4.0;

$fa = 3; $fs = 0.3;

function top_of(k) = board_z[k] - pcb_t / 2 - cu_t - gap;
spans = [[deck_y[0], step_y], [riser_y, deck_y[1]]];
corner_r = 4;                    // as the case's vertical edges

intersection() {
translate([0, 0, -50]) linear_extrude(100) offset(r = corner_r) offset(delta = -corner_r)
    translate([deck_x[0], plate_y[0]]) square([deck_x[1] - deck_x[0], deck_y[1] - plate_y[0]]);
difference() {
    union() {
        for (k = [0, 1])
            translate([deck_x[0], spans[k][0], top_of(k)]) cube([deck_x[1] - deck_x[0], spans[k][1] - spans[k][0], cover_top[k] - top_of(k)]);
        // the wall up the step, between the two slabs
        translate([deck_x[0], riser_y, cover_top[0] - 0.01]) cube([deck_x[1] - deck_x[0], step_wall, top_of(1) - cover_top[0] + 0.02]);
    }
    for (k = [0, 1]) {
        translate([board_dx[k], rows_y[k], top_of(k) - 1])
            linear_extrude(board_top[k] - top_of(k) + 1) offset(delta = fit) board2d();
        for (i = [0 : n_row - 1]) translate([key_xy(k, i)[0], key_xy(k, i)[1], top_of(k) - 1]) cylinder(d = open_d, h = 10);
        for (x = screws) translate([x + board_dx[k], rows_y[k], 0]) {
            translate([0, 0, top_of(k) - 1]) cylinder(d = screw_d, h = 10);
            translate([0, 0, cover_top[k] - (csk_d - screw_d) / 2]) cylinder(d1 = screw_d, d2 = csk_d + 0.2, h = (csk_d - screw_d) / 2 + 0.1);
        }
    }
}
}
