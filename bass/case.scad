// Bass case: a closed box, one print, open only at the back, which a back cover closes
// (part = "back_cover") [given: nicer and closed; the cover inside, on the side away from
// the hand, so the hand plate stays one piece, and stiffness first].
//
// SHAPE. On top the key deck, its full depth (y -12.5 .. 30.7). Below it the box is
// thin [given]: box_depth (11.2) from the hand's face to its back wall, so that under the
// deck, behind the box, a step opens where the gauges sit [given: integrated]. Its sides
// straight and flush with the deck's ends: deck and box are one rectangular block, 211 wide
// [given 2026-11-14: a rectangular footprint, replacing the sides that slanted in along the
// stored discant's ends]; the box reaches 14.1 below the hand plate (layout.scad). The front wall (3 mm) carries the hand: the
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
// DECK [given 2026-11-13: one Hall-sensor board, the cases as small as possible]: a
// thin tray round the flat board (../hall_pcb/bass/), as the discant's: a rim up to the
// board's top, a floor part_gap under the parts, a ledge along the board's edge and a
// boss at each screw hole under it, M2 pilots for the cover's screws. The keys
// (../switch_hall/) stand entirely above the board, in the cover (cover.scad). The bus
// connector J1 hangs in front of the front row, over the box: its plug comes from below
// and the wires drop straight into the box. The front wall ends at the board's top; the
// cover reaches over it to the hand's face, flush with the hand plate's top.
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
// WIDTH [given 2026-11-14: rectangular; stored, the discant's outer keys stay uncovered]:
// 211, deck and box alike, set by the strap's slots (layout.scad).
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

pilot_d  = 1.6;
ledge    = 0.8;                  // under the board's edge, inside the rim
boss_d   = 4.4;                  // under the board at its screw holes
floor_keep = 0.4;                // under the pilots
plug_h   = 6.5;                  // J1's plug below the board's underside, with its wires' bend [unverified]

wall     = 2;                    // sides and back
corner_r = 4;
recess   = 1;
recess_r = 6;
floor_b  = 2;                    // the box's bottom, closed [given: access by the back cover]
rib_t    = 1.6;                  // the front wall's ribs
rib_gap  = 0.2;                  //   short of the back cover
z_split  = z_bot + 12.5;         // the back cover from here up; below, the mount's strip stays
cov_screws = [[-45 + ex, -21], [ex, -21], [45 + ex, -21]];   // the back cover's screws: above the stored caps (z < -38)
pillar_d = 6;
bat       = [90, 6, 60];         // the battery: x, y, z
bat_gap   = 0.3;
cradle_t  = 2;

$fa = 3; $fs = 0.3;

// the tray (layout.scad: w_ft, z_floor), in the case's frame: the board's frame lifted to board_top
module on_board() translate([0, 0, board_top]) children();
module board_bodies(g) for (q = hall_parts) if (q[1] == "B")
    translate([q[2] - g, q[3] - g, board_bot - q[6] - g]) cube([q[4] - q[2] + 2 * g, q[5] - q[3] + 2 * g, q[6] + g + 0.01]);
module tray_supports() difference() {
    translate([0, 0, w_ft - 0.1]) linear_extrude(board_bot - w_ft + 0.1) {
        difference() { board2d(case_fit + 0.01); board2d(-ledge); }
        for (h = hall_holes) translate(h) circle(d = boss_d);
    }
    board_bodies(part_gap);
}
// over the stored discant's two sockets (link.scad, at x_mid -/+ 25) the floor is 1 thicker,
// up into the gap under the board where no part sits: the discant hangs from it, and a knock
// while it is carried loads it ten times its weight [given 2026-11-14: stiff enough]
module socket_pads() difference() {
    for (s = [-1, 1]) translate([x_mid + 25 * s - 7, 14, w_ft - 0.01]) cube([14, deck_y[1] - 14 - case_rim, 1.0]);
    board_bodies(part_gap);
}
// J1 and its plug, straight down through the tray's floor into the box
module plug_hole() let(j = [for (q = hall_parts) if (q[0] == "J1") q][0])
    translate([j[2] - part_gap, j[3] - part_gap, board_bot - plug_h]) cube([j[4] - j[2] + 2 * part_gap, j[5] - j[3] + 2 * part_gap, plug_h + 0.01]);

module rounded(xr, yr, d = 0) offset(r = corner_r - d) offset(delta = -corner_r)
    translate([xr[0], yr[0]]) square([xr[1] - xr[0], yr[1] - yr[0]]);
module box2d(xr, d = 0) rounded(xr, [plate_y[0], box_back], d);
// inside: side walls wall, back wall back_t, front wall to plate_y[1]
module cavity2d(xr) intersection() {
    box2d(xr, back_t);
    translate([xr[0] + wall, plate_y[1]]) square([xr[1] - xr[0] - 2 * wall, 100]);
}
// the box: straight from z0 to z1
module slanted(z0, z1) translate([0, 0, z0]) linear_extrude(z1 - z0) children(0);
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
rib_out = [for (s = [-1, 1]) (deck_x[0] + deck_x[1]) / 2 + s * 83];   // the outer upright ribs: inside the strap's slots
module rib_x(x, z0, z1) translate([x - rib_t / 2, rib_y[0], z0]) cube([rib_t, rib_y[1] - rib_y[0], z1 - z0]);
module rib_z(z, x0, x1) translate([x0, rib_y[0], z - rib_t / 2]) cube([x1 - x0, rib_y[1] - rib_y[0], rib_t]);
bat_x = [bat_xy[0] - bat_gap - cradle_t, bat_xy[0] + bat[0] + bat_gap + cradle_t];   // the cradle's ends
module ribs() intersection() {
    difference() {
        union() {
            for (x = [rib_out[0], bat_x[0] - 1.7, bat_x[1] + 1.7, rib_out[1]]) rib_x(x, z_bot, z_floor);
            rib_z(bat_z + bat[2] + bat_gap + cradle_t + 1.7, -200, 200);     // over the battery
            rib_z(-36, -56 + ex, 200);                                       // right of the wires' way down
            rib_z(-90 + ez, -200, bat_x[0]); rib_z(-110 + ez, -200, bat_x[0]);   // left of the battery
            rib_z(-88 + ez, bat_x[1], 200);                                  // over the power board
        }
        // the wires: along the bottom (from the contacts' bore to the power board and
        // left), and up left of the battery to the key board
        translate([-200, rib_y[0] - 1, z_bot]) cube([400, 20, floor_b + 3]);
        translate([-58 + ex, rib_y[0] - 1, z_bot]) cube([5, 20, 120]);
        // the boards and the key board's FFCs
        main_board_room();   // the main board (elec.scad)
        translate([-107 + ex, rib_y[0] - 1, -47]) cube([51, 20, 41 + 10]);
    }
    cavity3d();
}
// FOOT [given: statically stable under a strong push]: the push's moment reaches the
// gauges through the mount at the box's bottom; a thin floor (2) and back wall (1.6)
// would carry it in bending (about 100 MPa at 100 N, estimate). So behind the mount the
// box is solid from the battery's shelf down to 2.5 mm above the floor, joined to front
// wall and back wall: the moment goes into the walls as tension and compression (a few
// MPa). Under it the slot for the wires' bundles. In the mount's strip the ribs reach the
// back wall too.
foot_x = [bat_x[0] - 2.5, bat_x[1] + 2.5];
foot_z = [z_bot + floor_b + 2.65, bat_z - bat_gap];
module foot() {
    translate([foot_x[0], plate_y[1] - 0.01, foot_z[0]]) cube([foot_x[1] - foot_x[0], box_back - back_t - plate_y[1] + 0.02, foot_z[1] - foot_z[0]]);
    for (x = [rib_out[0], bat_x[0] - 1.7, bat_x[1] + 1.7, rib_out[1]])
        translate([x - rib_t / 2, rib_y[1] - 0.05, z_bot + floor_b + 3]) cube([rib_t, box_back - back_t - rib_y[1] + 0.06, z_split - 0.01 - (z_bot + floor_b + 3)]);
}
// STRAP [given: the heel of the hand presses about 11 cm below the bass keys; the strap
// at least 40 mm wide]: a strap across the back of the hand, level with its middle
// (strap_z; the heel at about z -105, the knuckles just below the deck). Each end goes
// through a pair of upright slots in the front wall beside the hand plate: in through the
// outer one, round the bar between them inside the box, out through the inner one,
// folded back and buckled. Flat on the front face: no twist (the slots stand upright, the
// strap's width too), nothing standing out, the package unchanged; threaded with the back
// cover off. The bar: the front wall between the slots and a block behind it, 5 x 6.5;
// a 100 N pull on each end puts 200 N round the bar: about 30 MPa [estimate].
strap_z  = -67;
strap_w  = 40;
slot_w   = 4;                    // for a strap up to 3 thick
slot_h   = strap_w + 2;
slot_in  = 87;                   // from the deck's middle: the inner slot's inner edge [given: further out, so the
                                 //   hand can slide far enough along the rows]; the outer slot ends at 100, 1.5 inside
                                 //   the front face's rounded edge where the box is narrowest (z -46)
bar_w    = 5;
function slot_x(s) = let(c = (deck_x[0] + deck_x[1]) / 2)
    [c + s * slot_in, c + s * (slot_in + slot_w), c + s * (slot_in + slot_w + bar_w), c + s * (slot_in + 2 * slot_w + bar_w)];
module strap_slots3d() for (s = [-1, 1]) let(x = slot_x(s)) for (p = [[x[0], x[1]], [x[2], x[3]]])
    translate([min(p), plate_y[0] - 1, strap_z - slot_h / 2]) rotate([90, 0, 0]) mirror([0, 0, 1])
        linear_extrude(plate_y[1] - plate_y[0] + 1.2) offset(r = slot_w / 2 - 0.01) offset(delta = -(slot_w / 2 - 0.01)) square([slot_w, slot_h]);
// the bar's block behind the front wall; the strap passes behind it
module strap_bars() for (s = [-1, 1]) let(x = slot_x(s))
    translate([min(x[1], x[2]), plate_y[1] - 0.01, strap_z - slot_h / 2 - 4]) cube([bar_w, 3.5, slot_h + 5.5]);   // 1.5 over the slots at the top: clear of the key board
// room inside for the strap: behind each slot the whole depth, behind the bar from its
// block back to the cover (through the ribs)
module strap_room() for (s = [-1, 1]) let(x = slot_x(s)) {
    for (p = [[x[0], x[1]], [x[2], x[3]]])
        translate([min(p), plate_y[1] - 0.02, strap_z - slot_h / 2 - 1]) cube([slot_w, box_back - back_t - plate_y[1] + 0.01, slot_h + 2]);
    translate([min(x[0], x[3]) - 0.5, plate_y[1] + 3.5 - 0.01, strap_z - slot_h / 2 - 1]) cube([abs(x[3] - x[0]) + 1, box_back - back_t - plate_y[1] - 3.5, slot_h + 2]);
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
cov_tongues = [[-80 + ex, -56 + ex], [52 + ex, 78 + ex]];   // between the ribs
// each tongue: behind the strip's inner face below z_split (0.05 clear of it), joined to
// the cover above it
module cover_tongues() for (x = cov_tongues) {
    translate([x[0], box_back - back_t - 1.25, z_split - 4]) cube([x[1] - x[0], 1.2, 6]);
    translate([x[0], box_back - back_t - 1.25, z_split + 0.05]) cube([x[1] - x[0], 1.25 + 0.5, 1.95]);
}

module body() {
    difference() {
        union() {
            difference() { intersection() { outer3d(); translate([-500, -500, z_bot]) cube([1000, 1000, z_floor - z_bot + 0.01]); } cavity3d(); }
            // the front wall up to the board's top: above it the cover carries it on to the
            // hand plate's top, so the case nowhere stands over the cover [given 2026-11-14]
            translate([deck_x[0], plate_y[0], z_floor]) cube([deck_x[1] - deck_x[0], plate_y[1] - plate_y[0], board_top - z_floor]);
            // the deck: the tray round the board, its rim up to the board's top
            translate([deck_x[0], deck_y[0] - 0.01, z_floor]) cube([deck_x[1] - deck_x[0], deck_y[1] - deck_y[0] + 0.01, board_top - z_floor]);
            cradle();
            ribs();
            pillars();
            foot();
            strap_bars();
            elec_pads();
        }
        // the board and its parts, less what carries the board
        difference() { translate([0, 0, w_ft]) linear_extrude(20) board2d(case_fit); tray_supports(); socket_pads(); }
        board_bodies(part_gap);
        plug_hole();
        for (h = hall_holes) translate([h[0], h[1], z_floor + floor_keep]) cylinder(d = pilot_d, h = board_bot - z_floor);
        // the stored discant's gauge ends: their pocket in the deck's underside (link.scad)
        store_pocket();
        // the contacts' wires into the box (link.scad), the charging port and its light,
        // and the boards' pilots (elec.scad)
        mount_cuts();
        elec_cuts();
        strap_slots3d();
        strap_room();
        // the hand plate: a shallow recess with rounded corners
        translate([0, plate_y[0] - 1, 0]) rotate([-90, 0, 0]) linear_extrude(recess + 1)
            offset(r = recess_r) offset(delta = -recess_r)
                translate([plate_x[0], -plate_z[1]]) square([plate_x[1] - plate_x[0], plate_z[1] - plate_z[0]]);
    }
}

echo(str("box below the deck: y ", plate_y[0], " .. ", box_back, ", x ", deck_x, " -> ", bottom_x, "; battery at ", bat_xy, ", z ", bat_z));

part = "case";                   // "case", "back_cover", "cover_screws", "strap" or "battery"
if (part == "case") {
    difference() { intersection() { body(); outer3d(); } cover_slab(); }
    mount();
    store_socket();
}
if (part == "battery") battery();
// the strap, for the page: 40 x 2, over the back of a hand (its back about 33 mm off the
// plate), each end in through the inner slot, round the bar, out through the outer slot
// and folded back towards the buckle
strap_c  = (deck_x[0] + deck_x[1]) / 2;
strap_yb = plate_y[0] - 33;
function strap_side(s) = let(xi = slot_in + slot_w / 2, xo = slot_in + 1.5 * slot_w + bar_w)
    [[strap_c + s * 40, strap_yb - 1], [strap_c + s * 75, strap_yb + 8],
     [strap_c + s * xi, plate_y[0] - 2.2], [strap_c + s * xi, box_back - back_t - 1.5],
     [strap_c + s * xo, box_back - back_t - 1.5], [strap_c + s * xo, plate_y[0] - 2.2],
     [strap_c + s * (xo - 5), plate_y[0] - 4.5], [strap_c + s * 70, strap_yb + 6]];
module strap_seg(a, b) hull() {
    translate([a[0] - 1, a[1] - 1, strap_z - strap_w / 2]) cube([2, 2, strap_w]);
    translate([b[0] - 1, b[1] - 1, strap_z - strap_w / 2]) cube([2, 2, strap_w]);
}
module strap() {
    for (s = [-1, 1]) let(p = strap_side(s)) for (i = [0 : len(p) - 2]) strap_seg(p[i], p[i + 1]);
    strap_seg([strap_c - 40, strap_yb - 1], [strap_c + 40, strap_yb - 1]);
}
if (part == "strap") strap();
if (part == "back_cover") difference() {
    union() { intersection() { body(); outer3d(); cover_slab(); } cover_tongues(); }
    for (p = cov_screws) translate([p[0], box_back - back_t - 1, p[1]]) rotate([-90, 0, 0]) {
        cylinder(d = 2.2, h = back_t + 2, $fn = 16);
        translate([0, 0, back_t + 1 - csk_h]) cylinder(d1 = 2.2, d2 = csk_d, h = csk_h + 0.01, $fn = 24);   // countersink
    }
}
// the back cover's screws: countersunk M2 x 6 (DIN 965, head d 3.8), flush with the back face
// (which faces the stored discant's keys), 4.4 into the pillars' 6 deep pilots
csk_d = 4.0; csk_h = (csk_d - 2.2) / 2;   // 90 deg countersink: 0.9 deep, 0.7 of the 1.6 left
module cover_screws() for (p = cov_screws) translate([p[0], box_back, p[1]]) rotate([90, 0, 0]) {
    cylinder(d1 = 3.8, d2 = 2.0, h = 0.9, $fn = 24);
    cylinder(d = 2.0, h = 6, $fn = 12);
}
if (part == "cover_screws") cover_screws();
