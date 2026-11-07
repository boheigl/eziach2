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
// face at the -x end of the board, turned by con_rot from y towards -x: its long
// side runs exactly along the normal of the housing's slanted -x face, which
// follows the staircase (stair_dx in x per stair_dy in y), so con_rot =
// atan(stair_dy / stair_dx) = 58.0 deg; contact 1 is at the outer (-x, +y) end
// (for the cabling). Its lowest
// corner stays 1.6 clear of the board below in the staircase (whose +y edge
// lies at margin_p - stair_dy in this frame); along x it sits as close to
// hole 1 as the guide below that hole allows (guide_clear from its centre).
// All pads lie on the board; the board reaches -x to the body's corner, and a
// short tab carries the body's highest corner beyond the +y edge. Being vertical, it takes the
// cable at right angles to the board, so the FFC leaves downwards (-z). At the
// -x end there is no higher board above it, and the -x end is never sawn off.
// Land pattern and body from the GCT FFC3A20 drawing, for 14 contacts:
//   two rows of 14 pads, 0.60 x 2.00 at 1.0 pitch, first to last centre
//   B = 13.0; the rows span 5.50 over both (1.50 between them); every contact
//   has a pad in each row. Housing A = 21.0 long (D = 19.5 at the base),
//   4.50 deep, 5.50 high, centred on the pad pattern (assumed). No separate
//   hold-down pads. In the connector's own frame (x' across, y' along, turned
//   by con_rot about its centre) the rows are two columns at x' = +-1.75, the
//   inner one (+x') towards hole 1, with the contacts stacked along y'.
// Contact 1 is at the +y' end, towards (-x, +y); contact 14 at the other.
//
// TRACKS. Contact 1 is the common: it joins the -y halves of all rings.
// Contacts 2 .. 14 each take the +y half of one ring. All thirteen signal
// tracks run on the bottom copper in the band between the rings and the +y
// edge, behind the holes; the row of holes sits off centre towards -y so that
// the -y side carries only the ring. In the band the farther the hole, the
// higher its track. Each turns at the connector and runs straight down its
// contact's line (along -x') into the outer end of its inner pad:
// hole h -> contact 15 - h, so hole 1 takes contact 14, the one nearest it.
// The lower the track, the further right it turns, so none cross; the
// diagonals lie con_pitch apart.
// The common runs on the top copper: a via in the middle of every -y half, a
// straight bus along y = -ring_in to the connector's centre line, along it
// between the two pad columns to a via at contact 1, and a short bottom track
// into its pad. The board is therefore two-layer; the top copper carries only
// the bus, under solder mask, and the vias are tented. Straight runs have
// square ends, so right-angle corners close without notches; the slanted
// runs have round ends.
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
// deburr it, since the tracks there are only 0.15 mm apart.
//
// Coordinates: origin at the centre of the middle hole, laminate from z = -pcb_t/2
// to +pcb_t/2, bottom copper below that, from -pcb_t/2 - cu_t to -pcb_t/2, and
// the top copper above it. The row runs
// along x. The copper DXF is seen from the top, like every other layer.
//
// make builds   openscad -o ../build/switch/pcb.stl pcb.scad                            (board + copper)
//              openscad -o ../build/switch/pcb_12.stl -D cut_holes=1 pcb.scad         (sawn off: 12 holes; 11, 10 alike)
//              openscad -o ../build/switch/pcb_board.stl  -D 'part="board"'  pcb.scad
//              openscad -o ../build/switch/pcb_copper.stl -D 'part="copper"' pcb.scad
//              openscad -o ../build/switch/pcb_connector.stl -D 'part="connector"' pcb.scad (body, for fit checks)
//          or  openscad -o ../build/switch/pcb.dxf        -D 'flat=true' -D 'part="board"'  pcb.scad  (outline)
//              openscad -o ../build/switch/pcb_copper.dxf -D 'flat=true' -D 'part="copper"' pcb.scad  (bottom copper)
//              openscad -o ../build/switch/pcb_copper_top.dxf -D 'flat=true' -D 'part="copper_top"' pcb.scad
//              openscad -o ../build/switch/pcb_drill.dxf  -D 'flat=true' -D 'part="drill"'  pcb.scad  (via holes)
//              openscad -o ../build/switch/pcb_mask.dxf   -D 'flat=true' -D 'part="mask"'   pcb.scad  (mask openings)

/* [Board] */
pcb_t   = 1.6;   // board thickness, FR4 standard
// margin (last hole centre to the +x end) follows from the end screw, below
margin_n = 5.3;  // row of holes to the -y edge: only the ring and edge_cu in front
margin_p = 9.4;  // row to the +y edge: the ring, all thirteen tracks and edge_cu
edge_cu  = 0.3;  // copper to the board edge

/* [Holes] */
n       = 13;    // number of holes
pitch   = 20;    // centre-to-centre distance
hole_d  = 8;     // hole diameter
// SCREWS. All M2 screws that hold cover, board and housing together sit on the
// row line (y = 0), halfway between two hole positions, and all pass through
// the board: one at each end and two in between.
// End screws: at -x left of the connector (x_scr_l, scr_cu clear of its pads
// and scr_body clear of its body), at +x half a pitch past the last hole; the
// board ends end_d beyond the +x one, and at -x where the connector needs it. The +x one of every sawn-off version is drilled in the full board too.
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
scr_body = 1.0;  // -x end screw hole to the connector body: housing wall round the pilot
end_web = 1.2;   // screw hole edge to the board end, both ends
stair_dx = 10;   // staircase step along the row (discant/array.scad)
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
tr_w      = 0.15;  // track width
tr_pitch  = 0.3;   // centre to centre, leaving 0.15 clearance
tr_ring   = 0.4;   // ring outside to the nearest track's centre line

via_drill = 0.3;   // vias of the common bus
via_d     = 0.6;   // pad diameter, both sides

/* [Connector placement] */
stair_dy  = 16;    // step of the staircase in y (discant/array.scad): the board below has its
                   // +y edge at margin_p - stair_dy in this frame
con_rot   = atan2(stair_dy, stair_dx);   // turned from y towards -x: long side along the
                   //   slanted face's normal (-stair_dy, stair_dx)
body_y_min = -5.0; // lowest corner of the housing: 1.6 clear of the board below
con_xc    = -135.7;  // connector centre, x: as close to hole 1 as guide_clear allows
guide_clear = 9.4 / 2 + 0.7 + 0.3;   // hole 1 centre to the body: housing guide d9.4,
                   // 0.7 wall, 0.3 pocket clearance
x_scr_l   = -142;  // -x end screw, on the row line
tab_side  = 0.5;   // tab beyond the body where it crosses the +y edge, in +x
tab_front = 0.654; // tab beyond the body's highest corner: out to y = 10.6, where the
                   //   slanted -x face of the staircase is anchored

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
row_y  = pad_span / 2 - pad_l / 2;         // pad columns at x' = +-row_y
// the connector's frame: x' across (towards the inner column), y' along (towards contact 1)
con_u  = [-sin(con_rot), cos(con_rot)];    // y'
con_v  = [cos(con_rot), sin(con_rot)];     // x'
function con_pt(p) = con_c + p[0] * con_v + p[1] * con_u;          // (x', y') to board x, y
function con_loc(q) = [(q - con_c) * con_v, (q - con_c) * con_u];  // board x, y to (x', y')
// the body's corners and its reach in y: the lowest corner sets the centre
body_pts = [for (sx = [-1, 1], sy = [-1, 1]) [sx * body_d / 2, sy * body_w / 2]];
body_dy  = max([for (p = body_pts) (p[0] * con_v + p[1] * con_u)[1]]);
con_c  = [con_xc, body_y_min + body_dy];
con_yc = con_c[1];
function pin_y(c) = con_a / 2 - (c - 1) * con_pitch;               // contact c along y': 1 at +y'
function pad_c(c, inner) = con_pt([inner ? row_y : -row_y, pin_y(c)]);
function pad_end(c) = con_pt([row_y + pad_l / 2, pin_y(c)]);       // outer end of the inner pad
function con_of(h) = con_n + 1 - h;                                // hole 1 -> 14
// distance from q to a rectangle (half sizes hx', hy') centred at c in the connector's frame
function rect_dist(q, c, hx, hy) =
    let(d = q - c, a = abs(d * con_v) - hx, b = abs(d * con_u) - hy)
    a > 0 || b > 0 ? norm([max(a, 0), max(b, 0)]) : max(a, b);
function body_dist(q) = rect_dist(q, con_c, body_d / 2, body_w / 2);
function pads_dist(q) = min([for (c = [1 : con_n], i = [true, false]) rect_dist(q, pad_c(c, i), pad_l / 2, pad_w / 2)]);
// tracks: every signal runs in the +y band, then down its contact's line
tr_lo  = r_out + tr_ring;                     // band level nearest the rings
ring_in = r_in + ring_w / 2;                  // tracks and vias start mid-ring
function hole_x(k) = -span / 2 + (k - 1) * pitch;               // hole k, 1-based
function mid_screws(k) = [-mid_c, mid_c - 2 * k * stair_dx];     // board k's two, own frame
mid_xs = [for (x = concat([-mid_c], [for (k = [0 : n_boards - 1]) mid_c - 2 * k * stair_dx])) x];
function lev_up(h) = tr_lo + (h - 1) * tr_pitch;                  // +y band
// the 45 deg turn of hole h's track: where its contact's line meets its band level
function turn(h) = let(e = pad_end(con_of(h)), t = (lev_up(h) - e[1]) / con_v[1]) e + t * con_v;
function track_pts(h) = [[hole_x(h), ring_in], [hole_x(h), lev_up(h)], turn(h), pad_end(con_of(h))];
via_c  = con_pt([0, pin_y(1)]);               // common: via between the pad columns at contact 1
bus_turn = let(t = (-ring_in - con_c[1]) / con_u[1]) con_c + t * con_u;   // bus meets the centre line
vias   = concat([for (k = [1 : n]) [hole_x(k), -ring_in]], [via_c]);
end_d   = mid_d / 2 + end_web;                // end screw centre to the board end
// board extremes the connector needs: body corners, pads + edge_cu
body_xy = [for (p = body_pts) con_pt(p)];
pad_xy  = [for (c = [1 : con_n], sx = [-1, 1], sp = [-1, 1], sw = [-1, 1])
               con_pt([sx * row_y + sp * pad_l / 2, pin_y(c) + sw * pad_w / 2])];
x_start = min(concat([for (q = body_xy) q[0]], [for (q = pad_xy) q[0] - edge_cu], [x_scr_l - end_d]));
// tab: under the body where it reaches past the +y edge
body_top = max([for (q = body_xy) q[1]]);
// (none if the body stays below the edge: then the tab is flush with it)
tab_cross = [for (i = [0 : 3], j = [0 : 3]) let(a = body_xy[i], b = body_xy[j])
             if (i != j && (a[1] - margin_p) * (b[1] - margin_p) < 0)
                 a[0] + (b[0] - a[0]) * (margin_p - a[1]) / (b[1] - a[1])];
tab_x1 = len(tab_cross) > 0 ? max(tab_cross) + tab_side : x_start;
tab_y  = len(tab_cross) > 0 ? body_top + tab_front : margin_p;
margin  = pitch / 2 + end_d;                  // last hole centre to the +x end
end_xs  = [for (k = [0 : n_boards - 1]) span / 2 - k * pitch + pitch / 2];   // +x end screws, board k
screw_xs = concat([x_scr_l], mid_xs, end_xs);  // every screw hole, all at y = mid_y
x_end = span / 2 - cut_holes * pitch + margin;           // +x end of the board, or the saw cut
len_x = x_end - x_start;
function seg_dist(q, a, b) = let(ab = b - a, t = max(0, min(1, (q - a) * ab / (ab * ab)))) norm(q - (a + t * ab));

assert(con_n == n + 1, "one contact per hole plus the common");
assert(lev_up(n) + tr_w / 2 <= margin_p - edge_cu + 1e-6, "+y band too close to the board edge");
assert(r_out <= margin_n - edge_cu, "ring too close to the -y edge");
// every turn lies above its pad (the track runs down to it) and left of hole 1's ring
for (h = [1 : n]) assert(turn(h)[1] > pad_end(con_of(h))[1], str("hole ", h, ": its pad lies above the band"));
min_ring = min([for (h = [1 : n]) seg_dist([hole_x(1), 0], turn(h), pad_end(con_of(h)))]) - r_out - tr_w / 2;
assert(min_ring >= tr_pitch - tr_w, "a diagonal comes too close to hole 1's ring");
assert(turn(1)[0] + tr_w / 2 <= hole_x(1) - tr_w / 2 - (tr_pitch - tr_w), "hole 1's turn lies right of its own track");
// pads on the main board, clear of the +y and -y edges
assert(max([for (q = pad_xy) q[1]]) <= margin_p - edge_cu + 1e-6, "a pad lies beyond the +y edge");
assert(min([for (q = pad_xy) q[1]]) >= -margin_n + edge_cu - 1e-6, "a pad lies beyond the -y edge");
assert(body_y_min >= margin_p - stair_dy + 0.4, "connector hits the board below");
assert(body_dist([hole_x(1), 0]) >= guide_clear - 1e-6, "connector too close to hole 1's guide");
assert(tab_x1 < x_start + 10, "tab reaches under the next board");
// the middle screw holes stay clear of the copper: band, rings and the top bus,
// and every board keeps its own two
assert(lev_up(1) - tr_w / 2 - (mid_y + mid_d / 2) >= 0.5, "middle screw hole too close to the band");
assert(min([for (k = [1 : n], x = screw_xs) norm([hole_x(k) - x, mid_y])]) - r_out - mid_d / 2 >= 0.5,
       "screw hole too close to a ring");
assert(pads_dist([x_scr_l, mid_y]) >= mid_d / 2 + scr_cu, "-x end screw too close to the pads");
assert(body_dist([x_scr_l, mid_y]) >= mid_d / 2 + scr_body, "-x end screw too close to the connector body");
assert(seg_dist([x_scr_l, mid_y], bus_turn, via_c) - tr_w / 2 >= mid_d / 2 + 0.5, "-x end screw too close to the top bus");
assert(seg_dist([hole_x(1), 0], bus_turn, via_c) - tr_w / 2 >= r_in + 0.5, "top bus too close to hole 1");
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
echo(str("connector turned ", con_rot, " deg, centre ", con_c, ", body corners ", body_xy,
         "; contact 1 at ", pad_c(1, true), ", 14 at ", pad_c(14, true), "; body ",
         body_dist([hole_x(1), 0]), " from hole 1's centre"));
echo(str("tracks ", tr_w, " wide at ", tr_pitch, " pitch, all in the +y band y = ", lev_up(1),
         " .. ", lev_up(n), "; turns x = ", turn(1)[0], " .. ", turn(n)[0], ", diagonals ",
         min_ring, " clear of hole 1's ring; -x end screw ", pads_dist([x_scr_l, mid_y]) - mid_d / 2,
         " from the pads, ", body_dist([x_scr_l, mid_y]) - mid_d / 2, " from the body"));
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
            // tab carrying the connector's corner beyond the +y edge
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

module at_con() translate(con_c) rotate(con_rot) children();

module connector_pads()
    at_con() for (c = [1 : con_n], x = [row_y, -row_y])
        translate([x, pin_y(c)]) square([pad_l, pad_w], center = true);

// a track as a polyline: axis-parallel segments with square ends, so that
// right-angle corners close; slanted ones with round ends
module track(pts)
    for (i = [0 : len(pts) - 2])
        let(a = pts[i], b = pts[i + 1], straight = abs(a[0] - b[0]) < 1e-9 || abs(a[1] - b[1]) < 1e-9)
        hull() for (q = [a, b])
            translate(q) if (straight) square(tr_w, center = true); else circle(d = tr_w, $fn = 16);

module tracks() {
    // +y band, a turn, down the contact's line into the outer end of its inner pad
    for (h = [1 : n]) track(track_pts(h));
    // the common's via at contact 1, into its inner pad
    track([via_c, pad_c(1, true)]);
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
        track([[hole_x(n), -ring_in], bus_turn, via_c]);
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
    translate([0, 0, -pcb_t / 2 - cu_t - body_h]) at_con()
        translate([-body_d / 2, -body_w / 2, 0]) cube([body_d, body_w, body_h]);

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
