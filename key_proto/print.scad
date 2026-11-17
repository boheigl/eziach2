// The prototype's printed parts, each turned as it is printed (flat face down);
// plate.py then sets each on the bed, centres it and arranges the X2D's plate
// (../build/key_proto/plate.3mf).
//
// tray   bottom down: the bottom is parallel to the slope, so the slab frame is undone
// board  flat
// cover  underside down (the plate's flat face, W = 0): tubes, shrouds and countersinks
//        stand up; the tubes lean 10.6 deg (the keys are vertical on the slope), no support
// cap    top down: skirt, rod socket and O-ring seat open upwards
// collar magnet pocket up: the first layers (elephant foot) land on the rod's end,
//        where the epoxy takes up a little, not on the magnet's press fit
// tube   fit test: one key's piece of cover (key.scad part "tube"), underside down
//
// make builds   ../build/key_proto/print_<part>.stl (Makefile), then plate.py

use <proto.scad>

part = "cover";      // tray, board, cover, cap, collar, tube

// fine circles for the press fits (bushing seat, rod socket, magnet pocket), as key.scad;
// use <> does not carry proto.scad's own $fa / $fs over
$fa = 2; $fs = 0.1;

key_ztop = 0.835;            // as proto.scad
slab_t   = atan(3 / 16);

// the slab frame back to level: inverse of proto.scad's on_slab()
module off_slab() rotate([-slab_t, 0, 0]) translate([0, 0, -key_ztop]) children();

if (part == "tray")        off_slab() base();
else if (part == "board")  off_slab() board();
else if (part == "cover")  off_slab() cover();
else if (part == "cap")    rotate([180, 0, 0]) import("../build/key_proto/cap.stl");
else if (part == "collar") rotate([180, 0, 0]) import("../build/key_proto/collar.stl");
else if (part == "tube")   import("../build/key_proto/tube.stl");
