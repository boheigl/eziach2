// Cover for the four-board staircase: closed, one box per step
//
// One printed part that closes the staircase, so that each step looks like a
// box, and that carries the boards and guides the buttons.
//
// ASSEMBLY. Lay each board into the upside-down cover, where ribs locate it on
// all sides; push the buttons through cover and board from the cover side and
// fit washers, sleeve and screw from below; plug in the FFCs; set the unit onto
// the housing (housing.scad), feeding each FFC down through its slot; screw the
// cover through each board into the housing at four points on the row line
// (y = 0): one near each board end and two between them, with M2 self-tapping
// screws for plastics with countersunk heads, flush with the cover (16 in all). The springs press each board up against the cover
// through the upper washer; the middle screws keep the cover from bowing up
// under them (54 N in all at rest).
//
// Per step k, in its own frame:
//   top: a cover_t plate on the board's top face, over the whole board, its
//   tab and end_pad beyond both ends, with d8 openings for the d7.6 stems: a second guide
//   above the board hole. The caps land on it at the lower stop;
//   front wall: wall_t thick, full length, in front of the board, between its
//   own caps and the caps of the board below; down onto the top of the step
//   below (for the bottom step, down to the bottom);
//   end walls at both ends, end_pad beyond the board ends, from the top down to the
//   level of the step below (step 0: to the bottom);
//   ribs that locate the board, rib_gap from its edges, over the board's
//   thickness only, so they stay clear of the housing step under it: a front
//   rib along the -y edge, a back wall along the +y edge and round the tab,
//   and an end rib at the -x end as the x stop.
// Where a wall comes down onto a lower step, that step's whole box is cut away
// from it; the floor plane cuts everything.
//
// Dents: the caps of board k stand in front of step k+1, whose front wall would
// pass them at only cap_gap. Around every cap of board k, step k+1 is dented in
// with a vertical cylinder cap_clear wider than the cap, down to step k's top,
// and closed again by a wall_t ring wall round the dent, so that every point of
// step k+1 stays at least cap_clear from the cap at any travel.
//
// Coordinates: board 0's frame (origin at its middle hole, z up).
//
// make builds   openscad -o ../build/switch/cover.stl cover.scad

/* [Boards — as in pcb.scad / housing.scad, do not edit here] */
pcb_t    = 1.6;
cu_t     = 0.035;
n        = 13;
pitch    = 20;
margin   = 12.3;    // last hole centre to the +x end
margin_n = 5.3;     // row to the -y / +y edge
margin_p = 10.6;
x_start  = -145.691;
tab_x1   = -145.691;   // no tab at this connector angle: flush with the +y edge
tab_y    = 10.6;
x_scr_l  = -142;    // -x end screw (pcb.scad)
n_boards = 4;
step     = [10, 17, 4];
end_pad  = 1.2;     // board end to the end walls' inner face: room for the -x end rib
fit      = 0.3;     // housing clearance around the boards
seat_z   = -16.583; // bottom plane as in housing.scad
floor_min = 1.5;
rec_h    = 0;      // FFC recess depth, as in housing.scad
collar_d = 8.6;

/* [Buttons] */
cap_d    = 15;
stem_d   = 7.6;

/* [Cover] */
cover_t  = 1.2;
wall_t   = 1.2;
open_d   = 8;       // stem guide: 0.2 all round
cap_gap  = 0.4;     // front wall to the caps, both ways
cap_clear = 2;      // caps of the board below to the dented step above
rib_t    = 0.6;
rib_gap  = 0.1;     // ribs to the board edges
screw_d  = 2.2;     // M2 clearance
csk_d    = 4.0;     // countersink, 90 deg, for M2 countersunk heads (ISO 7046 /
                    //   DIN 965, d3.8): the heads sit flush with the cover top,
                    //   leaving (cover_t - (csk_d - screw_d) / 2) of plain bore
mid_c    = 50;      // middle screws, as in pcb.scad: board k's at x = -mid_c and
mid_y    = 0;           //   mid_c - 2 k step[0] (own frame); in the staircase two lines
                    //   that meet in +y beyond the last board

$fa = 4; $fs = 0.4;

span    = (n - 1) * pitch;
z_top   = pcb_t / 2 + cu_t;          // board top, own frame
z_bot   = -pcb_t / 2 - cu_t;         // board underside
slope   = step[2] / step[1];         // the housing's bottom plane, parallel to the steps
floor_c = -(seat_z - floor_min) + slope * collar_d / 2 + rec_h;
function x_end(k) = span / 2 - k * pitch + margin;   // +x end or saw cut of board k
function holes(k) = [for (i = [0 : n - 1 - k]) -span / 2 + i * pitch];
end_d    = 2.3;     // end screws through the board, end_d inside each board end
function screws(k) = [[x_scr_l, 0], [x_end(k) - end_d, 0],
                      [-mid_c, mid_y], [mid_c - 2 * k * step[0], mid_y]];
// the middle screw heads sit between two caps
assert(norm([pitch / 2, mid_y]) - cap_d / 2 - csk_d / 2 >= 0.5, "middle screw head too close to a cap");
assert((csk_d - screw_d) / 2 <= cover_t - 0.2, "countersink too deep for the cover plate");

y_in   = -cap_d / 2 - cap_gap;        // front wall, inner face: behind the own caps
y_out  = y_in - wall_t;               //             outer face
y_bin  = margin_p + rib_gap;          // back wall, inner face
y_bout = y_bin + rib_t;               //            outer face
y_tin  = tab_y + rib_gap;             // tab back wall
y_tout = y_tin + rib_t;
x_tin  = tab_x1 + rib_gap;            // tab side wall
x_tout = x_tin + rib_t;
x_rib  = x_start - rib_gap;           // -x end rib, inner face
assert(x_rib - rib_t >= x_start - end_pad + 0.3, "-x end rib runs into the end wall");

below_cap = y_out - (-step[1] + cap_d / 2);  // caps of the board below in front of the wall
assert(below_cap >= cap_gap - 1e-6, "caps of the board below hit the front wall");
assert(y_in <= -margin_n - rib_gap - rib_t, "front wall behind the front rib");
assert(y_bout <= step[1] - margin_n - fit - 0.1, "back wall runs into the next step's housing");
echo(str("front wall y = ", y_out, " .. ", y_in, " (caps ", cap_gap, " behind it, caps below ",
         below_cap, " in front); ribs at y = ", -margin_n - rib_gap, " / ", y_bin,
         ", x = ", x_rib, "; openings d", open_d, " for the d", stem_d, " stems"));

module at_board(k) translate(k * step) children();

// outline of step k's box (2D, own frame)
module outer2d(k) union() {
    translate([x_start - end_pad - wall_t, y_out])
        square([x_end(k) - x_start + 2 * (end_pad + wall_t), y_bout - y_out]);
    translate([x_start - end_pad - wall_t, 0])
        square([x_tout - x_start + end_pad + wall_t, y_tout]);
}
// what is open below the plate: everything inside the front, end and back walls
module inner2d(k) union() {
    translate([x_start - end_pad, y_in])
        square([x_end(k) - x_start + 2 * end_pad, y_bin - y_in]);
    translate([x_start - end_pad, 0])
        square([x_tin - x_start + end_pad, y_tin]);
}
// the board-locating walls (back, round the tab) reach only down to the board's
// underside: below it lies the housing step
// (grown past the outline: shrunk, it left a skin of the outer face down to the bottom)
module rib_band2d(k) difference() {
    offset(delta = 0.5) outer2d(k);
    inner2d(k);
    translate([-1000, y_out - 1]) square([2000, y_in - y_out + 1]);              // front wall
    translate([-1000, -500]) square([x_start - end_pad + 1000, 1000]);             // -x end wall
    translate([x_end(k) + end_pad, -500]) square([1000, 1000]);                    // +x end wall
}

module solid_step(j)
    at_board(j) translate([0, 0, -100]) linear_extrude(100 + z_top + cover_t) outer2d(j);

module shell(k)
    at_board(k) difference() {
        union() {
            difference() {
                translate([0, 0, -100]) linear_extrude(100 + z_top + cover_t)
                    difference() { outer2d(k); dents2d(k, dent_r); }
                translate([0, 0, -101]) linear_extrude(101 + z_top)
                    difference() { inner2d(k); dents2d(k, dent_r + wall_t); }
                translate([0, 0, -101]) linear_extrude(101 + z_bot) rib_band2d(k);
            }
            // front rib along the board's -y edge, over the board thickness
            translate([x_start, -margin_n - rib_gap - rib_t, z_bot])
                cube([x_end(k) - x_start, rib_t, z_top - z_bot + 0.01]);
            // end rib at the -x end: the x stop
            translate([x_rib - rib_t, -margin_n, z_bot])
                cube([rib_t, margin_p + margin_n, z_top - z_bot + 0.01]);
            translate([x_rib - rib_t, 0, z_bot]) cube([rib_t, tab_y, z_top - z_bot + 0.01]);
        }
        for (x = holes(k)) translate([x, 0, z_top - 1]) cylinder(d = open_d, h = cover_t + 2);
        for (q = screws(k)) translate([q[0], q[1], 0]) {
            translate([0, 0, z_top - 1]) cylinder(d = screw_d, h = cover_t + 2);
            translate([0, 0, z_top + cover_t - (csk_d - screw_d) / 2])          // 90 deg countersink,
                cylinder(d1 = screw_d, d2 = csk_d + 0.2, h = (csk_d - screw_d) / 2 + 0.1);   // through the top
        }
    }

// dents in step k (k >= 1) round the caps of board k-1, in step k's frame (2D):
// they reach down through the whole step; below step k-1's top that step's box
// is cut away from step k anyway
dent_r = cap_d / 2 + cap_clear;
module dents2d(k, r)
    if (k > 0) for (x = holes(k - 1)) translate([x - step[0], -step[1]])
        circle(r = r / cos(180 / 90), $fn = 90);   // polygon round the true circle
// the ring wall stays clear of board k's front rib and of its own caps
assert(-step[1] + dent_r + wall_t <= -margin_n - rib_gap - rib_t - 0.2, "dent wall runs into the front rib above");
assert(norm([step[0], step[1]]) - dent_r - wall_t - cap_d / 2 >= cap_gap, "dent wall too close to the caps above");
echo(str("dents: r", dent_r, " round the caps of the board below (", cap_clear, " clear), ring wall ", wall_t,
         "; ring to the front rib above ", -margin_n - rib_gap - rib_t - (-step[1] + dent_r + wall_t)));

// step k's walls end at the top of step k-1, also where no lower box lies
// under them (the end walls beyond the staircase): only step 0 reaches the bottom
module below_stair(k)
    translate([-200, -100, (k - 1) * step[2] + z_top + cover_t - 100]) cube([400, 300, 100]);

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
// the cover's wall round the tab, as tab_wall in housing.scad
tab_wall = rib_gap + rib_t;
// (0.05 onto step k's top, so the two share a face, not just an edge, and
// starting 0.02 inside step k's corner, which it would otherwise touch in a point)
module notch_wedge(k, s)
    let(n = notch(k, s), t = [n[0] + [s == 0 ? 0.02 : -0.02, -0.05], n[1], n[2] - [0, 0.05]])
    hull() polyhedron(points = [[t[0][0], t[0][1], step_top(k)], [t[1][0], t[1][1], step_top(k)],
                                [t[2][0], t[2][1], step_top(k)], [t[1][0], t[1][1], step_top(k + 1)],
                                [t[2][0], t[2][1], step_top(k + 1)]],
                      faces = [[0, 1, 2, 3, 4]]);

module below_floor()
    multmatrix([[1, 0, 0, 0], [0, 1, 0, 0], [0, slope, 1, -floor_c], [0, 0, 0, 1]])
        translate([-200, -100, -100]) cube([400, 300, 100]);

difference() {
    union() {
        for (k = [0 : n_boards - 1])
            difference() {
                shell(k);
                if (k > 0) for (j = [0 : k - 1]) solid_step(j);
                if (k > 0) below_stair(k);
            }
        for (k = [0 : n_boards - 2]) { notch_wedge(k, 0); notch_wedge(k, 1); }
    }
    below_floor();
}
