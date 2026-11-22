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
// the board in the slab frame, its floor part_gap under the tallest part (the
// deep parts aside), a rim case_fit round the board, the cover plate on top
case_fit   = 0.3;
case_wall  = 1.2;
case_rim   = case_fit + case_wall;   // board edge to the outer faces
part_gap   = 0.3;
case_floor = 1.2;
cover_t    = 2.4;                    // [given 2026-11-14: thicker, 1.2 before]
// parts deeper than the rest stand into the floor (housing.scad cuts round them): the
// bass board's J1, the discant board's NAU7802
deep_parts = ["J1", "U7"];
function is_deep(r) = len([for (d = deep_parts) if (d == r) 1]) > 0;
h_max = max([for (p = hall_parts) if (!is_deep(p[0])) p[6]]);
w_ft  = -hall_t - h_max - part_gap;  // the floor's top (W)
w_b   = w_ft - case_floor;           // the tray's bottom
w_mid = (w_b + 1.2) / 2;             // the gauges' plane: the middle of the case as it was with the 1.2 cover,
                                     // kept (../bass/link.scad's mount and the stored position build on it)
slab_back = hall_outline[2][1] + case_rim;   // the back face (Y)

// THE THUMB BAR'S SHELF [given 2026-11-14: stiff enough]: along the tray's front face, at
// its bottom, a ledge shelf_d deep and shelf_t high on which the thumb bar's back sits
// (cover.scad): pressed down, the bar bears on the tray, not only on the cover plate;
// pressed back, on the tray's front face. The cover still goes on from above (the bar has
// nothing under the ledge). Part of the housing between w0 and w1 (slab frame).
shelf_d = 2.5;
shelf_t = 1.6;
// the board's shape: hall_outline with its corners rounded by hall_corner_r (arcs tangent to
// both edges, as the routed board's Edge.Cuts; ../hall_pcb/design.py CORNER_R) [2026-11-21]
module hall_shape2d() offset(r = hall_corner_r, $fn = 64) offset(delta = -hall_corner_r) polygon(hall_outline);
// how far from corner i its rounding reaches along the edges
function hall_corner_t(i) = let(n = len(hall_outline), p = hall_outline[i], a = hall_outline[(i + n - 1) % n],
    b = hall_outline[(i + 1) % n], u = (a - p) / norm(a - p), v = (b - p) / norm(b - p))
    hall_corner_r / tan(acos(u * v) / 2);
// the centre of corner i's rounding (the same for the board's shape grown by any g)
function hall_corner_c(i) = let(n = len(hall_outline), p = hall_outline[i], a = hall_outline[(i + n - 1) % n],
    b = hall_outline[(i + 1) % n], u = (a - p) / norm(a - p), v = (b - p) / norm(b - p))
    p + (u + v) / norm(u + v) * hall_corner_r / sin(acos(u * v) / 2);
// THE CASE'S OUTER SHAPE: the board's shape grown by g, and for the outer faces (g >= case_rim)
// its two front corners filled out under their rounding's widest point, square to the front
// edge: the thumb bar's ends (cover.scad) stand there, in line with the case's sides, so case
// and bar make one rounding in plan, R hall_corner_r + case_rim, from the side round to the
// bar's front [given 2026-11-22]
case_x_max = [for (i = [0, 1]) hall_corner_c(i)[0] + (2 * i - 1) * (hall_corner_r + case_rim)];   // the case's sides
module case_shape2d(g) {
    offset(delta = g) hall_shape2d();
    if (g >= case_rim) for (i = [0, 1]) let(c = hall_corner_c(i), r = hall_corner_r + g, y0 = hall_outline[i][1] - g)
        translate([i == 0 ? c[0] - r : c[0], y0]) square([r, c[1] - y0]);
}
// the shelf ends 1 past the front corners' rounding (3 in from the corners before)
module front_shelf(w0, w1) let(f = hall_outline[0][1] - case_rim, x0 = hall_outline[0][0] + max(3, hall_corner_t(0) + 1),
                               x1 = hall_outline[1][0] - max(3, hall_corner_t(1) + 1))
    on_slab() translate([x0, f - shelf_d, w0]) cube([x1 - x0, shelf_d + 0.5, w1 - w0]);

// the board: laminate with its holes, and the parts' bodies on the underside
module hall_board() on_slab() {
    color("SeaGreen") translate([0, 0, -hall_t]) linear_extrude(hall_t) difference() {
        hall_shape2d();
        for (h = hall_holes) translate(h) circle(d = hall_hole_d, $fn = 24);
    }
    color("DimGray") hall_bodies(0);
}
// the parts' bodies, grown by g on every side
module hall_bodies(g) for (p = hall_parts) if (p[1] == "B")
    translate([p[2] - g, p[3] - g, -hall_t - p[6] - g]) cube([p[4] - p[2] + 2 * g, p[5] - p[3] + 2 * g, p[6] + g + 0.01]);
