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
function _lift(e, w) = len(e) < 2 ? e : let(t = _nrm(e[1] - e[0])) concat([e[0] + (w * t) * t], [for (i = [1 : len(e) - 1]) e[i]]);
function strand_pts(core, n, d, k, starts = [], ends = [], spread = 1.15, by_ends = false) =
    let(f = frames(core), o = pack(n, d * spread)[slots(core, n, starts, ends, by_ends)[k]],
        mid = [for (i = [0 : len(core) - 1]) core[i] + _miter(core, i, o[0] * f[i][1] + o[1] * f[i][2], f[i][0])],
        m = len(core) - 1)
    concat(len(starts) > k ? starts[k] : [], mid, len(ends) > k ? _lift(ends[k], mid[m] - core[m]) : []);
// COLOURS [given 2026-11-26]: each wire has a colour (a name, as wire_colours lists them); the
// builds draw one colour at a time ($wire_color, set on the command line), so the 3D views can
// show each in its own: no $wire_color (or "") draws all
wire_colours = ["red", "black", "blue", "yellow", "green", "white", "orange", "brown"];
function show_colour(c) = is_undef($wire_color) || $wire_color == "" || c == $wire_color;
// a wire through points: round, d thick
module strand(p, d, fn = 8) for (i = [0 : len(p) - 2]) hull() {
    translate(p[i]) sphere(d = d, $fn = fn); translate(p[i + 1]) sphere(d = d, $fn = fn);
}
// a run of n single wires
module strands(core, n, d, starts = [], ends = [], spread = 1.15, colours = [], by_ends = false)
    for (k = [0 : n - 1]) if (show_colour(colours[k])) strand(strand_pts(core, n, d, k, starts, ends, spread, by_ends), d);
// one wire of colour c
module cstrand(p, d, c) if (show_colour(c)) strand(p, d);
function path_len(p) = len(p) < 2 ? 0 : norm(p[1] - p[0]) + path_len([for (i = [1 : len(p) - 1]) p[i]]);
