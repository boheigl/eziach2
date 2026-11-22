// Housing of the discant: a thin tray under the Hall-sensor board
//
// [given 2026-11-13: one sensor board for all 46 keys, the cases as small as
// possible, cover variant A (a flat plate on the tilted board)]. The keys
// (../switch_hall/) stand entirely above the board, so below it there are only the
// parts' bodies: the tray follows the board in the slope plane (hall.scad), a floor
// under the parts, a rim round the board up to its top face, and under the board a
// ledge along its edge and a boss at every screw hole, which carry it. The cover
// (cover.scad) lies on board and rim; 27 M2 countersunk screws go through cover
// and board into the bosses.
//
// The previous housing (four stepped boards with 46 guides, the hole behind the
// slanted face) is in the git history.
//
// GAUGES (gauge_link.scad) [given 2026-11-13: in the tray's plane]: on the back face,
// centred in the case's thickness, a pad with the gauges' outer holders. The bridges'
// ADC (NAU7802) is on the Hall-sensor board [chosen 2026-11-15]: channels lead the
// gauges' and the contacts' wires from the pad's groove under the board's back edge, to
// its wire pads. The NAU7802 stands deeper than the other parts: the floor under it is
// thinner there (hall_bodies() cuts it; hall.scad deep_parts).
//
// Coordinates: the discant's frame (row 0 / board 0, z up); the tray is built in the
// slab frame (hall.scad).
//
// make builds   openscad -o ../build/discant/housing.stl housing.scad

include <hall.scad>
use <gauge_link.scad>

/* [Tray: case_fit, case_wall, part_gap, case_floor in hall.scad] */
fit      = case_fit;
wall     = case_wall;
ledge    = 0.8;      // under the board's edge, inside the rim
boss_d   = 4.4;      // at the screw holes, under the board
pilot_d  = 1.7;      // M2 brass machine screws (DIN 965) cut their own thread; over the tap drill 1.6: printed holes come out small
floor_keep = 0.4;    // under the pilots

$fa = 4; $fs = 0.4;

echo(str("tray: floor top W = ", w_ft, ", bottom W = ", w_b, " (", -w_b, " below the board's top); rim ", wall,
         " round the board, ", fit, " clear"));

module outline2d(g) case_shape2d(g);   // the board's shape, grown (its corners rounded; hall.scad)
module slab_solid(w0, w1, g) on_slab() translate([0, 0, w0]) linear_extrude(w1 - w0) outline2d(g);
module below_top() on_slab() translate([-500, -500, -100]) cube([1000, 1000, 100]);   // W < 0

// what carries the board: a ledge along its edge and a boss at every screw hole, from
// the floor up to the board's underside; clear of the parts' bodies
module supports() difference() {
    union() {
        on_slab() translate([0, 0, w_ft - 0.1]) linear_extrude(-hall_t - w_ft + 0.1) {
            difference() { outline2d(fit + 0.01); outline2d(-ledge); }
            for (h = hall_holes) translate(h) circle(d = boss_d);
        }
    }
    on_slab() hall_bodies(part_gap);
}

module pilots() on_slab() for (h = hall_holes)
    translate([h[0], h[1], w_b + floor_keep]) cylinder(d = pilot_d, h = -w_b + 1);

cover_gap = 0.3;     // the gauge pad's lip over the cover plate's back edge (the case's fit)

// THE SHOULDER STRAP'S EYES [given 2026-11-22: a strap for the right shoulder, on the
// discant, on the housing's back (the tray's underside, the side to the body), near both
// ends of the rows, with carabiners; both eyes pulled towards (-1, -2), the upper one (-X)
// and the lower one (+X) alike, not mirrored: away from the upper end and towards the front]:
// an eye each, a fin standing out of the underside in the pull's plane with a hole for
// the carabiner, which then hangs in line with the pull. The floor (1.2) leaves no room
// inside the tray, as on the bass. Each sits in a front corner of the underside, as far
// out as the slanted side and the front face allow (strap_side, strap_y0).
// The housing prints standing on its front edge (spec.md, Printing): the fin then stands
// 27 deg off upright, its lower end (the pull's) is a 45 deg wedge, the hole a teardrop.
// (A bar across the pull, as for a tab, would lie 27 deg off level in the print.)
strap_hook = 4;      // the carabiner's wire [assumed: up to 4 thick, its gate opening 6 or more]
strap_dir  = [-1, -2];  // the pull at both eyes (X, Y) [given]
strap_t    = 4;      // the fin's thickness
strap_hr   = (strap_hook + 1) / 2;   // the hole's radius
strap_hd   = 1 + strap_hr;           // the hole's middle out of the underside
strap_lig  = 4.5;    // material between the hole and the fin's end, along the pull: in the gate
strap_hs   = 6.5;    // the hole's middle from the fin's back end (the teardrop's tip 3 behind it)
strap_h    = strap_hd + strap_hr + 1.5;   // how far it stands out of the underside
strap_L    = strap_hs + strap_hr + strap_lig + strap_hd;   // the fin's length (its end slanted 45 deg)
strap_r    = 1.5;    // its back corner rounded
strap_y0   = -8;     // the eye's lowest point (Y; the case's front face at -9.5)
strap_side = 2.5;    // the eye's outermost point in from the slanted side
// the right side face's outward normal and a point on it (hall_outline's edge 1 -> 2, grown by case_rim)
strap_n    = let(p = hall_outline[1], q = hall_outline[2], d = (q - p) / norm(q - p)) [-d[1], d[0]] * (d[1] > 0 ? -1 : 1);
strap_s    = hall_outline[1] + case_rim * strap_n;
// an eye in the +X corner pulled along d: along the fin, across it, its end (the pull's) on its
// middle line, with its lowest corner at strap_y0 and its outermost corner strap_side in from
// the side, and its back end. The -X eye is the +X one for d mirrored, mirrored.
function strap_P(d) = d / norm(d);
function strap_N(d) = [-strap_P(d)[1], strap_P(d)[0]];
function strap_E(d) = let(P = strap_P(d), N = strap_N(d), ey = strap_y0 + strap_t / 2 * abs(N[1]),
                          en = strap_s * strap_n - strap_side - max(0, -strap_L * (P * strap_n)) - strap_t / 2 * abs(N * strap_n))
    [(en - ey * strap_n[1]) / strap_n[0], ey];
function strap_B(d) = strap_E(d) - strap_L * strap_P(d);
strap_d    = [[-strap_dir[0], strap_dir[1]], strap_dir];   // -X eye (before mirroring), +X eye
for (d = strap_d) echo(str("strap eye: fin from ", strap_B(d), " to ", strap_E(d), " (in the +X corner), pull ",
    atan2(strap_P(d)[1], strap_P(d)[0]), " deg from the rows, ", strap_t, " thick, ", strap_h, " out of the underside, hole d ", 2 * strap_hr));
// the fin in (s, D): s along the pull from the back end, D out of the underside
module strap_fin2d() difference() {
    let(L = strap_L, h = strap_h, r = strap_r)
        hull() {
            translate([r, h - r]) circle(r = r, $fn = 24);
            translate([0, -0.01]) square([0.01, 0.01]);
            polygon([[L - h, h], [L, -0.01], [L - h, -0.01]]);
        }
    // teardrop, its tip up in the print (towards the back end)
    translate([strap_hs, strap_hd]) hull() {
        circle(r = strap_hr, $fn = 32);
        translate([-strap_hr * sqrt(2), 0]) square(0.01, center = true);
    }
}
// x -> along the pull, y -> out of the underside (-W), z -> across; from the back end at the underside
module strap_eye(d) let(P = strap_P(d), N = strap_N(d), B = strap_B(d))
    multmatrix([[P[0], 0, N[0], B[0]], [P[1], 0, N[1], B[1]], [0, -1, 0, w_b], [0, 0, 0, 1]])
        translate([0, 0, -strap_t / 2]) linear_extrude(strap_t) strap_fin2d();
module strap_bridges() on_slab() { mirror([1, 0, 0]) strap_eye(strap_d[0]); strap_eye(strap_d[1]); }

module housing() union() {
    difference() {
        union() {
            slab_solid(w_b, 0, fit + wall);
            front_shelf(w_b, w_b + shelf_t);              // the thumb bar sits on it (hall.scad)
            gauge_housing_pads();
        }
        difference() { slab_solid(w_ft, 1, fit); supports(); }
        on_slab() hall_bodies(part_gap);
        pilots();
        // the cover plate: the pad's block reaches 1 over its back edge, a lip it goes under;
        // cover_gap over the plate and round its edge [given 2026-11-21: was 0.01 and 0]
        slab_solid(0, cover_t + cover_gap, fit + wall + cover_gap);
        gauge_housing_cuts();
    }
    gauge_holders();
    strap_bridges();
}

housing();
