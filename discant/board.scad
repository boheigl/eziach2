// The discant's Hall-sensor board for the assembly and the phone page: part = "board"
// the laminate with its holes, "parts" the parts' bodies on its underside (boxes from
// the KiCad board, hall.scad); "all" both.
//
// make builds   openscad -o ../build/discant/board.stl -D 'part="board"' board.scad
//               openscad -o ../build/discant/board_parts.stl -D 'part="parts"' board.scad

include <hall.scad>

part = "all";

if (part == "board" || part == "all") on_slab() translate([0, 0, -hall_t]) linear_extrude(hall_t) difference() {
    polygon(hall_outline);
    for (h = hall_holes) translate(h) circle(d = hall_hole_d, $fn = 24);
}
if (part == "parts" || part == "all") on_slab() hall_bodies(0);
