// Bass electronics: two small boards in the box, the charging port, and the contacts'
// spring pins (placeholders: boxes; parts [unverified] until chosen).
//
// [given: the battery charges in the bass, also stored, by its own USB socket; the
// contacts switch it on to the electronics when the halves are plugged for playing]
//
// POWER BOARD, at the bottom on the +x side, beside the battery: USB-C (charging only,
// 5 V), a charger with power path (e.g. BQ24074 [unverified]), the battery's protection
// and a resettable fuse, the P-FET that switches the battery to the contacts, and a
// 3.3 V LDO for the key board. The FET's gate is pulled up (off) and pulled to ground
// through the contacts' DET pin, which the discant's contact board ties to GND: only
// plugged for playing is the battery on the contacts and the electronics. DET's pin is
// the shortest, so it closes last and opens first. The socket is in the +x side wall,
// in its straight part, free both stored (the discant covers only the box's back) and
// played; a side-emitting LED beside it shows charging through a hole in the wall.
//
// KEY BOARD, at the top on the -x side, where the two FFCs come down from the deck's
// tunnels: their two connectors and an I2C port expander with 24 inputs (e.g. PCAL6524
// [unverified]), each of the 18 keys on its own input, the boards' commons to ground:
// no matrix, no diodes [given: answers the open diode and line-count points].
//
// WIRES [not modelled]: from the pins through the mount's cavity and the back wall's
// bore into the box, below the battery's shelf along the bottom (notches in the ribs) to
// the power board;
// from there VBAT_SW, GND, 3.3 V, SDA, SCL, INT up beside the battery to the key board.
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
key_x   = [-86, -58];    key_z = [-44, -22];
// USB-C receptacle, top mount at the board's edge, its mouth 0.2 inside the wall's face
usb     = [7.35, 8.94, 3.26];               // along x (plugging), z, y
usb_z   = -104.5;
usb_x1  = box_x[1] - 0.2;
usb_yc  = brd_y[1] + usb[2] / 2;
led_z   = -96;
pilots  = [[102, -112.5], [102, -96.5], [-83, -41], [-83, -25]];
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
    for (z = [-27.5, -33]) bx([-80, -67], [brd_y[1], brd_y[1] + 2.0], [z, z + 3.5]);   // FFC connectors
    bx([-64, -60], [brd_y[1], brd_y[1] + 0.9], [-39, -35]);                            // expander (QFN)
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

part = "elec";
if (part == "elec") elec();
