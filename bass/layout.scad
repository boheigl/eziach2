// Bass: what all the bass's parts share. Taken from the example (ref/: the earlier
// BassCase) [given]: only the key arrangement and the hand plate's flat middle part.
//
// Frame: x along the rows, y from the hand plate towards the back, z up.

// --- keys: the example's arrangement
pitch    = 20;
rows_y   = [0, 14];              // front, back [given 2026-11-21: 14, was 16; the fingers' way as on a real
                                 //   instrument: the old BassCase's caps sat 1.5 off their axes towards each other]
rows_x0  = [-80, -70];           // first key of each row; 9 per row [given: 2 x 9]: the
n_row    = 9;                    //   example's 8 + 8, its half-closed front-left well and an added x = 90
cap_top  = [11, 21];             // cap tops at rest: the example's short and tall keys

// --- the keys: ../switch_hall/ (Hall sensor, spring under the cap) [given 2026-11-13], on
// one Hall-sensor board under both rows (../hall_pcb/bass/), lying flat (key.scad with
// board_tilt = 0). The back row's spring seat, tube top and all above it stand
// key_riser higher (key.scad riser), so its caps reach the example's 21 with the same
// board; collar, magnet and sensor keep their place at the board.
key_top   = 17.135;              // key.scad, board_tilt = 0: cap top over the board's middle (with the 4 mm bronze bushing)
key_riser = 10;
assert(abs(cap_top[1] - cap_top[0] - key_riser) < 1e-6, "the back row's riser must match the caps");
cover_t  = 2.4;                  // [given 2026-11-14: thicker, 1.2 before]
pcb_t    = 1.6;
cu_t     = 0.035;
stroke   = 3;
board_mid = cap_top[0] - key_top;               // -3.635: the board's middle plane
board_top = board_mid + pcb_t / 2 + cu_t;        // -2.8
board_bot = board_mid - pcb_t / 2 - cu_t;
board_z  = [board_mid, board_mid];               // per row, for code that indexes rows
cover_top = [board_top + cover_t, board_top + cover_t + key_riser];   // front slab, back step

// --- the hand plate: the example's flat middle part, half as wide [given], 131.5 x 128.3;
// its top flush with the front cover [given 2026-11-14: no raised edge over the cover],
// which lies 6.6 lower against the caps than before, since the new keys stand taller
plate_w  = 263 / 2;
plate_y  = [-12.5, -9.5];        // the front wall, 3 thick; the hand presses on y = -12.5
plate_top0 = 5.035;              // the old front cover's top: the plate's height and the old bottom follow from it
plate_h  = 0.75 * (166 + plate_top0);   // the example's height (z -166 to the front cover) less 25 % [given]
plate_z  = [cover_top[0] - plate_h, cover_top[0]];
plate_rise = plate_z[1] - cover_top[0];   // 0

gap      = 0.1;                  // housing to the boards' undersides
fit      = 0.3;

// --- the board: ../hall_pcb/bass/ (its data from the routed KiCad board): board frame
// X = x, Y = y, its middle at board_mid; the tray round it as the discant's (part_gap
// under the tallest part but the plug, case_fit and a case_wall rim)
include <../hall_pcb/bass/board.scad>
case_fit   = 0.3;
case_wall  = 1.2;
case_rim   = case_fit + case_wall;
part_gap   = 0.3;
case_floor = 1.2;
h_max  = max([for (q = hall_parts) if (q[0] != "J1") q[6]]);
w_ft   = board_bot - h_max - part_gap;          // the tray's floor, top (z)
z_floor = w_ft - case_floor;                    // the deck's underside
hx = [for (q = hall_outline) q[0]];
hy = [for (q = hall_outline) q[1]];

// --- the deck and the box below it: one rectangular block [given 2026-11-14: a
// rectangular footprint; stored, not all of the discant's keys need be covered], as
// narrow as the strap allows: its outer slots end 100 from the middle, 1.5 inside the
// front face's rounded edge (case.scad), so 211 wide; the board (with its rim) is
// narrower and lies in the middle
end_wall = 1.2;
deck_core = [min(hx) - case_rim, max(hx) + case_rim];   // the board and its rim
x_mid    = (deck_core[0] + deck_core[1]) / 2;
box_w    = max(deck_core[1] - deck_core[0], 2 * (100 + 1.5 + 4));
deck_x   = [x_mid - box_w / 2, x_mid + box_w / 2];
// the box, hand plate, strap and mount are centred on the deck; what was placed by hand
// on the old deck's middle (x -1.75, two sawn boards with their connector ends) moves
// with it by ex
ex       = x_mid + 1.75;
plate_x  = [(deck_x[0] + deck_x[1]) / 2 - plate_w / 2, (deck_x[0] + deck_x[1]) / 2 + plate_w / 2];   // centred on the deck
box_x    = deck_x;                    // straight sides, flush with the deck's ends
bottom_x = box_x;
function box_x_at(z) = box_x;
// THE BOX'S LENGTH, from the stored discant (link.scad: to_store()) [2026-11-14: the thin
// discant]: its short socket hangs right under the deck (its top store_socket_top over
// to_store()'s origin, measured from the build); the discant below it, and under its
// lowest point over the playing mount (store_front_d: the thumb bar, whole [given
// 2026-11-14: never cut, the bass is longer instead]) the travel to slide it on and off
// plus 0.3 over the mount's holders and their latches' lugs (hold_lo + hold_hi), which sit at the box's bottom.
// That fixes the bottom: 9.8 below the hand plate (7.7 before the latches' lugs for the
// rod raised the mount's top by 2.1, 2026-11-15). As link.scad:
// hold_lo, hold_hi, travel, front_d.
store_socket_top = 90.69;
store_front_d    = -16.47;
store_z  = z_floor + 0.5 - store_socket_top;             // to_store()'s z: the socket 0.5 into the deck's floor, one body with it
z_bot    = store_z - (5.9 + 9.0 + 0.3 + (8.3 + 1) - store_front_d);
box_ext  = plate_z[0] - z_bot;
assert(box_ext >= 2, "the box's bottom must stay under the hand plate");
// what was placed by hand in the box's lower part on the old bottom (z -130.84) moves with it
ez       = z_bot - (plate_top0 - 0.75 * (166 + plate_top0) - 7.6);
// below the deck the box is thin [given: thinner, gauges in the step behind it]: from the
// hand's face to box_back; the deck above keeps its full depth, and behind the box,
// under the deck, is the step where the gauges sit. 11.2 [given: 4.8 thinner, so that
// the stored discant comes 4.8 closer]: front wall 3, a 6 mm battery with 0.3 each side,
// back wall back_t
box_depth = 11.2;
box_back  = plate_y[0] + box_depth;
back_t    = 1.6;
// the wires' bundles (elec.scad wires()) run at this y, close under the back cover, in
// notches at the ribs' back edges (case.scad), so the ribs stay whole along the front
// wall [given 2026-11-15: the wires' way cut the ribs through]
wire_y    = box_back - back_t - 1.6;
// to the back: 0.9 of wall behind the back board's tab; the stored discant's gauge pocket
// (link.scad) reaches y 24.65, 3.2 inside
// to the back: the board's rim, or the stored discant's socket under the deck (link.scad,
// its holders' walls reach y 25.89), whichever is further: nothing stands out behind the cover
deck_y   = [plate_y[1], max(max(hy) + case_rim, 25.9)];
riser_y  = 9.8;                  // front of the back step: 2.3 clear of the front caps [given: >= 2]
step_wall = 1.2;                 // the cover's wall up the step, one piece with both slabs [given]
step_y   = riser_y + step_wall;  // where the back block begins
assert(min(hy) - case_rim >= plate_y[1] - 0.01, "the board's rim runs into the front wall");

function key_xy(k, i) = [rows_x0[k] + i * pitch, rows_y[k]];
function at_key(k, i) = [key_xy(k, i)[0], key_xy(k, i)[1], board_mid];   // key k, i's frame (key.scad)
module board2d(g = 0) offset(delta = g) polygon(hall_outline);
