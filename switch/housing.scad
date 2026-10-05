// Housing for the four-board staircase
//
// One closed, 3D-printed body under the four boards of array.scad. Each board
// rests on its own step of the body, and every hole of every board (13 + 12 +
// 11 + 10 = 46) gets a cylindrical guide bored into it, the same as the single
// guide tube of button.scad: d9.4 for the washers, down to a d8.6 pocket that
// centres the spring and carries it.
//
// The floor is one flat plane, parallel to the step edges: it rises with the
// staircase, 4 mm in z per 17 mm in y. Since every board sits 4 mm higher per
// 17 mm, the spring seats all lie on such a plane too, so the floor is equally
// far below each of them. Its height is set so that it stays floor_min below
// the deepest point of every bore.
//
// Shape of the body. Seen from above, under each board k it covers the part of
// the board that is not already over board k-1 (the lower one), and its top
// there is board k's underside (less a small gap). Where board k-1 reaches under
// board k, board k-1's step continues, so the body never rises between two
// boards and each board can be laid in from above. The connector of each board
// sits in a pocket at the board's -x end (turned, its long side along y), with
// a slot below it through the floor for the FFC, which leaves the vertical
// connector downwards. Board 0's slot is closed (ffc_slot): its FFC is to run
// in an open trough to the back of the housing instead (cabling/, in progress).
//
// The connectors sit at the -x ends of the boards, where no higher board and
// no guide lies above them, so every guide is closed all round. The thinnest
// walls are about 0.7 mm: between each connector pocket and the guide of the
// board's hole 1, and between the guides of board k+1 and the edge of board k.
//
// HOLDING THE BOARDS. The boards, buttons and cover go onto the housing as one
// unit: each board is laid into the upside-down cover (cover.scad), which
// locates it with ribs on all sides; the buttons are pushed through cover and
// board from the cover side, and washers, sleeve and screw go on from below.
// The FFCs are plugged in, the unit is set onto the housing with each FFC fed
// down through its slot, and the cover is screwed through each board into the
// housing at four points on the row line (y = 0): one near each board end and
// two between them, with M2 countersunk self-tapping screws. The springs then press each board up against the
// cover through the upper washer; the middle screws keep the cover from bowing
// up under that load. The housing steps sit 0.1 below the boards and carry them
// when a button is pressed.
//
// Coordinates as everywhere: board 0's frame, origin at its centre, z up.
//
// Render with  openscad -o housing.stl housing.scad


/* [Boards — as in pcb.scad / array.scad, do not edit here] */
pcb_t   = 1.6;
cu_t    = 0.035;
n       = 13;
pitch   = 20;
margin  = 12.3;   // last hole centre to the +x end (end screw half a pitch past it + 2.3)
margin_n = 5.3;   // row of holes to the -y / +y edge (the row sits off centre: all
margin_p = 10.6;  //   tracks run behind the holes)
hole_d  = 8;
x_start = -139.8; // -x end, lengthened for the connector and the end screw
tab_x1  = -129.9; // tab carrying the connector's +y end: x = x_start .. tab_x1
tab_y   = 16;     //   out to this y
n_boards = 4;
step    = [10, 17, 4];   // board k is moved by k * step

/* [Connector — GCT FFC3A20-14-G] */
con_w   = 21.0;
con_d   = 4.5;
con_h   = 5.5;
con_xc  = -133.15;// housing centre, x (at the -x end, turned along y)
con_yc  = 4.5;    // and y
ffc_w   = 16;     // slot for the FFC through the floor, along x
ffc_t   = 2;      // and across
ffc_slot = [false, true, true, true];   // board k has the slot; board 0's is closed: its
                                        //   FFC is to run in a trough to the back (cabling/)

/* [Guides — as the guide tube of button.scad] */
guide_d   = 9.4;    // washers d9, 0.2 clearance
collar_d  = 8.6;    // spring pocket
seat_z    = -16.583;// spring seat below each board's centre plane (button.scad)
collar_h  = 1.5;    // depth of the spring pocket

/* [Body] */
gap       = 0.1;    // between the body and the boards' undersides
fit       = 0.3;    // clearance around the connectors and the boards
floor_min = 1.5;    // floor material under the deepest point of any bore

/* [Holding the boards: cover] */
cover_t    = 1.2;   // cover plate thickness (cover.scad); the lips end flush with it
end_pad    = 1.2;   // board end to the inner face of the cover's end walls (cover.scad):
                    //   the body reaches out to them below the board level
tab_wall   = 0.1 + 0.6;   // cover's wall round each tab: rib_gap + rib_t (cover.scad)
screw_pilot = 1.6;  // M2 countersunk self-tapping screws holding the cover
mid_c      = 50;    // middle screws through cover and board, as in pcb.scad: board k's
mid_y      = 0;     //   at x = -mid_c and mid_c - 2 k step[0] (own frame), on the row line
end_d      = 2.3;   // end screws through the board: end_d inside each board end
mid_depth  = 7;     // pilot below the board's underside

$fa = 4; $fs = 0.4;

span   = (n - 1) * pitch;
slope  = step[2] / step[1];                       // floor rises with the staircase
z_bot  = -pcb_t / 2 - cu_t;                       // underside of a board, own frame
function x_end(k) = span / 2 - k * pitch + margin;   // +x end or saw cut of board k
function board_z(k) = k * step[2];
// floor: z = slope * y - floor_c, as high as possible while staying floor_min
// below every spring pocket (worst at the pocket's +y edge)
floor_c = -(seat_z - floor_min) + slope * collar_d / 2;
function floor_at(y) = slope * y - floor_c;

echo(str("floor: z = ", slope, " * y - ", floor_c, " (", atan(slope), " deg); ",
         "at the front edge y = ", -margin_n, ": z = ", floor_at(-margin_n), ", at the back y = ",
         (n_boards - 1) * step[1] + margin_p, ": z = ", floor_at((n_boards - 1) * step[1] + margin_p)));
echo(str(n * n_boards - (n_boards - 1) * n_boards / 2, " guides d", guide_d, ", spring pocket d",
         collar_d, " x ", collar_h));

// footprint of board k in its own frame (from the -x end to the cut at +x,
// plus the connector tab)
module footprint(k, grow = 0)
    offset(delta = grow) union() {
        translate([x_start, -margin_n]) square([x_end(k) - x_start, margin_n + margin_p]);
        translate([x_start, 0]) square([tab_x1 - x_start, tab_y]);
    }

module at_board(k) translate(k * step) children();

// the column of material under board k: its footprint, less what board k-1
// (lower) already covers, from far below up to board k's underside
module column(k)
    difference() {
        // grown by fit, so that it meets the next column, which starts fit
        // beyond this board's edge
        at_board(k) translate([0, 0, -60]) linear_extrude(60 + z_bot - gap) footprint(k, fit);
        if (k > 0) board_below(k);
    }

// what board k's body must leave free of board k-1 below it: that board, and the
// cover's wall round its tab, which board k's -x end overhangs
module board_below(k)
    at_board(k - 1) translate([0, 0, -100]) {
        linear_extrude(200) footprint(k - 1, fit);
        translate([x_start - 1, 0, 0]) cube([tab_x1 + tab_wall + fit - x_start + 1, tab_y + tab_wall + fit, 200]);
    }

// slab below the floor plane, removed from the columns
module below_floor()
    multmatrix([[1, 0, 0, 0], [0, 1, 0, 0], [0, slope, 1, -floor_c], [0, 0, 0, 1]])
        translate([-200, -100, -100]) cube([400, 300, 100]);

module holes_of(k)
    for (i = [0 : n - 1 - k]) translate([-span / 2 + i * pitch, 0]) children();

module guides(k)
    at_board(k) holes_of(k) {
        translate([0, 0, seat_z + collar_h]) cylinder(d = guide_d, h = 30);
        translate([0, 0, seat_z]) cylinder(d = collar_d, h = 30);
    }

module connector_pocket(k)
    at_board(k) {
        // connector housing
        // connector housing, turned: its long side along y
        translate([con_xc - con_d / 2 - fit, con_yc - con_w / 2 - fit, z_bot - con_h - fit])
            cube([con_d + 2 * fit, con_w + 2 * fit, con_h + fit + 1]);
        // FFC slot, straight down through the floor, along y
        if (ffc_slot[k])
            translate([con_xc - ffc_t / 2, con_yc - ffc_w / 2, -80]) cube([ffc_t, ffc_w, 80 + z_bot]);
    }

z_topcu = pcb_t / 2 + cu_t;                 // top of a board, own frame

// beyond both ends of each board, below the board level, the body reaches out
// to the cover's end walls (and under the cover's -x end rib, the x stop)
module end_pads(k)
    difference() {
        at_board(k) {
            translate([x_start - end_pad, -margin_n - fit, -60])
                cube([end_pad - fit + 0.01, tab_y + margin_n + fit, 60 + z_bot - gap]);
            translate([x_end(k) + fit - 0.01, -margin_n - fit, -60])   // overlaps the column
                cube([end_pad - fit + 0.01, margin_n + margin_p + 2 * fit, 60 + z_bot - gap]);
        }
        // the board below (and its tab) runs under these blocks
        if (k > 0) board_below(k);
    }

// between neighbouring boards (1.1 mm apart), below the board level, the steps
// are joined so that the housing stays one piece
module bridge(k)
    at_board(k) translate([x_start + step[0], margin_p, -60])
        cube([x_end(k + 1) + step[0] - x_start - step[0], step[1] - margin_n - margin_p,
              60 + z_bot - gap]);

function cover_screws(k) = [[x_start + end_d, 0], [x_end(k) - end_d, 0]];   // through the board
function mid_screws(k) = [[-mid_c, mid_y], [mid_c - 2 * k * step[0], mid_y]];

module screw_pilots(k) {
    at_board(k) for (q = cover_screws(k))
        translate([q[0], q[1], z_bot - mid_depth]) cylinder(d = screw_pilot, h = mid_depth + 1);
    at_board(k) for (q = mid_screws(k))
        translate([q[0], q[1], z_bot - mid_depth]) cylinder(d = screw_pilot, h = mid_depth + 1);
}

difference() {
    union() {
        for (k = [0 : n_boards - 1]) { column(k); end_pads(k); }
        for (k = [0 : n_boards - 2]) bridge(k);
    }
    below_floor();
    for (k = [0 : n_boards - 1]) { guides(k); connector_pocket(k); screw_pilots(k); }
}
