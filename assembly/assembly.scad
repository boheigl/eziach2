// Discant and bass together, in the bass's frame (../bass/layout.scad): the discant
// is moved by ../bass/link.scad's to_bass(), which mates the gauges' plates (the
// discant's) with their inner holders (the bass's). Turned 180 deg about z: the
// gauges point along the bass's y and sense along its z [given].
//
// The pieces for the phone page, one per part = ...; the keys are drawn light (cap,
// skirt, pin) so that the page stays small.
//
// STORED [given: plugged, two positions; stored, the bass covers the discant's keys]:
// the discant off the playing mount, turned 90 deg about x and back by its slope
// (10.62 deg; its gauges lie in that slope's plane), pushed straight up into the short
// socket under the bass's deck (../bass/link.scad: to_store()). Its keys lie parallel
// to the box's back wall, 1 mm off it. Latched in both positions (inner_holder.scad).
//
// make builds them into ../build/assembly/ (see Makefile).

use <../bass/link.scad>
include <../bass/layout.scad>

part = "d_housing";
D = "../build/discant/";

// a key at rest, light: cap, skirt and pin; its frame as ../switch_hall/key.scad
// (cap top at top over the board's middle, skirt sl long)
module key(top, sl) {
    $fn = 24;
    translate([0, 0, top - 2]) cylinder(d = 15, h = 2);
    translate([0, 0, top - 2 - sl]) difference() { cylinder(d = 12.4, h = sl); translate([0, 0, -1]) cylinder(d = 10.8, h = sl + 2); }
    translate([0, 0, top - 12]) cylinder(d = 3.6, h = 10);
}
// the discant's 46 keys: row k at k * (10, 16, 3), 13 - k keys from x = -120 + 10 k
// (../discant/hall.scad); cap top 15.066, skirt 6.55 (key.scad with the board's tilt)
module keys_discant() for (k = [0 : 3], i = [0 : 12 - k]) translate([-120 + 20 * i + 10 * k, 16 * k, 3 * k]) key(15.066, 6.55);
// the bass's 18: the back row's 10 higher (key_riser), skirt 7.3 (key.scad, board flat)
module keys_bass() for (k = [0, 1], i = [0 : n_row - 1]) translate(at_key(k, i)) key(key_top + k * key_riser, 7.3);

module d_all() for (f = ["housing", "cover", "board", "board_parts", "gauge_link"]) import(str(D, f, ".stl"));

if (part == "d_housing") to_bass() import(str(D, "housing.stl"));
if (part == "d_cover")   to_bass() import(str(D, "cover.stl"));
if (part == "d_boards")  to_bass() import(str(D, "board.stl"));
if (part == "d_parts")   to_bass() import(str(D, "board_parts.stl"));
if (part == "d_cables")  to_bass() import(str(D, "gauge_link.stl"));  // gauges, link board, wires
if (part == "keys_discant") to_bass() keys_discant();
if (part == "keys_bass") keys_bass();
// for the clash checks: the whole discant, played and stored
if (part == "d_played") to_bass() { d_all(); keys_discant(); }
if (part == "store_discant") to_store() { d_all(); keys_discant(); }
