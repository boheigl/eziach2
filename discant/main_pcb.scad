// The hole behind the slanted -x face: the key boards' bus wires
//
// [given: an I2C expander on every key board] Each board carries its own PCAL9555A at
// its -x end (../switch/pcb.scad, ioexp.scad). The board in the hole and the FFCs are
// gone: from each board's five wire pads (3.3 V, GND, SDA, SCL, INT) a bundle runs
// down the old cable's centre line into the hole, and the four meet at a splice where
// the board's wire pads were; from there one bundle runs on to the link board
// (gauge_link.scad: bundle()). The housing has a pocket under each board's -x end for
// the chip, its capacitor, the jumpers and the solder joints (housing.scad).
//
// (The cable geometry below is the old FFC's, kept for the wires' way.)
//
// make builds   openscad -o ../build/discant/main_pcb.stl main_pcb.scad    (the splice)
//               openscad -o ../build/discant/pcb_cable.stl -D 'show="cables"' main_pcb.scad   (the wires)
// housing.scad uses main_pcb_cuts() and main_pcb_pads().

show = "board";                  // "board" (laminate, parts, jack), "laminate", "parts", "copper" or "cables"
kicad = "../build/discant/main_pcb/";   // the routed board, from main_pcb/export_3d.py (make)

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
bend_r   = 2.4;                  // at the cable's centre (rMin 2)

/* [Board] */
pcb_t    = 1.6;
pcb_z    = 1.1;                  // its underside above the floor
pcb_x    = [4.7, 56.7];          // 0.5 clear of cable 3
pcb_y    = [-8.6, 13.9];         // inner side clear of the hole-1 tubes, outer 0.35 from the wall
// outline as in main_pcb/design.py: tabs between the tubes carry the ZIFs' hold-downs
outline  = [[4.7, 13.9], [56.7, 13.9], [56.7, -10.5], [49.6, -10.5], [48.6, -9.7], [48.6, -8.6], [40.2, -8.6],
            [40.2, -10.4], [30.3, -10.4], [30.3, -8.6], [21.1, -8.6], [21.1, -10.4], [19.6, -12.6],
            [12.6, -12.6], [11.1, -10.4], [11.1, -8.6], [4.7, -8.6]];

/* [Parts: bodies as boxes; [unverified] until parts are chosen] */
zif_w    = 21;                   // across the cable: the actuator bar at the mouth (GCT FFC3B, A)
zif_d    = 6.75;                 // along it, mouth to the tails' tips
zif_bar  = 1.1;                  // the bar's depth; the body behind it is zif_body wide
zif_body = 15.6;
zif_nail = [2.2, 5.2, 20.3];     // fitting nails: from, to behind the mouth, over both
zif_h    = 2.5;                  // height on the board
zif_in   = 3;                    // cable inside the ZIF
zif_x    = [10.57, 10.56, 10.66]; // top ZIFs: cable k's mouth beyond its connector: band X 11.2, 30.3, 49.5
zif3_x   = -2.4;                 // underside ZIF: mouth before connector 3: band X 54.9
mod_x    = [5.5, 31];            // ESP32-S3-WROOM-1-N16R8, 25.5 x 18 x 3.1, under the board
mod_y    = [-7.8, 10.2];
mod_h    = 3.1;
usb_x    = [36.2, 45.2];         // USB-C receptacle on top (GCT USB4105): 9 wide, beyond the
usb_y    = [8.0, 15.9];          //   module, whose pads its shield legs would otherwise hit
usb_h    = 3.3;
jack_x   = 26.1;                 // earphone jack, on wires, in the slanted wall
jack_z   = 9;                    // its axis above the floor, over the cable film
jack_d   = 6;                    // body; between cable 1 and the next rib
jack_l   = 14;
wall_y   = 16.5;                 // beyond the slanted wall's outer face, at the jack's height

/* [Floor] */
pocket_mod = 2.2;                // under the module and ZIF 3: 0.8 of floor left
pocket_low = 1.2;                // under the rest of the board's underside: 1.8 left
low_x    = [31.5, 47.3];
low_y    = [-8.3, 13.7];
pins     = [[7, 12.3], [54.5, 12.3], [16.6, -11.3], [37.6, -8.2]];   // on the band frame
pin_d    = 2;                    // locating pins; holes d2.2 in the board
pin_h    = 1.5;                  // above the board's underside: 0.1 under its top, clear of the ZIFs
pad_d    = 2.3;  

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

function cable_path(k) = k < 3 ? path(1, zc_top, zif_x[k] + zif_in)
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
    s = k < 3 ? 1 : -1;                       // from the mouth towards the tails
    m = e[0] - s * zif_in;
    z = k < 3 ? [pcb_z + pcb_t, pcb_z + pcb_t + zif_h] : [pcb_z - zif_h, pcb_z];
    function along(a, b) = s > 0 ? [m + a, m + b] : [m - b, m - a];
    function across(w) = [e[1] - w / 2, e[1] + w / 2];
    box(along(0, zif_bar), across(zif_w), z);
    box(along(0, zif_d), across(zif_body), z);
    box(along(zif_nail[0], zif_nail[1]), across(zif_nail[2]), z);
}

module board()
    translate([0, 0, pcb_z]) linear_extrude(pcb_t) difference() {
        polygon(outline);
        for (p = pins) translate([p[0], p[1]]) circle(d = pin_d + 0.2);
    }

module module_body() box(mod_x, mod_y, [pcb_z - mod_h, pcb_z]);
module usb_body()    box(usb_x, usb_y, [pcb_z + pcb_t, pcb_z + pcb_t + usb_h]);
module jack_body()   translate([jack_x, wall_y - 0.5 - jack_l, jack_z]) rotate([-90, 0, 0])
                         cylinder(d = jack_d, h = jack_l);

// the bus wires: from board k's connector plug (board frame, below its bottom face) to the
// old cable's centre line, down it, then across the hole to the splice
wire_d   = 1.8;                  // five wires, AWG 30 [assumed]
plug_at  = [-137.9, -3.2, -0.835 - 5.85 - 1.0];   // where the wires leave the plug (../switch/ioexp.scad, housing.scad)
splice   = from_band([50, 11.7, 4.6]);   // where the hole board's wire pads were: the link bundle's start
module wire_seg(a, b) hull() { translate(a) sphere(d = wire_d, $fn = 10); translate(b) sphere(d = wire_d, $fn = 10); }
function wire_pts(k) = let(p = cable_path(k))
    concat([plug_at + k * step],
           [for (i = [1 : len(p) - 1]) if (to_band(at(k, p[i]))[2] > 1.2) at(k, p[i])], [splice]);   // kept 1.2 over the hole's floor
module bus_wires() for (k = [0 : 3]) let(w = wire_pts(k)) for (i = [0 : len(w) - 2]) wire_seg(w[i], w[i + 1]);
module splice_sleeve() translate(splice) sphere(d = 4.0, $fn = 16);   // heat shrink over the joints

// nothing is cut from or added to the housing for the hole any more
module main_pcb_cuts() { }
module main_pcb_pads() { }

for (k = [0 : 3]) echo(str("cable ", k, ": ends on the band frame at ", end_of(k), ", lead ",
                           k < 3 ? lead_of(1, zc_top) : lead_of(-1, zc_bot)));
echo(str("board ", pcb_x[1] - pcb_x[0], " x ", pcb_y[1] - pcb_y[0], " x ", pcb_t));

if (show == "cables") bus_wires();
else splice_sleeve();
