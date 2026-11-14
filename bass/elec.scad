// Bass electronics: two small boards in the box, the charging port, and the contacts'
// spring pins (placeholders: boxes; parts [unverified] until chosen).
//
// [given: the battery charges in the bass, also stored, by its own USB socket; the
// contacts switch it on to the electronics when the halves are plugged for playing]
//
// MAIN BOARD [given: the electronics moved from the discant to the bass], at the bottom
// on the +x side, against the side wall, the outer rib notched over it: the ESP32-S3 module (its
// antenna at the board's bottom edge, away from the battery), the audio DAC
// (TLV320DAC3100) and the earphone jack, USB-C (charging, firmware, MIDI), a charger
// with power path (e.g. BQ24074 [unverified]), the battery's protection and a resettable
// fuse, and the 3.3 V supply for both halves, switched on by the contacts. The FET's gate is pulled up (off) and pulled to ground
// through the contacts' DET pin, which the discant's contact board ties to GND: only
// plugged for playing is the system on (the ESP32, and 3.3 V to the discant over the
// contacts); stored or apart only the charger works. DET's pin is the shortest, so it
// closes last and opens first. The USB socket and the jack are in the +x side wall, in
// its straight part, free both stored (the discant covers only the box's back) and
// played; a side-emitting LED beside them shows charging through a hole in the wall.
//
// KEY BOARD [given 2026-11-13]: one Hall-sensor board under both rows (../hall_pcb/bass/):
// three ADS7138 ADCs at 10h..12h on the ESP32's second I2C bus (the discant's six use
// 10h..15h on the first, through the contacts).
//
// WIRES (wires()): the nine pins' wires leave the mount's cavity through the back wall's
// bore as one bundle and run along the bottom under the battery's shelf (notches in the
// ribs) right to the main board (3.3 V, GND, SDA, SCL, INT, DET). The key board's bus
// wires (3.3 V, GND, SDA, SCL, INT) drop from its connector J1, which hangs over the box,
// straight down into it, run along under the strap bar's block and down beside the
// battery to the bottom, where they join the first bundle to the main board.
//
// The main board lies flat against the front wall's inside (0.47 above it), on three
// pads with M2 pilots into the front wall, outside the hand plate's recess; with the
// back cover off they are screwed from the back. The power board goes in 2 mm to the
// left of its place and slides right, its socket into the port.
//
// make builds   openscad -o ../build/bass/elec.stl elec.scad

include <layout.scad>
use <link.scad>

pcb_tk  = 1.0;
brd_y   = [plate_y[1] + 0.47, plate_y[1] + 0.47 + pcb_tk];   // -9.03 .. -8.03
pwr_x   = [box_x[1] - 2.45 - 45.5, box_x[1] - 2.45]; pwr_z = [-125.8, -92.8] + [ez, ez];   // main board: against the +x wall, under the strap's bar, the outer rib notched over it
// USB-C receptacle, top mount at the board's edge, its mouth 0.2 inside the wall's face
usb     = [7.35, 8.94, 3.26];               // along x (plugging), z, y
usb_z   = -104.5 + ez;
usb_x1  = box_x[1] - 0.2;
usb_yc  = brd_y[1] + usb[2] / 2;
led_z   = -96 + ez;
pilots  = [[pwr_x[0] + 3.2, -123.6 + ez], [pwr_x[0] + 3.2, -95.0 + ez], [pwr_x[0] + 41.8, -95.0 + ez]];
jack_z  = -116 + ez;                 // earphone jack, mid-mount (sunk into the board), axis along x
jack    = [14, 6, 5];            // length (x), width (z), height above the board's underside
wall_t  = 2;                     // the side wall (case.scad: wall)
pad_d   = 4.5;

module bx(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

module power_board() {
    difference() {
        bx(pwr_x, brd_y, pwr_z);
        for (p = pilots) translate([p[0], brd_y[0] - 1, p[1]]) rotate([-90, 0, 0]) cylinder(d = 2.2, h = 3, $fn = 16);
    }
    bx(pwr_x[0] + [1.2, 19.2], [brd_y[1], brd_y[1] + 3.1], [-125.3, -99.8] + [ez, ez]);    // ESP32-S3-WROOM-1, antenna end at the bottom
    bx(pwr_x[0] + [22.2, 27.2], [brd_y[1], brd_y[1] + 1.0], [-100, -95] + [ez, ez]);        // DAC (QFN)
    // jack: the body inside the wall (to 0.2 off it), its front sleeve into the wall's hole
    bx([box_x[1] - wall_t - 0.2 - jack[0], box_x[1] - wall_t - 0.2], [brd_y[0], brd_y[0] + jack[2]], [jack_z - jack[1] / 2, jack_z + jack[1] / 2]);
    translate([box_x[1] - wall_t - 0.21, brd_y[0] + jack[2] / 2, jack_z]) rotate([0, 90, 0]) cylinder(d = 3.6, h = wall_t, $fn = 24);
    // USB-C, its shell rounded at the ends as the real one
    translate([usb_x1 - usb[0], usb_yc, usb_z]) rotate([0, 90, 0]) linear_extrude(usb[0])
        offset(r = 1.2) offset(delta = -1.2) square([usb[1], usb[2]], center = true);
    bx(pwr_x[0] + [23.2, 27.2], [brd_y[1], brd_y[1] + 1.0], [-110, -106] + [ez, ez]);       // charger (QFN)
    bx(pwr_x[0] + [29.2, 32.2], [brd_y[1], brd_y[1] + 1.1], [-100, -97] + [ez, ez]);        // FET, LDO, protection
    bx(pwr_x[0] + [29.2, 32.2], [brd_y[1], brd_y[1] + 1.1], [-106, -103] + [ez, ez]);
    bx(pwr_x[1] + [-1, 0], [brd_y[1], brd_y[1] + 0.8], [led_z - 0.5, led_z + 0.5]);   // side LED
}
// cut from the case: the port and the light through the +x side wall; the pilots
module elec_cuts() {
    translate([box_x[1] - 3, usb_yc, usb_z]) rotate([0, 90, 0]) linear_extrude(4)
        offset(r = 1.2) offset(delta = -1.2) square([usb[1] + 0.5, usb[2] + 0.5], center = true);
    translate([box_x[1] - 3, usb_yc, led_z]) rotate([0, 90, 0]) cylinder(d = 1.6, h = 4, $fn = 16);
    translate([box_x[1] - 3, brd_y[0] + jack[2] / 2, jack_z]) rotate([0, 90, 0]) cylinder(d = 4.0, h = 4, $fn = 24);   // the jack [unverified: type]
    for (p = pilots) translate([p[0], plate_y[1] - 2.0, p[1]]) rotate([-90, 0, 0]) cylinder(d = 1.6, h = 3, $fn = 16);
}
// cut from the case's ribs: the main board's room, front to back
module main_board_room() translate([pwr_x[0] - 1, plate_y[1] - 1, pwr_z[0] - 1]) cube([pwr_x[1] - pwr_x[0] + 2, 20, pwr_z[1] - pwr_z[0] + 2]);
// added to the case: the boards' pads
module elec_pads() for (p = pilots) difference() {
    translate([p[0], plate_y[1] - 0.01, p[1]]) rotate([-90, 0, 0]) cylinder(d = pad_d, h = 0.48, $fn = 24);
    translate([p[0], plate_y[1] - 2.0, p[1]]) rotate([-90, 0, 0]) cylinder(d = 1.6, h = 3, $fn = 16);
}

module elec() { power_board(); contact_plungers(); }

// a round bundle through points
module bundle(p, d) for (i = [0 : len(p) - 2]) hull() {
    translate(p[i]) sphere(d = d, $fn = 12); translate(p[i + 1]) sphere(d = d, $fn = 12);
}
// where the key board's bus wires leave J1's plug (4.25 header and the plug below the board)
plug_out = [hall_conn[0], hall_conn[1], board_bot - 6.0];
module wires() {
    zb = z_bot + 3.3;              // the bore and the slot under the case's foot (link.scad, case.scad)
    c = [[-1.748 + ex, 4.19, z_bot + 5.9], [-1.748 + ex, 4.19, zb], [-1.748 + ex, -6.2, zb]];
    bundle(c, 2.0);                                                                  // all nine
    bundle([c[2], [pwr_x[0] + 20.7, -6.4, zb], [pwr_x[0] + 21.7, -6.4, -124.0 + ez]], 1.8);                 // to the main board, beside the module
    // the key board's bus: straight down from J1's plug, over the strap bar's block (top -44.5),
    // down beside the battery, to the bottom bundle
    bundle([c[2], [-55.5 + ex, -5.0, zb], [-55.5 + ex, -5.0, -43], [plug_out[0], -5.0, -41.5], [plug_out[0], plug_out[1], plug_out[2] - 2], plug_out], 1.8);
}

part = "elec";
if (part == "elec") elec();
if (part == "wires") wires();

