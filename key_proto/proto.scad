// Key prototype: 2 rows of 4 Hall keys (../switch_hall/) in the discant's arrangement,
// without the board
//
// [given 2026-11-17: 2 rows of 4 keys, the discant's layout, no PCB]. To try the keys'
// feel, stops and spring, and the reach between two rows, before the whole discant is
// printed. The keys are the discant's, unchanged; the magnets may be left out.
//
// LAYOUT as on the discant (../discant/hall.scad): row 1 moved by (10, 16, 3) against
// row 0, the cover plate in the slope plane (tilted up by atan(3/16) about x), the keys'
// axes vertical. Row 0 at x = -30 .. 30, row 1 at x = -20 .. 40.
//
// MOUNTING as on the discant [given 2026-11-17: the screws as the full model's, with the
// tray], so the prototype also tests the screws' hold:
// - BOARD: a stand-in for the Hall board, without parts: a plate hall_t thick with 2.2
//   holes at the screws, printed or cut from a 1.6 mm blank PCB. Its top is the board's
//   top (W = 0 in the slab frame), so every key part sits exactly as on the discant: the
//   collar stops floor_gap above it at the bottom.
// - BASE: the discant's tray (../discant/housing.scad, hall.scad): a rim case_fit round
//   the board, case_wall thick, up to its top; under it a ledge along its edge and a boss
//   at every screw, from the floor up to the board's underside; the floor's top and the
//   tray's bottom at the discant's W (w_ft, w_b: there set by the parts on the board).
//   The bottom is parallel to the slope [given 2026-11-17]; on a table the keys lean back
//   by it, as the discant's do.
// - COVER (../discant/cover.scad): a plate cover_t thick over board and rim, with each
//   key's tube and shroud (key.scad tube_body() / tube_cut()); the bushings go in from
//   below.
// - Five M2 x 6 countersunk brass screws (DIN 965) through cover and board into 1.7
//   pilots in the bosses, stopping floor_keep above the tray's bottom: about 1.9 mm of
//   thread, as on the discant.
//
// ASSEMBLY as ../switch_hall/spec.md: keys into the cover (rods glued into caps, bushings
// in from below, springs, O-rings, cover turned over, stop washers, collars glued on);
// the board into the tray, the cover onto it, the screws.
//
// make builds   ../build/key_proto/base.stl, board.stl, cover.stl (to print), keys.stl,
//               keys_down.stl (the key parts in place, for viewing and the clash check)

use <../switch_hall/key.scad>

part = "all";        // base, board, cover, keys, all
down = false;        // keys: at the lower stop

/* [Layout: as ../discant/hall.scad] */
stair    = [10, 16, 3];          // row 1 against row 0
key_ztop = 0.835;                // board top on a key's axis (key.scad z_top)
slab_t   = atan(3 / 16);
pitch    = 20;
row_x    = [[-30, -10, 10, 30], [-20, 0, 20, 40]];

/* [Board stand-in] */
hall_t   = 1.67;     // as the Hall board (laminate and both coppers)
margin   = 7.5;      // board beyond the outer caps' edges (cap d15), along the rows
front_y  = -8;       // the board's front edge (slab Y), as the discant board's
back_m   = 9.4;      // the board behind row 1 (key.scad margin_p)

/* [Tray and cover: as ../discant/hall.scad and housing.scad] */
case_fit = 0.3;      // board to the rim
case_wall = 1.2;
case_rim = case_fit + case_wall;
w_ft     = -3.32;    // the floor's top (slab W): the discant's, set there by its board's parts
w_b      = -4.52;    // the tray's bottom
ledge    = 0.8;      // under the board's edge, inside the rim
boss_d   = 4.4;      // at the screws, under the board
cover_t  = 2.4;      // (key.scad cover_t)
screw_d  = 2.2;      // M2 clearance, in cover and board
csk_d    = 4.0;      // 90 deg countersink for the flush heads (d3.8)
pilot_d  = 1.7;      // M2 brass screws cut their own thread (over the tap drill 1.6: printed holes come out small)
floor_keep = 0.4;    // under the pilots
screw_l  = 6;

$fa = 4; $fs = 0.4;

// the slab frame (X along the rows, Y up the slope, W out of the plate's underside) in
// the prototype's frame (row 0, z up), as ../discant/hall.scad
module on_slab() translate([0, 0, key_ztop]) rotate([slab_t, 0, 0]) children();
module at_key(k, x) translate([x, k * stair[1], k * stair[2]]) children();
row1_Y = stair[1] / cos(slab_t);  // row 1 in slab Y

X0 = row_x[0][0] - 7.5 - margin;
X1 = row_x[1][3] + 7.5 + margin;
Y0 = front_y;
Y1 = row1_Y + back_m;
// screws (slab X, Y): the four corners and one between the rows, clear of every shroud
screws = [[X0 + 5, Y0 + 4], [X1 - 5, Y0 + 4], [X0 + 5, Y1 - 4], [X1 - 5, Y1 - 4], [0, row1_Y / 2]];

module board2d() translate([X0, Y0]) square([X1 - X0, Y1 - Y0]);
module outline2d(g) offset(delta = g) board2d();
module slab_solid(w0, w1, g) on_slab() translate([0, 0, w0]) linear_extrude(w1 - w0) outline2d(g);

thread = screw_l - cover_t - hall_t;     // into the boss
assert(-w_b - floor_keep > thread + 0.3, "pilot too short for the screw");

module cover() difference() {
    union() {
        slab_solid(0, cover_t, case_rim);
        for (k = [0, 1], x = row_x[k]) at_key(k, x) difference() {
            tube_body();
            on_slab() translate([0, 0, -50]) cube([200, 200, 100], center = true);   // nothing below W = 0
        }
    }
    for (k = [0, 1], x = row_x[k]) at_key(k, x) tube_cut();
    on_slab() for (s = screws) translate([s[0], s[1], 0]) {
        translate([0, 0, -1]) cylinder(d = screw_d, h = cover_t + 2);
        translate([0, 0, cover_t - (csk_d - screw_d) / 2]) cylinder(d1 = screw_d, d2 = csk_d + 0.2, h = (csk_d - screw_d) / 2 + 0.1);
    }
}

// the board's stand-in: no parts, holes at the screws
module board() on_slab() translate([0, 0, -hall_t]) linear_extrude(hall_t) difference() {
    board2d();
    for (s = screws) translate(s) circle(d = screw_d);
}

// the base: the discant's tray, with ledge and bosses under the board
module base() difference() {
    slab_solid(w_b, 0, case_rim);
    difference() {
        slab_solid(w_ft, 1, case_fit);
        on_slab() translate([0, 0, w_ft - 0.1]) linear_extrude(-hall_t - w_ft + 0.1) {
            difference() { outline2d(case_fit + 0.01); outline2d(-ledge); }
            for (s = screws) translate(s) circle(d = boss_d);
        }
    }
    on_slab() for (s = screws) translate([s[0], s[1], w_b + floor_keep]) cylinder(d = pilot_d, h = -w_b);
}

// the key parts in place, from ../build/switch_hall/ (its Makefile builds them)
K = "../build/switch_hall/";
module keys() for (k = [0, 1], x = row_x[k]) at_key(k, x)
    for (p = ["cap", "plunger", "magnet", "oring", "stop", "spring"]) import(str(K, p, down ? "_down" : "", ".stl"));

echo(str("board ", X1 - X0, " x ", Y1 - Y0, ", tray and cover ", X1 - X0 + 2 * case_rim, " x ", Y1 - Y0 + 2 * case_rim,
         " (slab); tray ", -w_b, " deep under the board's top; thread in the boss ", thread,
         ", pilot ", -w_b - floor_keep, " deep"));

if (part == "base") base();
else if (part == "board") board();
else if (part == "cover") cover();
else if (part == "keys") keys();
else {
    color("Gainsboro") cover();
    color("SeaGreen") board();
    color("Tan") base();
    color("Ivory") keys();
}
