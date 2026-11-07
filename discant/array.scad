// Four switch boards, arranged as a staircase
//
// Board k (k = 0 .. 3) is the complete board of pcb.scad with its button
// assembly, guide tube and spring from button.scad, moved by
// k * (pitch_x, pitch_y, pitch_z): half the hole pitch along the row, 16 mm
// across it and 3 mm up, so each board rises towards the +y (connector) side.
// The boards stay parallel to each other.
//
// Board k has 13 - k holes (13, 12, 11, 10): it is the same board with k holes
// sawn off at the +x end (pcb.scad, cut_holes = k; pcb.stl, pcb_12.stl,
// pcb_11.stl, pcb_10.stl). With the 10 mm shift, both ends of the staircase
// step in by 10 mm per board.
//
// The parts are taken from the rendered STLs (render pcb.scad and button.scad
// first); the moving parts are at the upper stop.
//
// AS SPECIFIED THE NEIGHBOURS CLASH (measured by grid sampling, 0.1 mm):
//   guide tube of board k+1   through the tab and the connector body of board k
//   washers, sleeve, screw, spring of board k+1   into the tab / connector of board k
//   button cap of board k     0.5 mm into the -y edge of board k+1
//   and the FFC leaving board k's vertical connector downwards runs into
//   board k+1's guide tube
// Boards two or more apart do not touch.
//
// Built by make as ../build/discant/array.stl, from the key's part STLs in
// ../build/switch/ (see Makefile; ../switch/ makes them).

n_boards = 4;
pitch_x  = 10;    // half the hole pitch
pitch_y  = 16;
pitch_z  = 3;

stl_dir = "../build/switch/";   // the key's part STLs, made by make in ../switch/

boards = ["pcb.stl", "pcb_12.stl", "pcb_11.stl", "pcb_10.stl"];   // 13 - k holes
parts  = ["pcb_connector.stl", "button.stl", "felt.stl", "washer.stl",
          "sleeve.stl", "screw.stl", "guide.stl", "spring.stl"];

for (k = [0 : n_boards - 1])
    translate(k * [pitch_x, pitch_y, pitch_z]) {
        import(str(stl_dir, boards[k]));
        for (p = parts) import(str(stl_dir, p));
    }
