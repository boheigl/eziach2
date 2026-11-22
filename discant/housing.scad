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

// THE SHOULDER STRAP'S BRIDGES [given 2026-11-22: a strap for the right shoulder, on the
// discant, on the housing's back (the tray's underside, the side to the body), near both
// ends of the rows]: a bridge each, a bar on two posts standing out of the underside, the
// tunnel under the bar along X (the rows), so the strap pulls along the rows. The strap's
// tab goes through the tunnel, round the bar and back onto itself (buckled). The floor
// (1.2) leaves no room for a strap inside the tray, as on the bass. Each sits as far out
// as the slanted side allows (strap_side in from it), from strap_y0 near the front face.
// The housing prints standing on its front edge (spec.md, Printing): the bar then grows
// upward along Y, the lower post is a 45 deg wedge, the tunnel's roof a 3 mm bridge.
strap_w    = 20;     // the tab's width [assumed: leather, 20 x 2-2.5]
strap_gap  = 3;      // the tunnel's height, under the bar (for a 2.5 tab)
strap_bar  = 2.5;    // the bar's thickness (out of the underside)
strap_b    = 12;     // the bar's width along X
strap_post = 5;      // the upper post along Y
strap_r    = 1;      // the bar's edges rounded, where the strap goes round
strap_y0   = -8;     // where the lower post starts (Y; the case's front face at -9.5)
strap_side = 2.5;    // the bridge's outer edge in from the slanted side
strap_h    = strap_gap + strap_bar;            // how far it stands out of the underside
strap_y1   = strap_y0 + strap_h;               // the tunnel from here ...
strap_y2   = strap_y1 + strap_w + 2;           // ... to here
strap_y3   = strap_y2 + strap_post;            // the bridge's end
// the case's outer side face at Y (the right one; hall_outline's edge 1 -> 2, grown by case_rim)
function case_side_x(y) = let(p = hall_outline[1], q = hall_outline[2], d = (q - p) / norm(q - p), n = [d[1], -d[0]])
    p[0] + case_rim / n[0] + (y - p[1]) * d[0] / d[1];
strap_x1   = case_side_x(strap_y3) - strap_side;   // the bridge's outer edge (X > 0; mirrored)
strap_x0   = strap_x1 - strap_b;
echo(str("strap bridges: X ", strap_x0, " .. ", strap_x1, ", Y ", strap_y0, " .. ", strap_y3,
         ", tunnel ", strap_w + 2, " x ", strap_gap, ", ", strap_h, " out of the underside"));
// in (X, Y, D), D out of the underside: W = w_b - D
// the bar's section across X (X, D) from D = d0 out, its corners rounded
module strap_bar2d(d0) translate([0, d0]) offset(r = strap_r, $fn = 24) offset(delta = -strap_r) square([strap_b, strap_h - d0]);
module strap_bridge() let(b = strap_b, h = strap_h) {
    // lower post: a 45 deg wedge up to the tunnel's start
    intersection() {
        rotate([90, 0, 90]) linear_extrude(b) polygon([[strap_y0, -0.01], [strap_y1, h], [strap_y1 + 0.01, h], [strap_y1 + 0.01, -0.01]]);
        rotate([90, 0, 0]) translate([0, 0, -strap_y1 - 0.01]) linear_extrude(strap_y1 + 0.01 - strap_y0) union() { strap_bar2d(0); square([b, h / 2]); }
    }
    // the bar
    translate([0, strap_y2 + 0.01, 0]) rotate([90, 0, 0]) linear_extrude(strap_y2 - strap_y1 + 0.02) strap_bar2d(strap_gap);
    // upper post
    translate([0, strap_y3, 0]) rotate([90, 0, 0]) linear_extrude(strap_y3 - strap_y2) union() { strap_bar2d(0); translate([0, -0.01]) square([b, h / 2]); }
}
module strap_bridges() on_slab() for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0])
    translate([strap_x0, 0, w_b]) mirror([0, 0, 1]) strap_bridge();

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
