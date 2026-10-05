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
    rMin: 2.0,       // smallest allowed bend radius, mm               [chosen]
    insert: 3.5,     // cable end inside the connector, below its face [estimated]
    lead: 2.0,       // straight (stiffened) beyond the connector face [chosen]
    slotDepth: 2.0,  // outlet wall thickness: held straight through it [chosen]
    tail: 10.0,      // cable drawn beyond the outlet                  [chosen]
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
    var N = pr.N, h = pr.h, n = 2 * N, m = 3 * N + 2 * (N - 1), kr2 = pr.kr * pr.kr;
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
    return { r: r, J: J, m: m };
  }

  function constraints(pr, x, T) {
    var N = pr.N, n = nVars(N), F = integrate(pr, x);
    var E = { R: F.Rs[N], p: F.ps[N] }, g = poseErr(pr, E, T);
    var Jg = new Float64Array(6 * n), eps = 1e-7;
    for (var j = 0; j < n; j++) {
      var i = j % N, keep = x[j];
      x[j] = keep + eps;
      var gj = poseErr(pr, endFrom(pr, x, i, F.Rs[i], F.ps[i]), T);
      x[j] = keep;
      for (var k = 0; k < 6; k++) Jg[k * n + j] = (gj[k] - g[k]) / eps;
    }
    return { g: g, J: Jg };
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
  // equality constraint, Levenberg damping, l1 merit line search.
  function solveTo(pr, x, T, opt) {
    opt = opt || {};
    var N = pr.N, n = nVars(N), K = n + 6, maxIt = opt.maxIt || 60, tol = opt.tol || 1e-7;
    var lam = 1e-6, rho = 1, it, gInf = Infinity;
    x = Float64Array.from(x);
    function merit(xx) {
      var R = residuals(pr, xx);
      if (!R.r) return { phi: Infinity, g: null };
      var F = integrate(pr, xx), g = poseErr(pr, { R: F.Rs[N], p: F.ps[N] }, T);
      return { phi: 0.5 * sumsq(R.r) + rho * norm1(g), g: g };
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
          A[i * K + j] = s; A[j * K + i] = s;
        }
        A[i * K + i] += lam * (1 + A[i * K + i]);
        var gb = 0;
        for (k = 0; k < Rr.m; k++) gb += Rr.J[k * n + i] * Rr.r[k];
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
      for (k = 0; k < 6; k++) rho = Math.max(rho, 2 * Math.abs(sol[n + k]));
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
        if (gInf < tol) break;            // at a minimum within round-off
        continue;
      }
      x = xn;
      lam = Math.max(lam / 3, 1e-9);
      if (alpha === 1 && dmax < 1e-9) break;
    }
    var F = integrate(pr, x);
    gInf = normInf(poseErr(pr, { R: F.Rs[N], p: F.ps[N] }, T));
    return { x: x, ok: gInf < 1e-4, err: gInf, iters: it };
  }

  // interpolate two poses: position linearly, rotation along the geodesic
  function lerpPose(A, B, s) {
    var d = logSO3(mul(tr(A.R), B.R));
    return { p: add(A.p, scl(sub(B.p, A.p), s)), R: mul(A.R, expSO3(scl(d, s))) };
  }

  // a straight cable cannot move sideways or shorten to first order, so a cold
  // start begins from a slightly wavy one, untwisted or twisted either way
  function wavy(N, L, twist) {
    var x = new Float64Array(2 * N), a = 2 / L;
    for (var i = 0; i < N; i++) {
      x[i] = a * Math.sin(2 * Math.PI * (i + 0.5) / N);
      x[N + i] = twist * a * Math.sin(Math.PI * (i + 0.5) / N);
    }
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

  // From x0 (warm): straight to the target, else by continuation. Without x0
  // the cable has several resting shapes (equilibria); three starts are tried
  // and the one of least energy is kept.
  function solve(pr, x0, opt) {
    opt = opt || {};
    if (!x0) {
      var best = null;
      [0, 1, -1].forEach(function (tw) {
        var r = continuation(pr, wavy(pr.N, pr.L, tw), opt);
        if (r.ok && (!best || !best.ok || r.energy < best.energy)) best = r;
        else if (!best) best = r;
      });
      return best;
    }
    var x = resample(x0, pr.N);
    if (!opt.cold) {
      var direct = solveTo(pr, x, pr.P1, opt);
      if (direct.ok) return finish(pr, direct);
    }
    return continuation(pr, x, opt);
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
    res.bendOk = res.rMin >= c.rMin;
    res.twistMax = tmax * 180 / Math.PI;      // deg/mm
    res.etaMax = emax;
    res.gap = gap(pr);
    return res;
  }

  // shortest free length whose resting shape keeps rMin; slack is added after
  function shortest(spec, opt) {
    opt = opt || {};
    var pr = problem(Object.assign({}, spec, { length: 1 }));
    var lo = gap(pr) + 0.05, hi = Math.max(1.5 * lo, lo + 20), best = null, x = null;
    for (var tries = 0; tries < 8; tries++) {
      setLength(pr, hi);
      var r = solve(pr, x, { cold: !x });
      if (r.ok && r.bendOk) { best = r; x = r.x; break; }
      lo = hi; hi *= 1.6; x = null;
    }
    if (!best) return null;
    for (var k = 0; k < (opt.iters || 16) && hi - lo > (opt.tol || 0.05); k++) {
      var mid = (lo + hi) / 2;
      setLength(pr, mid);
      var rm = solve(pr, x);
      if (rm.ok && rm.bendOk) { hi = mid; best = rm; x = rm.x; } else lo = mid;
    }
    return best;
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
    F.push([0, 2, 1], [0, 3, 2], [l, l + 1, l + 2], [l, l + 2, l + 3]);
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
    samples: samples, mesh: mesh, stl: stl,
    vec: { add: add, sub: sub, scl: scl, dot: dot, cross: cross, len: len, unit: unit, col: col, mul: mul, mulv: mulv, expSO3: expSO3, logSO3: logSO3 }
  };
});
