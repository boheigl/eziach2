// Bass: what all the bass's parts share. Taken from the example (ref/: the earlier
// BassCase) [given]: only the key arrangement and the hand plate's flat middle part.
//
// Frame: x along the rows, y from the hand plate towards the back, z up.

// --- keys: the example's arrangement
pitch    = 20;
rows_y   = [0, 16];              // front, back
rows_x0  = [-80, -70];           // first key of each row; 9 per row [given: 2 x 9]: the
n_row    = 9;                    //   example's 8 + 8, its half-closed front-left well and an added x = 90
cap_top  = [11, 21];             // cap tops at rest: the example's short and tall keys

// --- the discant's mechanism (switch/button.scad): the felt lands on a 1.2 cover on the board
cover_t  = 1.2;
pcb_t    = 1.6;
cu_t     = 0.035;
stroke   = 2.965;
cap_above = cover_t + stroke + 1 + 2;          // board top to cap top at rest: cover, stroke, felt, cap
board_top = [for (c = cap_top) c - cap_above]; // 3.835, 13.835: the back row 10 higher
board_z  = [for (t = board_top) t - cu_t - pcb_t / 2];
cover_top = [for (t = board_top) t + cover_t];

// --- the hand plate: the example's flat middle part, half as wide [given]
plate_w  = 263 / 2;
plate_y  = [-12.5, -9.5];        // the front wall, 3 thick; the hand presses on y = -12.5
plate_h  = 0.75 * (166 + cover_top[0]);   // the example's height (z -166 to the front cover) less 25 % [given]
plate_z  = [cover_top[0] - plate_h, cover_top[0]];   // flush with the front cover at the top

gap      = 0.1;                  // housing to the boards' undersides
fit      = 0.3;

// --- the boards: the discant's board sawn to 9 holes (pcb.scad, cut_holes = 4)
board_dx = [for (k = [0, 1]) rows_x0[k] + 120];   // hole 1 of 13 at x = -120: 40, 50
x_start  = -145.796;             // as pcb.scad
x_cut    = 52.3;
margin_n = 5.3;
margin_p = 9.4;
tab_x1   = -142.038;
tab_y    = 10.6;
screws   = [-142, -50, 50];      // per board, board frame, on the row line: M2 from the top

// --- the deck: the block behind the plate's top edge, as short in x as the boards
// allow [given]: their ends, fit, and a wall as the discant's cover
end_wall = 1.2;
deck_x   = [min([for (k = [0, 1]) x_start + board_dx[k]]) - fit - end_wall,
            max([for (k = [0, 1]) x_cut + board_dx[k]]) + fit + end_wall];
plate_x  = [(deck_x[0] + deck_x[1]) / 2 - plate_w / 2, (deck_x[0] + deck_x[1]) / 2 + plate_w / 2];   // centred on the deck
// the box below the deck: straight sides, wide enough to cover the discant's 46 keys
// (255 wide) when it is stored in the step [given: widen the box, keys covered]; it no
// longer tapers. box_x is centred on the deck, which keeps its width.
box_w    = 265;
box_x    = [(deck_x[0] + deck_x[1]) / 2 - box_w / 2, (deck_x[0] + deck_x[1]) / 2 + box_w / 2];
bottom_x = box_x;
// its sides run parallel to the stored discant's ends [given]: each row of the discant is
// a key shorter and steps in 10 at both ends, 16.28 apart along its slope; stored
// (link.scad) the rows' end caps sit at z -94.2 (row 0) and up by 16.28 each, at x
// -121.75 + 10 k and 118.25 - 10 k. So the box is straight (box_x) up to box_slant_z and
// above that slants in, tangent 5 mm off those caps (12.5 round their centres), up to
// the deck, which stands out over it at the top.
box_slant   = 10 / sqrt(16 * 16 + 3 * 3);
box_slant_z = -94.2 + (12.5 / cos(atan(box_slant)) - 12.5) / box_slant;
function box_x_at(z) = let(c = (deck_x[0] + deck_x[1]) / 2,
                           h = min(box_w / 2, box_w / 2 + (12.5 / cos(atan(box_slant)) - 12.5) - box_slant * (z + 94.2)))
    [c - h, c + h];
// longer than the hand plate at the bottom: room for the stored discant's travel onto its
// short socket under the deck (link.scad): 3 [given: +3 mm], and 2.3 more for the
// socket's latch [given: latch in both positions]
box_ext  = 5.3;
z_bot    = plate_z[0] - box_ext;
// below the deck the box is thin [given: thinner, gauges in the step behind it]: from the
// hand's face to box_back; the deck above keeps its full depth, and behind the box,
// under the deck, is the step where the gauges sit. 11.2 [given: 4.8 thinner, so that
// the stored discant comes 4.8 closer]: front wall 3, a 6 mm battery with 0.3 each side,
// back wall back_t
box_depth = 11.2;
box_back  = plate_y[0] + box_depth;
back_t    = 1.6;
// to the back: 0.9 of wall behind the back board's tab; the stored discant's gauge pocket
// (link.scad) reaches y 24.65, 3.2 inside
deck_y   = [plate_y[1], 27.8];
riser_y  = 9.8;                  // front of the back step: 2.3 clear of the front caps [given: >= 2]
step_wall = 1.2;                 // the cover's wall up the step, one piece with both slabs [given]
step_y   = riser_y + step_wall;  // where the case's back block begins

function key_xy(k, i) = [rows_x0[k] + i * pitch, rows_y[k]];
function at_board(k) = [board_dx[k], rows_y[k], board_z[k]];
module board2d() union() {
    translate([x_start, -margin_n]) square([x_cut - x_start, margin_n + margin_p]);
    translate([x_start, 0]) square([tab_x1 - x_start, tab_y]);
}
