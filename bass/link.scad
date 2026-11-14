// The bass's side of the gauges: each gauge is three parts [given], the outer holder
// (printed with the discant's housing), the flexure plate, and the inner holder, which
// is the bass's: both inner holders are printed with the case [given], on one mount on
// the outside of the box's thin back wall at the bass's -z end, in the step under the
// deck, flush with the bottom and centred. The bass goes on by sliding its inner holders onto the plates' W, as the
// holder is meant to (../strain_gauge/inner_holder.scad), and comes off the same way,
// after lifting the lugs of their latches, which hold the strap's pull [given: latch].
//
// The gauges point along the bass's y and sense along its z [given]: the discant is
// turned 180 deg about z, its y pointing back into the bass and its z staying the
// bass's z: bass = (-x, -y, z) of the discant, moved.
//
// Written in the discant's frame (../discant/gauge_link.scad) and moved into the bass
// by to_bass(): the mount is where the discant's link plate was, 76 x 6 x 10.8.

include <layout.scad>
use <../discant/gauge_link.scad>

// --- as gauge_link.scad (discant frame)
gauge_x = 0;
gz      = 1.6;
link_y  = 91.5;                  // the inner holders' backs
half_h  = 5.4;
// the inner holder (../strain_gauge/inner_holder.scad, walls 4.5): below the plate's middle
// 5.9, above it 6.89 with the latch's lug
hold_lo = 5.9;
hold_hi = 6.89;

// --- the mount
mount_x = 38;                    // half width, over both inner holders
mount_t = 6;                     // along the discant's y: from the holders to the hand plate

// where it sits on the bass: on the back wall's outside, centred on the hand plate in
// x, flush with the box's bottom
at = [(plate_x[0] + plate_x[1]) / 2, box_back, z_bot + hold_lo];   // the holders flush with the box's bottom
// the discant's gauges lie in its slope's plane (gauge_link.scad): the playing position
// takes its gauge frame, so the plates point along the bass's y and the discant's slope
// plane lies level
module to_bass()
    translate(at) multmatrix([[-1, 0, 0, 0], [0, -1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
        translate([-gauge_x, -(link_y + mount_t) + 0.01, -gz]) gauge_untilt() children();

module box(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

// --- CONTACTS [given: power and I2C cross by contacts closing as the bass slides on;
// the bass's battery switched on by them]: a block on the mount between the inner holders,
// reaching between the discant's outer holders, with nine spring pins (3 x 3 at 2.54)
// against the discant's contact board (../discant/gauge_link.scad, face at gauge y 84).
// Pins pressed in from the front, wires soldered on before, through a cavity behind
// them and a bore through the back wall into the box (elec.scad).
pin_p    = 2.54;
pin_hole = 1.6;                  // the pins' barrels [unverified: pin type, e.g. Mill-Max 0906]
blk_y    = [85, link_y];         // the block's face, 1 mm off the contact board, to the mount
blk_hw   = 5.2;  blk_hh = 5.0;   // as the discant's boss
cav      = [88.5, 3.6];          // cavity behind the barrels: from y, half size
chan_d   = 2.6;  chan_dz = -2.6; // the wires' bore through mount and back wall: at z_bot + 3.3, the middle of the slot under the case's foot
module contact_chan() translate([0, cav[0] + 2, gz + chan_dz]) rotate([-90, 0, 0]) cylinder(d = chan_d, h = 14);

module mount() to_bass() {
    difference() {
        gauge_tilt_frame() union() {
            box([gauge_x - mount_x, gauge_x + mount_x], [link_y - 0.01, link_y + mount_t], [gz - half_h, gz + half_h]);
            box([-blk_hw, blk_hw], [blk_y[0], blk_y[1] + 0.01], [gz - blk_hh, gz + blk_hh]);
        }
        gauge_tilt_frame() {
            for (i = [-1 : 1], j = [-1 : 1]) translate([i * pin_p, blk_y[0] - 1, gz + j * pin_p]) rotate([-90, 0, 0]) cylinder(d = pin_hole, h = cav[0] - blk_y[0] + 1.01, $fn = 16);
            box([-cav[1], cav[1]], [cav[0], link_y + mount_t - 1.5], [gz - cav[1], gz + cav[1]]);
            contact_chan();
        }
    }
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/inner_holder.stl");
}
// cut from the case: the wires' bore through the back wall
module mount_cuts() to_bass() gauge_tilt_frame() contact_chan();
// the pins' plungers, mated: 1 mm out of the block, on the pads (elec.scad)
module contact_plungers() to_bass() gauge_tilt_frame()
    for (i = [-1 : 1], j = [-1 : 1]) translate([i * pin_p, 84.02, gz + j * pin_p]) rotate([-90, 0, 0]) cylinder(d = 1.0, h = blk_y[0] - 84.02 + 0.5, $fn = 12);
// the discant's side, for checks and the page: plates with their dowel pins, and the
// outer holders, which are the discant housing's
module discant_side() to_bass() {
    gauge();
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/outer_holder.stl");
}

// --- STORED [given: plugged, not hinged; in the other plug position the bass covers the
// discant's keys; short socket, box 3 longer]. The discant turns 90 deg about x: its keys
// face the box's back wall, its back face up under the deck, and its plates go up into a
// short socket in a pocket in the deck's underside. The socket is the inner holder's last
// socket_e (8.3) of the W plus its bridge, with the holder's latch as a detent
// (../strain_gauge/inner_holder.scad, latch = "detent") [given: latch in both positions]:
// it holds the discant's weight, a firm pull down releases it. socket_e reaches just past
// the latch's tongue. Below the discant's front edge stays the travel to slide it on,
// socket_e + 1, above the playing mount, which is in the way of anything longer.
//
// TILTED by the discant's slope [given: use the slope]: its rows climb 3 per 16, so turned
// straight its caps lay on a slant, 1 mm off the wall at the top row and 10 at the bottom
// one. Turned back by atan(3/16) = 10.62 deg, caps and housing lie parallel to the wall:
// 26.2 thick. The plates lie in the same slope's plane [given], so they point straight up
// the bass's z, and the discant slides straight.
// Measured from the discant's build (../build/discant/: housing, cover, gauge_link, keys),
// turned so [2026-11-14: the thin discant on one Hall-sensor board, keys with the bronze
// bushing]: nearest the wall -18.546 (the caps' tops), farthest 7.64 (the thumb bar's
// foot), lowest over the playing mount -16.47: the thumb bar, whole along its length
// [given 2026-11-14: never cut].
socket_e   = 8.3;                 // holder y -16.7 .. -4.2: the W's bottom edge (-12.5) to the tongue's tip
travel     = socket_e + 1;
store_tilt = atan(3 / 16);
store_gap  = 1;
wall_d     = -18.546;
front_d    = -16.47;
// its front edge travel + 0.3 above the playing holders' tops (with the lugs)
store_at   = [(deck_x[0] + deck_x[1]) / 2, box_back + store_gap - wall_d, z_bot + hold_lo + hold_hi + 0.3 + travel - front_d];
module to_store() translate(store_at) rotate([90 - store_tilt, 0, 0]) children();

// the short socket, one per gauge: the inner holder from its back (holder y -16.7, the
// bridge) to socket_e past the W's bottom edge (holder y -12.5)
module store_socket() to_store() for (d = [-1, 1]) at_gauge(d)
    intersection() {
        import("../build/strain_gauge/inner_holder_detent.stl");
        translate([-50, -30, -50]) cube([100, 30 - 12.5 + socket_e, 100]);
    }
// the room the discant's gauge ends need: their outline seen along the plates, from the
// outer holders' tips (discant y 89.6) and 0.5 more, down past the deck's underside
module store_pocket() to_store() difference() {
    gauge_tilt_frame() translate([0, 40, 0]) rotate([-90, 0, 0]) linear_extrude(89.6 + 0.5 - 40)
        offset(delta = 0.4) projection() rotate([90, 0, 0]) intersection() {
            gauge_untilt() union() { gauge(); gauge_holders(); contact_board(); }
            translate([-200, 80, -50]) cube([400, 30, 100]);
        }
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/inner_holder_detent.stl");
}

echo(str("gauge mount on the plate at ", at, "; stored discant at ", store_at));

part = "mount";                   // "mount", "discant", "socket" or "pocket"
if (part == "mount") mount();
if (part == "discant") discant_side();
if (part == "socket") store_socket();
if (part == "pocket") store_pocket();
