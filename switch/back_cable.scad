// The boards' FFCs to the outlet in the back of the housing
//
// The simplest route: each cable leaves its board's connector straight down,
// is bent once about its width towards its normal, and runs straight from
// there through an outlet in the housing's back face. No further bending.
//
// All four connectors lie in one vertical plane, each the one before moved by
// a staircase step (10, 17, 4), which runs exactly along the straight parts.
// So the four cables lie on one another: board 0's lowest, each next one
// stack_pitch higher (measured square to the cables), the same bend for all;
// only the straight lead below each connector differs, the top cable (board
// 3's) keeping lead. Each cable comes down onto the ones below it from above
// (a bend stays above its own straight part), so none crosses another.
//
// The connector stands square to the housing's slanted -x face (pcb.scad):
// its long side, so the cable's width, lies along that face's normal. The
// cable's normal then points along the face, towards the back (+x, +y), so
// after the bend it runs parallel to the slanted face, in the vertical plane
// through the connector's centre, along the hole behind that face (see
// housing.scad). The bend is 90 deg plus the rise of the housing's bottom
// along that direction (11.5 deg): straight on, the cable stays parallel to
// the hole's floor, 3.8 mm above it, below the connectors (5.3 mm), screw
// bosses and ribs (3.8 mm) of boards 1-3, beside the hole-1 guide tubes
// (0.8 mm in plan). (At exactly 90 deg it would run level and leave through
// the rising bottom under board 2 instead of the back face.) It meets row 3's
// back wall obliquely, 30.5 deg off its normal: a flat cable cannot turn in
// its own plane.
//
// Coordinates: board 0's frame, as everywhere.
//
// make builds   openscad -o ../build/switch/back_cable.stl back_cable.scad   (the cable)
// housing.scad uses back_outlet() for the hole in the back wall.
// Figures in the description above are for board 0's cable before the stack;
// it now runs (n_cables - 1) * stack_pitch lower, the top one there.

/* [From pcb.scad / housing.scad, do not edit here] */
step     = [10, 17, 4];          // staircase
con_c    = [-135.5, 1.2631];     // board 0's connector centre
con_rot  = atan2(step[1], step[0]);   // turned from y towards -x
face_z   = -0.835 - 5.5;         // connector face: bottom copper - body height
slope    = step[2] / step[1];    // the housing's bottom rises with the staircase
back_y   = 3 * step[1] + 10.6 + 0.7;   // housing's back face behind board 3 (cover outline)
back_t   = 1.2;                  // its wall round the hole

/* [Cable: 14-way FFC, 1.0 mm pitch] */
ffc_w    = 15;                   // width
ffc_t    = 0.3;                  // thickness
insert   = 3.5;                  // inside the connector
lead     = 2;                    // straight below the connector face (stiffener)
bend_r   = 3;                    // bend radius, at the cable's centre (rMin 2)
tail     = 10;                   // beyond the back face, along y
n_cables = 4;                    // boards 0 .. 3
stack_pitch = 0.5;               // cable to cable, square to them: 0.2 between the films

/* [Outlet] */
outlet_w = ffc_w + 1;            // hole in the back wall: 0.5 beside the cable each side
outlet_h = (n_cables - 1) * stack_pitch + ffc_t + 2 * 0.85;   //   and 0.85 above and below the stack

$fa = 2; $fs = 0.2;

// the cable's plane: x' along its run in plan (the cable's normal at the
// connector), y' = z; the width lies along u (towards contact 1)
run  = [cos(con_rot), sin(con_rot)];        // in plan, towards the back
u    = [-sin(con_rot), cos(con_rot)];
rise = atan(slope * run[1]);                 // the bottom's rise along run
bend = 90 + rise;                            // turned by this from straight down
dir    = [cos(rise), sin(rise)];             // straight on, after the bend
nrm    = [-sin(rise), cos(rise)];            // square to it, up
// cable k in its own board's frame, (x', z'), from inside the connector:
// its lead puts it (n_cables - 1 - k) * stack_pitch below the top one
function lead_of(k) = lead + (n_cables - 1 - k) * stack_pitch / cos(rise);
function arc_c(k) = [bend_r, face_z - lead_of(k)];
function arc_pt(k, a) = arc_c(k) + bend_r * [-cos(a), -sin(a)];   // a = 0 at the lead's end
function p_arc(k) = arc_pt(k, bend);
// straight part: to tail beyond the back face (along y)
function x_back(k) = (back_y - k * step[1] - con_c[1]) / run[1];   // x' where it meets the back face
function s_end(k) = (x_back(k) + tail / run[1] - p_arc(k)[0]) / dir[0];
function p_end(k) = p_arc(k) + s_end(k) * dir;
function at(k, q) = [con_c[0] + q[0] * run[0], con_c[1] + q[0] * run[1], q[1]] + k * step;   // -> board 0's frame
function z_back(k) = p_arc(k)[1] + (x_back(k) - p_arc(k)[0]) * dir[1] / dir[0];

for (k = [0 : n_cables - 1])
    echo(str("cable ", k, ": lead ", lead_of(k), ", bend ", bend, " deg (R ", bend_r, "), then straight at ", rise,
             " deg; leaves the back face at ", at(k, [x_back(k), z_back(k)]), "; free length ",
             lead_of(k) + bend_r * bend * PI / 180 + s_end(k), " mm from the connector face"));

// the plane of the cable, (x', z') in it, extruded along u by the width
module in_plane(k)
    translate(k * step)
    multmatrix([[run[0], 0, u[0], con_c[0]],
                [run[1], 0, u[1], con_c[1]],
                [0,      1, 0,    0],
                [0,      0, 0,    1]])
        children();

module centre_line2d(k)
    union() {
        hull() { translate([0, face_z + insert]) circle(d = ffc_t, $fn = 12);
                 translate([0, face_z - lead_of(k)]) circle(d = ffc_t, $fn = 12); }
        for (i = [0 : 29]) hull() {
            translate(arc_pt(k, bend * i / 30)) circle(d = ffc_t, $fn = 12);
            translate(arc_pt(k, bend * (i + 1) / 30)) circle(d = ffc_t, $fn = 12);
        }
        hull() { translate(p_arc(k)) circle(d = ffc_t, $fn = 12); translate(p_end(k)) circle(d = ffc_t, $fn = 12); }
    }

module back_cable(k)
    in_plane(k) translate([0, 0, -ffc_w / 2]) linear_extrude(ffc_w) centre_line2d(k);

module back_cables() for (k = [0 : n_cables - 1]) back_cable(k);

// the outlet: a slot along the straight parts, round the whole stack, from
// just inside the hole until past the back face, outlet_w across and
// outlet_h through
module back_outlet()
    in_plane(0) translate(p_arc(0) + (n_cables - 1) / 2 * stack_pitch * nrm) rotate(rise)
        translate([(x_back(0) - p_arc(0)[0]) / dir[0] - 15, -outlet_h / 2, -outlet_w / 2])
            cube([30, outlet_h, outlet_w]);

back_cables();
