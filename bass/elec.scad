// Bass electronics: two small boards in the box, the charging port, and the contacts'
// spring pins (placeholders: boxes; parts [unverified] until chosen).
//
// [given: the battery charges in the bass, also stored, by its own USB socket; the
// contacts switch it on to the electronics when the halves are plugged for playing]
//
// MAIN BOARD [given: the electronics moved from the discant to the bass], at the bottom
// on the +x side, against the side wall, the outer rib notched over it: designed in
// ../main_pcb/ (KiCad; its parts and screw holes come in through ../main_pcb/board.scad).
// The ESP32-S3 module (its antenna at the board's bottom edge, away from the battery),
// the audio DAC and the earphone jack, USB-C (charging, firmware, MIDI), the charger with
// power path, a fuse (the cell carries its own protection), and the 3.3 V supply for
// both halves. The system runs when the contacts' DET pin is tied to ground by the
// discant's contact board (plugged for playing) or when USB is plugged in; 3.3 V goes to
// the discant over the contacts only with DET. The nine spring pins are alike, so DET
// may close before the others: the 3.3 V to the discant ramps up after DET (main board,
// Q3's gate) [open: about 10 ms, more than the 1 ms now, to cover the pins' spread]. The USB socket and the jack are in the +x side wall, in its
// straight part, free both stored (the discant covers only the box's back) and played; a
// side-emitting LED beside them shows charging (red) and full (green) through a hole in the wall. The jack is a
// panel jack held by the side wall, over the board in a 5.7 mm bulge of the back cover.
//
// KEY BOARD [given 2026-11-13]: one Hall-sensor board under both rows (../hall_pcb/bass/):
// three ADS7128 ADCs at 10h..12h on the ESP32's second I2C bus (the discant's six use
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
// pads with M2 pilots into the front wall, placed clear of the former hand plate recess; with the
// back cover off they are screwed from the back. The power board goes in 2 mm to the
// left of its place and slides right, its socket into the port.
//
// make builds   openscad -o ../build/bass/elec.stl elec.scad

include <layout.scad>
include <../main_pcb/board.scad>
use <link.scad>

pcb_tk  = 1.0;
brd_y   = [plate_y[1] + 0.47, plate_y[1] + 0.47 + pcb_tk];   // -9.03 .. -8.03
pwr_x   = [box_x[1] - 2.45 - 45.5, box_x[1] - 2.45]; pwr_z = [-125.8, -92.8] + [ez, ez];   // main board: against the +x wall, under the strap's bar, the outer rib notched over it
// USB-C receptacle, top mount at the board's edge, its mouth 0.2 inside the wall's face
usb     = [7.35, 8.94, 3.26];               // along x (plugging), z, y
usb_z   = -104.5 + ez;
usb_x1  = box_x[1] - 0.2;
usb_yc  = brd_y[1] + usb[2] / 2;
// a recess in the wall's face round the port, as deep as the mouth lies inside it, so a
// plug's overmold reaches the socket's face [given 2026-11-20: 0 mm]: the USB Type-C spec's
// largest overmold 12.35 x 6.5, and 0.25 round it
usb_rec = [12.35 + 0.5, 6.5 + 0.5, box_x[1] - usb_x1];   // along z, y; depth
led_z   = mz(main_led_y);         // the charge light (red/green, side-emitting, ../main_pcb D1)
led_h   = 1.6;                    // its height; the lens at half of it [unverified: LTST-S326 datasheet]
// the main board's own frame (../main_pcb/design.py): X from its side wall's edge, Y up
function mx(X) = pwr_x[1] - X;
function mz(Y) = pwr_z[0] + Y;
pilots  = [for (h = main_holes) [mx(h[0]), mz(h[1])]];
wall_t  = 2;                     // the side wall (case.scad: wall)
// EARPHONE JACK [given 2026-11-15: a panel jack held by the case; a 5 mm bulge in the
// back cover for it]: Switchcraft 35PRM3 [datasheet: drawing 35PRM3 rev 0A], from inside
// screwed into a tapped M6 x 0.75 hole in the side wall and its boss [2026-11-25: was
// through the 2 mm wall with its knurled nut outside, the wall 1.5 under the nut; too weak
// for 20 N across the plug, and no 3.5 mm jack with a longer thread was found]. Its body lies over the main board (1.0
// clear under the flange), three wires down to the board's pads P19..P21.
jack_z    = mz(main_jack_y);     // its axis
jack_fl   = [9.5, 2.1];          // flange: diameter, length (against the wall's inside)
jack_body = [7.7, 13.4];         // body behind the flange
jack_lugs = [8.0, 5.8];          // solder lugs beyond the body [envelope estimated]
jack_thr  = [6.0, 3.5];          // M6 x 0.75, length: wall + nut at most 3.5
jack_tap  = 5.3;                 // tap drill for M6 x 0.75 (5.25), printed holes come out small; tapped after printing
// THE BOSS [2026-11-25]: outside on the side wall round the hole, jack_boss_t proud, so the
// thread (3.5) has wall + boss = 3.5 to bite into and ends flush with the boss. Round the
// jack's axis (jack_boss_r), inside the bulge's outline, and clear of the USB plug's
// overmold above it (usb_rec, 0.25 more each side)
jack_boss_t = 1.5;
jack_boss_r = 6.5;
jack_gap  = 1.0;                 // the flange over the board's top [given 2026-11-15: more than 0.3]
jack_yc   = brd_y[1] + jack_gap + jack_fl[0] / 2;   // its axis
jack_x1   = box_x[1] - wall_t;   // the wall's inside: the flange against it
jack_x0   = jack_x1 - jack_fl[1] - jack_body[1] - jack_lugs[1];   // the lugs' end
// the bulge: round the jack, the cover's wall back_t (case.scad) on 0.3 clear
jack_room_r = jack_fl[0] / 2 + 0.3;
jack_bump_r = jack_room_r + 1.6;
// the jack goes in from inside [2026-11-24: since the bulge's lower half is the case's,
// case.scad]: from behind, its bottom over the bulge's lower half, down into it jack_slide
// short of the wall, then slid +x through the hole. jack_slide: its thread (3.5) out of the
// hole, and its lugs clear of the main board's tall part at x 81.75 (more than 5.15 would
// touch it); the bulge is jack_slide longer for it
jack_slide = 5;
jack_bump_x0 = jack_x0 - 0.8 - 1.6 - jack_slide;
pad_d   = 4.5;

module bx(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

// the tab under the USB socket (../main_pcb/design.py USB_TAB), into a pocket of the side wall
tab_x  = [pwr_x[1], mx(main_usb_tab[0])];
tab_z  = [mz(main_usb_tab[1]), mz(main_usb_tab[2])];

module power_board() {
    difference() {
        union() {
            bx(pwr_x, brd_y, pwr_z);
            bx(tab_x, brd_y, tab_z);
        }
        for (p = pilots) translate([p[0], brd_y[0] - 1, p[1]]) rotate([-90, 0, 0]) cylinder(d = 2.2, h = 3, $fn = 16);
    }
    // its parts, from KiCad (../main_pcb/board.scad); the socket and the jack drawn below
    for (p = main_parts) if (p[0] != "J1")
        bx([mx(p[3]), mx(p[1])], [brd_y[1], brd_y[1] + p[5]], [mz(p[2]), mz(p[4])]);
    jack();
    // USB-C, its shell rounded at the ends as the real one
    translate([usb_x1 - usb[0], usb_yc, usb_z]) rotate([0, 90, 0]) linear_extrude(usb[0])
        offset(r = 1.2) offset(delta = -1.2) square([usb[1], usb[2]], center = true);
}
// cut from the case: the port and the light through the +x side wall; the pilots
module elec_cuts() {
    translate([box_x[1] - 3, usb_yc, usb_z]) rotate([0, 90, 0]) linear_extrude(4)
        offset(r = 1.2) offset(delta = -1.2) square([usb[1] + 0.5, usb[2] + 0.5], center = true);
    translate([box_x[1] - usb_rec[2], usb_yc, usb_z]) rotate([0, 90, 0]) linear_extrude(usb_rec[2] + 1)
        offset(r = 1.2) offset(delta = -1.2) square([usb_rec[0], usb_rec[1]], center = true);
    // the pocket for the board's tab [given 2026-11-18: way B]: fit all round; the board slides
    // into it with the socket into its port (back cover off, the board 2 mm off the wall first)
    bx([pwr_x[1] - 1, tab_x[1] + fit], [brd_y[0] - fit, brd_y[1] + fit], [tab_z[0] - fit, tab_z[1] + fit]);
    translate([box_x[1] - 3, brd_y[1] + led_h / 2, led_z]) rotate([0, 90, 0]) cylinder(d = 1.6, h = 4, $fn = 16);
    jack_cuts();
    for (p = pilots) translate([p[0], plate_y[1] - 2.0, p[1]]) rotate([-90, 0, 0]) cylinder(d = 1.7, h = 3, $fn = 16);
}
// the jack: lugs, body, flange inside; thread through the wall; the nut outside
module jack() translate([0, jack_yc, jack_z]) rotate([0, 90, 0]) {
    translate([0, 0, jack_x0]) cylinder(d = jack_lugs[0], h = jack_lugs[1] + 0.01, $fn = 24);
    translate([0, 0, jack_x0 + jack_lugs[1]]) cylinder(d = jack_body[0], h = jack_body[1] + 0.01, $fn = 32);
    translate([0, 0, jack_x1 - jack_fl[1]]) cylinder(d = jack_fl[0], h = jack_fl[1], $fn = 32);
    translate([0, 0, jack_x1]) cylinder(d = jack_thr[0], h = jack_thr[1], $fn = 32);
}
// added to the case's outline: the bulge, round the jack's axis down into the box
module jack_bump() hull() {
    translate([jack_bump_x0, jack_yc, jack_z]) rotate([0, 90, 0]) cylinder(r = jack_bump_r, h = box_x[1] - jack_bump_x0, $fn = 48);
    translate([jack_bump_x0, brd_y[1], jack_z - jack_bump_r]) cube([box_x[1] - jack_bump_x0, 1, 2 * jack_bump_r]);
}
// added to the case's outline: the boss round the tapped hole
module jack_boss() translate([box_x[1] - 0.01, 0, 0]) rotate([90, 0, 90]) linear_extrude(jack_boss_t + 0.01) difference() {
    translate([jack_yc, jack_z]) circle(r = jack_boss_r, $fn = 64);
    translate([usb_yc - usb_rec[1] / 2 - 0.25, usb_z - usb_rec[0] / 2 - 0.25]) square([usb_rec[1] + 0.5, 50]);
}
// cut from the case: the room in the bulge and the tapped hole through wall and boss
module jack_cuts() translate([0, jack_yc, jack_z]) rotate([0, 90, 0]) {
    hull() {
        translate([0, 0, jack_bump_x0 + 1.6]) cylinder(r = jack_room_r, h = jack_x1 - jack_bump_x0 - 1.6, $fn = 48);
        // down to the board, not into the front wall
        translate([0, -(jack_yc - jack_room_r - brd_y[0]), jack_bump_x0 + 1.6]) cylinder(r = jack_room_r, h = jack_x1 - jack_bump_x0 - 1.6, $fn = 48);
    }
    translate([0, 0, jack_x1 - 1]) cylinder(d = jack_tap, h = wall_t + jack_boss_t + 2, $fn = 32);
    // the thread's way down, jack_slide short of the wall: through the side wall's inner
    // corner rounding above the bulge, inside the back wall's line (the cover's stays whole)
    intersection() {
        hull() for (u = [0, 9]) translate([-u, 0, jack_x1 - jack_slide - 0.3]) cylinder(r = jack_thr[0] / 2 + 0.4, h = jack_slide + 0.31, $fn = 32);
        translate([-20, -20, jack_x1 - jack_slide - 1]) cube([20.01, -(jack_yc - (box_back - back_t)) + 20, jack_slide + 2]);
    }
}
// which of the bulge is the back cover's: all but the side wall, which carries the jack
// (so the cover comes off with the jack in place)
// [corner, size]; also for case.scad's back cover, which stands cov_gap back from the case
function jack_cover_box() = [[jack_bump_x0 - 1, box_back - back_t, jack_z - jack_bump_r - 1], [jack_x1 - jack_bump_x0 + 1, 30, 2 * jack_bump_r + 2]];
// the jack's axis (y, z) and the bulge's outer radius, for case.scad's bulge sweep
function jack_bump_yzr() = [jack_yc, jack_z, jack_bump_r];
// the jack's lengths along x and radii, for case.scad's cradle: [lugs' end, body's start,
// flange's start, body r, lugs r, room r, jack_slide]
function jack_dims() = [jack_x0, jack_x0 + jack_lugs[1], jack_x1 - jack_fl[1], jack_body[0] / 2, jack_lugs[0] / 2, jack_room_r, jack_slide];
// the jack without its nut, for the checks of putting it in
module jack_bare() jack();   // it has no nut any more
module jack_cover_zone() translate(jack_cover_box()[0]) cube(jack_cover_box()[1]);
// the main board's lowest screw lies below z_split, behind the case's strip: case.scad
// cuts a hole in the strip in front of it, so a screwdriver reaches it [given 2026-11-15:
// all screws reachable] (until 2026-11-24 that piece of the strip was the cover's)
low_hole = [for (h = main_holes) if (h[1] == min([for (q = main_holes) q[1]])) h][0];
function screw_cover_box() = [[mx(low_hole[0]) - 3.5, box_back - back_t, mz(low_hole[1]) - 3.5], [7, 30, 7]];
module screw_cover_zone() translate(screw_cover_box()[0]) cube(screw_cover_box()[1]);
module jack_wall_zone() translate([jack_x1, -50, jack_z - jack_bump_r - 1]) cube([10, 100, 2 * jack_bump_r + 2]);

// cut from the case's ribs: the main board's room, front to back
module main_board_room() translate([pwr_x[0] - 1, plate_y[1] - 1, pwr_z[0] - 1]) cube([pwr_x[1] - pwr_x[0] + 2, 20, pwr_z[1] - pwr_z[0] + 2]);
// added to the case: the boards' pads
module elec_pads() for (p = pilots) difference() {
    translate([p[0], plate_y[1] - 0.01, p[1]]) rotate([-90, 0, 0]) cylinder(d = pad_d, h = 0.48, $fn = 24);
    translate([p[0], plate_y[1] - 2.0, p[1]]) rotate([-90, 0, 0]) cylinder(d = 1.7, h = 3, $fn = 16);
}

module elec() { power_board(); }   // the contacts' spring pins: link.scad, contact_pins()

// a round bundle through points
module bundle(p, d) for (i = [0 : len(p) - 2]) hull() {
    translate(p[i]) sphere(d = d, $fn = 12); translate(p[i + 1]) sphere(d = d, $fn = 12);
}
// where the key board's bus wires leave J1's plug (4.25 header and the plug below the board)
plug_out = [hall_conn[0], hall_conn[1], board_bot - 6.0];
wire_zb = z_bot + 3.3;                  // the bore and the slot under the case's foot (link.scad, case.scad)
// the wires' ways as point lists, so the cable list (../assembly/spec.md, Wiring) takes its lengths from them
function pins_pts() = [[-1.748 + ex, 4.19, z_bot + 5.9], [-1.748 + ex, 4.19, wire_zb], [-1.748 + ex, wire_y, wire_zb]];   // all nine, out of the mount
// to the main board: along the bottom to below its solder pads (P1..P18, X 1..17), then up to
// them; kept off the lowest screw's way [given 2026-11-15: all screws reachable]
function main_leg_pts() = [pins_pts()[2], [mx(9), wire_y, wire_zb], [mx(9), brd_y[1] + 1.2, mz(1.9)]];
// the key board's bus: straight down from J1's plug, over the strap bar's block (top -44.5),
// down beside the battery, to the bottom bundle (listed from the join up to the plug)
function key_pts() = [pins_pts()[2], [-54.7 + ex, wire_y, wire_zb], [-54.7 + ex, wire_y, -43], [plug_out[0], wire_y, -41.5],
                      [plug_out[0], plug_out[1], plug_out[2] - 2], plug_out];
function path_len(p) = len(p) < 2 ? 0 : norm(p[1] - p[0]) + path_len([for (i = [1 : len(p) - 1]) p[i]]);
module wires() {
    bundle(pins_pts(), 2.0);
    bundle(main_leg_pts(), 1.8);
    bundle(key_pts(), 1.8);
    echo(str("wire lengths: contacts to main board ", path_len(pins_pts()) + path_len(main_leg_pts()),
             ", key board J1 to main board ", path_len(key_pts()) + path_len(main_leg_pts()),
             " (shared leg ", path_len(main_leg_pts()), ")"));
}

part = "elec";
if (part == "elec") elec();
if (part == "wires") wires();

