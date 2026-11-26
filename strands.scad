// Single wires (strands) along a bundle's way [given 2026-11-26: model every wire of every
// run on its own; they are loose single wires, not cables].
//
// A run is drawn as n strands of diameter d. Along its way (core, a point list: where the
// bundle runs) they lie side by side in its cross-section (pack()), in frames carried
// along the way without twisting (parallel transport), so they do not cross each other
// in the bundle. Each strand has its own ends (starts[k], ends[k]: point lists of its own):
// from its pad or pin into the bundle, and out of it to its pad.
//
// used by ../bass/elec.scad (the bass's runs) and ../discant/gauge_link.scad (the discant's)

function _nrm(v) = let(l = norm(v)) l < 1e-9 ? v : v / l;
// the way's direction at point i (the mean of the two segments at a bend)
function _tan(p, i) = let(n = len(p))
    i == 0 ? _nrm(p[1] - p[0]) : i == n - 1 ? _nrm(p[n - 1] - p[n - 2])
    : let(a = _nrm(p[i] - p[i - 1]), b = _nrm(p[i + 1] - p[i]), s = a + b) norm(s) < 1e-6 ? b : _nrm(s);
function _first(t) = _nrm(cross(t, abs(t[2]) < 0.9 ? [0, 0, 1] : [1, 0, 0]));
// frames [t, u, v] along the way: u carried over from the last point, made square to t
function frames(p, i = 0, u0 = undef) = i >= len(p) ? [] :
    let(t = _tan(p, i), u = i == 0 ? _first(t) : let(w = u0 - (u0 * t) * t) norm(w) < 1e-6 ? _first(t) : _nrm(w))
    concat([[t, u, cross(t, u)]], frames(p, i + 1, u));
// the strands' centres in the bundle's cross-section, d apart: one, a pair, a ring, and for
// seven or more a ring round a centre
function pack(n, d) =
    n == 1 ? [[0, 0]] :
    n <= 6 ? let(r = n == 2 ? d / 2 : d / (2 * sin(180 / n))) [for (k = [0 : n - 1]) [r * cos(360 * k / n + 90), r * sin(360 * k / n + 90)]] :
    concat([[0, 0]], [for (k = [0 : n - 2]) let(r = d / (2 * sin(180 / (n - 1)))) [r * cos(360 * k / (n - 1) + 90), r * sin(360 * k / (n - 1) + 90)]]);
// flat: the strands side by side in a row instead (along the cross-section's v), as loose wires
// lie in a groove; where they come from a row and would pass each other in a ring
// [2026-11-26: the gauge leads, off the plate's edge]
function pack_row(n, d) = [for (k = [0 : n - 1]) [0, (k - (n - 1) / 2) * d]];
function _pack(n, d, flat) = flat ? pack_row(n, d) : pack(n, d);
// twist: the cross-section turned by this angle from the way's first point to its last (evenly
// along its points), as wires twist in a bundle: so a row can come in across one way and leave
// across the next [2026-11-26: the gauge leads turn from the plate's edge down and then along
// the board; untwisted, their row lay along the second way and they cut across each other]
function _turn(o, a) = [o[0] * cos(a) - o[1] * sin(a), o[0] * sin(a) + o[1] * cos(a)];
// strand k's points: its start, the bundle's way offset, its end
// at a bend the cross-section stands square to the mean direction, so the offset across the
// bend (in its plane) is widened by 1 / cos(half the bend), as a mitre: the strands keep their
// spacing round the corner
function _miter(core, i, w, t) = i == 0 || i == len(core) - 1 ? w :
    let(a = _nrm(core[i] - core[i - 1]), b = _nrm(core[i + 1] - core[i]), c = a * t, x = cross(a, b))
    norm(x) < 1e-6 || c < 0.2 ? w : let(m = _nrm(cross(_nrm(x), t))) w + (w * m) * (1 / c - 1) * m;
// which place in the bundle each strand takes: in the order of the angle at which its start
// stands round the way's first point (seen along the way), so the strands come into the
// bundle without crossing (they may still cross on the way out, as loose wires do)
function _ang(core, f, q) = let(w = q - core[0]) atan2(w * f[0][2], w * f[0][1]);
// by_ends: in the order of the ends round the way's last point instead (where the fan at the
// ends is the tighter one)
// by_start_row: in the order of the starts along the row they stand in (where they stand in a
// row along the way's direction, so their angle round it says nothing)
function slots_row(core, n, pts, i, flat = false) = let(f = frames(core),
        e = pts, far = [for (k = [0 : n - 1]) norm(e[k] - e[0])],
        dir = _nrm(e[[for (k = [0 : n - 1]) if (far[k] == max(far)) k][0]] - e[0]),
        a = [for (k = [0 : n - 1]) e[k] * dir],
        p = [for (j = [0 : n - 1]) let(o = _pack(n, 1, flat)[j]) (o[0] * f[i][1] + o[1] * f[i][2]) * dir],
        r = [for (k = [0 : n - 1]) len([for (q = [0 : n - 1]) if (a[q] < a[k] || (a[q] == a[k] && q < k)) 1])],
        qq = [for (j = [0 : n - 1]) len([for (q = [0 : n - 1]) if (p[q] < p[j] || (p[q] == p[j] && q < j)) 1])])
    [for (k = [0 : n - 1]) [for (j = [0 : n - 1]) if (qq[j] == r[k]) j][0]];
function slots(core, n, starts, ends = [], by_ends = false) =
    by_ends && len(ends) >= n ? let(m = len(core) - 1, f = frames(core),
        // the row the ends stand in: from the first to the one furthest from it
        e = [for (k = [0 : n - 1]) ends[k][0]], far = [for (k = [0 : n - 1]) norm(e[k] - e[0])],
        dir = _nrm(e[[for (k = [0 : n - 1]) if (far[k] == max(far)) k][0]] - e[0]),
        a = [for (k = [0 : n - 1]) e[k] * dir],                                   // the ends along it
        p = [for (j = [0 : n - 1]) let(o = pack(n, 1)[j]) (o[0] * f[m][1] + o[1] * f[m][2]) * dir],   // the places along it
        r = [for (k = [0 : n - 1]) len([for (i = [0 : n - 1]) if (a[i] < a[k] || (a[i] == a[k] && i < k)) 1])],
        q = [for (j = [0 : n - 1]) len([for (i = [0 : n - 1]) if (p[i] < p[j] || (p[i] == p[j] && i < j)) 1])])
        [for (k = [0 : n - 1]) [for (j = [0 : n - 1]) if (q[j] == r[k]) j][0]] :
    len(starts) < n ? [for (k = [0 : n - 1]) k] :
    let(f = frames(core), a = [for (k = [0 : n - 1]) _ang(core, f, starts[k][len(starts[k]) - 1])]) _rank(n, a);
function _rank(n, a) = let(
        r = [for (k = [0 : n - 1]) len([for (j = [0 : n - 1]) if (a[j] < a[k] || (a[j] == a[k] && j < k)) 1])],
        p0 = [for (k = [0 : n - 1]) atan2(pack(n, 1)[k][1], pack(n, 1)[k][0])],
        q = [for (k = [0 : n - 1]) len([for (j = [0 : n - 1]) if (p0[j] < p0[k] || (p0[j] == p0[k] && j < k)) 1])])
    [for (k = [0 : n - 1]) [for (j = [0 : n - 1]) if (q[j] == r[k]) j][0]];
// out of the bundle each strand keeps the height it has in it, along the way its end then takes
// (its first two points: across to its pad, then onto or through it), so strands that cross on
// the way out pass over and under each other [2026-11-26: at the same height they ran into each
// other]
// lift: that height taken lift times (more room between the strands that cross; where there is
// room for it)
function _lift(e, w, lift = 1) = len(e) < 2 ? e : let(t = _nrm(e[1] - e[0])) concat([e[0] + lift * (w * t) * t], [for (i = [1 : len(e) - 1]) e[i]]);
// slot_of: the place in the bundle of each strand, given (an order searched for the least
// overlap of the fans at both ends [2026-11-26]); else by the ends or the starts as above
function strand_pts(core, n, d, k, starts = [], ends = [], spread = 1.15, by_ends = false, slot_of = [], lift = 1, by_start_row = false, flat = false, twist = 0) =
    let(f = frames(core), o0 = _pack(n, d * spread, flat)[len(slot_of) == n ? slot_of[k]
            : by_start_row ? slots_row(core, n, [for (s = starts) s[len(s) - 1]], 0, flat)[k] : slots(core, n, starts, ends, by_ends)[k]],
        mid = [for (i = [0 : len(core) - 1]) let(o = _turn(o0, twist * i / (len(core) - 1))) core[i] + _miter(core, i, o[0] * f[i][1] + o[1] * f[i][2], f[i][0])],
        m = len(core) - 1)
    concat(len(starts) > k ? _lift_start(starts[k], mid[0] - core[0]) : [], mid, len(ends) > k ? _lift(ends[k], mid[m] - core[m], lift) : []);
// the same at the start: off its pad (its last two points) a strand first takes its height in
// the bundle, then goes across to its place
function _lift_start(st, w) = let(n = len(st)) n < 2 ? st :
    let(t = _nrm(st[n - 1] - st[n - 2])) concat(st, [st[n - 1] + (w * t) * t]);
// COLOURS [given 2026-11-26]: each wire has a colour (a name, as wire_colours lists them); the
// builds draw one colour at a time ($wire_color, set on the command line), so the 3D views can
// show each in its own: no $wire_color (or "") draws all
wire_colours = ["red", "black", "blue", "yellow", "green", "white", "purple"];
function show_colour(c) = is_undef($wire_color) || $wire_color == "" || c == $wire_color;
// a wire through points: round, d thick
module strand(p, d, fn = 8) for (i = [0 : len(p) - 2]) hull() {
    translate(p[i]) sphere(d = d, $fn = fn); translate(p[i + 1]) sphere(d = d, $fn = fn);
}
// a run of n single wires
module strands(core, n, d, starts = [], ends = [], spread = 1.15, colours = [], by_ends = false, slot_of = [], lift = 1, by_start_row = false, flat = false, twist = 0)
    for (k = [0 : n - 1]) if (show_colour(colours[k])) strand(strand_pts(core, n, d, k, starts, ends, spread, by_ends, slot_of, lift, by_start_row, flat, twist), d);
// one wire of colour c
module cstrand(p, d, c) if (show_colour(c)) strand(p, d);
function path_len(p) = len(p) < 2 ? 0 : norm(p[1] - p[0]) + path_len([for (i = [1 : len(p) - 1]) p[i]]);
