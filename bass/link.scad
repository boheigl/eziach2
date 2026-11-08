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

// --- the mount
mount_x = 38;                    // half width, over both inner holders
mount_t = 6;                     // along the discant's y: from the holders to the hand plate

// where it sits on the bass: on the back wall's outside, centred on the hand plate in
// x, flush with the box's bottom
at = [(plate_x[0] + plate_x[1]) / 2, box_back, z_bot + half_h];
// the discant's gauges lie in its slope's plane (gauge_link.scad): the playing position
// takes its gauge frame, so the plates point along the bass's y and the discant's slope
// plane lies level
module to_bass()
    translate(at) multmatrix([[-1, 0, 0, 0], [0, -1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
        translate([-gauge_x, -(link_y + mount_t) + 0.01, -gz]) gauge_untilt() children();

module box(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

module mount() to_bass() {
    gauge_tilt_frame() box([gauge_x - mount_x, gauge_x + mount_x], [link_y - 0.01, link_y + mount_t], [gz - half_h, gz + half_h]);
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/inner_holder.stl");
}
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
// 29.5 thick instead of 37.6 (and 3.4 higher). The plates lie in the same slope's plane
// [given], so they point straight up the bass's z, and the discant slides straight.
// Measured from the discant's build, turned so (discant parts, keys): nearest the wall
// -9.245, lowest -12.74 (the cover's front edge).
socket_e   = 8.3;                 // holder y -16.7 .. -4.2: the W's bottom edge (-12.5) to the tongue's tip
travel     = socket_e + 1;
store_tilt = atan(3 / 16);
store_gap  = 1;
wall_d     = -9.245;
front_d    = -12.74;
store_at   = [(deck_x[0] + deck_x[1]) / 2, box_back + store_gap - wall_d, z_bot + 2 * half_h + travel - front_d];
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
            gauge_untilt() union() { gauge(); gauge_holders(); }
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
