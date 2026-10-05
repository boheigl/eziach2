// Printed circuit board with a single row of holes
//
// 13 holes of 10 mm on a 20 mm pitch, centred on the board. The board extends
// one edge margin beyond the outer hole centres in x, and the same margin each
// side of the row in y.
//
// Each hole is ringed on the bottom face by two half-ring tracks of exposed copper
// (no solder mask). They run right up to the bore, with no gap to it, and are
// kept apart by a straight gap along the row axis: one half on the +y side, one
// on the -y side. The gap has parallel sides, so it is the same width at the
// bore and at the outside of the ring.
//
// FFC CONNECTOR. A GCT FFC3A20-14-G (14 contacts, 1.0 mm pitch, vertical SMT,
// ZIF slide lock, single-sided contact, for 0.30 mm FFC) sits on the bottom
// face at the -x end of the board, turned so that its long side runs along y.
// Its x position follows from the tracks: just left of where the last of them
// turns down beside hole 1. Its -y end stays 0.4 clear of the board below in
// the staircase (whose +y edge lies at margin_p - stair_dy in this frame) and
// overhangs this board's -y edge a little; all pads lie on the board. The rest
// of its 21 mm length reaches past the +y edge onto a small tab. Being
// vertical, it takes the cable at right angles to the board, so the FFC leaves
// downwards (-z). At the -x end there is no higher board above it, and the -x
// end is never sawn off.
// Land pattern and body from the GCT FFC3A20 drawing, for 14 contacts:
//   two rows of 14 pads, 0.60 x 2.00 at 1.0 pitch, first to last centre
//   B = 13.0; the rows span 5.50 over both (1.50 between them); every contact
//   has a pad in each row. Housing A = 21.0 long (D = 19.5 at the base),
//   4.50 deep, 5.50 high, centred on the pad pattern (assumed). No separate
//   hold-down pads. Turned, the rows become two columns at x = con_xc +- 1.75,
//   the inner one towards hole 1, with the contacts stacked along y.
// Contact 1 is at the +y end, contact 14 at the -y end.
//
// TRACKS. Contact 1 is the common: it joins the -y halves of all rings.
// Contacts 2 .. 14 each take the +y half of one ring. All thirteen signal
// tracks run on the bottom copper in the band between the rings and the +y
// edge, behind the holes; the row of holes sits off centre towards -y so that
// the -y side carries only the ring. In the band the farther the hole, the
// higher its track. Each turns down beside hole 1, left of its ring, the
// lowest furthest right, and runs left into the inner pad column from its end:
// hole h -> contact 15 - h, so hole 1 takes contact 14 at the bottom.
// The common runs on the top copper: a via in the middle of every -y half, a
// straight bus along y = -ring_in to the connector, up between its two pad
// columns to a via at contact 1 (on the tab), and a short bottom track into its
// pad. The board is therefore two-layer; the top copper carries only the bus,
// under solder mask, and the vias are tented. All corners are right angles; the
// tracks have square ends, so the corners close without notches.
// The rings and pads are left bare; the tracks are meant to sit under solder
// mask (part = "mask" gives the openings).
//
// SAWN-OFF VERSIONS. The same board is used with fewer holes: cut_holes holes
// are sawn off at the +x end. The cut runs across the board end_d past the
// screw hole that lies half a pitch past the last hole kept, so it stays 2.7 mm
// clear of the first ring removed. Everything beyond it goes,
// copper included: the bus on the top is cut short but still reaches every
// remaining -y half, and the band tracks of the removed holes are left as dead
// stubs on their (now unused) contacts. Copper is cut through at the sawn edge;
// deburr it, since the tracks there are only 0.2 mm apart.
//
// Coordinates: origin at the centre of the middle hole, laminate from z = -pcb_t/2
// to +pcb_t/2, bottom copper below that, from -pcb_t/2 - cu_t to -pcb_t/2, and
// the top copper above it. The row runs
// along x. The copper DXF is seen from the top, like every other layer.
//
// Render with  openscad -o pcb.stl pcb.scad                            (board + copper)
//              openscad -o pcb_12.stl -D cut_holes=1 pcb.scad         (sawn off: 12 holes; 11, 10 alike)
//              openscad -o pcb_board.stl  -D 'part="board"'  pcb.scad
//              openscad -o pcb_copper.stl -D 'part="copper"' pcb.scad
//              openscad -o pcb_connector.stl -D 'part="connector"' pcb.scad (body, for fit checks)
//          or  openscad -o pcb.dxf        -D 'flat=true' -D 'part="board"'  pcb.scad  (outline)
//              openscad -o pcb_copper.dxf -D 'flat=true' -D 'part="copper"' pcb.scad  (bottom copper)
//              openscad -o pcb_copper_top.dxf -D 'flat=true' -D 'part="copper_top"' pcb.scad
//              openscad -o pcb_drill.dxf  -D 'flat=true' -D 'part="drill"'  pcb.scad  (via holes)
//              openscad -o pcb_mask.dxf   -D 'flat=true' -D 'part="mask"'   pcb.scad  (mask openings)

/* [Board] */
pcb_t   = 1.6;   // board thickness, FR4 standard
// margin (last hole centre to the +x end) follows from the end screw, below
margin_n = 5.3;  // row of holes to the -y edge: only the ring and edge_cu in front
margin_p = 10.6; // row to the +y edge: the ring, all thirteen tracks and edge_cu
edge_cu  = 0.3;  // copper to the board edge

/* [Holes] */
n       = 13;    // number of holes
pitch   = 20;    // centre-to-centre distance
hole_d  = 8;     // hole diameter
// SCREWS. All M2 screws that hold cover, board and housing together sit on the
// row line (y = 0), halfway between two hole positions, and all pass through
// the board: one at each end and two in between.
// End screws: at -x just left of the connector's outer pads (scr_cu clear of
// them), at +x half a pitch past the last hole; the board ends end_d beyond
// each. The +x one of every sawn-off version is drilled in the full board too.
// Middle screws: two per board in the staircase, at x = -mid_c and mid_c on board 0.
// On board k (moved by k * stair_dx, k holes sawn off) both step in by stair_dx
// in the staircase, so the screws of all boards lie on two lines that meet in
// +y beyond the last board. In the board's own frame that is x = -mid_c and
// mid_c - 2 k stair_dx: always halfway between two holes. Every board gets all
// of them, since it is one design; the ones its step does not use stay empty.
mid_c   = 50;
mid_y   = 0;     // on the row line, like the end screws
mid_d   = 2.2;   // M2 clearance, every screw hole
scr_cu  = 0.5;   // -x end screw hole to the connector pads
end_web = 1.2;   // screw hole edge to the board end, both ends
stair_dx = 10;   // staircase step along the row (array.scad)
n_boards = 4;

/* [Copper] */
ring_w  = 1.0;   // track width, measured radially from the bore: 0.5 beyond the d9 washer
                 // (ISO 7093 / DIN 9021, M3: d3.2 / d9 x 0.8)
ring_gap = 0.5;  // gap between the two halves of a ring
cu_t    = 0.035; // copper thickness, 1 oz

/* [Connector — GCT FFC3A20-14-G, from the drawing] */
con_n     = 14;    // contacts
con_pitch = 1.0;
pad_w     = 0.6;
pad_l     = 2.0;   // per row
pad_span  = 5.5;   // over both rows
body_w    = 21.0;  // A: housing length along the row
body_d    = 4.5;   // housing depth
body_h    = 5.5;   // height above the board face

/* [Tracks] */
tr_w      = 0.2;   // track width
tr_pitch  = 0.4;   // centre to centre, leaving 0.2 clearance
tr_ring   = 0.4;   // ring outside to the nearest track's centre line

via_drill = 0.3;   // vias of the common bus
via_d     = 0.6;   // pad diameter, both sides

/* [Connector placement] */
stair_dy  = 17;    // step of the staircase in y (array.scad): the board below has its
                   // +y edge at margin_p - stair_dy in this frame
body_y_min = -6.0; // -y end of the housing: 0.4 clear of the board below
jog_x0    = 5.3;   // the first turn of the +y band, left of hole 1's centre: clear of
                   // its ring; the others follow, one pitch further left each
tab_side  = 0.5;   // tab beyond the inner pad column, in +x
tab_front = 1.0;   // tab beyond the housing's +y end

/* [Sawn-off versions] */
cut_holes = 0;   // holes sawn off at the +x end: 0 = 13 holes, 1 = 12, 2 = 11, 3 = 10

/* [Output] */
part    = "all"; // "all", "board", "copper", "copper_top", "drill", "mask" or "connector"
flat    = false; // true: 2D outline only, for DXF/SVG export

$fa = 2; $fs = 0.2;

span  = (n - 1) * pitch;        // first to last hole centre
len_y = margin_n + margin_p;
r_in  = hole_d / 2;             // tracks start at the bore
r_out = r_in + ring_w;

con_a  = (con_n - 1) * con_pitch;          // first to last contact
con_yc = body_y_min + body_w / 2;                    // connector centre, y (turned)
row_y  = pad_span / 2 - pad_l / 2;         // pad columns at x = con_xc +- row_y
// tracks: every signal runs in the +y band, behind the holes
tr_lo  = r_out + tr_ring;                     // band level nearest the rings
ring_in = r_in + ring_w / 2;                  // tracks and vias start mid-ring
function hole_x(k) = -span / 2 + (k - 1) * pitch;               // hole k, 1-based
function mid_screws(k) = [-mid_c, mid_c - 2 * k * stair_dx];     // board k's two, own frame
mid_xs = [for (x = concat([-mid_c], [for (k = [0 : n_boards - 1]) mid_c - 2 * k * stair_dx])) x];
function pin_y(c) = con_yc + con_a / 2 - (c - 1) * con_pitch;    // contact c: 1 at +y
function con_of(h) = con_n + 1 - h;                              // hole 1 -> 14 (lowest)
function lev_up(h) = tr_lo + (h - 1) * tr_pitch;                  // +y band
// each track turns down beside hole 1 towards its contact, the lowest one
// furthest right; tracks turning up would have to come first, highest furthest
// right (none do with these numbers)
function goes_up(h) = pin_y(con_of(h)) > lev_up(h);
jog_order = concat([for (h = [n : -1 : 1]) if (goes_up(h)) h],
                   [for (h = [1 : n]) if (!goes_up(h)) h]);
function x_jog(h) = hole_x(1) - jog_x0 - search(h, jog_order)[0] * tr_pitch;
function x_jog_min() = min([for (h = [1 : n]) x_jog(h)]);
// the connector follows from the turns: inner pad column just left of the last
x_in   = x_jog_min() - tr_w / 2 - (tr_pitch - tr_w) - pad_l / 2;   // inner pad column, centre
con_xc = x_in - row_y;                        // connector centre, x
x_out  = con_xc - row_y;                      // outer pad column, centre
via_c  = [con_xc, pin_y(1)];                  // common: via between the pad columns
vias   = concat([for (k = [1 : n]) [hole_x(k), -ring_in]], [via_c]);
end_d   = mid_d / 2 + end_web;                // end screw centre to the board end
x_scr_l = x_out - pad_l / 2 - scr_cu - mid_d / 2;   // -x end screw
x_start = x_scr_l - end_d;                    // -x end of the board
margin  = pitch / 2 + end_d;                  // last hole centre to the +x end
end_xs  = [for (k = [0 : n_boards - 1]) span / 2 - k * pitch + pitch / 2];   // +x end screws, board k
screw_xs = concat([x_scr_l], mid_xs, end_xs);  // every screw hole, all at y = mid_y
tab_x1 = x_in + pad_l / 2 + tab_side;         // tab: +x edge
tab_y  = con_yc + body_w / 2 + tab_front;     //      +y edge
x_end = span / 2 - cut_holes * pitch + margin;           // +x end of the board, or the saw cut
len_x = x_end - x_start;

assert(con_n == n + 1, "one contact per hole plus the common");
assert(lev_up(n) + tr_w / 2 <= margin_p - edge_cu + 1e-6, "+y band too close to the board edge");
assert(r_out <= margin_n - edge_cu, "ring too close to the -y edge");
// every turn clears hole 1's ring (hole 1's own track passes its -y half);
// measured to the square corner nearest the ring, on the ring's axis
min_ring = min([for (h = [1 : n]) abs(x_jog(h) + tr_w / 2 - hole_x(1)) - r_out]);
assert(min_ring >= tr_pitch - tr_w, "a turn comes too close to hole 1's ring");
// signal contacts on the main board, below the +y edge
assert(pin_y(2) + pad_w / 2 <= margin_p - edge_cu + 1e-6, "a signal contact lies beyond the +y edge");
assert(body_y_min >= margin_p - stair_dy + 0.4, "connector hits the board below");
assert(tab_x1 < x_start + 10, "tab reaches under the next board");
// the middle screw holes stay clear of the copper: band, rings and the top bus,
// and every board keeps its own two
assert(lev_up(1) - tr_w / 2 - (mid_y + mid_d / 2) >= 0.5, "middle screw hole too close to the band");
assert(min([for (k = [1 : n], x = screw_xs) norm([hole_x(k) - x, mid_y])]) - r_out - mid_d / 2 >= 0.5,
       "screw hole too close to a ring");
assert(x_scr_l + mid_d / 2 + scr_cu <= x_out - pad_l / 2 + 1e-6, "-x end screw too close to the pads");
assert(mid_y - mid_d / 2 - (-ring_in + tr_w / 2) >= 0.5, "middle screw hole too close to the top bus");
for (k = [0 : n_boards - 1]) assert(mid_screws(k)[1] < span / 2 - (k - 0.5) * pitch - 5,
                                    str("board ", k, " loses its right middle screw to the saw"));
assert(cut_holes >= 0 && cut_holes <= n - 1, "at least one hole must remain");

echo(str("board ", len_x, " x ", len_y, " x ", pcb_t, " mm, x = ", x_start, " .. ", x_end,
         ", plus a tab x = ", x_start, " .. ", tab_x1, " out to y = ", tab_y));
if (cut_holes > 0)
    echo(str("sawn off: ", cut_holes, " holes at +x, cut at x = ", x_end, ", ", n - cut_holes,
             " holes left"));
echo(str(n, " holes d", hole_d, " at pitch ", pitch, ", centres x = ", -span / 2,
         " .. ", span / 2));
echo(str("copper half rings d", hole_d, " .. d", 2 * r_out, ", gap ", ring_gap,
         " mm; ", pitch - 2 * r_out, " mm between rings, ", margin_n - r_out, " / ",
         margin_p - r_out, " mm from ring to the -y / +y edge"));
echo(str("connector turned, centre (", con_xc, ", ", con_yc, "), housing x = ",
         con_xc - body_d / 2, " .. ", con_xc + body_d / 2, ", y = ", con_yc - body_w / 2, " .. ",
         con_yc + body_w / 2, "; contacts y = ", pin_y(1), " (1) .. ", pin_y(con_n), " (14)"));
echo(str("tracks ", tr_w, " wide at ", tr_pitch, " pitch, all in the +y band y = ", lev_up(1),
         " .. ", lev_up(n), "; turns x = ", x_jog(jog_order[0]), " .. ", x_jog_min(), ", ",
         min_ring, " clear of hole 1's ring; connector body overhangs the -y edge by ",
         -margin_n - body_y_min));
echo(str("contacts: ", [for (h = [1 : n]) str("hole ", h, " -> ", con_of(h))]));
echo(str("screw holes d", mid_d, " at y = ", mid_y, ": -x end ", x_scr_l, ", middle ", mid_xs,
         ", +x ends ", end_xs, "; used per board: ",
         [for (k = [0 : n_boards - 1]) [x_scr_l, mid_screws(k)[0], mid_screws(k)[1], end_xs[k]]]));
echo(str("common on the top copper: ", n, " vias at y = ", -ring_in, ", bus to the via at ", via_c));

module at_holes()
    for (i = [0 : n - 1])
        translate([-span / 2 + i * pitch, 0]) children();

// what is left of the board after the saw cut at +x
module keep()
    translate([x_start - 1, -50]) square([x_end - x_start + 1, 100]);

module outline() intersection() { full_outline(); keep(); }

module full_outline()
    difference() {
        union() {
            translate([x_start, -margin_n]) square([span / 2 + margin - x_start, len_y]);
            // tab carrying the connector's +y end
            translate([x_start, 0]) square([tab_x1 - x_start, tab_y]);
        }
        at_holes() circle(d = hole_d);
        for (x = screw_xs) translate([x, mid_y]) circle(d = mid_d);
    }

// both halves of every ring: an annulus with a strip of width ring_gap removed
// along the row axis
module rings()
    at_holes() difference() {
        circle(r = r_out);
        circle(r = r_in);
        square([2 * r_out + 1, ring_gap], center = true);
    }

module connector_pads() {
    for (c = [1 : con_n], x = [x_in, x_out])
        translate([x, pin_y(c)]) square([pad_l, pad_w], center = true);
}

// a track as a polyline of axis-parallel segments with square ends, so that
// right-angle corners close
module track(pts)
    for (i = [0 : len(pts) - 2])
        hull() for (q = [pts[i], pts[i + 1]])
            translate(q) square(tr_w, center = true);

module tracks() {
    for (h = [1 : n]) {
        y = pin_y(con_of(h));
        // +y band, turning beside hole 1, right-hand end into the inner column
        track([[hole_x(h), ring_in], [hole_x(h), lev_up(h)],
               [x_jog(h), lev_up(h)], [x_jog(h), y], [x_in, y]]);
    }
    // the common's via at contact 1, into its inner pad
    track([via_c, [x_in, pin_y(1)]]);
}

module via_pads()
    for (v = vias) translate(v) circle(d = via_d);

module copper() intersection() {
    union() {
        rings();
        connector_pads();
        tracks();
        via_pads();
    }
    keep();
}

// top copper: the common bus, over the -y halves to contact 1
module copper_top() intersection() {
    union() {
        track([[hole_x(n), -ring_in], [con_xc, -ring_in], via_c]);
        via_pads();
    }
    keep();
}

module drill() intersection() {
    union() {
        for (v = vias) translate(v) circle(d = via_drill);
        for (x = screw_xs) translate([x, mid_y]) circle(d = mid_d);
    }
    keep();
}

// openings in the solder mask: everything but the tracks is left bare
module mask_openings() {
    rings();
    connector_pads();
}

// simplified body: one block hanging below the bottom copper
module connector_body()
    translate([con_xc - body_d / 2, con_yc - body_w / 2, -pcb_t / 2 - cu_t - body_h])
        cube([body_d, body_w, body_h]);

if (flat) {
    if (part == "copper") copper();
    else if (part == "copper_top") copper_top();
    else if (part == "drill") drill();
    else if (part == "mask") mask_openings();
    else outline();
} else {
    if (part == "all" || part == "board")
        translate([0, 0, -pcb_t / 2]) linear_extrude(pcb_t)
            difference() { outline(); drill(); }
    if (part == "all" || part == "copper") {
        translate([0, 0, -pcb_t / 2 - cu_t]) linear_extrude(cu_t) copper();
        translate([0, 0, pcb_t / 2]) linear_extrude(cu_t) copper_top();
        // via barrels, plated through the laminate
        translate([0, 0, -pcb_t / 2]) linear_extrude(pcb_t) intersection() {
            difference() {
                for (v = vias) translate(v) circle(d = via_drill);
                for (v = vias) translate(v) circle(d = via_drill - 2 * cu_t);
            }
            keep();
        }
    }
    if (part == "connector")
        connector_body();
}
