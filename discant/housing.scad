// Housing for the four-board staircase
//
// One closed, 3D-printed body under the four boards of array.scad. Each board
// rests on its own step of the body, and every hole of every board (13 + 12 +
// 11 + 10 = 46) gets a cylindrical guide bored into it, the same as the single
// guide tube of button.scad: d9.4 for the washers, down to a d8.6 pocket that
// centres the spring and carries it.
//
// The bottom is one flat plane, parallel to the step edges: it rises with the
// staircase, 3 mm in z per 16 mm in y. Since every board sits 3 mm higher per
// 16 mm, the spring seats all lie on such a plane too. The roof of the FFC
// recess (see below) is the parallel plane that stays floor_min below the
// deepest point of every bore; the bottom lies rec_h below it.
//
// Shape of the body. Seen from above, under each board k it covers the part of
// the board that is not already over board k-1 (the lower one), and its top
// there is board k's underside (less a small gap). Where board k-1 reaches under
// board k, board k-1's step continues, so the body never rises between two
// boards and each board can be laid in from above. The connector of each board
// sits in a pocket at the board's -x end, turned so that its long side lies
// along the normal of the slanted -x face (see pcb.scad); its FFC leaves the
// vertical connector downwards into the hole behind that face. There is no
// outlet through the floor (cable routing still open).
//
// The connectors sit at the -x ends of the boards, where no higher board and
// no guide lies above them, so every guide is closed all round. The thinnest
// walls are about 0.7 mm, between each connector pocket and the guide of the
// board's hole 1. Between the guides of board k+1 and the cover's back wall on
// board k stay 1.2 mm of the body.
//
// HOLDING THE BOARDS. The boards, buttons and cover go onto the housing as one
// unit: each board is laid into the upside-down cover (cover.scad), which
// locates it with ribs on all sides; the buttons are pushed through cover and
// board from the cover side, and washers, sleeve and screw go on from below.
// The FFCs are plugged in, the unit is set onto the housing with each FFC
// hanging into the hole at the -x end, and the cover is screwed through each board into the
// housing at four points on the row line (y = 0): one near each board end and
// two between them, with M2 countersunk self-tapping screws. The springs then press each board up against the
// cover through the upper washer; the middle screws keep the cover from bowing
// up under that load. The housing steps sit 0.1 below the boards and carry them
// when a button is pressed.
//
// Coordinates as everywhere: board 0's frame, origin at its centre, z up.
//
// FFC RECESS. All four FFCs leave under the housing towards the back, flat,
// in one shallow recess in the bottom, open downwards. Each FFC runs straight
// down its slot, bends 90 deg (about y) to run +x lying flat in its own branch
// of the recess, under the guides, and at the common strip is folded flat once
// along a 45 deg crease, so that it turns to run +y. In the strip the four lie
// stacked and leave at the back face of board 3's step. Where the most layers
// meet (three passing FFCs and board 3's fold) there are five, about 1.5 mm
// plus the crease; the recess is rec_h deep. The fold turns each FFC face
// down: the far end needs the matching contact side.
// The FFCs are laid in from below once the unit is on the housing, and held
// there (tape or a bottom plate).
//
// MAIN PCB. main_pcb.scad: floor pockets, wall openings and locating pins for
// the board in the hole; main_pcb_cuts() and main_pcb_pads() below.
//
// GAUGE LINK. gauge_link.scad: on the back face the pad with the gauges' outer
// holders, in the back wall the link board's pocket and the bore for its wires.
//
// make builds   openscad -o ../build/discant/housing.stl housing.scad

use <main_pcb.scad>
use <gauge_link.scad>

/* [Boards — as in pcb.scad / array.scad, do not edit here] */
pcb_t   = 1.6;
cu_t    = 0.035;
n       = 13;
pitch   = 20;
margin  = 12.3;   // last hole centre to the +x end (end screw half a pitch past it + 2.3)
margin_n = 5.3;   // row of holes to the -y / +y edge (the row sits off centre: all
margin_p = 9.4;   //   tracks run behind the holes)
hole_d  = 8;
x_start = -145.796; // -x end, lengthened for the turned connector
tab_x1  = -142.038; // tab carrying a connector corner beyond the +y edge: x = x_start .. tab_x1;
tab_y   = 10.6;     //   out to this y
x_scr_l = -142;     // -x end screw, on the row line
n_boards = 4;
step    = [10, 16, 3];   // board k is moved by k * step

/* [Connector — GCT FFC3A20-14-G] */
con_w   = 21.0;
con_d   = 4.5;
con_h   = 5.5;
con_xc  = -135.7; // housing centre, x (at the -x end)
con_yc  = 2.47299; // and y
con_rot = atan2(step[1], step[0]);   // turned from y towards -x: long side along the
                  //   slanted face's normal
ffc_w   = 16;     // slot for the FFC through the floor, along x
ffc_t   = 2;      // and across

/* [Guides — as the guide tube of button.scad] */
guide_d   = 9.4;    // washers d9, 0.2 clearance
collar_d  = 8.6;    // spring pocket
seat_z    = -16.583;// spring seat below each board's centre plane (button.scad)
collar_h  = 1.5;    // depth of the spring pocket

/* [Body] */
gap       = 0.1;    // between the body and the boards' undersides
fit       = 0.3;    // clearance around the connectors and the boards
floor_min = 1.5;    // material between the deepest bore and the FFC recess

/* [FFC recess in the bottom, open downwards] */
rec_h     = 0;      // depth: up to five FFC layers (0.3) plus the crease would need 3;
                    //   0 for now: cable routing still open, no recess, the bottom
                    //   stays floor_min below the guides
rec_w     = 17;     // common strip along y: the FFC (15) folded onto it, 1 mm each side
rec_x0    = -99.6;  // its -x edge: just +x of board 3's tab, so it leaves through the
                    //   straight back face of board 3's step

/* [Holding the boards: cover] */
cover_t    = 1.2;   // cover plate thickness (cover.scad); the lips end flush with it
end_pad    = 1.2;   // board end to the inner face of the cover's end walls (cover.scad):
                    //   the body reaches out to them below the board level
tab_wall   = 0.1 + 0.6;   // cover's wall round each tab: rib_gap + rib_t (cover.scad)
wall_t     = 1.2;   // cover's front and end walls (cover.scad)
y_in       = -15 / 2 - 0.4;  // cover's front wall, inner face: -cap_d / 2 - cap_gap (cover.scad)
screw_pilot = 1.6;  // M2 countersunk self-tapping screws holding the cover
mid_c      = 50;    // middle screws through cover and board, as in pcb.scad: board k's
mid_y      = 0;     //   at x = -mid_c and mid_c - 2 k step[0] (own frame), on the row line
end_d      = 2.3;   // end screws through the board: end_d inside each board end
mid_depth  = 7;     // pilot below the board's underside

/* [Hole behind the slanted -x face] */
shell_t    = 1.2;   // outer wall left round the hole
hole_floor = 3;     // floor closing the hole, parallel to the bottom
tube_wall  = 1.0;   // round the hole-1 guides
boss_d     = 5;     // round the -x end screw pilots (pilot d1.6: 1.7 wall); the
                    //   connector pocket flattens it on its +x side
rib_w      = 2.2;   // ribs from each boss, over the boss's height (not 2: the -x rib's
                    //   edge would lie exactly on the tab edge of the board below)

$fa = 4; $fs = 0.4;

span   = (n - 1) * pitch;
z_bot  = -pcb_t / 2 - cu_t;                       // underside of a board, own frame
function x_end(k) = span / 2 - k * pitch + margin;   // +x end or saw cut of board k
function board_z(k) = k * step[2];
slope  = step[2] / step[1];                       // the bottom rises with the staircase
// recess roof: z = slope * y - floor_c, as high as possible while staying
// floor_min below every spring pocket (worst at the pocket's +y edge); the
// bottom is rec_h below it
floor_c = -(seat_z - floor_min) + slope * collar_d / 2;
function floor_at(y) = slope * y - floor_c - rec_h;
back_y  = (n_boards - 1) * step[1] + margin_p + fit;    // back face of board 3's step
// each branch runs from the board's slot to the far side of the strip
function slot_x(k) = con_xc + k * step[0] - ffc_t / 2;
function slot_y(k) = con_yc + k * step[1] - ffc_w / 2;
// (the recess layout predates the turned connector; checked only when it is cut)
if (rec_h > 0) {
    assert(slot_x(n_boards - 1) + ffc_t < rec_x0, "last slot reaches into the strip");
    assert(rec_x0 >= tab_x1 + (n_boards - 1) * step[0] + fit, "strip runs out through board 3's tab face");
    assert(slot_y(0) >= -margin_n - fit + 1.5, "board 0's branch too close to the front face");
}

echo(str("bottom: z = ", slope, " * y - ", floor_c + rec_h, " (", atan(slope), " deg), at the front y = ",
         -margin_n, ": z = ", floor_at(-margin_n), ", at the back y = ", back_y, ": z = ", floor_at(back_y),
         "; FFC recess ", rec_h, " deep, strip x = ",
         rec_x0, " .. ", rec_x0 + rec_w, ", y = ", slot_y(0), " .. back face ", back_y));
echo(str(n * n_boards - (n_boards - 1) * n_boards / 2, " guides d", guide_d, ", spring pocket d",
         collar_d, " x ", collar_h));

// footprint of board k in its own frame (from the -x end to the cut at +x,
// plus the connector tab)
module footprint(k, grow = 0)
    offset(delta = grow) union() {
        translate([x_start, -margin_n]) square([x_end(k) - x_start, margin_n + margin_p]);
        translate([x_start, 0]) square([tab_x1 - x_start, tab_y]);
    }

module at_board(k) translate(k * step) children();

// the column of material under board k: its footprint, less what board k-1
// (lower) already covers, from far below up to board k's underside
module column(k)
    difference() {
        // grown by fit, so that it meets the next column, which starts fit
        // beyond this board's edge
        at_board(k) translate([0, 0, -60]) linear_extrude(60 + z_bot - gap) footprint(k, fit);
        if (k > 0) board_below(k);
    }

// what board k's body must leave free of board k-1 below it: that board, the
// cover's wall round its tab, which board k's -x end overhangs, and the cover's
// back wall (it reaches down to the board's underside only, so the body stays
// whole below it)
module board_below(k)
    at_board(k - 1) {
        translate([0, 0, -100]) {
            linear_extrude(200) footprint(k - 1, fit);
            translate([x_start - 1, 0, 0]) cube([tab_x1 + tab_wall + fit - x_start + 1, tab_y + tab_wall + fit, 200]);
        }
        translate([0, 0, z_bot - gap]) linear_extrude(100) cover_outer2d(k - 1);
    }

// a slab parallel to the bottom plane, from z0 to z0 + h above it
module bottom_slab(z0, h)
    multmatrix([[1, 0, 0, 0], [0, 1, 0, 0], [0, slope, 1, -floor_c - rec_h], [0, 0, 0, 1]])
        translate([-200, -100, z0]) cube([400, 300, h]);
// everything below the bottom plane
module below_floor() bottom_slab(-100, 100);

// the FFC recess: a branch from each slot in +x, and the common strip in +y,
// rec_h deep above the bottom plane
module ffc_recess() intersection() {
    translate([0, 0, -100]) linear_extrude(200) {
        for (k = [0 : n_boards - 1])
            translate([slot_x(k), slot_y(k)]) square([rec_x0 + rec_w - slot_x(k), ffc_w]);
        translate([rec_x0, slot_y(0)]) square([rec_w, back_y + 1 - slot_y(0)]);
    }
    bottom_slab(-1, rec_h + 1);
}

module holes_of(k)
    for (i = [0 : n - 1 - k]) translate([-span / 2 + i * pitch, 0]) children();

module guides(k)
    at_board(k) holes_of(k) {
        translate([0, 0, seat_z + collar_h]) cylinder(d = guide_d, h = 30);
        translate([0, 0, seat_z]) cylinder(d = collar_d, h = 30);
    }

module connector_pocket(k)
    at_board(k) translate([con_xc, con_yc]) rotate(con_rot) {
        // connector housing, turned: its long side along the slanted face's normal
        translate([-con_d / 2 - fit, -con_w / 2 - fit, z_bot - con_h - fit])
            cube([con_d + 2 * fit, con_w + 2 * fit, con_h + fit + 1]);
        // (no FFC outlet through the floor: cable routing still open)
    }

z_topcu = pcb_t / 2 + cu_t;                 // top of a board, own frame

// beyond both ends of each board, below the board level, the body reaches out
// to the cover's end walls (and under the cover's -x end rib, the x stop)
module end_pads(k)
    difference() {
        at_board(k) {
            translate([x_start - end_pad, -margin_n - fit, -60])
                cube([end_pad - fit + 0.01, tab_y + margin_n + fit, 60 + z_bot - gap]);
            translate([x_end(k) + fit - 0.01, -margin_n - fit, -60])   // overlaps the column
                cube([end_pad - fit + 0.01, margin_n + margin_p + 2 * fit, 60 + z_bot - gap]);
        }
        // the board below (and its tab) runs under these blocks
        if (k > 0) board_below(k);
    }

// between neighbouring boards (1.3 mm apart), below the board level, the steps
// are joined so that the housing stays one piece
module bridge(k)
    at_board(k) translate([x_start + step[0], margin_p, -60])
        cube([x_end(k + 1) + step[0] - x_start - step[0], step[1] - margin_n - margin_p,
              60 + z_bot - gap]);

// FILLING UNDER THE COVER. The walls of cover step k >= 1 end at the top of
// step k-1, and its back wall and the wall round its tab only cover the
// board's thickness. Below them, out to the cover's outline, the housing is
// filled: under the end walls up to their lower edge, elsewhere up to the
// steps (z_bot - gap). Step 0's front and end walls reach the bottom; there
// only the rest is filled. What lies over a lower step stays that step's.
function cover_back(k) = k == n_boards - 1 ? tab_y + tab_wall : margin_p + tab_wall;   // y_back() of cover.scad
module cover_outer2d(k) union() {   // outer2d() of cover.scad
    if (k < n_boards - 1) translate(-k * [step[0], step[1]]) tab_gap2d(k);
    translate([x_start - end_pad - wall_t, y_in - wall_t])
        square([x_end(k) - x_start + 2 * (end_pad + wall_t), cover_back(k) - y_in + wall_t]);
    translate([x_start - end_pad - wall_t, 0])
        square([tab_x1 + tab_wall - x_start + end_pad + wall_t, tab_y + tab_wall]);
}
module end_strips2d(k) {
    translate([-500, -500]) square([500 + x_start - end_pad, 1000]);
    translate([x_end(k) + end_pad, -500]) square([1000, 1000]);
}
module cover_fill(k)
    difference() {
        at_board(k) translate([0, 0, -60]) {
            linear_extrude(60 + z_bot - gap) difference() {
                cover_outer2d(k);
                end_strips2d(k);
                if (k == 0) translate([-500, -500]) square([1000, 500 + y_in]);
            }
            if (k > 0) linear_extrude(60 + pcb_t / 2 + cu_t + cover_t - step[2])
                intersection() { cover_outer2d(k); end_strips2d(k); }
        }
        for (j = [0 : 1 : k - 1]) at_board(j) translate([0, 0, -100]) linear_extrude(200) cover_outer2d(j);
    }

// CHAMFERED STAIRCASE. Seen from above, the steps' outer corners at both ends
// lie on a straight line (step[0] in x per step[1] in y), so each notch between
// step k and step k+1 is closed by one slanted face from corner k to corner
// k+1; its top edge rises from step k's top to step k+1's. The notch is the
// triangle corner k, corner k+1 and the inner corner, where step k+1's end
// wall meets step k's tab (at -x) or back (at +x). The housing fills it up to
// step k's top, the cover's wedge from there up to the slanted top.
function step_top(k) = pcb_t / 2 + cu_t + cover_t + k * step[2];
// the notch triangle between steps k and k+1 at the -x (s = 0) or +x (s = 1) end
function notch(k, s) =
    let(c0 = s == 0 ? [x_start - end_pad - wall_t, tab_y + tab_wall]
                    : [x_end(k) + end_pad + wall_t, margin_p + tab_wall],
        a = [c0[0] + k * step[0], c0[1] + k * step[1]],
        b = [a[0] + (s == 0 ? 1 : -1) * step[0], a[1] + step[1]])
    [a, b, [b[0], a[1]]];
// between step k's tab and the -x end of step k+1 the cover's back wall stands in
// from the tab: the cover closes that gap down to the board's underside, and the
// housing is filled up to there
function tab_gap(k) = let(x0 = tab_x1 + tab_wall, x1 = x_start + step[0] - end_pad - wall_t)
    x1 > x0 && tab_y > margin_p ? [[x0 + k * step[0], margin_p + tab_wall + k * step[1]],
               [x1 + k * step[0], tab_y + tab_wall + k * step[1]]] : undef;
module tab_gap2d(k) let(g = tab_gap(k)) if (g != undef) translate(g[0]) square(g[1] - g[0]);
module tab_gap_fill(k)   // (0.01 into its neighbours, so that it merges with them)
    translate([0, 0, -60]) linear_extrude(k * step[2] + z_bot - gap + 60) offset(delta = 0.01) tab_gap2d(k);

module notch_fill(k, s)
    translate([0, 0, -60]) linear_extrude(step_top(k) + 60) polygon(notch(k, s));

// HOLE BEHIND THE SLANTED -X FACE. Behind the slanted face at the -x end the
// body is open to the top above a hole_floor floor (parallel to the bottom), in
// a band parallel to the face: from
// shell_t inside the outer faces to the line through the hole-1 guides (also
// parallel to it). The connectors and FFCs hang in it. What stays: the outer
// walls, a tube_wall tube with its spring floor round each hole-1 guide, and a
// boss round each -x end screw pilot, from 1 mm below the pilot up, tied to the
// slanted wall and its surroundings by ribs (boss_ribs()). These are cut from the body as it was, so they keep
// all its clearances to boards, connectors and cover.
face_c = [x_start - end_pad - wall_t, tab_y + tab_wall];       // corner of step 0
face_n = [step[1], -step[0]] / norm([step[0], step[1]]);       // into the body
function face_dist(p) = (p - face_c) * face_n;
face_depth = face_dist([-span / 2, 0]);                        // to the hole-1 guides
module outline2d() union() {                                   // the body's outline
    for (k = [0 : n_boards - 1]) at_board(k) cover_outer2d(k);
    for (k = [0 : n_boards - 2]) { polygon(notch(k, 0)); tab_gap2d(k); }
}
module face_hole2d()
    intersection() {
        offset(delta = -shell_t) outline2d();
        translate([x_start - end_pad + shell_t, y_in + shell_t]) square(500);   // step 0's end and front
        translate(face_c) rotate(atan2(face_n[1], face_n[0])) translate([-1, -500]) square([face_depth + 1, 1000]);
    }
module face_keep()
    for (k = [0 : n_boards - 1]) at_board(k) {
        translate([-span / 2, 0, seat_z - floor_min]) cylinder(r = guide_d / 2 + tube_wall, h = 100);
        q = cover_screws(k)[0];
        translate([0, 0, z_bot - mid_depth - 1]) linear_extrude(100) {
            translate(q) circle(d = boss_d);
            for (e = boss_ribs(k, q)) rib2d(e[0], e[1]);
        }
    }
// the ribs from board k's boss at q (own frame), each to beyond the wall it
// meets (only what lies in the hole counts): at right angles to the slanted
// wall (parallel to the connector, beside its pocket), in -x to it, and to the
// front wall in -y (board 0) or straight to the hole-1 tube of the board below
// (boards 1-3, past both connectors)
function boss_ribs(k, q) = concat(
    [[q, q - 40 * face_n], [q, q - [40, 0]]],
    k == 0 ? [[q, q - [0, 40]]] : [[q, [-span / 2 - step[0], -step[1]]]]);
module rib2d(a, b) hull() { translate(a) circle(d = rib_w); translate(b) circle(d = rib_w); }
module face_hole() difference() {
    intersection() {
        translate([0, 0, -60]) linear_extrude(140) face_hole2d();
        bottom_slab(hole_floor, 200);
    }
    face_keep();
}
echo(str("hole behind the -x face: ", face_depth, " mm deep from the face to the hole-1 guides"));

function cover_screws(k) = [[x_scr_l, 0], [x_end(k) - end_d, 0]];   // through the board
function mid_screws(k) = [[-mid_c, mid_y], [mid_c - 2 * k * step[0], mid_y]];

module screw_pilots(k) {
    at_board(k) for (q = cover_screws(k))
        translate([q[0], q[1], z_bot - mid_depth]) cylinder(d = screw_pilot, h = mid_depth + 1);
    at_board(k) for (q = mid_screws(k))
        translate([q[0], q[1], z_bot - mid_depth]) cylinder(d = screw_pilot, h = mid_depth + 1);
}

union() {
    difference() {
        union() {
            for (k = [0 : n_boards - 1]) { column(k); end_pads(k); cover_fill(k); }
            for (k = [0 : n_boards - 2]) { bridge(k); notch_fill(k, 0); notch_fill(k, 1); tab_gap_fill(k); }
            gauge_housing_pads();
        }
        below_floor();
        face_hole();
        for (k = [0 : n_boards - 1]) { guides(k); connector_pocket(k); screw_pilots(k); }
        if (rec_h > 0) ffc_recess();
        main_pcb_cuts();
        gauge_housing_cuts();
    }
    main_pcb_pads();
    gauge_holders();
}
