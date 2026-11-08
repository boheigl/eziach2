// Bass case: a closed box, one print, open only at the bottom, which a lid closes
// (lid.scad) [given: nicer and closed].
//
// SHAPE. On top the key deck, its full depth (y -12.5 .. 30.7). Below it the box is
// thin [given]: box_depth (11.2) from the hand's face to its back wall, so that under the
// deck, behind the box, a step opens where the gauges sit [given: integrated]. Its sides
// are straight and 265 apart (box_x) [given: replaces the earlier taper, so that the box
// covers the stored discant's keys], 3 longer at the bottom than the hand plate. The front wall (3 mm) carries the hand: the
// example's hand plate, half as wide and 25 % lower (131.5 x 128.3) [given], is a 1 mm
// recess in it with rounded corners. The vertical edges are rounded; the cover
// (cover.scad) follows them.
//
// STIFFNESS [given: the hand plate must not bend]: the closed box section itself, front
// wall 3, back wall 1.6, 11.2 deep: estimate 0.05 mm at 50 N at the plate's middle (the
// 16 mm box's 0.02, scaled by the walls' second moment, 2.65 x; PLA, E 3500 MPa assumed).
//
// DECK. The housing of the keys, the discant's for two rows, the back one 10 higher:
// each board rests on it 0.1 above its underside, every key has a guide (d9.4 for the
// washers, d8.6 spring pocket, floor 1.5 under it), M2 pilots take the cover's screws.
// Each board's FFC connector hangs in a pocket with a floor; a tunnel inside the deck
// leads its cable forward and down into the box, since both connectors stand partly
// over the step.
//
// BATTERY [given]. A 1S Li-ion pouch (606090: 6 x 60 x 90, about 4 Ah [unverified]; 6 mm
// thick [given: box 4.8 thinner], it was a 9 mm 906090)
// stands against the back wall: a shelf under it, stops at its ends, a lip over its top.
//
// GAUGES. On the back wall's outside at the bottom, in the step, the mount with both
// inner holders (link.scad) [given]. Under the deck the short socket the discant's plates
// go into when it is stored (link.scad), in a pocket in the deck's underside.
//
// WIDTH [given: discant keys covered when stored]: the box below the deck is 265 wide,
// straight, wider than the deck (211): beside the deck its top is a 2 mm wall.
//
// make builds   openscad -o ../build/bass/case.stl case.scad

include <layout.scad>
use <link.scad>

guide_d  = 9.4;
spring_d = 8.6;
seat_z   = -16.583;              // spring seat below the board centre (button.scad)
collar_h = 1.5;
floor_t  = 1.5;
pilot_d  = 1.6;
pilot_l  = 7;
con_c    = [-135.7, 2.47299];    // connector centre, board frame (pcb.scad)
con_w    = 21.0; con_d = 4.5; con_h = 5.5;
con_rot  = atan2(16, 10);
tunnel   = [18, 3.5];            // the FFC's tunnel: width, height (inside the deck)
tunnel_floor = 1.5;

wall     = 2;                    // sides and back
corner_r = 4;
recess   = 1;
recess_r = 6;
lid_t    = 2;
boss_d   = 7;  boss_h = 10;
bat       = [90, 6, 60];         // the battery: x, y, z
bat_gap   = 0.3;
cradle_t  = 2;

$fa = 3; $fs = 0.3;

z_floor = board_z[0] + seat_z - floor_t;          // the deck's underside
function top_of(k) = board_z[k] - pcb_t / 2 - cu_t - gap;

module rounded(xr, yr, d = 0) offset(r = corner_r - d) offset(delta = -corner_r)
    translate([xr[0], yr[0]]) square([xr[1] - xr[0], yr[1] - yr[0]]);
module box2d(xr, d = 0) rounded(xr, [plate_y[0], box_back], d);
// inside: side walls wall, back wall back_t, front wall to plate_y[1]
module cavity2d(xr) intersection() {
    box2d(xr, back_t);
    translate([xr[0] + wall, plate_y[1]]) square([xr[1] - xr[0] - 2 * wall, 100]);
}
module tapered(z0, z1) hull() {
    translate([0, 0, z0]) linear_extrude(0.01) children(1);
    translate([0, 0, z1 - 0.01]) linear_extrude(0.01) children(0);
}
// the outline: the thin box below the deck, as wide as box_x; the deck above, full depth
module outer3d() {
    tapered(z_bot - 1, z_floor + 0.01) { box2d(box_x); box2d(bottom_x); }
    translate([0, 0, z_floor]) linear_extrude(60) rounded(deck_x, [plate_y[0], deck_y[1]]);
}
// the box is wider than the deck: beside the deck its top is a wall, under the deck
// the cavity reaches up to the deck's underside
module cavity3d() intersection() {
    tapered(z_bot - 1, z_floor) { cavity2d(box_x); cavity2d(bottom_x); }
    union() {
        translate([-500, -500, z_bot - 2]) cube([1000, 1000, z_floor - wall - z_bot + 2]);
        translate([deck_x[0] + wall, -500, z_bot - 2]) cube([deck_x[1] - deck_x[0] - 2 * wall, 1000, 200]);
    }
}

bat_xy = [(plate_x[0] + plate_x[1]) / 2 - bat[0] / 2, box_back - back_t - bat_gap - bat[1]];
bat_z  = z_bot + lid_t + 6;
module battery() translate([bat_xy[0], bat_xy[1], bat_z]) cube(bat);
module cradle() {
    x0 = bat_xy[0] - bat_gap; x1 = bat_xy[0] + bat[0] + bat_gap;
    y0 = plate_y[1] - 0.01; y1 = box_back - back_t + 0.01;
    translate([x0 - cradle_t, y0, bat_z - bat_gap - cradle_t]) cube([x1 - x0 + 2 * cradle_t, y1 - y0, cradle_t]);   // shelf
    for (x = [x0 - cradle_t, x1]) translate([x, y0, bat_z - bat_gap - cradle_t]) cube([cradle_t, y1 - y0, 20]);       // end stops
    translate([x0 + 10, y0, bat_z + bat[2] + bat_gap]) cube([x1 - x0 - 20, y1 - y0, cradle_t]);                       // lip over the top
}
// two bosses for the lid's screws, one at each end of the narrow bottom
function boss_xy() = [[bottom_x[0] + wall + boss_d / 2 - 0.5, (plate_y[1] + box_back - back_t) / 2],
                      [bottom_x[1] - wall - boss_d / 2 + 0.5, (plate_y[1] + box_back - back_t) / 2]];
// as blocks from the front wall to the back wall: in the thin box they join both
module bosses() for (p = boss_xy()) difference() {
    translate([p[0] - boss_d / 2, plate_y[1] - 0.01, z_bot + lid_t]) cube([boss_d, box_back - back_t - plate_y[1] + 0.02, boss_h]);
    translate([p[0], p[1], z_bot + lid_t - 1]) cylinder(d = pilot_d, h = boss_h - 2 + 1);
}
// the board's connector, turned (board frame), grown by g
module con2d(g) translate(con_c) rotate(con_rot) translate([-con_d / 2 - g, -con_w / 2 - g]) square([con_d + 2 * g, con_w + 2 * g]);

module body() {
    difference() {
        union() {
            difference() { intersection() { outer3d(); translate([-500, -500, z_bot]) cube([1000, 1000, z_floor - z_bot + 0.01]); } cavity3d(); }
            // the front wall up to the front cover's top
            translate([deck_x[0], plate_y[0], z_floor]) cube([deck_x[1] - deck_x[0], plate_y[1] - plate_y[0], cover_top[0] - z_floor]);
            // the deck
            translate([deck_x[0], deck_y[0] - 0.01, z_floor]) cube([deck_x[1] - deck_x[0], step_y - deck_y[0] + 0.02, top_of(0) - z_floor]);
            translate([deck_x[0], step_y, z_floor]) cube([deck_x[1] - deck_x[0], deck_y[1] - step_y, top_of(1) - z_floor]);
            bosses();
            cradle();
        }
        for (k = [0, 1], i = [0 : n_row - 1]) translate([key_xy(k, i)[0], key_xy(k, i)[1], board_z[k]]) {
            translate([0, 0, seat_z + collar_h]) cylinder(d = guide_d, h = 40);
            translate([0, 0, seat_z]) cylinder(d = spring_d, h = 40);
        }
        for (k = [0, 1]) {
            zt = z_floor + tunnel_floor;
            // the connector's pocket, down to the tunnel's floor
            translate([board_dx[k], rows_y[k], zt]) linear_extrude(board_z[k] - zt) con2d(fit);
            // the tunnel: from under the connector forward, then down into the box
            // centred under the connector, but kept 2 mm inside the deck's side walls
            cy = rows_y[k] + con_c[1];
            cx = max(board_dx[k] + con_c[0], deck_x[0] + wall + 2 + tunnel[0] / 2 + (deck_x[0] - bottom_x[0]) * -0.05);
            translate([cx - tunnel[0] / 2, plate_y[1] + 1, zt]) cube([tunnel[0], cy + 12 - plate_y[1] - 1, tunnel[1]]);
            translate([cx - tunnel[0] / 2, plate_y[1] + 1, z_floor - 1]) cube([tunnel[0], box_back - back_t - plate_y[1] - 1.5, tunnel_floor + tunnel[1] + 1]);
            translate(at_board(k)) for (x = screws) translate([x, 0, -pcb_t / 2 - cu_t - gap - pilot_l]) cylinder(d = pilot_d, h = pilot_l + 1);
        }
        // the stored discant's gauge ends: their pocket in the deck's underside (link.scad)
        store_pocket();
        // the hand plate: a shallow recess with rounded corners
        translate([0, plate_y[0] - 1, 0]) rotate([-90, 0, 0]) linear_extrude(recess + 1)
            offset(r = recess_r) offset(delta = -recess_r)
                translate([plate_x[0], -plate_z[1]]) square([plate_x[1] - plate_x[0], plate_z[1] - plate_z[0]]);
    }
}

echo(str("box below the deck: y ", plate_y[0], " .. ", box_back, ", x ", deck_x, " -> ", bottom_x, "; battery at ", bat_xy, ", z ", bat_z));

part = "case";                   // "case" or "battery"
if (part == "case") {
    intersection() { body(); outer3d(); }
    mount();
    store_socket();
}
if (part == "battery") battery();
