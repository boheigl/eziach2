// The two 9-hole boards with their connectors, in the case's frame.
//
// make builds   openscad -o ../build/bass/boards.stl array.scad
include <layout.scad>
part = "boards";
B = "../build/bass/"; K = "../build/switch/";
for (k = [0, 1]) translate(at_board(k)) {
    if (part == "boards") import(str(B, "pcb_board_9.stl"));
    if (part == "copper") import(str(B, "pcb_copper_9.stl"));
    if (part == "boards" || part == "connectors") import(str(K, "pcb_connector.stl"));
}
