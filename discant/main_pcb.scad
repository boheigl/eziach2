// Main PCB in the hole behind the slanted -x face, and the boards' FFCs to it
//
// One board lying parallel to the hole's floor, so to the bottom plane, under
// the four connectors. It replaces the four long cables to the old back outlet;
// what leaves the hole now are six wires to the link board (gauge_link.scad),
// USB-C and the earphone jack (slanted wall).
//
// Every cable drops every staircase step along the band, so the 25.5 mm module
// cannot lie between two of them: it hangs under the board, in a pocket in the
// floor. A 14-way ZIF, about 20 mm wide on its cable's line, fits in only three
// places, since the hole-1 tubes bite into the band. So cables 0-2 bend towards
// the back, the same bend as before, into ZIFs on the board's top; cable 3
// bends the other way, past the board's end, into a ZIF on the underside.
//
// ASSEMBLY, on the bench, with the boards in the upside-down cover (cover.scad):
// plug the four cables into this board, turn it over, feed them into the board
// connectors from above and close those. The board then rides on the cables
// into the hole as the unit goes onto the housing, where four pins in the floor
// locate it. Nothing is reached from below.
//
// Frame: the band frame, band(): origin on the hole's floor under board 0's
// connector centre, X up the staircase, Y towards the slanted wall, Z square
// to the floor. Connector k lies at X = k * pitch.
//
// make builds   openscad -o ../build/discant/main_pcb.stl main_pcb.scad    (board and parts)
//               openscad -o ../build/discant/pcb_cable.stl -D 'show="cables"' main_pcb.scad
// housing.scad uses main_pcb_cuts() and main_pcb_pads().

show = "board";                  // "board" or "cables"

/* [From pcb.scad / housing.scad, do not edit here] */
step     = [10, 16, 3];          // staircase
con_c    = [-135.7, 2.47299];     // board 0's connector centre
face_z   = -0.835 - 5.5;         // connector face: bottom copper - body height
slope    = step[2] / step[1];    // the housing's bottom rises with the staircase
floor_c  = 18.88925;              // bottom plane: z = slope * y - floor_c
hole_floor = 3;                  // the hole's floor above the bottom plane

/* [Cable: 14-way FFC, 1.0 mm pitch,] */
ffc_w    = 15;
ffc_t    = 0.3;
insert   = 3.5;                  // inside the board connector
bend_r   = 3;                    // at the cable's centre (rMin 2)

/* [Board] */
pcb_t    = 1.6;
pcb_z    = 1.1;                  // its underside above the floor
pcb_x    = [4.7, 56.2];          // 0.3 clear of tube 0 and 0.5 of cable 3
pcb_y    = [-8.6, 13.4];         // inner side clear of the hole-1 tubes, outer 0.3 from the wall

/* [Parts: bodies as boxes; [unverified] until parts are chosen] */
zif_w    = 20;                   // across the cable
zif_d    = 5;                    // along it
zif_h    = 2;                    // height on the board
zif_in   = 3;                    // cable inside the ZIF
zif_x    = 11.2;                 // top ZIFs: mouth beyond their own connector
zif3_x   = -3;                   // underside ZIF: mouth before connector 3
mod_x    = [5.5, 31];            // ESP32-S3-WROOM-1, 25.5 x 18 x 3.1, under the board
mod_y    = [-8.1, 9.9];
mod_h    = 3.1;
usb_x    = [21, 30];             // USB-C receptacle on top: 9 wide
usb_y    = [8, 15.4];          // 7.4 deep, front inside the wall's opening
usb_h    = 3.3;
bass_x   = [41.5, 49.5];             // six-way connector for the wires to gauge_link.scad
bass_y   = [10.1, 13.3];
bass_h   = 3;
jack_x   = 45.2;                 // earphone jack, on wires, in the slanted wall
jack_z   = 9;                    // its axis above the floor, over the cable film
jack_d   = 6;                    // body; between cable 2 and the next rib
jack_l   = 14;
wall_y   = 16.5;                 // beyond the slanted wall's outer face, at the jack's height

/* [Floor] */
pocket_mod = 2.2;                // under the module and ZIF 3: 0.8 of floor left
pocket_low = 1.2;                // under the rest of the board's underside: 1.8 left
low_x    = [31.5, 55.9];
low_y    = [-8.3, 10.4];
pins     = [[7, 11.9], [34, 11.9], [54, 11.9], [37.2, 0]];   // on the band frame
pin_d    = 2;                    // locating pins; holes d2.2 in the board
pin_h    = 2.5;                  // above the board's underside
pad_d    = 3.6;

$fa = 2; $fs = 0.2;

function unit(v) = v / norm(v);
pitch = norm(step);
ex = unit(step);
ez = unit([0, -slope, 1]);
ey = cross(ez, ex);
function floor_z(y) = slope * y - floor_c + hole_floor;
origin = [con_c[0], con_c[1], floor_z(con_c[1])];
function from_band(p) = origin + p[0] * ex + p[1] * ey + p[2] * ez;
function to_band(p) = [(p - origin) * ex, (p - origin) * ey, (p - origin) * ez];

module band()
    multmatrix([[ex[0], ey[0], ez[0], origin[0]],
                [ex[1], ey[1], ez[1], origin[1]],
                [ex[2], ey[2], ez[2], origin[2]],
                [0, 0, 0, 1]])
        children();

// cables run in the vertical plane through their connector
con_rot = atan2(step[1], step[0]);
run  = [cos(con_rot), sin(con_rot)];
u    = [-sin(con_rot), cos(con_rot)];        // the width, at the connector: level
rise = atan(slope * run[1]);                 // the floor's rise along run
function at(k, q) = [con_c[0] + q[0] * run[0], con_c[1] + q[0] * run[1], q[1]] + k * step;
floor0 = floor_z(con_c[1]);
along  = pitch / norm([step[0], step[1]]);   // band X per mm along run in plan
zc_top = pcb_z + pcb_t + zif_h / 2;          // the top ZIFs' mouth, above the floor
zc_bot = pcb_z - zif_h / 2;                  // the underside ZIF's
function v_of(z) = z / ez[2];                // height square to the floor -> vertical

// the path in (q, z), board frame, from inside the connector to inside the ZIF.
// dirn = +1 towards the back, -1 towards the front; the arc turns the cable
// from straight down to parallel to the floor
function bend_of(dirn) = 90 + dirn * rise;
function arc_drop(dirn) = bend_r * sin(bend_of(dirn));
function arc_run(dirn)  = dirn * bend_r * (1 - cos(bend_of(dirn)));
function lead_of(dirn, zt) = face_z - floor0 - arc_drop(dirn) - v_of(zt) - arc_run(dirn) * tan(rise);
function path(dirn, zt, x_end) =
    let (zc = face_z - lead_of(dirn, zt), b = bend_of(dirn), n = 24,
         pe = [arc_run(dirn), zc - arc_drop(dirn)],
         qe = x_end / along,
         e = [qe, pe[1] + (qe - pe[0]) * tan(rise)])
    concat([[0, face_z + insert], [0, zc]],
           [for (i = [1 : n]) let (a = b * i / n)
                [dirn * bend_r * (1 - cos(a)), zc - bend_r * sin(a)]],
           [for (i = [1 : 6]) pe + (e - pe) * i / 6]);

function cable_path(k) = k < 3 ? path(1, zc_top, zif_x + zif_in)
                               : path(-1, zc_bot, zif3_x - zif_in);

// the film in 3D: level at the connector, turned into the floor's plane at the
// ZIF. The floor rolls 5.7 deg against level along the cable's width, so the
// film twists that much along its free length
wide0 = [u[0], u[1], 0];
wide1 = ey;                                  // same sense as wide0
function width_at(t) = unit(wide0 * (1 - t) + wide1 * t);

module film_seg(p0, p1, w0, w1) {
    t = unit(p1 - p0);
    n0 = unit(cross(w0, t)) * ffc_t / 2;
    n1 = unit(cross(w1, t)) * ffc_t / 2;
    h0 = w0 * ffc_w / 2; h1 = w1 * ffc_w / 2;
    hull() polyhedron(
        points = [p0 - h0 - n0, p0 + h0 - n0, p0 + h0 + n0, p0 - h0 + n0,
                  p1 - h1 - n1, p1 + h1 - n1, p1 + h1 + n1, p1 - h1 + n1],
        faces = [[0, 1, 2], [0, 2, 3], [4, 6, 5], [4, 7, 6], [0, 4, 5], [0, 5, 1],
                 [1, 5, 6], [1, 6, 2], [2, 6, 7], [2, 7, 3], [3, 7, 4], [3, 4, 0]]);
}

module cable(k) {
    p = cable_path(k);
    m = len(p) - 1;
    for (i = [0 : m - 1])
        film_seg(at(k, p[i]), at(k, p[i + 1]),
                 width_at(max(0, i - 1) / (m - 1)), width_at(i / (m - 1)));
}
module cables() for (k = [0 : 3]) cable(k);

// where cable k ends, on the band frame: its ZIF sits there
function end_of(k) = to_band(at(k, cable_path(k)[len(cable_path(k)) - 1]));

module box(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

module zif(k) {
    e = end_of(k);
    y = [e[1] - zif_w / 2, e[1] + zif_w / 2];
    if (k < 3) box([e[0] - zif_in, e[0] - zif_in + zif_d], y, [pcb_z + pcb_t, pcb_z + pcb_t + zif_h]);
    else       box([e[0] + zif_in - zif_d, e[0] + zif_in], y, [pcb_z - zif_h, pcb_z]);
}

module board()
    difference() {
        box(pcb_x, pcb_y, [pcb_z, pcb_z + pcb_t]);
        for (p = pins) translate([p[0], p[1], 0]) cylinder(d = pin_d + 0.2, h = 10);
    }

module module_body() box(mod_x, mod_y, [pcb_z - mod_h, pcb_z]);
module usb_body()    box(usb_x, usb_y, [pcb_z + pcb_t, pcb_z + pcb_t + usb_h]);
module bass_body()   box(bass_x, bass_y, [pcb_z + pcb_t, pcb_z + pcb_t + bass_h]);
module jack_body()   translate([jack_x, wall_y - 0.5 - jack_l, jack_z]) rotate([-90, 0, 0])
                         cylinder(d = jack_d, h = jack_l);

module main_pcb() band() {
    board(); module_body(); usb_body(); bass_body(); jack_body();
    for (k = [0 : 3]) zif(k);
}

// cut from the housing: floor pockets, USB-C and jack openings
module main_pcb_cuts() band() {
    g = 0.3;
    box([mod_x[0] - g, mod_x[1] + g], [mod_y[0] - g, mod_y[1] + g], [-pocket_mod, 1]);
    box(low_x, low_y, [-pocket_low, 1]);
    e = end_of(3);
    // on past the mouth: the film still twists there and would scrape the floor
    box([e[0] + zif_in - zif_d - g, e[0] + zif_in + 3], [e[1] - zif_w / 2 - g, e[1] + zif_w / 2 + g], [-pocket_mod, 1]);
    box([usb_x[0] - 0.3, usb_x[1] + 0.3], [12, wall_y + 1], [pcb_z + pcb_t - 0.3, pcb_z + pcb_t + usb_h + 0.3]);
    translate([jack_x, 10, jack_z]) rotate([-90, 0, 0]) cylinder(d = jack_d + 0.2, h = 10);
}

// added to the housing: a pad under the board and a locating pin, at each pin
module main_pcb_pads() band()
    for (p = pins) translate([p[0], p[1], 0]) {
        translate([0, 0, -pocket_mod - 0.2]) cylinder(d = pad_d, h = pcb_z + pocket_mod + 0.2);   // from the floor below the pockets
        cylinder(d = pin_d, h = pcb_z + pin_h);
    }

for (k = [0 : 3]) echo(str("cable ", k, ": ends on the band frame at ", end_of(k), ", lead ",
                           k < 3 ? lead_of(1, zc_top) : lead_of(-1, zc_bot)));
echo(str("board ", pcb_x[1] - pcb_x[0], " x ", pcb_y[1] - pcb_y[0], " x ", pcb_t));

if (show == "cables") cables(); else main_pcb();
