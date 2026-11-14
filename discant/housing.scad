// Housing of the discant: a thin tray under the Hall-sensor board
//
// [given 2026-11-13: one sensor board for all 46 keys, the cases as small as
// possible, cover variant A (a flat plate on the tilted board)]. The keys
// (../switch_hall/) stand entirely above the board, so below it there are only the
// parts' bodies: the tray follows the board in the slope plane (hall.scad), a floor
// under the parts, a rim round the board up to its top face, and under the board a
// ledge along its edge and a boss at every screw hole, which carry it. The cover
// (cover.scad) lies on board and rim; seven M2 countersunk screws go through cover
// and board into the bosses.
//
// The previous housing (four stepped boards with 46 guides, the hole behind the
// slanted face) is in the git history.
//
// GAUGES AND LINK BOARD (gauge_link.scad) [given 2026-11-13: in the tray's plane]: on
// the back face, centred in the case's thickness, a pad with the gauges' outer holders,
// and beside it a block with the link board's pocket, the board lying flat, flush with
// the board's top: the cover closes it. The board's side-entry bus connector (J1, opening to the back) sits just in
// front of the pocket: the plug's wires run straight in.
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
pilot_d  = 1.6;      // M2 self-tapping
floor_keep = 0.4;    // under the pilots

/* [Bus plug: JST SH (SHR-05V-S) in J1, from its opening towards +Y] */
plug_l   = 4.4;      // [unverified]; the cavity runs on 0.5 into the link pocket behind the back face
plug_hw  = 3.8;      // half width, with clearance
plug_h   = 3.2;      // below the board's underside

$fa = 4; $fs = 0.4;

echo(str("tray: floor top W = ", w_ft, ", bottom W = ", w_b, " (", -w_b, " below the board's top); rim ", wall,
         " round the board, ", fit, " clear"));

module outline2d(g) offset(delta = g) polygon(hall_outline);
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

// J1 (2.95 high) and its plug stand deeper than the tray: a pod under them, its floor
// pod_floor under the plug, from the link pocket's block forward [given 2026-11-14: hide it]
pod_floor = 1.0;
j1 = [for (q = hall_parts) if (q[0] == "J1") q][0];
pod_b = -hall_t - max(j1[6] + part_gap, plug_h) - pod_floor;
module conn_pod() on_slab() translate([-86.5, j1[3] - 1.5, pod_b])
    cube([j1[4] + 1.5 - (-86.5), slab_back - (j1[3] - 1.5), w_b - pod_b + 0.01]);
// the plug in J1, through the rim straight into the link pocket behind the back face
module plug_cavity()
    on_slab() translate([hall_conn[0] - plug_hw, hall_conn_front - 0.3, -hall_t - plug_h])
        cube([2 * plug_hw, max(plug_l, slab_back + 0.5 - hall_conn_front) + 0.3, plug_h + 0.01]);

module pilots() on_slab() for (h = hall_holes)
    translate([h[0], h[1], w_b + floor_keep]) cylinder(d = pilot_d, h = -w_b + 1);

module housing() union() {
    difference() {
        union() {
            slab_solid(w_b, 0, fit + wall);
            front_shelf(w_b, w_b + shelf_t);              // the thumb bar sits on it (hall.scad)
            conn_pod();
            gauge_housing_pads();
        }
        difference() { slab_solid(w_ft, 1, fit); supports(); }
        on_slab() hall_bodies(part_gap);
        plug_cavity();
        pilots();
        slab_solid(0, cover_t + 0.01, fit + wall);   // the cover plate (the pad's block reaches 1 into it)
        gauge_housing_cuts();
    }
    gauge_holders();
}

housing();
