// The Hall-sensor board (../hall_pcb/bass/) in the case's frame: part = "boards" the
// laminate with its holes, "connectors" the parts' bodies on its underside (boxes from
// the KiCad board).
//
// make builds   openscad -o ../build/bass/boards.stl array.scad
include <layout.scad>
part = "boards";
if (part == "boards") translate([0, 0, board_bot]) linear_extrude(board_top - board_bot) difference() {
    board2d();
    for (h = hall_holes) translate(h) circle(d = hall_hole_d, $fn = 24);
}
if (part == "connectors") for (q = hall_parts) if (q[1] == "B")
    translate([q[2], q[3], board_bot - q[6]]) cube([q[4] - q[2], q[5] - q[3], q[6]]);
