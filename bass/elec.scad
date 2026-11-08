// Bass electronics: two small boards in the box, the charging port, and the contacts'
// spring pins (placeholders: boxes; parts [unverified] until chosen).
//
// [given: the battery charges in the bass, also stored, by its own USB socket; the
// contacts switch it on to the electronics when the halves are plugged for playing]
//
// POWER BOARD, at the bottom on the +x side, beside the battery: USB-C (charging only,
// 5 V), a charger with power path (e.g. BQ24074 [unverified]), the battery's protection
// and a resettable fuse, and the P-FET that switches the battery to the contacts. The FET's gate is pulled up (off) and pulled to ground
// through the contacts' DET pin, which the discant's contact board ties to GND: only
// plugged for playing is the battery on the contacts and the electronics. DET's pin is
// the shortest, so it closes last and opens first. The socket is in the +x side wall,
// in its straight part, free both stored (the discant covers only the box's back) and
// played; a side-emitting LED beside it shows charging through a hole in the wall.
//
// KEY BOARD, at the top on the -x side, where the two FFCs come down from the deck's
// tunnels: their two connectors, a 3.3 V LDO and an I2C port expander with 24 inputs
// (e.g. PCAL6524 [unverified]), each of the 18 keys on its own input, the boards' commons to ground:
// no matrix, no diodes [given: answers the open diode and line-count points].
//
// WIRES (wires()): the nine pins' wires leave the mount's cavity through the back wall's
// bore as one bundle and part inside the box, along the bottom under the battery's shelf
// (notches in the ribs): right to the power board VBAT x 2, GND x 2, DET; left and up
// beside the battery to the key board SDA, SCL, INT, GND and a second wire on a VBAT pin
// (the switched battery, for its LDO), so no bundle crosses another. The FFCs: 15 x 0.3,
// flat, out of the boards' connectors downwards (turned 58 deg in plan), twisted and
// folded flat into the deck's tunnel (stacked: board 1's below, so they never cross),
// down its drop and into the key board's two connectors.
//
// Both boards lie flat against the front wall's inside (0.47 above it), each on two
// pads with M2 pilots into the front wall, outside the hand plate's recess; with the
// back cover off they are screwed from the back. The power board goes in 2 mm to the
// left of its place and slides right, its socket into the port.
//
// make builds   openscad -o ../build/bass/elec.stl elec.scad

include <layout.scad>
use <link.scad>

pcb_tk  = 1.0;
brd_y   = [plate_y[1] + 0.47, plate_y[1] + 0.47 + pcb_tk];   // -9.03 .. -8.03
pwr_x   = [99, 128.3];   pwr_z = [-115.5, -93.5];
key_x   = [-104.5, -76.5];  key_z = [-44, -22];   // under the FFCs' drop (case.scad: tun_x)
// USB-C receptacle, top mount at the board's edge, its mouth 0.2 inside the wall's face
usb     = [7.35, 8.94, 3.26];               // along x (plugging), z, y
usb_z   = -104.5;
usb_x1  = box_x[1] - 0.2;
usb_yc  = brd_y[1] + usb[2] / 2;
led_z   = -96;
pilots  = [[102, -112.5], [102, -96.5], [-101.5, -41], [-79.5, -25]];
pad_d   = 4.5;

module bx(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

module power_board() {
    difference() {
        bx(pwr_x, brd_y, pwr_z);
        for (p = [pilots[0], pilots[1]]) translate([p[0], brd_y[0] - 1, p[1]]) rotate([-90, 0, 0]) cylinder(d = 2.2, h = 3, $fn = 16);
    }
    // USB-C, its shell rounded at the ends as the real one
    translate([usb_x1 - usb[0], usb_yc, usb_z]) rotate([0, 90, 0]) linear_extrude(usb[0])
        offset(r = 1.2) offset(delta = -1.2) square([usb[1], usb[2]], center = true);
    bx([108, 112], [brd_y[1], brd_y[1] + 1.0], [-108, -104]);       // charger (QFN)
    bx([104, 107], [brd_y[1], brd_y[1] + 1.1], [-100, -97]);        // FET, LDO, protection
    bx([110, 113], [brd_y[1], brd_y[1] + 1.1], [-100, -97]);
    bx([127.3, 128.3], [brd_y[1], brd_y[1] + 0.8], [led_z - 0.5, led_z + 0.5]);   // side LED
}
module key_board() {
    difference() {
        bx(key_x, brd_y, key_z);
        for (p = [pilots[2], pilots[3]]) translate([p[0], brd_y[0] - 1, p[1]]) rotate([-90, 0, 0]) cylinder(d = 2.2, h = 3, $fn = 16);
    }
    // two ZIF connectors for the 15 mm FFCs (14 x 1.0), taking them from above, the upper
    // one at the board's top edge [unverified: type, about 19 wide]
    for (z = [-25.5, -31]) bx([-94.3 - 9.5, -94.3 + 9.5], [brd_y[1], brd_y[1] + 2.0], [z, z + 3.5]);
    bx([-86, -82], [brd_y[1], brd_y[1] + 0.9], [-40, -36]);                            // expander (QFN)
    bx([-80, -78], [brd_y[1], brd_y[1] + 1.1], [-40, -38]);                            // 3.3 V LDO
}

// cut from the case: the port and the light through the +x side wall; the pilots
module elec_cuts() {
    translate([box_x[1] - 3, usb_yc, usb_z]) rotate([0, 90, 0]) linear_extrude(4)
        offset(r = 1.2) offset(delta = -1.2) square([usb[1] + 0.5, usb[2] + 0.5], center = true);
    translate([box_x[1] - 3, usb_yc, led_z]) rotate([0, 90, 0]) cylinder(d = 1.6, h = 4, $fn = 16);
    for (p = pilots) translate([p[0], plate_y[1] - 2.0, p[1]]) rotate([-90, 0, 0]) cylinder(d = 1.6, h = 3, $fn = 16);
}
// added to the case: the boards' pads
module elec_pads() for (p = pilots) difference() {
    translate([p[0], plate_y[1] - 0.01, p[1]]) rotate([-90, 0, 0]) cylinder(d = pad_d, h = 0.48, $fn = 24);
    translate([p[0], plate_y[1] - 2.0, p[1]]) rotate([-90, 0, 0]) cylinder(d = 1.6, h = 3, $fn = 16);
}

module elec() { power_board(); key_board(); contact_plungers(); }

// a round bundle through points, and a flat cable (width along x) through points in y-z
module bundle(p, d) for (i = [0 : len(p) - 2]) hull() {
    translate(p[i]) sphere(d = d, $fn = 12); translate(p[i + 1]) sphere(d = d, $fn = 12);
}
// a flat cable through nodes [point, width direction, thickness direction]: its section
// turns from node to node, which stands for the twists and folds between
function nx(v) = v / norm(v);
module ffc_rect(n, w, t) let(u = nx(n[1]), v = nx(n[2]), s = cross(u, v))
    multmatrix([[u[0], v[0], s[0], n[0][0]], [u[1], v[1], s[1], n[0][1]], [u[2], v[2], s[2], n[0][2]], [0, 0, 0, 1]])
        translate([-w / 2, -t / 2, -0.005]) cube([w, t, 0.01]);
module ffc(nodes, w = 15, t = 0.3) for (i = [0 : len(nodes) - 2]) hull() { ffc_rect(nodes[i], w, t); ffc_rect(nodes[i + 1], w, t); }

tun_x = -94.3;                   // as case.scad
zt    = -13.583;                 // the tunnel's floor (case.scad: z_floor + tunnel_floor)
X = [1, 0, 0]; Y = [0, 1, 0]; Z = [0, 0, 1];
// the boards' connectors (GCT FFC3A20, vertical, on the boards' undersides): turned
// atan2(16, 10) in plan, the cable leaving downwards with its width along their length
CU = [-sin(atan2(16, 10)), cos(atan2(16, 10)), 0];  CV = [cos(atan2(16, 10)), sin(atan2(16, 10)), 0];
con_xy  = [for (k = [0, 1]) [board_dx[k] - 135.7, rows_y[k] + 2.47299]];
con_bot = [-3.34, 6.66];          // their undersides (connectors.stl)
// board 0's cable: down out of its connector, twisted flat into the tunnel's upper layer,
// forward, down the drop at the front and into the key board's upper connector; board
// 1's: down, flat into the lower layer, under board 0's, down the drop behind it, past
// the upper connector and into the lower one
function ffc_nodes(k) = k == 0 ?
    [[[con_xy[0][0], con_xy[0][1], con_bot[0] + 1], CU, CV], [[con_xy[0][0], con_xy[0][1], -8.6], CU, CV],
     [[tun_x, -1.5, zt + 2.2], X, Z], [[tun_x, -6.9, zt + 2.2], X, Z],
     [[tun_x, -7.3, -15.5], X, Y], [[tun_x, -7.3, -23.0], X, Y]] :
    [[[con_xy[1][0], con_xy[1][1], con_bot[1] + 1], CU, CV], [[con_xy[1][0], con_xy[1][1], -8.0], CU, CV],
     [[tun_x, 12.0, zt + 0.9], X, Z], [[tun_x, -5.6, zt + 0.9], X, Z],
     [[tun_x, -5.4, -15], X, Y], [[tun_x, -5.4, -26.8], X, Y], [[tun_x, -7.0, -27.3], X, Y], [[tun_x, -7.0, -28.5], X, Y]];
// cut from the case: room round both cables in the deck and its drop
module ffc_channels() intersection() {
    for (k = [0, 1]) ffc(ffc_nodes(k), 16.5, 1.6);
    translate([-300, -300, -17]) cube([600, 600, 100]);
}
module wires() {
    c = [[-1.748, 4.19, -123.14], [-1.748, 4.19, -125.24], [-1.748, -6.2, -125.24]];
    bundle(c, 2.0);                                                                  // all nine
    bundle([c[2], [97.5, -6.4, -125.2], [100.5, -6.6, -114.3]], 1.6);              // to the power board
    bundle([c[2], [-55.5, -5.0, -125.2], [-55.5, -5.0, -45], [-79, -5.0, -41]], 1.6);   // to the key board
    for (k = [0, 1]) ffc(ffc_nodes(k));
}

part = "elec";
if (part == "elec") elec();
if (part == "wires") wires();
if (part == "ffc0") ffc(ffc_nodes(0));
if (part == "ffc1") ffc(ffc_nodes(1));
