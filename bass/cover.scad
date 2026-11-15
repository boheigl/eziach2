// Bass cover: one piece [given], on the Hall-sensor board and the case's tray
//
// [given 2026-11-13: one flat board under both rows, the keys of ../switch_hall/]. The
// cover reaches out to the case's outline on every side [given 2026-11-14: the case never
// stands over it, no raised edge at the hand plate]: a front slab, cover_t on the board,
// from the hand's face (over the case's front wall, flush with the hand plate's top) to
// the step; a wall up the step (its face 2.3 clear of the front caps [given: >= 2]) and a
// back block on the board, key_riser higher, to the back face. The back block is hollow,
// a 1.2 shell, carried by the back row's tube columns. At every key the key's tube and
// shroud (key.scad tube_body() /
// tube_cut(), built flat and, for the back row, with the riser: ../build/switch_hall/
// bass0_*, bass1_*): the tube guides the plunger, the shroud hides the spring under the
// cap's skirt, a level floor inside it is the spring's seat.
//
// SCREWS: M2 countersunk through cover and board into the tray's bosses at the board's
// four holes (layout.scad: hall_holes). In the back block each screw sits at the bottom
// of a column, its head 1.2 over the board, reached from the top by a bore.
//
// make builds   openscad -o ../build/bass/cover.stl cover.scad

include <layout.scad>

screw_d = 2.2; csk_d = 4.0;
col_d   = 6.4;                   // the screw columns in the back block
bore_d  = 4.4;                   // the screwdriver's bore down a column
shell   = 2.4;                   // the back block's walls and top, as thick as the slab
corner_r = 4;                    // as the case's vertical edges
recess = 0; recess_r = 6;        // the hand plate's recess, as case.scad (none since 2026-11-15)
K = "../build/switch_hall/";

$fa = 3; $fs = 0.3;

module rounded2d() offset(r = corner_r) offset(delta = -corner_r)
    translate([deck_x[0], plate_y[0]]) square([deck_x[1] - deck_x[0], deck_y[1] - plate_y[0]]);
module box3(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

back_y = [riser_y, deck_y[1]];
function in_back(h) = h[1] > riser_y;
module keys_do(k) for (i = [0 : n_row - 1]) translate(at_key(k, i)) children();

module cover() intersection() {
    translate([0, 0, -50]) linear_extrude(100) rounded2d();
    difference() {
        union() {
            box3(deck_x, [plate_y[0], step_y], [board_top, cover_top[0]]);              // front slab, out to the hand's face
            difference() {                                                            // back block, hollow
                box3(deck_x, back_y, [board_top, cover_top[1]]);
                box3([deck_x[0] + shell, deck_x[1] - shell], [step_y, back_y[1] - shell], [board_top - 1, cover_top[1] - shell]);
            }
            for (h = hall_holes) if (in_back(h)) translate([h[0], h[1], board_top]) cylinder(d = col_d, h = cover_top[1] - board_top);
            keys_do(0) import(str(K, "bass0_tube_body.stl"));
            keys_do(1) import(str(K, "bass1_tube_body.stl"));
        }
        // the hand plate's recess, where it reaches the cover (none now: recess 0)
        if (recess > 0) translate([0, plate_y[0] - 1, 0]) rotate([-90, 0, 0]) linear_extrude(recess + 1)
            offset(r = recess_r) offset(delta = -recess_r)
                translate([plate_x[0], -plate_z[1]]) square([plate_x[1] - plate_x[0], plate_z[1] - plate_z[0]]);
        keys_do(0) import(str(K, "bass0_tube_cut.stl"));
        keys_do(1) import(str(K, "bass1_tube_cut.stl"));
        for (h = hall_holes) translate([h[0], h[1], 0]) {
            zs = in_back(h) ? board_top + cover_t : cover_top[0];     // the head's seat
            translate([0, 0, board_top - 1]) cylinder(d = screw_d, h = zs - board_top + 1);
            translate([0, 0, zs - (csk_d - screw_d) / 2]) cylinder(d1 = screw_d, d2 = csk_d + 0.2, h = (csk_d - screw_d) / 2 + 0.01);
            if (in_back(h)) translate([0, 0, zs]) cylinder(d = bore_d, h = cover_top[1] - zs + 1);
        }
    }
}

cover();
