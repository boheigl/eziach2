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
use <../strain_gauge/inner_holder.scad>

// --- as gauge_link.scad (discant frame)
gauge_x = 0;
gauge_dx = 25;                   // each gauge's centre from gauge_x (as gauge_link.scad, whose variables use<> does not bring)
gz      = 1.6;
link_y  = 91.5;                  // the inner holders' backs
half_h  = 5.4;
// the inner holder (../strain_gauge/inner_holder.scad, walls 4.5): below the plate's middle
// 5.9, above it the cam's lugs to latch_top() (9.0), which carry the axle (below)
hold_lo = 5.9;
hold_hi = latch_top();
// --- THE CAM LEVER [2026-11-25: the test print's spring latches held nothing and the plates
// rattled; replaces the rod that lifted them]: one printed part for both inner holders, two
// cams joined by their arms and a crossbar, on a stock steel axle (rod_d, rod_l) pressed
// through the four lugs (inner_holder.scad, latch = "cam"). Locked, it lies flat on the
// holders, the arms towards their mouths, and each cam presses its holder's shoe onto the
// plate through the M3 grub screw in the shoe, a little over centre, so it stays; one finger
// lifts the crossbar between the holders, 90 deg up, and the bass slides off. Over the
// discant's boss and outer holders (5.0, 5.4) and the contacts' block (5.5) the axle runs
// at 6.2 .. 8.2, the arms and crossbar at lever_z.
rod_l = 68;

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
// the bass's battery switched on by them; chosen 2026-11-15: spring pins on a small board]:
// a block on the mount between the inner holders, reaching between the discant's outer
// holders, holds the pin half of ../contact_pcb: three PG2541-03-003P strips (3 spring
// pins each, 2.54 apart, strips 3.0 apart: nine pins) against the discant's pad board
// (../discant/gauge_link.scad, face at gauge y 84). The board sits in a pocket open to the
// front; the pins' force (9 x about 1 N) presses it onto the pocket's ledge. Its nine wires
// are soldered to its back before, and run through the cavity behind it and a bore through
// the back wall into the box (elec.scad).
pin_px   = 2.54;  pin_pz = 3.0;  // as ../contact_pcb/gen_pcb.py (PX, PZ)
pcb      = [5.0, 4.5, 1.6];      // the board: half width (x), half height (z), thickness
pin_work = 4.5;                  // the pins' working height, 1.0 short of free 5.5; limit 4.2 [datasheet]
// [chosen 2026-11-18, review/contact_pcb.md MAJOR 1]: 4.7, 0.8 pressed, not the working
// height: the stack's tolerances (both boards' thickness ±0.16, the printed ledge and boss)
// come to about ±0.35, which then stays within 0 .. 1.3 of travel instead of bottoming
// out (a stiff second force path past the gauges). The force is about 100 g a pin there.
pin_h    = 4.7;
pin_base = 0.1;                  // copper and solder under the pins (not drawn)
pad_y    = 85;                   // the discant's pads (../discant/gauge_link.scad, contact_y)
pcb_y    = pad_y + pin_h + pin_base;   // the board's front
pcb_c    = 0.1;                  // the pocket's clearance round the board
blk_y    = [pad_y + 1, link_y];  // the block's face, 1 mm off the pad board, to the mount
// between the discant's outer holders (5.8 off the middle, their tips at 89.6) the block is
// 0.3 narrower; behind their tips, from tip_y, it is wider, and its walls there locate the board
tip_y    = 89.6 + 0.3;
blk_hw   = 5.5;                  // between the outer holders
blk_hw2  = pcb[0] + pcb_c + 1.0; // behind them: walls 1.0 round the board
blk_hh   = pcb[1] + pcb_c + 0.9; //   0.9 above and below: 5.5, under the latches' rod (6.2)
cav      = [pcb_y + pcb[2], 3.6];  // the cavity behind the board, for the wires' joints: from y, half size; the ledge round it carries the board
chan_d   = 2.6;  chan_dz = -2.6; // the wires' bore through mount and back wall: at z_bot + 3.3, the middle of the slot under the case's foot
module contact_chan() translate([0, cav[0] + 2, gz + chan_dz]) rotate([-90, 0, 0]) cylinder(d = chan_d, h = 14);

// --- OVERLOAD STOPS [given 2026-11-20: adjustable screw stops; ../discant/gauge_link.scad]:
// beside each inner holder, outboard, a block on the mount reaches forward past the outer
// holder's tip, round the discant's tongue, with a slot open to the holder. The slot is
// stop_gap wider than the tongue above and below; the screws close it: S1, a grub screw
// M3 x 4 in an insert in the slot's floor, tip up against the tongue; S2, M3 x 6 in the
// tongue's insert, tip up against the slot's roof, turned through a slot in the floor open
// to the front (the screw's foot slides in with the tongue). Both from below. The blocks
// reach from the box's bottom (the holders' bottoms) to stop_top.
// case.scad cuts their back part (y < 4.7, by the box) 2.3 lower, for the back cover's
// bulge sliding past [2026-11-24]; the roof over the slot (y > 6.2) stays whole.
st       = gauge_stop();         // [x, y, z, screws' x, S1 y, S2 y, insert]
stop_gap = 0.8;                  // the slot round the tongue, above and below, before the screws are set
stop_c   = 0.4;                  // clearances: to the outer holder, and round the tongue's end and edge
stop_out = 3.4;                  // the block's outer wall beyond the tongue's edge (with stop_c)
stop_bx  = 36.9;                 // behind the holder's tip the block reaches in to the mount's end (the inner holder ends at 36.5)
stop_top = st[2][1] + stop_gap + 4;
stop_key = 3.4;                  // the floor's slot for S2: wide enough for the screw and its key
stop_fy  = st[1][0] + 1.5;       // the block's front
hold_out = 25 + 19.2;            // the outer holder's outboard face: gauge_dx + its half width (../strain_gauge/outer_holder.scad)
module stop_blocks() for (d = [-1, 1]) mirror([d < 0 ? 1 : 0, 0, 0]) {
    box([gauge_x + stop_bx, gauge_x + st[0][1] + stop_out], [tip_y + 0.1, link_y + mount_t], [gz - hold_lo, stop_top]);
    box([gauge_x + hold_out + stop_c, gauge_x + st[0][1] + stop_out], [stop_fy, tip_y + 0.2], [gz - hold_lo, stop_top]);
}
module stop_cuts() for (d = [-1, 1]) mirror([d < 0 ? 1 : 0, 0, 0]) {
    box([gauge_x + hold_out, gauge_x + st[0][1] + stop_c], [stop_fy - 1, st[1][1] + stop_c],
        [st[2][0] - stop_gap, st[2][1] + stop_gap]);                                                    // the slot
    translate([gauge_x + st[3], st[4], gz - hold_lo - 0.01]) cylinder(d = st[6][0], h = st[2][0] - stop_gap - (gz - hold_lo) + 0.02);   // S1's insert
    box([gauge_x + st[3] - stop_key / 2, gauge_x + st[3] + stop_key / 2], [stop_fy - 1, st[5] + stop_key / 2],
        [gz - hold_lo - 0.01, st[2][0] - stop_gap + 0.01]);                                              // S2's way through the floor
}
// the four grub screws as set (tips at the tongue and the roof), for the page and the checks
module stop_screws() to_bass() gauge_tilt_frame() for (d = [-1, 1]) mirror([d < 0 ? 1 : 0, 0, 0]) {
    translate([gauge_x + st[3], st[4], st[2][0] - 0.05 - 4]) cylinder(d = 3, h = 4, $fn = 16);       // S1, M3 x 4
    translate([gauge_x + st[3], st[5], st[2][1] + stop_gap - 0.05 - 6]) cylinder(d = 3, h = 6, $fn = 16);   // S2, M3 x 6
}

module mount() to_bass() {
    difference() {
        gauge_tilt_frame() union() {
            box([gauge_x - mount_x, gauge_x + mount_x], [link_y - 0.01, link_y + mount_t], [gz - half_h, gz + half_h]);
            box([-blk_hw, blk_hw], [blk_y[0], blk_y[1] + 0.01], [gz - blk_hh, gz + blk_hh]);
            box([-blk_hw2, blk_hw2], [tip_y, blk_y[1] + 0.01], [gz - blk_hh, gz + blk_hh]);
            stop_blocks();
        }
        gauge_tilt_frame() {
            box([-pcb[0] - pcb_c, pcb[0] + pcb_c], [blk_y[0] - 1, cav[0] + 0.01], [gz - pcb[1] - pcb_c, gz + pcb[1] + pcb_c]);   // the pocket
            box([-cav[1], cav[1]], [cav[0], link_y + mount_t - 1.5], [gz - cav[1], gz + cav[1]]);
            contact_chan();
            stop_cuts();
        }
    }
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/inner_holder.stl");
}
// the axle, along x through the lugs: in each holder's frame (cam_axle(): y, z of its axis, d)
module latch_rod_body() let(r = cam_axle()) hull() for (d = [-1, 1]) at_gauge(d)
    translate([-(rod_l / 2 - 25), r[0], r[1]]) rotate([0, 90, 0]) cylinder(d = r[2], h = rod_l - 50, $fn = 24);
// the lever, locked, in each holder's frame (y towards its mouth, z up from the plate's middle)
lever_z  = [5.95, 9.0];          // arms and crossbar: flush with the hubs' tops; locked, the arms rest
                                 //   on the holders' top faces (5.9): the stop just past over centre
lever_y  = 2.0;                  // the crossbar's back edge, holder y (the holders' fronts at 4.5)
lever_w  = 2.0;                  // the crossbar's depth (y)
arm_w    = 4.0;                  // the arms' width (x), between the lugs
cam_hump = 0.05;                 // over centre: the cam's radius this much more just before locked
// the cam's outline in y-z about the axle, locked: theta from +y towards +z; the part that faces
// down (-z) is theta -90 locked, -180 released (the arm up). Released radius r0 under the
// axle, rising to the locked r1 (+ the hump just before it), the hub's r0 elsewhere
function cam_r(t, r0, r1) = t <= -180 || t >= -60 ? r0
    : t < -100 ? r0 + (r1 + cam_hump - r0) * (t + 180) / 80
    : t < -90 ? r1 + cam_hump * (-90 - t) / 10
    : r1 - (r1 - r0) * (t + 90) / 30;
module cam2d() let(c = cam_axle())
    polygon([for (t = [-270 : 2.5 : 89.9]) let(r = cam_r(t > 90 ? t - 360 : t, c[4], c[5])) [c[0] + r * cos(t), c[1] + r * sin(t)]]);
// the lever in the +x holder's frame (at_gauge(1)): the other holder at x 2 gauge_dx there
module cam_lever_flat() {
    c = cam_axle();
    difference() {
        union() {
            for (x = [0, 2 * gauge_dx]) translate([x, 0, 0]) {
                // the hub with its cam, between the lugs; flat on top over the axle, so the
                // lever lies flat as it prints (upside down)
                translate([-c[3], 0, 0]) rotate([90, 0, 90]) linear_extrude(2 * c[3]) cam2d();
                translate([-c[3], c[0] - c[4], c[1]]) cube([2 * c[3], 2 * c[4], lever_z[1] - c[1]]);
                // the arm, from the hub to the crossbar
                translate([-arm_w / 2, c[0], lever_z[0]]) cube([arm_w, lever_y + lever_w - c[0], lever_z[1] - lever_z[0]]);
            }
            translate([-arm_w / 2, lever_y, lever_z[0]]) cube([2 * gauge_dx + arm_w, lever_w, lever_z[1] - lever_z[0]]);
        }
        // the axle's hole, a running fit, pointed at -z (up as it prints, upside down)
        translate([-c[3] - 1, c[0], c[1]]) rotate([0, 90, 0]) linear_extrude(2 * gauge_dx + 2 * c[3] + 2)
            hull() { circle(d = c[2] + 0.15, $fn = 32); translate([rod_hole_up(c[2] + 0.15), 0]) square(0.01, center = true); }
    }
}
// placed, turned phi about the axle (0 locked, 90 released, the arms up)
module cam_lever(phi = 0) let(c = cam_axle()) at_gauge(1)
    translate([0, c[0], c[1]]) rotate([phi, 0, 0]) translate([0, -c[0], -c[1]]) cam_lever_flat();
function rod_hole_up(d) = d / 2 * sqrt(2);
// one cam with its arm and a grip, for one holder (the holder test print), in its frame
module cam_lever_one() {
    c = cam_axle();
    difference() {
        union() {
            translate([-c[3], 0, 0]) rotate([90, 0, 90]) linear_extrude(2 * c[3]) cam2d();
            translate([-c[3], c[0] - c[4], c[1]]) cube([2 * c[3], 2 * c[4], lever_z[1] - c[1]]);
            translate([-arm_w / 2, c[0], lever_z[0]]) cube([arm_w, lever_y + lever_w - c[0], lever_z[1] - lever_z[0]]);
            translate([-c[3], lever_y, lever_z[0]]) cube([2 * c[3], lever_w, lever_z[1] - lever_z[0]]);
        }
        translate([-c[3] - 1, c[0], c[1]]) rotate([0, 90, 0]) linear_extrude(2 * c[3] + 2)
            hull() { circle(d = c[2] + 0.15, $fn = 32); translate([rod_hole_up(c[2] + 0.15), 0]) square(0.01, center = true); }
    }
}
// cut from the case: the wires' bore through the back wall
module mount_cuts() to_bass() gauge_tilt_frame() contact_chan();
// the pin board with its three strips, mated (for the page and the checks): the strip's
// housing, the barrels to 4.0 and the plungers to the pads, their tips round [datasheet:
// PG2541-03-003P, plunger 0.9, barrel 1.5; the housing's height estimated]
pin_barrel = 1.5;
pin_plunger = 0.9;
module contact_pins() to_bass() gauge_tilt_frame() {
    box([-pcb[0], pcb[0]], [pcb_y, pcb_y + pcb[2]], [gz - pcb[1], gz + pcb[1]]);                     // the board
    for (j = [-1 : 1]) {
        box([-3.8, 3.8], [pcb_y - 1.5, pcb_y], [gz + j * pin_pz - 1.25, gz + j * pin_pz + 1.25]);    // a strip's housing
        for (i = [-1 : 1]) translate([i * pin_px, 0, gz + j * pin_pz]) rotate([-90, 0, 0]) {
            translate([0, 0, pcb_y - 4.0]) cylinder(d = pin_barrel, h = 2.5, $fn = 16);                 // barrel
            translate([0, 0, (pad_y + 0.02) + pin_plunger / 2]) cylinder(d = pin_plunger, h = pcb_y - 4.0 - (pad_y + 0.02) - pin_plunger / 2 + 0.01, $fn = 12);
            translate([0, 0, (pad_y + 0.02) + pin_plunger / 2]) sphere(d = pin_plunger, $fn = 12);           // tip
        }
    }
}
// the discant's side, for checks and the page: plates with their dowel pins, and the
// outer holders, which are the discant housing's
module discant_side() to_bass() {
    gauge();
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/outer_holder.stl");
    gauge_stop_tongues();
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
// 27.7 thick (26.2 on 2026-11-14). The plates lie in the same slope's plane [given], so they point straight up
// the bass's z, and the discant slides straight.
// Measured from the discant's build (../build/discant/: housing, cover, gauge_link, keys),
// turned so [2026-11-14: the thin discant on one Hall-sensor board, keys with the bronze
// bushing]: nearest the wall -18.546 (the caps' tops), farthest 7.64 (the thumb bar's
// foot), lowest over the playing mount -16.47: the thumb bar, whole along its length
// [given 2026-11-14: never cut]. Measured again 2026-11-21 (the keys taller since, the
// caps 3.2 for the 14 mm dowel pins): nearest -21.494 (the caps' tops; -18.546 was stale,
// the caps ran 2 mm into the back cover), farthest 6.24 (the housing), lowest -15.92
// (front_d kept at -16.47: 0.55 more over the playing mount).
socket_e   = 8.3;                 // holder y -16.7 .. -4.2: from y -12.5 (the STEP's bottom edge of the W; the
                                  // bought cell's is -10.8, the holder kept its length) to the tongue's tip
travel     = socket_e + 1;
store_tilt = atan(3 / 16);
store_gap  = 1;
wall_d     = -21.494;
front_d    = -16.47;
// its front edge travel + 0.3 above the playing holders' tops (with the lugs)
store_at   = [(deck_x[0] + deck_x[1]) / 2, box_back + store_gap - wall_d, z_bot + hold_lo + hold_hi + 0.3 + travel - front_d];
module to_store() translate(store_at) rotate([90 - store_tilt, 0, 0]) children();

// the short socket, one per gauge: the inner holder from its back (holder y -16.7, the
// bridge) to socket_e past holder y -12.5 (the STEP's bottom edge of the W)
module store_socket() to_store() for (d = [-1, 1]) at_gauge(d)
    intersection() {
        import("../build/strain_gauge/inner_holder_detent.stl");
        translate([-50, -30, -50]) cube([100, 30 - 12.5 + socket_e, 100]);
    }
// the room the discant's gauge ends need: their outline seen along the plates, from the
// ends of the overload stops' tongues (discant y 96.5; the outer holders' tips 89.6) and 0.5
// more, down past the deck's underside
module store_pocket() to_store() difference() {
    gauge_tilt_frame() translate([0, 40, 0]) rotate([-90, 0, 0]) linear_extrude(st[1][1] + 0.5 - 40)
        offset(delta = 0.4) projection() rotate([90, 0, 0]) intersection() {
            gauge_untilt() union() { gauge(); gauge_holders(); contact_board(); }
            translate([-200, 80, -50]) cube([400, 30, 100]);
        }
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/inner_holder_detent.stl");
}

echo(str("gauge mount on the plate at ", at, "; stored discant at ", store_at));

part = "mount";                   // "mount", "discant", "socket", "pocket", "rod", "lever", "pins" or "stops" (the grub screws)
if (part == "mount") mount();
if (part == "pins") contact_pins();
if (part == "stops") stop_screws();
if (part == "rod") to_bass() latch_rod_body();
phi = 0;                          // the lever: 0 locked, 90 released
if (part == "lever") to_bass() cam_lever(phi);
if (part == "discant") discant_side();
if (part == "socket") store_socket();
if (part == "pocket") store_pocket();
