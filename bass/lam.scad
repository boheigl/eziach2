// the boards' laminate alone, for the phone page
include <layout.scad>
B = "../build/bass/";
for (k = [0, 1]) translate(at_board(k)) import(str(B, "pcb_board_9.stl"));
