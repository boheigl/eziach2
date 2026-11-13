// The discant's Hall-sensor board in the discant's frame, shared by housing.scad,
// cover.scad, keys.scad and gauge_link.scad
//
// One board under all 46 keys [given], in the staircase's slope plane
// (../hall_pcb/): tilted up by atan(3/16) about x, as the rows climb (3 per 16).
// Its top copper meets every key's axis at that row's z_top (../switch_hall/key.scad),
// so every key sees the same board under it.
//
// SLAB FRAME: X along the rows, Y up the slope in the board's plane, W out of the
// board's top face; the board's own frame (../hall_pcb/design.py) with W added.
// The discant's frame (board 0 / row 0, z up) is on_slab() of it.
//
// The board's data (outline, holes, part bodies) come from the routed KiCad board:
// ../hall_pcb/discant/board.scad, written by ../hall_pcb/export_scad.py.

include <../hall_pcb/discant/board.scad>

stair    = [10, 16, 3];          // row k+1 relative to row k
key_ztop = 0.835;                // board top on a key's axis, key frame (key.scad z_top)
slab_t   = hall_tilt;            // atan(3/16)

// the slab frame in the discant's frame
module on_slab() translate([0, 0, key_ztop]) rotate([slab_t, 0, 0]) children();
// a point of the slab frame in the discant's frame
function slab_pt(p) = [p[0], p[1] * cos(slab_t) - p[2] * sin(slab_t), key_ztop + p[1] * sin(slab_t) + p[2] * cos(slab_t)];
// row k's key frame (key.scad) for key at X
module at_key(k, x) translate([x, k * stair[1], k * stair[2]]) children();
function key_x(i) = hall_keys[i][2];
function key_row(i) = hall_keys[i][0];

// THE CASE ROUND THE BOARD (housing.scad, cover.scad, gauge_link.scad): a tray under
// the board in the slab frame, its floor part_gap under the tallest part (the plug's
// J1 aside), a rim case_fit round the board, the cover plate on top
case_fit   = 0.3;
case_wall  = 1.2;
case_rim   = case_fit + case_wall;   // board edge to the outer faces
part_gap   = 0.3;
case_floor = 1.2;
cover_t    = 1.2;
h_max = max([for (p = hall_parts) if (p[0] != "J1") p[6]]);
w_ft  = -hall_t - h_max - part_gap;  // the floor's top (W)
w_b   = w_ft - case_floor;           // the tray's bottom
w_mid = (w_b + cover_t) / 2;         // the middle of the case's thickness
slab_back = hall_outline[2][1] + case_rim;   // the back face (Y)

// the board: laminate with its holes, and the parts' bodies on the underside
module hall_board() on_slab() {
    color("SeaGreen") translate([0, 0, -hall_t]) linear_extrude(hall_t) difference() {
        polygon(hall_outline);
        for (h = hall_holes) translate(h) circle(d = hall_hole_d, $fn = 24);
    }
    color("DimGray") hall_bodies(0);
}
// the parts' bodies, grown by g on every side
module hall_bodies(g) for (p = hall_parts) if (p[1] == "B")
    translate([p[2] - g, p[3] - g, -hall_t - p[6] - g]) cube([p[4] - p[2] + 2 * g, p[5] - p[3] + 2 * g, p[6] + g + 0.01]);
