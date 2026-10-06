// Thumb bar profile: a closed 2D shape
//
// The back is a straight line from the origin in the direction back_angle
// (measured from the x axis, counter-clockwise) and back_length long. At its
// end the outline turns left by 90 degrees and returns to the origin along one
// smooth curve, arriving there in +x direction. On its way the curve touches
// the back at its midpoint M, tangent to it, so the shape has a pinched waist
// and two lobes:
//
//   upper half, end of the back -> M:
//     left bend of small_radius -> straight -> right bend of large_radius
//   lower half, M -> origin:
//     right bend of large_radius -> straight -> left bend of small_radius
//
// Each half is first laid out exactly from circles and their common tangent
// (G1): the small circle touches the back's end (resp. the x axis at the
// origin), the large circle touches the back at M, from inside the shape;
// both halves share it. Then every jump in curvature is replaced by a ramp of
// length blend * (the shorter neighbour, arcs counted twice since a ramp
// takes half of each neighbour), over which the curvature changes as a half
// cosine, so the curve becomes curvature-continuous (G2). The arc and line
// lengths are then re-solved (damped Newton) so that each half again ends in
// its point with its heading.
//
// The waist exists only while the circles stay apart:
//   (back_length/2 - small_radius)^2 >= small_radius^2
//                                       + 2 small_radius large_radius
// and correspondingly for the lower lobe.

back_length  = 40;
back_angle   = 57;   // degrees
small_radius = 4;
large_radius = 15;
blend        = 0.8;  // 0: arcs and lines (G1); larger: longer ramps (1 may fail)

steps = 48;          // samples per curve segment

thumb_profile(back_length, back_angle, small_radius, large_radius, blend);

module thumb_profile(back_length, back_angle, small_radius, large_radius,
                     blend = 0.8)
    polygon(thumb_profile_points(back_length, back_angle,
                                 small_radius, large_radius, blend));

// The outline, counter-clockwise from the origin.
function thumb_profile_points(back_length, back_angle,
                              small_radius, large_radius, blend = 0.8) =
    let(th = back_angle * PI / 180,
        u = _dir(th), n = _dir(th + PI / 2),
        P = back_length * u, M = P / 2,
        r = small_radius, R = large_radius,
        upper = _half(P, th + PI / 2, P - r * u, 1, r,
                      M + R * n, -1, R, th + PI, M, blend),
        lower = _half(M, th + PI, M + R * n, -1, R,
                      [0, r], 1, r, 2 * PI, [0, 0], blend),
        curve = concat(upper, [for (i = [1 : len(lower) - 2]) lower[i]]))
    concat([[0, 0]], curve);

// --- one half ------------------------------------------------------------

// From p0 with heading ps around circle C1 (radius r1, sense s1: +1 left,
// -1 right), along the common tangent, around circle C2 (r2, s2) into the
// point pe with heading he. Returns its points.
function _half(p0, ps, C1, s1, r1, C2, s2, r2, he, pe, blend) =
    let(g = _tangent_path(ps, C1, s1, r1, C2, s2, r2, he),
        a = g[0], l = g[1], c = g[2],
        k1 = s1 / r1, k2 = s2 / r2,
        t1 = blend * min(2 * a, l),
        t2 = blend * min(l, 2 * c),
        segs = function(v) [[k1, k1, v[0]], [k1, 0, t1], [0, 0, v[1]],
                            [0, k2, t2], [k2, k2, v[2]]],
        f = function(v) let(q = _chain(segs(v), p0, ps))
                        [q[1][0] - pe[0], q[1][1] - pe[1], q[2] - he],
        v = _newton(f, [a - t1 / 2, l - (t1 + t2) / 2, c - t2 / 2], 40),
        e = _norm_inf(f(v)))
    assert(e < 1e-6, str("thumb_profile: solver did not converge (", e, ")"))
    assert(min(v) >= 0,
           str("thumb_profile: blend too large for this shape (", v, ")"))
    _chain(segs(v), p0, ps)[0];

// Arc, line and arc lengths of the G1 path: heading ps on circle 1, then the
// common tangent, then circle 2 up to heading he.
function _tangent_path(ps, C1, s1, r1, C2, s2, r2, he) =
    let(D = C2 - C1, d = norm(D),
        k = s2 * r2 - s1 * r1)
    assert(abs(k) <= d,
           str("thumb_profile: the circles overlap; ",
               "back_length too short for these radii"))
    let(psi = atan2(D[1], D[0]) * PI / 180 - PI / 2 + acos(k / d) * PI / 180,
        N = _dir(psi + PI / 2),
        T1 = C1 - s1 * r1 * N,
        T2 = C2 - s2 * r2 * N)
    [_mod(s1 * (psi - ps), 2 * PI) * r1,
     norm(T2 - T1),
     _mod(s2 * (he - psi), 2 * PI) * r2];

// --- curve ---------------------------------------------------------------

function _dir(a) = [cos(a * 180 / PI), sin(a * 180 / PI)];   // a in radians
function _mod(x, m) = x - m * floor(x / m);
function _norm_inf(v) = max([for (x = v) abs(x)]);

// Heading at arc length t along a segment of length s, curvature k0 -> k1.
function _heading(phi, k0, k1, s, t) =
    phi + k0 * t + (k0 == k1 || s == 0 ? 0
        : (k1 - k0) / 2 * (t - s / PI * sin(180 * t / s)));

// Points of one segment from p with heading phi: [points, end heading].
function _segment(p, phi, k0, k1, s) =
    let(h = [for (i = [0 : steps]) _heading(phi, k0, k1, s, s * i / steps)],
        d = [for (i = [0 : steps - 1])
                 s / steps * (_dir(h[i]) + _dir(h[i + 1])) / 2],
        pts = [for (i = 0, q = p; i <= steps;
                    q = q + (i < steps ? d[i] : [0, 0]), i = i + 1) q])
    [pts, h[steps]];

// Segments [k0, k1, length] one after another from p with heading phi:
// [points, end point, end heading].
function _chain(segs, p, phi, i = 0, pts = []) =
    i == len(segs) ? [len(pts) == 0 ? [p] : pts, p, phi]
    : let(sg = _segment(p, phi, segs[i][0], segs[i][1], segs[i][2]),
          // skip empty segments and each segment's repeated start point
          add = segs[i][2] <= 0 ? []
              : len(pts) == 0 ? sg[0]
              : [for (j = [1 : steps]) sg[0][j]])
      _chain(segs, sg[0][steps], sg[1], i + 1, concat(pts, add));

// --- solver --------------------------------------------------------------

function _newton(f, v, n) =
    let(fv = f(v), e = _norm_inf(fv), m = len(v))
    n == 0 || e < 1e-10 ? v
    : let(h = 1e-7,
          J = [for (i = [0 : m - 1])
                  [for (j = [0 : m - 1])
                       (f(v + h * [for (k = [0 : m - 1]) k == j ? 1 : 0])[i]
                        - fv[i]) / h]],
          d = _solve(J, fv))
      _newton(f, _damp(f, v, d, e, 1), n - 1);

// Halve the step until the residual decreases.
function _damp(f, v, d, e, lam) =
    let(w = v - lam * d)
    lam < 1e-4 || _norm_inf(f(w)) < e ? w : _damp(f, v, d, e, lam / 2);

// Solve A x = b by Gaussian elimination with partial pivoting.
function _solve(A, b) =
    let(n = len(b), M = [for (i = [0 : n - 1]) concat(A[i], [b[i]])])
    _back(_eliminate(M, 0), n, n - 1, []);

function _eliminate(M, c) =
    c == len(M) ? M
    : let(rows = [for (i = [c : len(M) - 1]) abs(M[i][c])],
          p = c + search(max(rows), rows)[0],
          S = [for (i = [0 : len(M) - 1])
                  i == c ? M[p] : i == p ? M[c] : M[i]],
          N = [for (i = [0 : len(M) - 1])
                  i <= c ? S[i] : S[i] - S[i][c] / S[c][c] * S[c]])
      _eliminate(N, c + 1);

function _back(M, n, i, x) =
    i < 0 ? x
    : let(s = M[i][n] - (len(x) == 0 ? 0
                  : [for (j = [0 : len(x) - 1]) M[i][i + 1 + j]] * x))
      _back(M, n, i - 1, concat([s / M[i][i]], x));
