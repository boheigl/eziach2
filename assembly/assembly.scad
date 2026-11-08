// Discant and bass together, in the bass's frame (../bass/layout.scad): the discant
// is moved by ../bass/link.scad's to_bass(), which mates the gauges' plates (the
// discant's) with their inner holders (the bass's). Turned 180 deg about z: the
// gauges point along the bass's y and sense along its z [given].
//
// The pieces for the phone page, one per part = ...; the keys are drawn light (stem,
// felt, cap) so that the page stays small.
//
// STORED [given: plugged, two positions; stored, the bass covers the discant's keys]:
// the discant off the playing mount, turned 90 deg about x and back by its slope
// (10.62 deg; its gauges lie in that slope's plane), pushed straight up into the short
// socket under the bass's deck (../bass/link.scad: to_store()). Its keys lie parallel
// to the box's back wall, 1 mm off it. Package 282.9 x 40.3 x 149.5 mm (1.7 L). Latched in both positions (inner_holder.scad).
//
// make builds them into ../build/assembly/ (see Makefile).

use <../bass/link.scad>
include <../bass/layout.scad>

part = "d_housing";
D = "../build/discant/"; K = "../build/switch/";
boards  = ["pcb_board.stl", "pcb_board_12.stl", "pcb_board_11.stl", "pcb_board_10.stl"];
coppers = ["pcb_copper.stl", "pcb_copper_12.stl", "pcb_copper_11.stl", "pcb_copper_10.stl"];
step = [10, 16, 3];

// a key at rest, in its board's frame (as switch/button.scad): stem, felt, cap
module key() {
    $fn = 24;
    translate([0, 0, -0.835]) cylinder(d = 7.6, h = 6.835);
    translate([0, 0, 5]) cylinder(d = 15, h = 1);
    translate([0, 0, 6]) cylinder(d = 15, h = 2);
}

if (part == "d_housing") to_bass() import(str(D, "housing.stl"));
if (part == "d_cover")   to_bass() import(str(D, "cover.stl"));
if (part == "d_boards")  to_bass() for (k = [0 : 3]) translate(k * step) import(str(K, boards[k]));
if (part == "d_copper")  to_bass() for (k = [0 : 3]) translate(k * step) import(str(K, coppers[k]));
if (part == "d_conn")    to_bass() for (k = [0 : 3]) translate(k * step) import(str(K, "pcb_connector.stl"));
if (part == "d_main")    to_bass() { import(str(D, "main_pcb_laminate.stl")); import(str(D, "main_pcb_parts.stl")); }
if (part == "d_main_cu") to_bass() import(str(D, "main_pcb_copper.stl"));
if (part == "d_cables")  to_bass() { import(str(D, "pcb_cable.stl")); import(str(D, "gauge_link.stl")); }
module keys_discant() for (k = [0 : 3], i = [0 : 12 - k]) translate(k * step + [-120 + 20 * i, 0, 0]) key();
module keys_bass() for (k = [0, 1], i = [0 : n_row - 1]) translate([key_xy(k, i)[0], key_xy(k, i)[1], board_z[k]]) key();
if (part == "keys_discant") to_bass() keys_discant();
if (part == "keys_bass") keys_bass();

B = "../build/bass/";
if (part == "store_discant") to_store() { for (f = ["housing", "cover", "gauge_link"]) import(str(D, f, ".stl")); keys_discant(); }
