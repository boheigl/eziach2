// Bass case: a closed box, one print, open only at the back, which a back cover closes
// (part = "back_cover") [given: nicer and closed; the cover inside, on the side away from
// the hand, so the hand plate stays one piece, and stiffness first].
//
// SHAPE. On top the key deck, its full depth (y -12.5 .. 30.7). Below it the box is
// thin [given]: box_depth (11.2) from the hand's face to its back wall, so that under the
// deck, behind the box, a step opens where the gauges sit [given: integrated]. Its sides
// are 265 apart (box_x) at the bottom and slant in above, parallel to the stored discant's
// ends [given] (layout.scad: box_x_at()) [given: replaces the earlier taper, so that the box
// covers the stored discant's keys], 3 longer at the bottom than the hand plate. The front wall (3 mm) carries the hand: the
// example's hand plate, half as wide and 25 % lower (131.5 x 128.3) [given], is a 1 mm
// recess in it with rounded corners. The vertical edges are rounded; the cover
// (cover.scad) follows them.
//
// STIFFNESS [given: the hand plate must not bend; very important]: the hand bends the
// front wall locally, between its edges, since the cavity is empty; the box section does
// not help there (an earlier estimate of 0.05 mm missed that: a plain 3 mm wall between
// clamped edges gives about 0.5 mm at 50 N mid-plate). So the front wall carries ribs
// inside (ribs()), across the cavity, round battery and boards: the largest field left is
// over the battery, 91 x 62 between ribs, about 0.15 mm at 50 N there [estimate: clamped
// plate, PLA, E 3500 MPa, point load; a palm spreads it]. Three pillars join front wall and
// back cover at the cover's screws.
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
// stands on a shelf, stops at its ends, a lip over its top, all on the front wall; the
// back cover keeps it in.
//
// GAUGES. On the back wall's outside at the bottom, in the step, the mount with both
// inner holders (link.scad) [given]. Under the deck the short socket the discant's plates
// go into when it is stored (link.scad), in a pocket in the deck's underside.
//
// WIDTH [given: discant keys covered when stored]: the box below the deck is 265 wide at
// the bottom, its sides slanting in above (layout.scad).
//
// ASSEMBLY: back cover off (three screws, then lift it out of the tongues' slot): the
// battery, both boards (screwed from the back into the front wall's pilots; the power
// board goes in 2 mm to the left and slides right into the port), the FFCs from the deck
// and the contacts' wires are all in reach. The bottom is closed.
//
// make builds   openscad -o ../build/bass/case.stl case.scad

include <layout.scad>
use <link.scad>
use <elec.scad>

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
tun_x    = -94.3;                // the tunnel's middle: 0.6 clear of the deck's end wall and of the front keys' guides

wall     = 2;                    // sides and back
corner_r = 4;
recess   = 1;
recess_r = 6;
floor_b  = 2;                    // the box's bottom, closed [given: access by the back cover]
rib_t    = 1.6;                  // the front wall's ribs
rib_gap  = 0.2;                  //   short of the back cover
z_split  = z_bot + 12.5;         // the back cover from here up; below, the mount's strip stays
cov_screws = [[-45, -21], [0, -21], [45, -21]];   // the back cover's screws: above the stored caps (z < -38)
pillar_d = 6;
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
// the box: straight to box_slant_z, then slanting in (layout.scad: box_x_at())
module slanted(z0, z1) hull() {
    translate([0, 0, z0]) linear_extrude(0.01) children(0);
    translate([0, 0, box_slant_z]) linear_extrude(0.01) children(0);
    translate([0, 0, box_top_z]) linear_extrude(0.01) children(1);
    translate([0, 0, z1 - 0.01]) linear_extrude(0.01) children(1);
}
module tapered(z0, z1) hull() {
    translate([0, 0, z0]) linear_extrude(0.01) children(1);
    translate([0, 0, z1 - 0.01]) linear_extrude(0.01) children(0);
}
// the outline: the thin box below the deck, as wide as box_x; the deck above, full depth
module outer3d() {
    slanted(z_bot - 1, z_floor + 0.01) { box2d(box_x); box2d(box_x_at(z_floor + 0.01)); }
    translate([0, 0, z_floor]) linear_extrude(60) rounded(deck_x, [plate_y[0], deck_y[1]]);
}
// the box is wider than the deck: beside the deck its top is a wall, under the deck
// the cavity reaches up to the deck's underside
module cavity3d() intersection() {
    slanted(z_bot + floor_b, z_floor) { cavity2d(box_x); cavity2d(box_x_at(z_floor)); }
    union() {
        translate([-500, -500, z_bot - 2]) cube([1000, 1000, z_floor - wall - z_bot + 2]);
        translate([deck_x[0] + wall, -500, z_bot - 2]) cube([deck_x[1] - deck_x[0] - 2 * wall, 1000, 200]);
    }
}

bat_xy = [(plate_x[0] + plate_x[1]) / 2 - bat[0] / 2, box_back - back_t - bat_gap - bat[1]];
bat_z  = z_bot + floor_b + 6;
module battery() translate([bat_xy[0], bat_xy[1], bat_z]) cube(bat);
module cradle() {
    x0 = bat_xy[0] - bat_gap; x1 = bat_xy[0] + bat[0] + bat_gap;
    y0 = plate_y[1] - 0.01; y1 = box_back - back_t - rib_gap;   // short of the back cover
    translate([x0 - cradle_t, y0, bat_z - bat_gap - cradle_t]) cube([x1 - x0 + 2 * cradle_t, y1 - y0, cradle_t]);   // shelf
    for (x = [x0 - cradle_t, x1]) translate([x, y0, bat_z - bat_gap - cradle_t]) cube([cradle_t, y1 - y0, 20]);       // end stops
    translate([x0 + 10, y0, bat_z + bat[2] + bat_gap]) cube([x1 - x0 - 20, y1 - y0, cradle_t]);                       // lip over the top
}
// RIBS [given: stiffness very important]: on the front wall's inside, 1.6 thick, across
// the cavity to 0.2 short of the back cover, round the battery and clear of the boards
// and the wires' way (notches): they make the hand plate a ribbed plate.
rib_y = [plate_y[1] - 0.01, box_back - back_t - rib_gap];
module rib_x(x, z0, z1) translate([x - rib_t / 2, rib_y[0], z0]) cube([rib_t, rib_y[1] - rib_y[0], z1 - z0]);
module rib_z(z, x0, x1) translate([x0, rib_y[0], z - rib_t / 2]) cube([x1 - x0, rib_y[1] - rib_y[0], rib_t]);
bat_x = [bat_xy[0] - bat_gap - cradle_t, bat_xy[0] + bat[0] + bat_gap + cradle_t];   // the cradle's ends
module ribs() intersection() {
    difference() {
        union() {
            for (x = [-90, bat_x[0] - 1.7, bat_x[1] + 1.7, 90]) rib_x(x, z_bot, z_floor);
            rib_z(bat_z + bat[2] + bat_gap + cradle_t + 1.7, -200, 200);     // over the battery
            rib_z(-36, -56, 200);                                            // beside the key board
            rib_z(-90, -200, bat_x[0]); rib_z(-110, -200, bat_x[0]);          // left of the battery
            rib_z(-88, bat_x[1], 200);                                       // over the power board
        }
        // the wires: along the bottom (from the contacts' bore to the power board and
        // left), and up left of the battery to the key board
        translate([-200, rib_y[0] - 1, z_bot]) cube([400, 20, floor_b + 3]);
        translate([-58, rib_y[0] - 1, z_bot]) cube([5, 20, 120]);
        // the boards and the key board's FFCs
        translate([96, rib_y[0] - 1, -117]) cube([40, 20, 25]);
        translate([-107, rib_y[0] - 1, -47]) cube([51, 20, 41]);
    }
    cavity3d();
}
// pillars for the back cover's screws, from the front wall across the cavity
module pillars() for (p = cov_screws) difference() {
    translate([p[0], plate_y[1] - 0.01, p[1]]) rotate([-90, 0, 0]) cylinder(d = pillar_d, h = box_back - back_t - plate_y[1] + 0.01);
    translate([p[0], box_back - back_t - 6, p[1]]) rotate([-90, 0, 0]) cylinder(d = pilot_d, h = 7);
}
// BACK COVER [given: inside, on the side away from the hand]: the back wall from z_split
// up to the deck, with the side walls' last back_t, as one plate; its bottom edge hooks
// in behind the mount's strip with two tongues, three screws hold its top; it rests on
// the side walls' ends, ribs and pillars, so the hand's push never loads it.
module cover_slab() translate([-300, box_back - back_t, z_split]) cube([600, back_t + 0.001, z_floor - z_split]);
cov_tongues = [[-85, -60], [55, 85]];
// each tongue: behind the strip's inner face below z_split (0.05 clear of it), joined to
// the cover above it
module cover_tongues() for (x = cov_tongues) {
    translate([x[0], box_back - back_t - 1.25, z_split - 4]) cube([x[1] - x[0], 1.2, 6]);
    translate([x[0], box_back - back_t - 1.25, z_split + 0.05]) cube([x[1] - x[0], 1.25 + 0.5, 1.95]);
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
            cradle();
            ribs();
            pillars();
            elec_pads();
        }
        for (k = [0, 1], i = [0 : n_row - 1]) translate([key_xy(k, i)[0], key_xy(k, i)[1], board_z[k]]) {
            translate([0, 0, seat_z + collar_h]) cylinder(d = guide_d, h = 40);
            translate([0, 0, seat_z]) cylinder(d = spring_d, h = 40);
        }
        for (k = [0, 1]) {
            zt = z_floor + tunnel_floor;
            // the connector's pocket, down to the tunnel's floor
            translate([board_dx[k], rows_y[k], zt]) linear_extrude(board_z[k] - zt) con2d(fit);
            // the tunnel: from under the connector forward, then down into the box. One
            // tunnel for both FFCs (15 wide, stacked), left of the front keys' guides
            // (x -84.7): from under board 1's connector it leads to it
            cy = rows_y[k] + con_c[1];
            translate([tun_x - tunnel[0] / 2, plate_y[1] + 1, zt]) cube([tunnel[0], cy + 6 - plate_y[1] - 1, tunnel[1]]);
            translate([tun_x - tunnel[0] / 2, plate_y[1] + 1, z_floor - 1]) cube([tunnel[0], box_back - back_t - plate_y[1] - 1.5, tunnel_floor + tunnel[1] + 1]);
            translate(at_board(k)) for (x = screws) translate([x, 0, -pcb_t / 2 - cu_t - gap - pilot_l]) cylinder(d = pilot_d, h = pilot_l + 1);
        }
        // the stored discant's gauge ends: their pocket in the deck's underside (link.scad)
        store_pocket();
        // the contacts' wires into the box (link.scad), the charging port and its light,
        // and the boards' pilots (elec.scad)
        mount_cuts();
        elec_cuts();
        ffc_channels();
        // the hand plate: a shallow recess with rounded corners
        translate([0, plate_y[0] - 1, 0]) rotate([-90, 0, 0]) linear_extrude(recess + 1)
            offset(r = recess_r) offset(delta = -recess_r)
                translate([plate_x[0], -plate_z[1]]) square([plate_x[1] - plate_x[0], plate_z[1] - plate_z[0]]);
    }
}

echo(str("box below the deck: y ", plate_y[0], " .. ", box_back, ", x ", deck_x, " -> ", bottom_x, "; battery at ", bat_xy, ", z ", bat_z));

part = "case";                   // "case", "back_cover" or "battery"
if (part == "case") {
    difference() { intersection() { body(); outer3d(); } cover_slab(); }
    mount();
    store_socket();
}
if (part == "battery") battery();
if (part == "back_cover") difference() {
    union() { intersection() { body(); outer3d(); cover_slab(); } cover_tongues(); }
    for (p = cov_screws) translate([p[0], box_back - back_t - 1, p[1]]) rotate([-90, 0, 0]) cylinder(d = 2.2, h = back_t + 2);
}
