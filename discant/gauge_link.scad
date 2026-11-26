// Strain gauges and link to the bass module, on the discant's +y side
//
// Force path [given]: discant -> gauges -> bass module. Each gauge is three parts
// [given]: the outer holder (the discant's), the plate, the inner holder (the bass's).
// Two gauges side by side [given], which also holds against torsion, their plates in
// the slope's plane [given], so they sense force normal to it. Fixed side: the outer
// holders, printed as part of the housing [given], growing out of the gauge pad on the
// back face. Each plate slides into its holder from the far end until its edge lands
// on the pad, and a dowel pin across each jaw keeps it in. Moving side: the inner
// holders, printed with the bass on one mount [given] (../bass/link.scad).
//
// Each bridge reads moment at its column, so force times the arm from the gauges to
// where the force acts. The sum follows the force, the difference the twist.
//
// THE GAUGE FRAME. Everything here, and the bass's side in ../bass/link.scad, is written
// in one frame: the gauges' local coordinates, as they were when the pad sat on the old
// housing's vertical back face (back face y = 59.3, middle z = gz = 1.6, the plates
// along y, tilted into the slope's plane about the pad face's middle). Those numbers
// stay; gauge_tilt_frame() maps them onto the discant. [given 2026-11-13: in the tray's
// plane] Since the tray (housing.scad) is thin, the frame now sits on the tray's back
// face (slab_back, hall.scad), centred in the case's thickness (w_mid): the tilt leaves
// the plates parallel to the tray, and the pad's face parallel to its back face, so the
// pad is a plain block, no wedge. The holders are thicker than the tray and stand out
// above and below it by the same amount. ../bass/link.scad's to_bass() uses
// gauge_untilt(), the inverse, so the bass's side follows by itself; only where the
// discant's body lies relative to the bass changes (../assembly/).
//
// THE BRIDGES' ADC [chosen 2026-11-15: on the Hall-sensor board, no link board]: the
// NAU7802 sits on the Hall-sensor board's underside at its back edge, between the gauges
// (../hall_pcb/design.py). The gauges' leads leave the plates towards the pad, run along
// a groove in it to a channel each, and through the channel, under the board's back edge,
// up through its wire pads J2 / J3 (soldered from the top; the cover has a recess over
// them, cover.scad). Where a plate's edge lands the groove runs under a 1 mm strip, which
// is the plate's stop. The gauge plane lies at the height of the gap under the board
// (w_mid, hall.scad), so the channels run straight in. The wire pads' places come from
// the board (hall_wires, board.scad).
//
// CONTACTS [given: power and I2C cross by contacts that close when the bass slides on]:
// a boss between the outer holders carries a small board with six gold pads, 2 x 3 at
// 2.54 across and 3.0 up, facing the bass's spring pins (../bass/link.scad), the pad half
// of ../contact_pcb [2026-11-25: was nine]. Pads: 3.3 V, GND, SDA, SCL, INT, DET; DET is tied to GND on
// this board, which switches the bass's system on (../assembly/spec.md). Five wires are
// soldered to its back, in a recess of the boss, and go down a bore into the groove.
//
// Part bodies are boxes; sizes [unverified] until the parts are chosen.
//
// make builds   openscad -o ../build/discant/gauge_link.stl gauge_link.scad   (part "link")
// housing.scad uses gauge_housing_pads(), gauge_holders() and gauge_housing_cuts().

include <hall.scad>
use <../strands.scad>

/* [The gauge frame: local numbers, as before; do not change (../bass/link.scad)] */
back_y   = 59.3;                 // the pad's back, local
gauge_z  = 1.6;                  // the pad's middle, local
plate_top = 12.5;                // the +y edge of plate and outer holder, plate frame
inner_end_abs = 16.7;            // the inner holder's far end from the plate frame's origin
gauge_x  = 0;                    // the row's middle key
gauge_dx = 25;                   // each gauge's centre from gauge_x: 11.6 between the holders
half_h   = 5.4;                  // the holders' half thickness
pad_t    = 3;                    // the gauge pad on the back face
pad_x    = [-46, 46];            // past both holders
groove_h = 1.6;                  // lead groove in the pad: half height
groove_d = 1.5;                  //   and depth, behind the strips
strip_t  = 1;                    // the plate's stop in front of the groove
strip_in = 9.6;                  // strips from strip_in to strip_out either side of a gauge's middle,
strip_out = 15.4;                //   so under the plate's edge; open between them for the leads
pin_x    = 13.5;                 // dowel pins, as in outer_holder.scad
plate_bot = -10.8;               // the bought cell's -y edge (../strain_gauge/outer_holder.scad plate_bot)
pin_y    = plate_bot - 0.05 - 0.75;   // as outer_holder.scad: 0.05 past the arm tips, d 1.5 [2026-11-21: was -13.3, the STEP's plate]
pin_d    = 1.5;
pin_l    = 10;
plate_y0 = back_y + pad_t + plate_top;   // the plate frame's origin on local y; turned 180 deg
gauge_tilt = atan(3 / 16);               // the slope's plane [given]
pivot_y  = back_y + pad_t;               // the tilt's axis: the pad face's middle, at gz

/* [Contacts to the bass, between the outer holders (local)] */
contact_y  = 85;                 // the pads' face (the outer holders' tips: 89.6): the bass's pin board sits behind those tips
contact_t  = 1.6;                // ../contact_pcb (gen_pcb.py: W, H, T, PX, PZ, PAD_D)
contact_hw = 5.0;                // half width (x) and half height (z) of boss and board
contact_hh = 3.5;
contact_px = 2.54;               // the pads: across (x)
contact_pz = 3.0;                //   and up (z)
contact_pad = 2.2;
contact_rec = [3.6, 1.5, 2.6];   // the recess behind the board for the wires' joints: half width, depth, half height
contact_bore = 2.2;
contact_wire_d = 1.4;            // five AWG 30 PTFE (⌀0.55 each) bundled (../assembly/spec.md, Wiring)

/* [Overload stops (local) [given 2026-11-20: adjustable screw stops]] */
// The bought cells take 490 N at their 7 mm arm, 3430 N·mm, 150 % (5145 N·mm) without
// harm [seller]; a hard push on the bass's hand plate puts 6400-12500 N·mm on the two
// (100 N at 64-125 mm), more on one when the push is off centre (../strain_gauge/spec.md
// §4a). So each gauge gets two stops beside it: a tongue, 5 thick in z (the sensing
// direction), stands out from its outer holder's outboard face, and the bass's mount
// reaches forward round it with a slot open to the holder (../bass/link.scad); a grub
// screw in the slot's floor stops the tongue going down, one in an insert in the tongue,
// its tip against the slot's roof, stops it going up. Both are set from below, by load
// (../assembly/spec.md, Overload stops): up to the set force the cells carry it all, past
// it the screws take the rest. The tongue stays within the holder's length (to its tip,
// 89.6), so the stored discant's pocket in the deck keeps its depth.
stop_x   = [43.7, 52.6];         // the tongue across: 0.5 into the holder's outboard wall (to 44.2), 8.4 out
stop_y   = [80, 89.6];           // along: to the holder's tip
stop_z   = [gauge_z - 1.0, gauge_z + 4.0];
stop_sx  = 48.6;                 // both screws' x
stop_s2  = 83.4;                 // the screw in the tongue (up against the slot's roof): y
stop_s1  = 87.4;                 // the screw in the slot's floor (up against the tongue): y
stop_ins = [4.0, 4.0];           // heat-set insert M3: hole diameter, length [unverified: the insert bought]
function gauge_stop() = [stop_x, stop_y, stop_z, stop_sx, stop_s1, stop_s2, stop_ins];

/* [Wires into the tray: a channel each from the groove under the board's back edge] */
lead_d   = 1.2;                  // a gauge's three leads, AWG 30 PTFE, bundled
chan_w   = 3.0;                  // the channels' width (x)
// [2026-11-25: in the test print the leads could not be threaded: their channels at x +-12
// (under the pad rows J2 / J3) began behind the strip, the plates' stop, so the turn from
// the groove into the channel lay inside a closed tunnel, and loose wires pushed along ran
// past it. Then they left the groove at x +-8 with a chamfer at the turn: still two turns
// out of sight.] Now each gauge's channel runs straight, no turn: from the groove at the
// plate's middle (x +-gauge_dx), where it is open to the pad's face between the strips,
// slanting through pad and back wall to under its pad row (x +-12): the leads are pushed in
// where they leave the plate and come out under the pads.

$fa = 2; $fs = 0.2;

gz = gauge_z;
module box(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

// where the pad face's middle (local [0, pivot_y, gz]) sits on the discant: the tray's back
// face, pad_t further back, in the middle of the case's thickness
pivot_new = slab_pt([0, slab_back + pad_t, w_mid]);
gauge_shift = pivot_new - [0, pivot_y, gz];
// local -> discant, and back
module gauge_tilt_frame() translate(gauge_shift) translate([0, pivot_y, gz]) rotate([gauge_tilt, 0, 0])
    translate([0, -pivot_y, -gz]) children();
module gauge_untilt() translate([0, pivot_y, gz]) rotate([-gauge_tilt, 0, 0]) translate([0, -pivot_y, -gz])
    translate(-gauge_shift) children();
function gauge_tilt() = gauge_tilt;
// a point of the slab frame in local coordinates (the two frames differ by a shift only)
function slab_local(p) = [p[0], back_y + (p[1] - slab_back), gz + (p[2] - w_mid)];
module at_gauge(d) gauge_tilt_frame() translate([gauge_x + d * gauge_dx, plate_y0, gz]) rotate(180) children();

// the plates and their pins; the inner holders are the bass's (../bass/link.scad) [given]
module gauge() for (d = [-1, 1]) at_gauge(d) {
    import("../build/strain_gauge/strain_gauge_plate.stl");
    for (s = [-1, 1]) translate([s * pin_x, pin_y, -pin_l / 2]) cylinder(d = pin_d, h = pin_l);
}
// part of the housing: the outer holders, and the contacts' boss between them
module gauge_holders() {
    for (d = [-1, 1]) at_gauge(d) import("../build/strain_gauge/outer_holder.stl");
    gauge_contact_boss();
    gauge_stop_tongues();
}
// part of the housing: the overload stops' tongues, with the upper screw's insert hole
// Under it a 45° gusset down the holder's face: the housing prints standing, holders up
// (spec.md, Printing), where the tongue's -y face would hang out flat; the gusset lies in
// front of the bass's block (its front at stop_y[0] + 1.5).
module gauge_stop_tongues() gauge_tilt_frame() for (d = [-1, 1]) mirror([d < 0 ? 1 : 0, 0, 0]) difference() {
    union() {
        box([gauge_x + stop_x[0], gauge_x + stop_x[1]], stop_y, stop_z);
        translate([0, 0, stop_z[0]]) linear_extrude(stop_z[1] - stop_z[0])
            polygon([[gauge_x + stop_x[0], stop_y[0] + 0.01], [gauge_x + stop_x[1], stop_y[0] + 0.01],
                     [gauge_x + stop_x[0], stop_y[0] - (stop_x[1] - stop_x[0])]]);
    }
    translate([gauge_x + stop_sx, stop_s2, stop_z[0] - 0.01]) cylinder(d = stop_ins[0], h = stop_z[1] - stop_z[0] + 0.02);
}
// a point under the board, in local coordinates: X, Y of the board, W in the gap under it
function under_board(x, y) = slab_local([x, y, (-hall_t + w_ft) / 2]);
// the board's wire pads: [ref, X of the row's middle, Y], from board.scad
function wires(r) = [for (w = hall_wires) if (w[0] == r) w][0];

// the contact board; pads as thin discs on its face
module contact_board() gauge_tilt_frame() {
    box([-contact_hw, contact_hw], [contact_y - contact_t, contact_y - 0.035], [gz - contact_hh, gz + contact_hh]);
    for (i = [-1 : 1], j = [-1, 1]) translate([i * contact_px, contact_y - 0.035, gz + j * contact_pz / 2])
        rotate([-90, 0, 0]) cylinder(d = contact_pad, h = 0.035, $fn = 20);
}
// part of the housing: the boss under the contact board, with the wires' bore
module gauge_contact_boss() gauge_tilt_frame() difference() {
    box([-contact_hw, contact_hw], [back_y + pad_t - 0.5, contact_y - contact_t], [gz - contact_hh, gz + contact_hh]);
    translate([0, back_y + pad_t - 1, gz]) rotate([-90, 0, 0]) cylinder(d = contact_bore, h = contact_y - back_y);
    box([-contact_rec[0], contact_rec[0]], [contact_y - contact_t - contact_rec[1], contact_y - contact_t + 0.01], [gz - contact_rec[2], gz + contact_rec[2]]);
}
g_y = back_y + pad_t - strip_t;                 // the groove's front, behind the strips
// a wire's way from the groove at x0 to the board's pad row r: the contacts' along the groove
// to x 0 and through its channel under the board; a gauge's straight from x0 (its channel
// slants); to below the pads (they go up through them)
function to_pads(x0, r) = let(w = wires(r), u = under_board(w[1], w[2] - 0.4))
    r == "J1" ? [[x0, g_y - groove_d / 2, gz], [0, g_y - groove_d / 2, gz], [0, g_y - groove_d / 2, u[2]], [0, u[1] + 0.5, u[2]], u]
              : [[x0, g_y - groove_d / 2, gz], [x0, g_y - groove_d / 2, u[2]], u];
// the contacts' wires (3.3 V, GND, SDA, SCL, INT; DET stays on the board): down the boss's
// bore into the groove, to J1, the board's bus pads
function contact_pts() = concat([[0, contact_y - contact_t - 0.2, gz]], to_pads(0, "J1"));
// a gauge's three leads (E+, E-, middle): from the plate's middle at the pad, to J2 / J3
function lead_pts(d) = to_pads(gauge_x + d * gauge_dx, d < 0 ? "J2" : "J3");
module wire(p, dw) for (i = [0 : len(p) - 2]) hull() { translate(p[i]) sphere(d = dw, $fn = 12); translate(p[i + 1]) sphere(d = dw, $fn = 12); }
// SINGLE WIRES [given 2026-11-26: every wire modelled on its own] (../strands.scad): along the
// ways above side by side, each with its own end at its pad. AWG 30 PTFE, d 0.55.
awg30 = 0.55;
// a wire's end at the board's wire pad X of row r: from under the board up through it
function up_pad(x, r) = let(w = wires(r)) [under_board(x, w[2] - 0.4), slab_local([x, w[2], 0.4])];   // 0.4 over the board: the joint, under the cover's recess
// the contacts' five: from the pad board's back pads (x 2.54 apart, z +-1.6; DET stays on the
// board) to J1, its pads 2.0 apart: INT, 3.3 V, SDA, SCL, GND (pins 1 .. 5)
c_pad = [[-1, 1], [1, 1], [0, -1], [0, 1], [-1, -1]];   // 3.3 V, GND, SDA, SCL, INT [2026-11-26: ../contact_pcb GRID, searched]
c_slot = [3, 1, 0, 2, 4];   // their places in the bundle (searched: their fans do not touch)
c_pin = [2, 5, 3, 4, 1];
module contact_wires() gauge_tilt_frame() let(c = contact_pts(), w = wires("J1"))
    // [2026-11-26: each from its pad straight back, then to its own place in the bundle, which
    // starts at the bore (they all ran through the bore's first point before, into each other)]
    // the bundle from the bore's entry on (the recess behind the board, contact_rec, is where
    // they come together)
    strands(concat([[0, contact_y - contact_t - contact_rec[1], gz]], [for (i = [1 : len(c) - 2]) c[i]]), 5, awg30,
            [for (k = [0 : 4]) let(q = [c_pad[k][0] * contact_px, contact_y - contact_t - 0.05, gz + c_pad[k][1] * 1.6]) [q, q - [0, 0.3, 0]]],
            [for (k = [0 : 4]) up_pad(w[1] + (c_pin[k] - 3) * 2.0, "J1")], colours = ["red", "black", "blue", "yellow", "green"],
            slot_of = c_slot);
// a gauge's three leads: off the plate's edge at its column (glued along it, ../strain_gauge) into
// the groove, to J2 / J3, its pads 2.0 apart (AVDD, the middle, GND)
module lead_wires() gauge_tilt_frame() for (d = [-1, 1]) let(c = lead_pts(d), r = d < 0 ? "J2" : "J3", w = wires(r))
    // the way down the groove in thirds: the three turn there evenly (twist), from across their
    // way off the plate (a row along x) to across their way to the pads (which runs mostly along x)
    strands([c[0], c[0] + (c[1] - c[0]) / 3, c[0] + 2 * (c[1] - c[0]) / 3, c[1]], 3, awg30,
            [for (k = [0 : 2]) [[c[0][0] + (k - 1) * 0.7, back_y + pad_t + 1.5, gz]]],
            [for (k = [0 : 2]) up_pad(w[1] + (k - 1) * 2.0, r)], colours = ["red", "yellow", "black"],   // AVDD (E+), the middle, GND: as the bought cell's
            by_start_row = true, flat = true, twist = 67 * d);   // [2026-11-26: they leave the plate in a row and stay in one, flat in
                                                 // the groove; in a ring two passed each other at the plate's edge]
// the cable list (../assembly/spec.md, Wiring) takes its lengths from the point lists
function path_len(p) = len(p) < 2 ? 0 : norm(p[1] - p[0]) + path_len([for (i = [1 : len(p) - 1]) p[i]]);
echo(str("wire lengths: contacts to J1 ", path_len(contact_pts()), "; gauge leads to J2 ", path_len(lead_pts(-1)),
         ", to J3 ", path_len(lead_pts(1))));

// [2026-11-26: the wires apart, in their colours: part "wires" with $wire_color]
module gauge_link() { gauge(); contact_board(); }
module gauge_wires() { contact_wires(); lead_wires(); }
part = "link";   // "link": the gauges and the contact board; "wires": their wires

// added to the housing: the gauge pad on the back face
module gauge_housing_pads() gauge_tilt_frame()
    box([gauge_x + pad_x[0], gauge_x + pad_x[1]], [back_y - 1, back_y + pad_t], [gz - half_h, gz + half_h]);

// cut from the housing: the groove, and the channels from it under the board
module gauge_housing_cuts() gauge_tilt_frame() {
    // groove and strips along the pad's face, past both gauges
    g_x = [gauge_x - gauge_dx - strip_in, gauge_x + gauge_dx + strip_in];
    box(g_x, [g_y - groove_d, g_y + 0.01], [gz - groove_h, gz + groove_h]);
    // open to the pad's face between the strips: between and inside the plates
    for (o = [[-gauge_dx - strip_in, -gauge_dx + strip_in], [-gauge_dx + strip_out, gauge_dx - strip_out],
              [gauge_dx - strip_in, gauge_dx + strip_in]])
        box([o[0], o[1]], [g_y, back_y + pad_t + 1.2], [gz - groove_h, gz + groove_h]);
    // the contacts' wires: from the boss's bore through the pad into the groove
    translate([0, g_y - groove_d, gz]) rotate([-90, 0, 0]) cylinder(d = contact_bore, h = pad_t + 2);
    // a channel from the groove through pad and back wall under the board, below each pad row:
    // from 0.3 into the floor up to 0.05 under the board's underside. The contacts' at x 0;
    // a gauge's straight from the groove at its plate's middle to under its pad row
    let(z0 = slab_local([0, 0, w_ft - 0.3])[2], z1 = slab_local([0, 0, -hall_t - 0.05])[2]) {
        // [2026-11-26: on under the groove to its front: the contacts' wires, drawn one by one,
        // turn down into the channel there and the lowest grazed the groove's floor]
        let(w = wires("J1"), u = under_board(w[1], w[2] - 1.2))
            box([-chan_w / 2, chan_w / 2], [u[1], g_y], [z0, z1]);
        for (d = [-1, 1]) let(w = wires(d < 0 ? "J2" : "J3"), u = under_board(w[1], w[2] - 1.2)) hull() {
            box([gauge_x + d * gauge_dx - chan_w / 2, gauge_x + d * gauge_dx + chan_w / 2], [g_y - groove_d, g_y], [z0, z1]);
            box([w[1] - chan_w / 2, w[1] + chan_w / 2], [u[1], u[1] + chan_w], [z0, z1]);
        }
    }
}

echo(str("gauge frame on the tray's back face: pad face's middle at ", pivot_new, " (was [0, ", pivot_y, ", ", gz,
         "]), moved by ", gauge_shift));

if (part == "link") gauge_link();
if (part == "wires") gauge_wires();
