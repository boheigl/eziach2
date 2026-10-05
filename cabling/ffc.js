// ffc.js: shape of a flat flexible cable (FFC) between a clamped start and an
// outlet it has to pass. One file for the browser (window.FFC) and node
// (require('./ffc.js')). See spec.md for the model and its assumptions.
//
// Frame along the cable, right-handed, columns of R:
//   t  along the cable, in the direction start -> outlet
//   w  across the width, towards contact 1
//   n  = t x w, normal to the film
//
// The film is thin and wide (about 0.15 x 15 mm), so it behaves like a paper
// strip: it does not stretch and cannot bend in its own plane (no geodesic
// curvature). It bends about w (curvature kappa, towards +n) and twists about
// t (tau). Energy per length, in units of the bending stiffness:
//     kappa^2 + 2 tau^2 + tau^4 / (kappa^2 + kappa_r^2).
// With kappa_r = 0 this is Sadowsky's (kappa^2 + tau^2)^2 / kappa^2 for a
// developable strip, in which twisting comes cheap while the film is bent
// (straight rulings at eta = tau / kappa across it). A twist without bending
// has to stretch the edges; kappa_r stands for that stretching energy.
// The cable takes the shape of least energy that joins the two clamped ends
// with the given length; kappa and tau are constant on each of N segments.
// Maximum bending: the film's curvature across its rulings,
// k1 = (kappa^2 + tau^2) / |kappa|, may not exceed 1 / rMin. The limit is a
// penalty that is stiffened until it holds (to 0.5 %), so where the free shape
// would bend tighter the cable lies on the limit radius instead, like a cable
// laid over a former.
// Obstacles: signed distance functions (cylinder, box, sphere, or any
// function of a point). At every node, five points across the width must keep
// half the film thickness plus a clearance from every obstacle, again as a
// penalty stiffened until it holds. Each obstacle can lie on either side of
// the cable; solve() works out every combination (topological option).

(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.FFC = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  // ---------------------------------------------------------------- defaults

  var CABLE = {
    pins: 14,        // contacts                                       [given]
    pitch: 1.0,      // mm                                             [given]
    width: 15.0,     // (pins + 1) x pitch, GCT FFC3A20 drawing        [datasheet]
    thick: 0.15,     // film away from the stiffened ends              [unverified]
    rMin: 2.0,       // maximum bending, as the smallest bend radius (mm);
                     // the solver keeps the cable at or above it, 0 = no limit [given]
    insert: 3.5,     // cable end inside the connector, below its face [estimated]
    lead: 2.0,       // straight (stiffened) beyond the connector face [chosen]
    slotDepth: 2.0,  // outlet wall thickness: held straight through it [chosen]
    tail: 10.0,      // cable drawn beyond the outlet                  [chosen]
    clearance: 0.5,  // film surface to any obstacle, mm               [chosen]
    selfGap: null,   // film centre to film centre where the cable passes itself, mm;
                     //   null: thick + clearance                       [chosen]
    segs: 48         // segments of the free length
  };

  function cableParams(c) {
    var o = {}, k;
    for (k in CABLE) o[k] = CABLE[k];
    if (c) for (k in c) if (c[k] !== undefined && c[k] !== null) o[k] = c[k];
    if (!(c && c.width)) o.width = (o.pins + 1) * o.pitch;
    return o;
  }

  // edge stretching of a pure twist, E t w^5 tau^4 / 1440, written as the
  // Sadowsky term (D w / 2) tau^4 / kappa_r^2 with D = E t^3 / 12
  function kappaR(c) { return Math.sqrt(60) * c.thick / (c.width * c.width); }

  // ------------------------------------------------------------ 3-vectors

  function add(a, b) { return [a[0] + b[0], a[1] + b[1], a[2] + b[2]]; }
  function sub(a, b) { return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]; }
  function scl(a, s) { return [a[0] * s, a[1] * s, a[2] * s]; }
  function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
  function cross(a, b) {
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
  }
  function len(a) { return Math.sqrt(dot(a, a)); }
  function unit(a) { var l = len(a); return [a[0] / l, a[1] / l, a[2] / l]; }

  // ----------------------------------------- 3x3 matrices, row-major [9]

  function mul(A, B) {
    var C = new Array(9);
    for (var i = 0; i < 3; i++)
      for (var j = 0; j < 3; j++)
        C[3 * i + j] = A[3 * i] * B[j] + A[3 * i + 1] * B[3 + j] + A[3 * i + 2] * B[6 + j];
    return C;
  }
  function mulv(A, v) {
    return [A[0] * v[0] + A[1] * v[1] + A[2] * v[2],
            A[3] * v[0] + A[4] * v[1] + A[5] * v[2],
            A[6] * v[0] + A[7] * v[1] + A[8] * v[2]];
  }
  function tr(A) { return [A[0], A[3], A[6], A[1], A[4], A[7], A[2], A[5], A[8]]; }
  function col(A, j) { return [A[j], A[3 + j], A[6 + j]]; }
  function fromCols(a, b, c) { return [a[0], b[0], c[0], a[1], b[1], c[1], a[2], b[2], c[2]]; }

  function expSO3(f) {
    var th2 = dot(f, f), th = Math.sqrt(th2), a, b;
    if (th < 1e-6) { a = 1 - th2 / 6; b = 0.5 - th2 / 24; }
    else { a = Math.sin(th) / th; b = (1 - Math.cos(th)) / th2; }
    var x = f[0], y = f[1], z = f[2];
    // I + a K + b K^2, K = [f]x
    return [1 - b * (y * y + z * z), -a * z + b * x * y, a * y + b * x * z,
            a * z + b * x * y, 1 - b * (x * x + z * z), -a * x + b * y * z,
            -a * y + b * x * z, a * x + b * y * z, 1 - b * (x * x + y * y)];
  }

  function logSO3(R) {
    var c = Math.max(-1, Math.min(1, (R[0] + R[4] + R[8] - 1) / 2));
    var th = Math.acos(c);
    var v = [(R[7] - R[5]) / 2, (R[2] - R[6]) / 2, (R[3] - R[1]) / 2];  // sin(th) * axis
    if (th < 1e-6) return v;
    if (Math.PI - th > 1e-4) return scl(v, th / Math.sin(th));
    // near pi: axis from the symmetric part
    var d = [R[0], R[4], R[8]], i = d[0] > d[1] ? (d[0] > d[2] ? 0 : 2) : (d[1] > d[2] ? 1 : 2);
    var ax = [(R[3 * i] + R[i]) / 2, (R[3 * i + 1] + R[3 + i]) / 2, (R[3 * i + 2] + R[6 + i]) / 2];
    ax[i] = (R[4 * i] + 1) / 2;
    ax = unit(ax);
    if (dot(ax, v) < 0) ax = scl(ax, -1);
    return scl(ax, th);
  }

  // ---------------------------------------------------------------- poses

  // pose {p, t, w}: t along the cable, w towards contact 1 (made orthonormal)
  function pose(p, t, w) {
    t = unit(t);
    w = unit(sub(w, scl(t, dot(w, t))));
    return { p: p.slice(), R: fromCols(t, w, cross(t, w)) };
  }
  function fromSpec(s) { return pose(s.p, s.t, s.w); }
  function toSpec(P) { return { p: P.p.slice(), t: col(P.R, 0), w: col(P.R, 1) }; }
  function advance(P, d) { return { p: add(P.p, scl(col(P.R, 0), d)), R: P.R.slice() }; }

  // one segment of length h with constant kappa, tau: exact screw motion
  function step(R, p, kap, tau, h) {
    var f = [tau * h, -kap * h, 0];          // body rotation: twist about t, bend about w
    var th2 = dot(f, f), a, b;
    if (th2 < 1e-10) { a = 0.5 - th2 / 24; b = 1 / 6 - th2 / 120; }
    else { var th = Math.sqrt(th2); a = (1 - Math.cos(th)) / th2; b = (th - Math.sin(th)) / (th2 * th); }
    // displacement V(f) (h e1), V = I + a K + b K^2
    var e = [h, 0, 0], k1 = cross(f, e), k2 = cross(f, k1);
    var d = [e[0] + a * k1[0] + b * k2[0], a * k1[1] + b * k2[1], a * k1[2] + b * k2[2]];
    return { R: mul(R, expSO3(f)), p: add(p, mulv(R, d)) };
  }

  // ----------------------------------------------------------- obstacles

  // spec -> {spec, sdf(p)}: signed distance, negative inside.
  //   {type: 'cylinder', p: centre, axis, r, h: length}   capped cylinder
  //   {type: 'box', p: centre, size: [a, b, c], x?, y?}   x, y: its axes (default world)
  //   {type: 'sphere', p: centre, r}
  //   {type: 'halfspace', p: point on the plane, normal}  solid behind the plane (against normal)
  //   {sdf: function (p) {...}}                           anything else (JS only)
  function obstacleFrame(o, xa, ya) {
    var X = unit(xa), Y = unit(sub(ya, scl(X, dot(ya, X))));
    return { X: X, Y: Y, Z: cross(X, Y) };
  }
  function compileObstacle(o) {
    if (typeof o.sdf === 'function') return { spec: o, sdf: o.sdf };
    var c = o.p;
    if (o.type === 'sphere') return { spec: o, sdf: function (q) { return len(sub(q, c)) - o.r; } };
    if (o.type === 'halfspace') {
      var nn = unit(o.normal);
      return { spec: o, sdf: function (q) { return dot(sub(q, c), nn); } };
    }
    if (o.type === 'cylinder') {
      var a = unit(o.axis || [0, 0, 1]), hh = o.h / 2;
      return { spec: o, sdf: function (q) {
        var d = sub(q, c), ax = dot(d, a), rad = len(sub(d, scl(a, ax)));
        var dx = rad - o.r, dy = Math.abs(ax) - hh;
        return Math.min(Math.max(dx, dy), 0) + Math.hypot(Math.max(dx, 0), Math.max(dy, 0));
      } };
    }
    if (o.type === 'box') {
      var F = obstacleFrame(o, o.x || [1, 0, 0], o.y || [0, 1, 0]), hs = scl(o.size, 0.5);
      return { spec: o, sdf: function (q) {
        var d = sub(q, c), u = [Math.abs(dot(d, F.X)) - hs[0], Math.abs(dot(d, F.Y)) - hs[1], Math.abs(dot(d, F.Z)) - hs[2]];
        return Math.min(Math.max(u[0], u[1], u[2]), 0) +
               Math.hypot(Math.max(u[0], 0), Math.max(u[1], 0), Math.max(u[2], 0));
      } };
    }
    throw new Error('unknown obstacle type: ' + o.type);
  }

  // triangle mesh of a primitive obstacle, for drawing and STL
  function obstacleMesh(o, seg) {
    var V = [], F = [], i;
    seg = seg || 48;
    if (o.type === 'cylinder') {
      var a = unit(o.axis || [0, 0, 1]), ref = Math.abs(a[0]) < 0.9 ? [1, 0, 0] : [0, 1, 0];
      var u = unit(cross(a, ref)), v = cross(a, u), hh = o.h / 2;
      for (i = 0; i < seg; i++) {
        var t = 2 * Math.PI * i / seg, rv = add(scl(u, o.r * Math.cos(t)), scl(v, o.r * Math.sin(t)));
        V.push(add(add(o.p, rv), scl(a, -hh)), add(add(o.p, rv), scl(a, hh)));
      }
      V.push(add(o.p, scl(a, -hh)), add(o.p, scl(a, hh)));
      var b0 = 2 * seg, b1 = b0 + 1;
      for (i = 0; i < seg; i++) {
        var j = (i + 1) % seg;
        F.push([2 * i, 2 * j, 2 * j + 1], [2 * i, 2 * j + 1, 2 * i + 1], [b0, 2 * j, 2 * i], [b1, 2 * i + 1, 2 * j + 1]);
      }
    } else if (o.type === 'box') {
      var Fr = obstacleFrame(o, o.x || [1, 0, 0], o.y || [0, 1, 0]), h = scl(o.size, 0.5);
      for (i = 0; i < 8; i++)
        V.push(add(add(add(o.p, scl(Fr.X, i & 1 ? h[0] : -h[0])), scl(Fr.Y, i & 2 ? h[1] : -h[1])), scl(Fr.Z, i & 4 ? h[2] : -h[2])));
      [[0, 2, 3, 1], [4, 5, 7, 6], [0, 1, 5, 4], [2, 6, 7, 3], [0, 4, 6, 2], [1, 3, 7, 5]]
        .forEach(function (q) { F.push([q[0], q[1], q[2]], [q[0], q[2], q[3]]); });
    } else if (o.type === 'halfspace') {
      // drawn as a 60 x 60 x 1 plate on the plane, behind it
      var nh = unit(o.normal), a1 = unit(cross(nh, Math.abs(nh[0]) < 0.9 ? [1, 0, 0] : [0, 1, 0])), a2 = cross(nh, a1);
      return obstacleMesh({ type: 'box', p: sub(o.p, scl(nh, 0.5)), size: [60, 60, 1], x: a1, y: a2 }, seg);
    } else if (o.type === 'sphere') {
      var nl = seg / 2;
      for (var la = 0; la <= nl; la++)
        for (var lo = 0; lo < seg; lo++) {
          var th = Math.PI * la / nl, ph = 2 * Math.PI * lo / seg;
          V.push(add(o.p, [o.r * Math.sin(th) * Math.cos(ph), o.r * Math.sin(th) * Math.sin(ph), o.r * Math.cos(th)]));
        }
      for (la = 0; la < nl; la++)
        for (lo = 0; lo < seg; lo++) {
          var p00 = la * seg + lo, p01 = la * seg + (lo + 1) % seg, p10 = p00 + seg, p11 = p01 + seg;
          F.push([p00, p10, p11], [p00, p11, p01]);
        }
    }
    return { V: V, F: F };
  }

  // ------------------------------------------------------------- problem

  // spec: {start, target: pose specs; length: free length, mm; cable: overrides}
  // start: the connector face, t pointing out of it.
  // target: the middle of the outlet, t pointing through it.
  function problem(spec) {
    var c = cableParams(spec.cable);
    var S = fromSpec(spec.start), T = fromSpec(spec.target);
    var N = c.segs;
    return {
      cable: c, N: N, L: spec.length, h: spec.length / N,
      start: S, target: T,
      P0: advance(S, c.lead),                 // free part starts after the lead
      P1: advance(T, -c.slotDepth / 2),       // and ends where the outlet wall begins
      kr: kappaR(c),
      kmax: c.rMin > 0 ? 1 / c.rMin : 0,      // maximum bending, as curvature
      mu: 0,                                  // its penalty weight, raised by solve()
      obs: (spec.obstacles || []).map(compileObstacle),
      dmin: c.thick / 2 + c.clearance,        // centre plane of the film to any obstacle
      selfGap: c.selfGap != null ? c.selfGap : c.thick + c.clearance,
      shifts: null,                           // per obstacle: moved by this while solve() slides them in
      muO: 0,                                 // obstacle penalty weight, raised by solve()
      Ls: c.width                             // scales rotation errors to mm
    };
  }

  function gap(pr) { return len(sub(pr.P1.p, pr.P0.p)); }
  function setLength(pr, L) { pr.L = L; pr.h = L / pr.N; }

  // unknowns x = [kappa_0 .. kappa_{N-1}, tau_0 .. tau_{N-1}]
  function nVars(N) { return 2 * N; }

  function integrate(pr, x) {
    var N = pr.N, Rs = [pr.P0.R], ps = [pr.P0.p], R = pr.P0.R, p = pr.P0.p;
    for (var i = 0; i < N; i++) {
      var s = step(R, p, x[i], x[N + i], pr.h);
      R = s.R; p = s.p; Rs.push(R); ps.push(p);
    }
    return { Rs: Rs, ps: ps };
  }

  function endFrom(pr, x, i0, R, p) {
    for (var i = i0; i < pr.N; i++) {
      var s = step(R, p, x[i], x[pr.N + i], pr.h);
      R = s.R; p = s.p;
    }
    return { R: R, p: p };
  }

  // end-pose error, 6 numbers: position (mm), rotation (rad x Ls)
  function poseErr(pr, E, T) {
    var dp = sub(E.p, T.p), dr = logSO3(mul(tr(T.R), E.R));
    return [dp[0], dp[1], dp[2], dr[0] * pr.Ls, dr[1] * pr.Ls, dr[2] * pr.Ls];
  }

  // film curvature across the rulings, and the ruling tilt; both made finite
  // at kappa = 0 by kappa_r
  function k1Of(kap, tau, kr) { return (kap * kap + tau * tau) / Math.sqrt(kap * kap + kr * kr); }
  function etaOf(kap, tau, kr) { return tau * kap / (kap * kap + kr * kr); }
  function energyDensity(kap, tau, kr) {
    var t2 = tau * tau;
    return kap * kap + 2 * t2 + t2 * t2 / (kap * kap + kr * kr);
  }

  var SMOOTH = 0.02;   // weight of the curvature-jump term, keeps kappa, tau from zig-zagging

  // residuals whose squared sum is the energy (plus smoothing), and their
  // Jacobian; three per segment keep the Gauss-Newton Hessian regular at zero
  // curvature
  function residuals(pr, x) {
    var N = pr.N, h = pr.h, n = 2 * N, m = 4 * N + 2 * (N - 1), kr2 = pr.kr * pr.kr;
    var r = new Float64Array(m), J = new Float64Array(m * n), sh = Math.sqrt(h), s2 = Math.sqrt(2 * h);
    for (var i = 0; i < N; i++) {
      var kap = x[i], tau = x[N + i], S = Math.sqrt(kap * kap + kr2);
      r[i] = sh * kap;                         J[i * n + i] = sh;
      r[N + i] = s2 * tau;                     J[(N + i) * n + N + i] = s2;
      r[2 * N + i] = sh * tau * tau / S;
      J[(2 * N + i) * n + i] = -sh * tau * tau * kap / (S * S * S);
      J[(2 * N + i) * n + N + i] = sh * 2 * tau / S;
    }
    var ws = Math.sqrt(SMOOTH * h), row = 3 * N;
    for (var v = 0; v < 2; v++)
      for (var j = 0; j < N - 1; j++, row++) {
        var a = v * N + j;
        r[row] = ws * (x[a + 1] - x[a]);
        J[row * n + a + 1] = ws;
        J[row * n + a] = -ws;
      }
    // maximum bending: penalty on k1 beyond kmax
    var wp = Math.sqrt(pr.mu * h);
    for (var q = 0; q < N && pr.kmax > 0; q++, row++) {
      var kq = x[q], tq = x[N + q], Sq = Math.sqrt(kq * kq + kr2), Aq = kq * kq + tq * tq;
      var over = Aq / Sq - pr.kmax;
      if (over <= 0) continue;
      r[row] = wp * over;
      J[row * n + q] = wp * (2 * kq / Sq - Aq * kq / (Sq * Sq * Sq));
      J[row * n + N + q] = wp * 2 * tq / Sq;
    }
    return { r: r, J: J, m: m };
  }

  // Obstacle check points: along the cable at most CHECK_STEP apart (every
  // segment split into sub(pr) stations, the last at its far node), and at
  // each station five across the width. Checking at the nodes alone let a
  // cable pass through a thin obstacle between two nodes.
  var ACROSS = [-1, -0.5, 0, 0.5, 1], CHECK_STEP = 1.0;
  function subN(pr) { return Math.max(1, Math.ceil(pr.h / CHECK_STEP)); }
  function nChecks(pr) { return pr.N * subN(pr) * ACROSS.length; }
  // calls fn(index, point, frame R, arc length) for segments i0 .. N-1,
  // index ((i * sub + m) * 5 + k)
  function eachCheck(pr, x, Rs, ps, i0, fn) {
    var M = subN(pr), K = ACROSS.length, hw = pr.cable.width / 2;
    for (var i = i0; i < pr.N; i++)
      for (var m = 1; m <= M; m++) {
        var st = m === M ? { R: Rs[i + 1], p: ps[i + 1] } : step(Rs[i], ps[i], x[i], x[pr.N + i], pr.h * m / M);
        var w = col(st.R, 1);
        for (var k = 0; k < K; k++)
          fn(((i * M + m - 1) * K) + k, add(st.p, scl(w, ACROSS[k] * hw)), st.R, pr.h * (i + m / M));
      }
  }
  // every check point of the cable x, as {q, R, s}
  function checkPoints(pr, x) {
    var F = integrate(pr, x), out = [];
    eachCheck(pr, x, F.Rs, F.ps, 0, function (j, q, R, s) { out.push({ q: q, R: R, s: s }); });
    return out;
  }
  function nearest(pr, q) {
    var d = Infinity, sh = pr.shifts;
    for (var o = 0; o < pr.obs.length; o++) d = Math.min(d, pr.obs[o].sdf(sh ? sub(q, sh[o]) : q));
    return d;
  }
  function obstaclesOn(pr) { return pr.obs.length > 0 && pr.muO > 0; }
  // obstacle residuals of segments i0 .. N-1 into out
  function obsRes(pr, x, Rs, ps, i0, out) {
    var wt = Math.sqrt(pr.muO * pr.h / (subN(pr) * ACROSS.length));
    eachCheck(pr, x, Rs, ps, i0, function (j, q) {
      var pen = pr.dmin - nearest(pr, q);
      out[j] = pen > 0 ? wt * pen : 0;
    });
    return out;
  }
  // Self-contact: three points across the width (edges, centre) at every
  // check station, against every other more than SELF_S along the cable,
  // must stay selfGap apart. Pairs are listed once per segment length.
  var SELF_ACROSS = [0, 2, 4], SELF_S = 5.0;
  function selfPairs(pr) {
    if (pr._pairs && pr._pairsH === pr.h) return pr._pairs;
    var M = subN(pr), st = [], pairs = [];
    for (var i = 0; i < pr.N; i++) for (var m = 1; m <= M; m++) st.push(pr.h * (i + m / M));
    var P = st.length * SELF_ACROSS.length;
    for (var a = 0; a < P; a++)
      for (var b = a + 1; b < P; b++)
        if (st[Math.floor(b / 3)] - st[Math.floor(a / 3)] >= SELF_S) pairs.push(a, b);
    pr._pairs = pairs; pr._pairsH = pr.h;
    return pairs;
  }
  function selfPoints(pr, x, Rs, ps) {
    var K = ACROSS.length, pts = [];
    eachCheck(pr, x, Rs, ps, 0, function (j, q) {
      var k = j % K;
      if (k === 0 || k === 2 || k === 4) pts.push(q);
    });
    return pts;
  }
  function nSelf(pr) { return pr.selfGap > 0 ? selfPairs(pr).length / 2 : 0; }
  function selfRes(pr, x, Rs, ps, out, off) {
    var pairs = selfPairs(pr), pts = selfPoints(pr, x, Rs, ps), wt = Math.sqrt(pr.muO * pr.h / 3);
    for (var k = 0; k < pairs.length; k += 2) {
      var a = pts[pairs[k]], b = pts[pairs[k + 1]];
      var dx = a[0] - b[0], dy = a[1] - b[1], dz = a[2] - b[2], pen = pr.selfGap - Math.sqrt(dx * dx + dy * dy + dz * dz);
      out[off + k / 2] = pen > 0 ? wt * pen : 0;
    }
    return out;
  }
  // smallest distance between two parts of the cable more than SELF_S apart
  function selfDistance(pr, x) {
    var F = integrate(pr, x), pairs = selfPairs(pr), pts = selfPoints(pr, x, F.Rs, F.ps), m = Infinity;
    for (var k = 0; k < pairs.length; k += 2) m = Math.min(m, len(sub(pts[pairs[k]], pts[pairs[k + 1]])));
    return m;
  }
  // obstacle and self-contact residuals, all of them
  function allObsRes(pr, x, Rs, ps, i0, out) {
    obsRes(pr, x, Rs, ps, i0, out);
    if (pr.selfGap > 0) selfRes(pr, x, Rs, ps, out, nChecks(pr));
    return out;
  }
  function nObsRes(pr) { return nChecks(pr) + nSelf(pr); }

  function tailFrom(pr, x, i0, R, p, Rs, ps) {
    for (var i = i0; i < pr.N; i++) {
      var s = step(R, p, x[i], x[pr.N + i], pr.h);
      R = s.R; p = s.p; Rs[i + 1] = R; ps[i + 1] = p;
    }
    return { R: R, p: p };
  }

  // end-pose error and obstacle residuals with their Jacobians (forward
  // differences: a change in segment i moves every node after it)
  function constraints(pr, x, T) {
    var N = pr.N, n = nVars(N), F = integrate(pr, x);
    var E = { R: F.Rs[N], p: F.ps[N] }, g = poseErr(pr, E, T);
    var Jg = new Float64Array(6 * n), eps = 1e-7, j, k;
    var on = obstaclesOn(pr), mo = on ? nObsRes(pr) : 0, mc = on ? nChecks(pr) : 0, per = subN(pr) * ACROSS.length;
    var ro = new Float64Array(mo), Jo = new Float64Array(mo * n), rj = new Float64Array(mo);
    if (on) allObsRes(pr, x, F.Rs, F.ps, 0, ro);
    var Rs = F.Rs.slice(), ps = F.ps.slice();
    for (j = 0; j < n; j++) {
      var i = j % N, keep = x[j];
      x[j] = keep + eps;
      var gj = poseErr(pr, tailFrom(pr, x, i, F.Rs[i], F.ps[i], Rs, ps), T);
      x[j] = keep;
      for (k = 0; k < 6; k++) Jg[k * n + j] = (gj[k] - g[k]) / eps;
      if (on) {
        x[j] = keep + eps;
        allObsRes(pr, x, Rs, ps, i, rj);
        x[j] = keep;
        for (k = i * per; k < mc; k++) Jo[k * n + j] = (rj[k] - ro[k]) / eps;
        for (k = mc; k < mo; k++) Jo[k * n + j] = (rj[k] - ro[k]) / eps;
      }
    }
    // rows that matter: touching, or about to (most pairs and checks are far)
    var act = [];
    for (k = 0; k < mo; k++) {
      if (ro[k] !== 0) { act.push(k); continue; }
      for (j = 0; j < n; j++) if (Jo[k * n + j] !== 0) { act.push(k); break; }
    }
    return { g: g, J: Jg, ro: ro, Jo: Jo, mo: mo, act: act };
  }

  // dense solve, partial pivoting; A is overwritten
  function solveDense(A, b, n) {
    for (var c = 0; c < n; c++) {
      var piv = c, best = Math.abs(A[c * n + c]);
      for (var r = c + 1; r < n; r++) {
        var v = Math.abs(A[r * n + c]);
        if (v > best) { best = v; piv = r; }
      }
      if (!(best > 1e-300)) return null;
      if (piv !== c) {
        for (var k = 0; k < n; k++) { var t = A[c * n + k]; A[c * n + k] = A[piv * n + k]; A[piv * n + k] = t; }
        var tb = b[c]; b[c] = b[piv]; b[piv] = tb;
      }
      var d = A[c * n + c];
      for (var r2 = c + 1; r2 < n; r2++) {
        var f = A[r2 * n + c] / d;
        if (f === 0) continue;
        for (var k2 = c; k2 < n; k2++) A[r2 * n + k2] -= f * A[c * n + k2];
        b[r2] -= f * b[c];
      }
    }
    var x = new Float64Array(n);
    for (var i = n - 1; i >= 0; i--) {
      var s = b[i];
      for (var k3 = i + 1; k3 < n; k3++) s -= A[i * n + k3] * x[k3];
      x[i] = s / A[i * n + i];
    }
    return x;
  }

  function sumsq(r) { var s = 0; for (var i = 0; i < r.length; i++) s += r[i] * r[i]; return s; }
  function norm1(g) { var s = 0; for (var i = 0; i < g.length; i++) s += Math.abs(g[i]); return s; }
  function normInf(g) { var s = 0; for (var i = 0; i < g.length; i++) s = Math.max(s, Math.abs(g[i])); return s; }

  // Gauss-Newton on the KKT system: least energy with the end pose as an
  // equality constraint, Levenberg damping, line search on an augmented
  // Lagrangian (smooth, so full steps are taken near the solution; an l1
  // merit would cut them short there).
  function solveTo(pr, x, T, opt) {
    opt = opt || {};
    var N = pr.N, n = nVars(N), K = n + 6, maxIt = opt.maxIt || 60, tol = opt.tol || 1e-7;
    var lam = 1e-6, rho = 1, nu = [0, 0, 0, 0, 0, 0], it, gInf = Infinity;
    x = Float64Array.from(x);
    function merit(xx) {
      var R = residuals(pr, xx);
      if (!R.r) return { phi: Infinity, g: null };
      var F = integrate(pr, xx), g = poseErr(pr, { R: F.Rs[N], p: F.ps[N] }, T), e = sumsq(R.r);
      if (obstaclesOn(pr)) e += sumsq(allObsRes(pr, xx, F.Rs, F.ps, 0, new Float64Array(nObsRes(pr))));
      var lg = 0;
      for (var q = 0; q < 6; q++) lg += nu[q] * g[q];
      return { phi: 0.5 * e + lg + 0.5 * rho * sumsq(g), g: g };
    }
    for (it = 0; it < maxIt; it++) {
      var Rr = residuals(pr, x);
      if (!Rr.r) break;
      var C = constraints(pr, x, T);
      gInf = normInf(C.g);
      var A = new Float64Array(K * K), b = new Float64Array(K), i, j, k;
      for (i = 0; i < n; i++) {
        for (j = i; j < n; j++) {
          var s = 0;
          for (k = 0; k < Rr.m; k++) s += Rr.J[k * n + i] * Rr.J[k * n + j];
          for (var a2 = 0; a2 < C.act.length; a2++) { k = C.act[a2]; s += C.Jo[k * n + i] * C.Jo[k * n + j]; }
          A[i * K + j] = s; A[j * K + i] = s;
        }
        A[i * K + i] += lam * (1 + A[i * K + i]);
        var gb = 0;
        for (k = 0; k < Rr.m; k++) gb += Rr.J[k * n + i] * Rr.r[k];
        for (var a3 = 0; a3 < C.act.length; a3++) { k = C.act[a3]; gb += C.Jo[k * n + i] * C.ro[k]; }
        b[i] = -gb;
      }
      for (k = 0; k < 6; k++) {
        for (j = 0; j < n; j++) { A[(n + k) * K + j] = C.J[k * n + j]; A[j * K + n + k] = C.J[k * n + j]; }
        b[n + k] = -C.g[k];
        A[(n + k) * K + n + k] = -1e-10;   // keeps the system regular where Jg loses rank
      }
      var sol = solveDense(A, b, K);
      if (!sol) { lam *= 100; continue; }
      // trust region: kappa and tau change by at most 0.2 /mm per step
      var dmax = 0, cap = 1;
      for (i = 0; i < n; i++) {
        dmax = Math.max(dmax, Math.abs(sol[i]));
        cap = Math.min(cap, 0.2 / (Math.abs(sol[i]) || 1e-300));
      }
      if (cap < 1) for (i = 0; i < n; i++) sol[i] *= cap;
      for (k = 0; k < 6; k++) nu[k] = sol[n + k];
      if (gInf < tol && dmax < 1e-9) break;
      var m0 = merit(x).phi, alpha = 1, accepted = false, xn;
      if (opt.trace) console.log('it', it, 'err', gInf, 'step', dmax, 'lambda', lam, 'merit', m0);
      for (var ls = 0; ls < 14; ls++, alpha /= 2) {
        xn = new Float64Array(n);
        for (i = 0; i < n; i++) xn[i] = x[i] + alpha * sol[i];
        var mn = merit(xn);
        if (mn.phi < m0 - 1e-12 * Math.abs(m0) || (mn.g && normInf(mn.g) < tol && mn.phi <= m0)) { accepted = true; break; }
      }
      if (!accepted) {
        lam = Math.min(lam * 10, 1e6);
        rho = Math.min(rho * 2, 1e6);
        if (gInf < tol) break;            // at a minimum within round-off
        continue;
      }
      x = xn;
      lam = Math.max(lam / 3, 1e-9);
      if (alpha === 1 && dmax < 1e-9) break;
    }
    var F = integrate(pr, x);
    gInf = normInf(poseErr(pr, { R: F.Rs[N], p: F.ps[N] }, T));
    return { x: x, ok: gInf < (opt.okTol || 1e-4), err: gInf, iters: it };
  }

  // interpolate two poses: position linearly, rotation along the geodesic
  function lerpPose(A, B, s) {
    var d = logSO3(mul(tr(A.R), B.R));
    return { p: add(A.p, scl(sub(B.p, A.p), s)), R: mul(A.R, expSO3(scl(d, s))) };
  }

  // A cold start is a single, almost straight line: an exactly straight cable
  // cannot move sideways or shorten to first order, so it gets a very low,
  // untwisted curvature (radius STRAIGHT_R).
  var STRAIGHT_R = 10000;   // mm
  function straight(N) {
    var x = new Float64Array(2 * N);
    for (var i = 0; i < N; i++) x[i] = 1 / STRAIGHT_R;
    return x;
  }

  // carry a solution over to another segment count
  function resample(x, N) {
    if (!x) return null;
    var M = x.length / 2;
    if (M === N) return Float64Array.from(x);
    var y = new Float64Array(2 * N);
    for (var i = 0; i < N; i++) {
      var j = Math.min(M - 1, Math.floor((i + 0.5) * M / N));
      y[i] = x[j]; y[N + i] = x[M + j];
    }
    return y;
  }

  var MU0 = 1e3, MU_MAX = 1e9, BEND_TOL = 0.005;
  var TRACE = typeof process !== 'undefined' && process.env && process.env.FFC_TRACE;
  var MUO = 1e3, CLEAR_TOL = 0.02;   // obstacle penalty weight; mm allowed into the gap
  var SLIDE = 1.0;                   // mm the obstacles slide in per step, at most

  var MAX_SIDES = 12;  // obstacles whose sides are enumerated; any beyond stay on the side they come to

  // Without x0: the free shape first (obstacles off), from a single almost
  // straight line whose end is moved to the outlet. With obstacles, every
  // topological option is then solved: each obstacle on either side of the
  // cable (see topologies()). The best option is returned (within the limits
  // first, then least energy), all of them in .options. With x0 (warm) the
  // shape follows from it, keeping its topology, as a real cable would.
  function solve(pr, x0, opt) {
    opt = opt || {};
    if (x0) {
      pr.mu = pr.kmax > 0 ? MU0 : 0;
      pr.muO = pr.obs.length ? MUO : 0;
      return limits(pr, warm(pr, resample(x0, pr.N), opt));
    }
    pr.mu = pr.kmax > 0 ? MU0 : 0;
    pr.muO = 0;
    var free = limits(pr, continuation(pr, straight(pr.N), opt));
    if (!pr.obs.length || !free.ok) { free.sides = []; free.options = [free]; return free; }
    var opts = opt.enumerate === false ? [pushOut(pr, free)] : topologies(pr, free, opt);
    var best = opts.reduce(function (b, r) { return better(r, b) ? r : b; }, null);
    if (!best) {                                   // every branch got stuck
      best = finish(pr, { x: free.x, ok: false, err: Infinity, iters: free.iters });
      best.sides = [];
    }
    best.options = opts;
    return best;
  }

  // One option only (opt.enumerate === false): every obstacle stays on the
  // side the free cable passes it. The required gap starts at the deepest
  // point the free cable reaches into the obstacles (so it is met) and grows
  // in steps to the full gap; the cable is pushed out evenly from all of them.
  function pushOut(pr, free) {
    var full = pr.dmin, cur = free, iters = free.iters, d = full - free.pen, step = 1.0;
    pr.muO = MUO;
    while (d < full && step > 0.02) {
      var to = Math.min(full, d + step);
      pr.dmin = to;
      var r2 = solveTo(pr, cur.x, pr.P1, { maxIt: 200 });
      pr.dmin = full;
      r2 = finish(pr, r2);
      iters += r2.iters;
      if (TRACE) console.log('push gap', (to - pr.cable.thick / 2).toFixed(2), 'ok', r2.ok);
      if (r2.ok) { cur = r2; d = to; step = Math.min(1.0, step * 1.5); }
      else step /= 2;
    }
    var out = limits(pr, finish(pr, d >= full ? cur : { x: cur.x, ok: false, err: Infinity, iters: 0 }));
    out.iters = iters;
    out.sides = sideLabels(pr, out.x);
    return out;
  }

  // The direction across which obstacle o can pass the cable x: at the cable
  // point nearest to it (or deepest inside it), the way out of the obstacle,
  // square to the cable.
  function sideDir(pr, x, o) {
    var e = 1e-4, ob = pr.obs[o], best = Infinity, q0 = null, t0 = null, n0 = null;
    checkPoints(pr, x).forEach(function (c) {
      var d = ob.sdf(c.q);
      if (d < best) { best = d; q0 = c.q; t0 = col(c.R, 0); n0 = col(c.R, 2); }
    });
    var g = [0, 1, 2].map(function (a) {
      var qp = q0.slice(), qm = q0.slice();
      qp[a] += e; qm[a] -= e;
      return (ob.sdf(qp) - ob.sdf(qm)) / (2 * e);
    });
    g = sub(g, scl(t0, dot(g, t0)));
    return len(g) > 1e-6 ? unit(g) : n0;
  }

  // Every combination of sides, as a tree: the obstacles go in one after
  // another, in the order the free cable passes them, and each splits the
  // search in two (its side -1 or +1, see slideOne()). Combinations sharing
  // their first choices share that work; a branch that gets stuck is dropped
  // with everything below it, and so is one that reaches an arrangement
  // (placed obstacles, each on its side) already explored. opt.budget (ms)
  // stops the search early (.truncated on the result list); opt.onOption(r)
  // is called for each option as it is found.
  function topologies(pr, free, opt) {
    // opt.enumerate === false: every obstacle stays on the side the free cable
    // passes it (one option)
    var nO = pr.obs.length, k = opt && opt.enumerate === false ? 0 : Math.min(nO, MAX_SIDES), out = [], t0 = Date.now();
    var budget = (opt && opt.budget) || Infinity;
    // order: where along the free cable each obstacle comes nearest
    var pts = checkPoints(pr, free.x);
    var order = pr.obs.map(function (ob, o) {
      var best = Infinity, at = 0;
      pts.forEach(function (c) { var d = ob.sdf(c.q); if (d < best) { best = d; at = c.s; } });
      return { o: o, at: at };
    }).sort(function (a, b) { return a.at - b.at; }).map(function (q) { return q.o; });
    var placed = pr.obs.map(function () { return false; });
    var truncated = false, slides = 0, seen = {};
    function leaf(r) {
      var res = limits(pr, finish(pr, r));
      res.sides = sideLabels(pr, res.x);
      if (!out.some(function (q) { return q.sides.join() === res.sides.join() && Math.abs(q.energy - res.energy) < 1e-4 * (1 + res.energy); })) {
        out.push(res);
        if (opt && opt.onOption) opt.onOption(res);
      }
    }
    function dfs(i, cur) {
      if (i === nO) { leaf(cur); return; }
      if (Date.now() - t0 > budget) { truncated = true; return; }
      var o = order[i];
      (i < k ? [-1, 1] : [-1]).forEach(function (side) {
        if (truncated) return;
        var r = slideOne(pr, cur, o, side, placed);
        slides++;
        if (TRACE) console.log('tree', order.slice(0, i + 1).map(function (q) { return q + 1; }).join(' '), 'side', side, 'ok', r.ok);
        if (!r.ok) return;
        placed[o] = true;
        var lab = sideLabels(pr, r.x), key = i + ':' + order.slice(0, i + 1).map(function (q) { return lab[q]; }).join('');
        if (!seen[key]) { seen[key] = true; dfs(i + 1, r); }
        else if (TRACE) console.log('tree', 'same arrangement as before:', key);
        placed[o] = false;
      });
    }
    pr.muO = MUO;
    dfs(0, free);
    pr.shifts = null;
    out.truncated = truncated;
    out.slides = slides;
    return out;
  }

  // which side of the film each obstacle lies on, at the cable point nearest
  // to it: '+n' or '-n' (n = t x w, the film normal)
  function sideLabels(pr, x) {
    var e = 1e-4, pts = checkPoints(pr, x);
    return pr.obs.map(function (ob) {
      var best = Infinity, q0 = null, n0 = null;
      pts.forEach(function (c) { var d = ob.sdf(c.q); if (d < best) { best = d; q0 = c.q; n0 = col(c.R, 2); } });
      var g = [0, 1, 2].map(function (a) {
        var qp = q0.slice(), qm = q0.slice();
        qp[a] += e; qm[a] -= e;
        return (ob.sdf(qp) - ob.sdf(qm)) / (2 * e);
      });
      return dot(g, n0) < 0 ? '+n' : '-n';   // g points from the obstacle to the cable
    });
  }

  // Bring obstacle o in from the given side, with the obstacles in `placed`
  // in place and the rest out of the way: first move it along side x its
  // direction until it is clear of the cable (carried across, side +1, it
  // has to meet the cable first; side -1 and already clear: nothing to do),
  // then slide it back in steps, the cable pushed ahead.
  var FAR = [1e9, 1e9, 1e9], MAX_FAILS = 8;
  function slideOne(pr, res, o, side, placed) {
    var cur = res, iters = res.iters, hw = pr.cable.width / 2;
    var shifts = pr.obs.map(function (ob, i) { return placed[i] ? [0, 0, 0] : FAR; });
    function done(ok) {
      shifts[o] = [0, 0, 0];
      pr.shifts = shifts.slice();
      var out = ok ? finish(pr, cur) : finish(pr, { x: cur.x, ok: false, err: Infinity, iters: iters });
      out.iters = iters;
      return out;
    }
    // how far obstacle o, moved by v, reaches into the gap around the cable
    function penOne(v) {
      var d = Infinity;
      checkPoints(pr, cur.x).forEach(function (c) { d = Math.min(d, pr.obs[o].sdf(sub(c.q, v))); });
      return pr.dmin - d;
    }
    var dir = scl(sideDir(pr, cur.x, o), side), hit = penOne([0, 0, 0]) > 0;
    if (!hit && side < 0) return done(true);        // clear on this side already
    var D = 0;
    while (D < 4096) {
      D = D < 1 ? 1 : hit ? 2 * D : D + 1;
      if (penOne(scl(dir, D)) > 0) hit = true;
      else if (hit) break;
    }
    if (!hit || D >= 4096) return done(false);       // it never meets the cable this way
    var at = D, step = SLIDE, fails = 0;
    while (at > 0 && step > 0.05 && fails < MAX_FAILS) {
      var to = Math.max(0, at - step);
      if (penOne(scl(dir, to)) <= 0) { at = to; continue; }    // not touching yet
      shifts[o] = scl(dir, to);
      pr.shifts = shifts.slice();
      // intermediate positions need not be exact; the last one is
      var r2 = finish(pr, solveTo(pr, cur.x, pr.P1, to > 0 ? { maxIt: 150, tol: 1e-5, okTol: 0.01 } : { maxIt: 150 }));
      iters += r2.iters;
      if (r2.ok && r2.pen <= 0.5) { cur = r2; at = to; fails = 0; step = Math.min(SLIDE, step * 1.5); }
      else { step /= 2; fails++; }
    }
    return done(at <= 0);
  }

  function feasible(r) { return r.ok && r.bendOk && r.clearOk && r.selfOk; }
  function better(r, best) {
    if (!best) return true;
    if (feasible(r) !== feasible(best)) return feasible(r);
    if (r.ok !== best.ok) return r.ok;
    return r.energy < best.energy;
  }

  // from x: straight to the target, else by continuation
  function warm(pr, x, opt) {
    if (!opt.cold) {
      var direct = solveTo(pr, x, pr.P1, opt);
      if (direct.ok) return finish(pr, direct);
    }
    return continuation(pr, x, opt);
  }

  // stiffen the bending and obstacle penalties until both limits hold; a step
  // that fails is retried with a smaller increase
  function limits(pr, res) {
    var iters = res.iters, c = pr.cable, fac = 10;
    for (var k = 0; k < 40 && res.ok; k++) {
      var bendBad = pr.kmax > 0 && res.rMin < c.rMin * (1 - BEND_TOL) && pr.mu < MU_MAX;
      var obsBad = pr.muO > 0 && (res.pen > CLEAR_TOL || !res.selfOk) && pr.muO < MU_MAX;
      if (!bendBad && !obsBad) break;
      var mu = pr.mu, muO = pr.muO;
      if (bendBad) pr.mu *= fac;
      if (obsBad) pr.muO *= fac;
      var r2 = warm(pr, res.x, { maxIt: 200 });
      if (TRACE) console.log('limits mu', pr.mu, 'muO', pr.muO, 'ok', r2.ok, 'pen', r2.pen, 'rMin', r2.rMin);
      iters += r2.iters;
      if (r2.ok) { res = r2; fac = Math.min(10, fac * 2); continue; }
      pr.mu = mu; pr.muO = muO;
      if ((fac = Math.sqrt(fac)) < 1.05) break;
    }
    res.iters = iters;
    return res;
  }

  // continuation from the end pose of x to the target, smaller steps on failure
  function continuation(pr, x, opt) {
    var N = pr.N;
    var F = integrate(pr, x), E = { R: F.Rs[N], p: F.ps[N] };
    var s = 0, ds = opt.step || 0.125, last = null, iters = 0;
    while (s < 1 - 1e-12) {
      var s1 = Math.min(1, s + ds), T = lerpPose(E, pr.P1, s1);
      var res = solveTo(pr, x, T, opt);
      iters += res.iters;
      if (TRACE) console.log('continuation', s1.toFixed(4), 'ok', res.ok, 'err', res.err.toExponential(1), 'its', res.iters);
      if (res.ok) { x = res.x; s = s1; last = res; ds = Math.min(ds * 1.5, 0.5); }
      else if ((ds /= 2) < 1 / 512) break;
    }
    var out = last && s >= 1 - 1e-12 ? last : { x: x, ok: false, err: Infinity, iters: 0 };
    out.iters = iters;
    return finish(pr, out);
  }

  // ------------------------------------------------------------ analysis

  function finish(pr, res) {
    var N = pr.N, x = res.x, c = pr.cable, kmax = 0, tmax = 0, emax = 0, energy = 0, iAt = 0;
    for (var i = 0; i < N; i++) {
      var k = k1Of(x[i], x[N + i], pr.kr);
      energy += pr.h * energyDensity(x[i], x[N + i], pr.kr);
      if (k > kmax) { kmax = k; iAt = i; }
      tmax = Math.max(tmax, Math.abs(x[N + i]));
      emax = Math.max(emax, Math.abs(etaOf(x[i], x[N + i], pr.kr)));
    }
    res.L = pr.L;
    res.total = c.insert + c.lead + pr.L + c.slotDepth + c.tail;
    res.toOutlet = c.insert + c.lead + pr.L + c.slotDepth / 2;
    res.energy = energy;
    res.rMin = kmax > 0 ? 1 / kmax : Infinity;
    res.rMinAt = (iAt + 0.5) * pr.h;
    res.bendOk = res.rMin >= c.rMin * (1 - BEND_TOL);
    res.twistMax = tmax * 180 / Math.PI;      // deg/mm
    res.etaMax = emax;
    res.gap = gap(pr);
    // obstacles: deepest penetration of the required gap, and the smallest
    // gap between film surface and obstacle, over the free length
    res.pen = 0; res.clearance = Infinity; res.clearAt = null;
    if (pr.obs.length) {
      checkPoints(pr, x).forEach(function (cp) {
        var d = nearest(pr, cp.q);
        res.pen = Math.max(res.pen, pr.dmin - d);
        if (d - c.thick / 2 < res.clearance) { res.clearance = d - c.thick / 2; res.clearAt = cp.s; }
      });
    }
    // self-contact, checked where there are obstacles (where the solver keeps it)
    res.selfDist = pr.obs.length && pr.selfGap > 0 ? selfDistance(pr, x) : Infinity;
    res.selfOk = !(pr.obs.length && pr.selfGap > 0) || res.selfDist >= pr.selfGap - CLEAR_TOL;
    res.clearOk = res.pen <= CLEAR_TOL;
    return res;
  }

  // Shortest free length for which a shape within the bending limit and clear
  // of the obstacles exists, for each topological option (bisection, each
  // step starting from the last shape, so the option keeps its topology).
  // Returns the shortest; .options holds every feasible option at its own
  // shortest length. Slack is added by the caller.
  function shortest(spec, opt) {
    opt = opt || {};
    var pr = problem(Object.assign({}, spec, { length: 1 }));
    var lo0 = gap(pr) + 0.05, hi = Math.max(1.5 * lo0, lo0 + 20), first = null;
    for (var tries = 0; tries < 8; tries++) {
      setLength(pr, hi);
      first = solve(pr, null);
      if (first.options.some(feasible)) break;
      lo0 = hi; hi *= 1.6; first = null;
    }
    if (!first) return null;
    var res = first.options.filter(feasible).map(function (o) {
      var lo = lo0, h = hi, best = o, x = o.x;
      for (var k = 0; k < (opt.iters || 16) && h - lo > (opt.tol || 0.05); k++) {
        var mid = (lo + h) / 2;
        setLength(pr, mid);
        var rm = solve(pr, x);
        if (feasible(rm)) { h = mid; best = rm; x = rm.x; } else lo = mid;
      }
      best.sides = o.sides;
      return best;
    });
    var out = res.reduce(function (b, r) { return !b || r.L < b.L ? r : b; }, null);
    out.options = res;
    return out;
  }

  // ------------------------------------------------------------- geometry

  // samples along the whole cable, connector end to tail: centre p, frame R,
  // arc length s. The film is drawn as a ribbon, its edges at +-width/2 along
  // w; where it bends and twists at once, the real film forms cones and its
  // edges lie off these by up to the ruling tilt.
  function samples(pr, x, per) {
    per = per || 4;
    var c = pr.cable, N = pr.N, out = [], i, k;
    function put(P, s) { out.push({ p: P.p, R: P.R, g: col(P.R, 1), s: s }); }
    put(advance(pr.start, -c.insert), 0);
    put(pr.start, c.insert);
    put(pr.P0, c.insert + c.lead);
    var R = pr.P0.R, p = pr.P0.p, s0 = c.insert + c.lead;
    for (i = 0; i < N; i++) {
      for (k = 1; k <= per; k++)
        put(step(R, p, x[i], x[N + i], pr.h * k / per), s0 + pr.h * (i + k / per));
      var s1 = step(R, p, x[i], x[N + i], pr.h);
      R = s1.R; p = s1.p;
    }
    var E = { R: R, p: p }, s = s0 + pr.L;
    put(advance(E, c.slotDepth), s + c.slotDepth);
    put(advance(E, c.slotDepth + c.tail), s + c.slotDepth + c.tail);
    return out;
  }

  // closed rectangular tube of the film: 4 vertices per sample
  function mesh(pr, x, per) {
    var S = samples(pr, x, per), c = pr.cable, hw = c.width / 2, ht = c.thick / 2;
    var V = [], F = [];
    S.forEach(function (q) {
      var n = col(q.R, 2), e = scl(q.g, hw);
      V.push(add(add(q.p, e), scl(n, ht)), add(sub(q.p, e), scl(n, ht)),
             add(sub(q.p, e), scl(n, -ht)), add(add(q.p, e), scl(n, -ht)));
    });
    for (var i = 0; i + 1 < S.length; i++) {
      var a = 4 * i, b = a + 4;
      for (var k = 0; k < 4; k++) {
        var k2 = (k + 1) % 4;
        F.push([a + k, b + k, b + k2], [a + k, b + k2, a + k2]);
      }
    }
    var l = 4 * (S.length - 1);
    F.push([0, 1, 2], [0, 2, 3], [l, l + 2, l + 1], [l, l + 3, l + 2]);   // end caps, wound like the sides
    return { V: V, F: F, samples: S };
  }

  // binary STL as a Uint8Array
  function stl(m, name) {
    var buf = new ArrayBuffer(84 + 50 * m.F.length), dv = new DataView(buf), o = 80;
    var head = (name || 'ffc').slice(0, 79);
    for (var i = 0; i < head.length; i++) dv.setUint8(i, head.charCodeAt(i));
    dv.setUint32(o, m.F.length, true); o += 4;
    m.F.forEach(function (f) {
      var A = m.V[f[0]], B = m.V[f[1]], C = m.V[f[2]], nn = cross(sub(B, A), sub(C, A)), l = len(nn) || 1;
      [scl(nn, 1 / l), A, B, C].forEach(function (v) {
        dv.setFloat32(o, v[0], true); dv.setFloat32(o + 4, v[1], true); dv.setFloat32(o + 8, v[2], true); o += 12;
      });
      o += 2;
    });
    return new Uint8Array(buf);
  }

  return {
    CABLE: CABLE, cableParams: cableParams, kappaR: kappaR,
    pose: pose, fromSpec: fromSpec, toSpec: toSpec,
    problem: problem, setLength: setLength, gap: gap,
    solve: solve, shortest: shortest, resample: resample,
    compileObstacle: compileObstacle, obstacleMesh: obstacleMesh,
    samples: samples, mesh: mesh, stl: stl,
    vec: { add: add, sub: sub, scl: scl, dot: dot, cross: cross, len: len, unit: unit, col: col, mul: mul, mulv: mulv, expSO3: expSO3, logSO3: logSO3 }
  };
});
