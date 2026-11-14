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
// LINK BOARD [given: housed, no screws]: the bridges' ADC (NAU7802) on a small board,
// lying flat in a pocket in a block beside the pad, flush with the board's top; the
// discant's cover reaches out over the block and closes it [given 2026-11-14: cover and
// lid one part] (gauge_cover_tongue(), cover.scad). Corner ledges carry the board. Five wires come from
// the Hall-sensor board's bus connector J1 (../hall_pcb/): 3.3 V, ground, SDA, SCL, INT;
// J1 is a side-entry JST at the board's back edge, just in front of the pocket, and the
// plug's wires run straight in (housing.scad, plug_cavity()). The gauges' leads leave the
// plates towards the pad and run along a groove in it into the pocket. Where a plate's
// edge lands the groove runs under a 1 mm strip, which is the plate's stop.
//
// CONTACTS [given: power and I2C cross by contacts that close when the bass slides on]:
// a boss between the outer holders carries a small board with nine gold pads, 3 x 3 at
// 2.54, facing the bass's spring pins (../bass/link.scad). Pads: 3.3 V x 2, GND x 3,
// SDA, SCL, INT, DET; DET is tied to GND on this board, which switches the bass's
// system on (../assembly/spec.md). A bore down the boss takes the wires into the groove.
//
// Part bodies are boxes; sizes [unverified] until the parts are chosen.
//
// make builds   openscad -o ../build/discant/gauge_link.stl gauge_link.scad   (part "link")
// housing.scad uses gauge_housing_pads(), gauge_holders() and gauge_housing_cuts();
// cover.scad gauge_cover_tongue().

include <hall.scad>

/* [The gauge frame: local numbers, as before; do not change (../bass/link.scad)] */
back_y   = 59.3;                 // the pad's back, local
gauge_z  = 1.6;                  // the pad's middle, local
plate_top = 12.5;                // the +y edge of plate and outer holder, plate frame
inner_end_abs = 16.7;            // the inner holder's far end from the plate frame's origin
gauge_x  = 0;                    // the row's middle key
gauge_dx = 25;                   // each gauge's centre from gauge_x: 11.6 between the holders
half_h   = 5.4;                  // the holders' half thickness
pad_t    = 3;                    // the gauge pad on the back face
pad_x    = [-50, 46];            // from the pocket's block to past the far holder
groove_h = 1.6;                  // lead groove in the pad: half height
groove_d = 1.5;                  //   and depth, behind the strips
strip_t  = 1;                    // the plate's stop in front of the groove
strip_in = 9.6;                  // strips from strip_in to strip_out either side of a gauge's middle,
strip_out = 15.4;                //   so under the plate's edge; open between them for the leads
pin_x    = 13.5;                 // dowel pins, as in outer_holder.scad
pin_y    = -13.3;
pin_d    = 1.5;
pin_l    = 10;
plate_y0 = back_y + pad_t + plate_top;   // the plate frame's origin on local y; turned 180 deg
gauge_tilt = atan(3 / 16);               // the slope's plane [given]
pivot_y  = back_y + pad_t;               // the tilt's axis: the pad face's middle, at gz

/* [Link board, lying flat in its pocket beside the pad (local)] */
board_w  = 20.5;                 // along x
board_d  = 13.5;                 // along y
board_t  = 3;                    // board and parts
blk_x    = [-86.5, pad_x[0] + 0.5];   // the pocket's block, from past J1's plug to the pad
pk_x     = [-84.5, -51.2];       // the pocket: J1's plug (x -83.8 .. -76.2) and the board
pk_y     = [back_y, back_y + 16.5];
blk_y1   = back_y + 18;          // the block's back: 1.5 behind the pocket
pk_floor = 1.0;                  // under the pocket
ledge    = 1;                    // floor to the board: room for the wires' joints
pk_head  = 0.3;                  // the board's parts to the cover over them

/* [Contacts to the bass, between the outer holders (local)] */
contact_y  = 84;                 // the pads' face (the outer holders' tips: 89.6)
contact_t  = 0.8;
contact_hw = 5.2;                // half width (x) and half height (z) of boss and board
contact_hh = 5.0;
contact_p  = 2.54;
contact_bore = 2.2;

/* [The bus wires from J1] */
bundle_d = 1.8;

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
}
// the pocket: its top at the board's top (W 0), where the cover lies; the board under it
pk_top   = gz + (0 - w_mid);
pk_z     = [pk_top - pk_head - board_t - ledge, pk_top];
blk_z    = [pk_z[0] - pk_floor, pk_top];
bd_x     = [pk_x[1] - 1.5 - board_w, pk_x[1] - 1.5];        // the board, at the pocket's +x end
bd_y     = [pk_y[0] + 1.5, pk_y[0] + 1.5 + board_d];
bd_z     = pk_z[0] + ledge;
link_y   = plate_y0 + inner_end_abs;   // the inner holders' backs: where the bass's mount begins
module link_board() gauge_tilt_frame() box(bd_x, bd_y, [bd_z, bd_z + board_t]);
// part of the cover: the plate over the pocket's block, cover_t thick, flush with the
// cover's top (W 0 .. cover_t), out to the block's back
module gauge_cover_tongue() gauge_tilt_frame() box([blk_x[0], gauge_x + pad_x[0]], [back_y - 1, blk_y1], [pk_top, pk_top + cover_t]);   // up to the pad, which stands higher

// the bus wires: from the plug's end in J1 straight into the pocket, to the board's -x end
function bundle_pts() = let(e = slab_local([hall_conn[0], hall_conn_front + 4.4, -hall_t - 1.6]))
    [e - [0, 1, 0], e + [0, 1.5, 0], [bd_x[0] - 1.2, bd_y[0] + 3, bd_z + 1.5], [bd_x[0] - 0.2, bd_y[0] + 3, bd_z + 1.5]];
module bundle() gauge_tilt_frame() {
    p = bundle_pts();
    for (i = [0 : len(p) - 2]) hull() {
        translate(p[i]) sphere(d = bundle_d, $fn = 12);
        translate(p[i + 1]) sphere(d = bundle_d, $fn = 12);
    }
}

// the contact board; pads as thin discs on its face
module contact_board() gauge_tilt_frame() {
    box([-contact_hw, contact_hw], [contact_y - contact_t, contact_y - 0.035], [gz - contact_hh, gz + contact_hh]);
    for (i = [-1 : 1], j = [-1 : 1]) translate([i * contact_p, contact_y - 0.035, gz + j * contact_p])
        rotate([-90, 0, 0]) cylinder(d = 1.8, h = 0.035, $fn = 20);
}
// part of the housing: the boss under the contact board, with the wires' bore
module gauge_contact_boss() gauge_tilt_frame() difference() {
    box([-contact_hw, contact_hw], [back_y + pad_t - 0.5, contact_y - contact_t], [gz - contact_hh, gz + contact_hh]);
    translate([0, back_y + pad_t - 1, gz]) rotate([-90, 0, 0]) cylinder(d = contact_bore, h = contact_y - back_y);
}
g_y = back_y + pad_t - strip_t;                 // the groove's front, behind the strips
// the contacts' wires (3.3 V, GND, SDA, SCL, INT; DET stays on the board): down the boss's
// bore, along the pad's groove into the pocket, to the link board's +x end
module contact_wires() gauge_tilt_frame() {
    p = [[0, contact_y - contact_t - 0.2, gz], [0, g_y - groove_d / 2, gz], [pk_x[1] - 0.6, g_y - groove_d / 2, gz],
         [bd_x[1] + 0.6, bd_y[0] + 3, bd_z + 1.5]];
    for (i = [0 : len(p) - 2]) hull() { translate(p[i]) sphere(d = 1.3, $fn = 12); translate(p[i + 1]) sphere(d = 1.3, $fn = 12); }
}

module gauge_link() { gauge(); link_board(); bundle(); contact_board(); contact_wires(); }
part = "link";   // "link": the gauges, boards and wires

// added to the housing: the gauge pad on the back face, and the pocket's block beside it
module gauge_housing_pads() gauge_tilt_frame() {
    box([gauge_x + pad_x[0], gauge_x + pad_x[1]], [back_y - 1, back_y + pad_t], [gz - half_h, gz + half_h]);
    box(blk_x, [back_y - 1, blk_y1], blk_z);
}

// cut from the housing: the pocket, the groove
module gauge_housing_cuts() gauge_tilt_frame() {
    difference() {
        box(pk_x, pk_y, [pk_z[0], pk_z[1] + 0.01]);
        // corner ledges under the board
        for (x = [bd_x[0], bd_x[1] - 3], y = [bd_y[0], bd_y[1] - 3]) box([x, x + 3], [y, y + 3], [pk_z[0] - 1, bd_z]);
    }
    // groove and strips along the pad's face, from the pocket to past the far gauge
    g_x = [pk_x[1] - 0.1, gauge_x + gauge_dx + strip_in];
    box(g_x, [g_y - groove_d, g_y + 0.01], [gz - groove_h, gz + groove_h]);
    // open to the pad's face between the strips: to the block, between and inside the plates
    for (o = [[g_x[0], -gauge_dx - strip_out], [-gauge_dx - strip_in, -gauge_dx + strip_in],
              [-gauge_dx + strip_out, gauge_dx - strip_out], [gauge_dx - strip_in, gauge_dx + strip_in]])
        box([o[0], o[1]], [g_y, back_y + pad_t + 1.2], [gz - groove_h, gz + groove_h]);
    // the contacts' wires: from the boss's bore through the pad into the groove
    translate([0, g_y - groove_d, gz]) rotate([-90, 0, 0]) cylinder(d = contact_bore, h = pad_t + 2);
}

echo(str("gauge frame on the tray's back face: pad face's middle at ", pivot_new, " (was [0, ", pivot_y, ", ", gz,
         "]), moved by ", gauge_shift, "; link board pocket x = ", pk_x, ", local y = ", pk_y));

if (part == "link") gauge_link();
