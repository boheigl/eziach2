// Cover of the discant: a flat plate on the Hall-sensor board, with the keys' tubes
//
// [given 2026-11-13: variant A: one plate parallel to the tilted board, the keys
// standing out of it]. In the slab frame (hall.scad) the plate covers board and rim
// (housing.scad), 1.2 thick. At every key it carries the key's tube and shroud
// (../switch_hall/key.scad tube_body() / tube_cut()): the tube guides the plunger,
// the shroud hides the spring under the cap's skirt, and inside the shroud a level
// floor is the spring's seat, whatever the plate's tilt. Nothing of the cover goes
// below the board's top face.
//
// THUMB BAR [given: on the discant's -y side; unchanged relative to the keys' tops]: its
// section is ../thumb-bar/profile.scad's thumb_profile(), fitted to the earlier
// DiscantCase's bar (0.2 mm rms) with the first row's caps' top at z = 8 and their front
// edge at y = -7.5: the back upright at y = -13.9 from z = -18.8 up 21.7 (its top 5.1
// below the caps' top), solid from there back to 0.4 in front of the caps (y = -7.9, as
// the old front wall stood), so it overlaps the cover plate along its whole length.
// The caps now stand higher (key.scad key_cap_top()), so the bar moves up with them by
// tb_dz [given 2026-11-13]. Never cut [given 2026-11-14]: it keeps its whole profile over
// its whole length; the bass makes room for it (its box is longer, ../bass/layout.scad).
//
// ASSEMBLY (../switch_hall/spec.md). The cover lies on a jig whose pins reach into the
// tubes from below; the plungers go in from below onto the pins, the springs from above
// over the tubes, and the caps are pressed onto the pins while the jig carries the
// collars. Off the jig the springs hold every plunger against its step: the cover is one
// unit with all 46 keys. It goes onto the board in the housing, and 27 M2 countersunk
// brass screws (DIN 965, flush) go through cover and board into the housing's bosses.
//
// The previous cover (four stepped boxes, dents round the caps) is in the git history.
//
// Coordinates: the discant's frame (row 0, z up).
//
// make builds   openscad -o ../build/discant/cover.stl cover.scad

include <hall.scad>
use <../switch_hall/key.scad>
use <../thumb-bar/profile.scad>   // thumb_profile(): the thumb bar's section

/* [As in housing.scad: hall.scad's case dimensions] */
fit      = case_fit;
wall     = case_wall;

/* [Cover] */
screw_d  = 2.2;      // M2 clearance
csk_d    = 4.0;      // 90 deg countersink for the flush heads (d3.8)
bore_lo  = key_bore_lo();   // key.scad: the bushing's way in, run down through the plate
wire_rec = 0.8;      // over the wire pads' solder joints

/* [Thumb bar, as before] */
tb_len = 21.7;  tb_angle = 86.1;  tb_r = 1.2;  tb_R = 20.6;   // thumb_profile()'s parameters
tb_y   = -13.9; tb_z0 = -18.8;
tb_fill  = -7.5 - 0.4;   // the bar's solid back: 0.4 in front of the caps (cap_d / 2), into the plate
tb_cap0  = 8;        // the caps' top the bar was fitted to (row 0, z): its top 5.1 below them
tb_above = 7;        // the caps' top over the bar's top, along the keys' axis [given 2026-11-21;
                     //   5.1 as fitted]: the whole bar, profile unchanged, 1.9 lower
tb_dz    = key_cap_top() - tb_above - (tb_z0 + tb_len);   // the bar follows the caps up
tb_round = 2;        // the foot's front edge rounded [given 2026-11-21: "etwas"]
// THE RIBS [given 2026-11-21: a little stiffer, the keys must not strike, not bulky, nothing
// past the housing in x/y]: thin triangular ribs behind the bar, one in the middle of each gap
// between the first row's keys (9 from either axis: clear of caps r 7.5 and skirts r 6.2),
// from the bar's back at its full height down onto the cover plate at the keys' axes' line;
// only in the gaps without a cover screw under it (every other one: 6 ribs, 40 apart), so the
// screws stay free to reach. The bar's top stays under the pressed caps' rims by
// key_cap_low() - bar top (0.8 at tb_above 7).
tb_rib_t   = 2;      // thickness (x)
tb_rib_y   = 0;      // where a rib meets the plate (row 0's axes)
tb_web_cap = 0.5;    // the least under a pressed cap (checked below)

$fa = 4; $fs = 0.4;

assert((csk_d - screw_d) / 2 <= cover_t - 0.2, "countersink too deep for the cover plate");
echo(str("thumb bar ", tb_dz, " higher than before: z = ", tb_z0 + tb_dz, " .. ", tb_z0 + tb_len + tb_dz,
         " (caps' top ", key_cap_top(), ")"));

module outline2d(g) offset(delta = g) polygon(hall_outline);
module slab_solid(w0, w1, g) on_slab() translate([0, 0, w0]) linear_extrude(w1 - w0) outline2d(g);
module below_top() on_slab() translate([-500, -500, -100]) cube([1000, 1000, 100]);   // W < 0

// the bar along the whole front edge
front = [for (p = hall_outline) p[1]][0];
x_front = [hall_outline[0][0] - (fit + wall) * 1.2, hall_outline[1][0] + (fit + wall) * 1.2];
// The section, in the extrusion's plane (u, v) = (y, z - tb_dz). Its foot is cut flush with
// the housing's underside (the tray's bottom, W = w_b, in the slope's plane) [given
// 2026-11-21: lowered for tb_above it reached 1.8 below], and the edge there rounded by
// tb_round; the rounding (an opening) acts only within 3 tb_round of the cut.
module tb_raw() {
    translate([tb_y, tb_z0]) rotate(90 - tb_angle) thumb_profile(tb_len, tb_angle, tb_r, tb_R);
    translate([tb_y - 0.01, tb_z0]) square([tb_fill - tb_y + 0.02, tb_len]);
}
// W >= w_b + h0 .. up to w_b + h1, as a strip in (u, v): W = -u sin + (v + tb_dz - key_ztop) cos
module tb_above_floor(h0, h1) let(s = sin(slab_t), c = cos(slab_t), o = [0, w_b / c - tb_dz + key_ztop],
                                   d = [c, s], n = [-s, c])
    polygon([o - 500 * d + h0 * n, o + 500 * d + h0 * n, o + 500 * d + h1 * n, o - 500 * d + h1 * n]);
module tb_section() let(band = 3 * tb_round) {
    intersection() { tb_raw(); tb_above_floor(band, 500); }
    intersection() {
        offset(r = tb_round) offset(delta = -tb_round) intersection() { tb_raw(); tb_above_floor(0, 500); }
        tb_above_floor(0, band + 0.01);
    }
}
tb_top = tb_z0 + tb_len + tb_dz;   // the bar's top (z, the keys' axis)
assert(key_cap_low() - tb_top >= tb_web_cap, "the bar's top would touch the pressed caps");
echo(str("thumb bar's top ", tb_top, ", the pressed caps' underside ", key_cap_low(), ": ", key_cap_low() - tb_top, " apart"));
function plate_top(y) = key_ztop + y * tan(slab_t) + cover_t / cos(slab_t);   // the cover's top (z) at y
r0 = [for (i = [0 : len(hall_keys) - 1]) if (key_row(i) == 0) key_x(i)];
r0s = [for (i = [0 : len(r0) - 1]) min([for (x = r0) if (x >= r0[i]) x])];     // row 0's x, sorted
// the gaps' middles with no screw within its head's reach of a rib
function screw_near(x) = len([for (h = hall_holes) if (abs(h[0] - x) < (csk_d + tb_rib_t) / 2 + 0.5
                                                       && h[1] > tb_fill - csk_d && h[1] < tb_rib_y + csk_d) 1]) > 0;
tb_ribs = [for (i = [0 : len(r0s) - 2]) let(x = (r0s[i] + r0s[i + 1]) / 2) if (!screw_near(x)) x];
echo(str("thumb bar's ribs at x = ", tb_ribs));
module tb_web() difference() {
    for (x = tb_ribs) translate([x - tb_rib_t / 2, 0, 0])
        rotate([90, 0, 90]) linear_extrude(tb_rib_t)
            polygon([[tb_fill - 0.01, -5], [tb_fill - 0.01, tb_top], [tb_rib_y, plate_top(tb_rib_y)], [tb_rib_y, -5]]);
    below_top();
}
module thumb_bar() difference() {
    union() {
        translate([x_front[0], 0, tb_dz]) rotate([90, 0, 90]) linear_extrude(x_front[1] - x_front[0]) tb_section();
        tb_web();
    }
    // the tray and the board stay whole: the bar ends at their front face, and sits on the
    // tray's shelf (hall.scad), with nothing under it
    slab_solid(-50, 0, fit + wall);
    front_shelf(-50, w_b + shelf_t);
    // and the bar does not stand into the plate's ends
    translate([-1000, -500, -500]) cube([1000 + x_front[0], 1000, 1000]);
    translate([x_front[1], -500, -500]) cube([1000, 1000, 1000]);
}

module cover() difference() {
    union() {
        slab_solid(0, cover_t, fit + wall);
        difference() {
            for (i = [0 : len(hall_keys) - 1]) at_key(key_row(i), key_x(i)) tube_body();
            below_top();
        }
        thumb_bar();
    }
    for (i = [0 : len(hall_keys) - 1]) at_key(key_row(i), key_x(i)) {
        tube_cut();
        translate([0, 0, -3]) cylinder(d = bore_lo, h = 4);      // the collar's bore down to the board
    }
    // over the wire pads (J1 .. J3: the wires come up through them from below and are
    // soldered on the top): a recess for the joints
    on_slab() for (w = hall_wires) translate([w[1] - w[3] / 2 - 1.2, w[2] - 1.2, -0.01]) cube([w[3] + 2.4, 2.4, wire_rec + 0.01]);
    on_slab() for (h = hall_holes) translate([h[0], h[1], 0]) {
        translate([0, 0, -1]) cylinder(d = screw_d, h = cover_t + 2);
        translate([0, 0, cover_t - (csk_d - screw_d) / 2]) cylinder(d1 = screw_d, d2 = csk_d + 0.2, h = (csk_d - screw_d) / 2 + 0.1);
    }
}

cover();
