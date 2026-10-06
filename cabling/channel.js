#!/usr/bin/env node
// channel.js: solve a route and write the slot that carries its cable as
// OpenSCAD polyhedra, to be cut out of a housing.
//   node channel.js [routes.json] name [--force]
// The route's "channel": {width, thick, out, wall?, open_top?}: slot
// cross-section (mm) swept along the cable from inside the connector to the
// end of its tail, and the .scad file to write (relative to routes.json).
//   open_top: z; the slot reaches up along the cable's width (the way that
//     points up) to this height, so the cable can be laid in from above.
//   wall: also write module <name>_wall(): the slot plus this wall all
//     round, not open and ending at the outlet, for material the housing
//     must have round the slot (e.g. a fin below the floor).
// The file defines module <name>() (one polyhedron per piece of the cable;
// a kink gives two) and, with wall, module <name>_wall().
// Planar routes may give "waypoints" (plan x, y) for their starting path and
// "length": "guide" to take the free length from it.
'use strict';
var fs = require('fs'), path = require('path'), FFC = require('./ffc.js'), V = FFC.vec;

var file = process.argv[2] || path.join(__dirname, 'routes.json'), name = process.argv[3];
var cfg = JSON.parse(fs.readFileSync(file, 'utf8'));
var rt = cfg.routes.filter(function (r) { return r.name === name; })[0];
if (!rt || !rt.channel) { console.error('no route "' + name + '" with a channel in ' + file); process.exit(1); }
var cable = Object.assign({}, cfg.cable || {}, rt.cable || {});
var spec = { start: rt.start, target: rt.target, cable: cable, length: typeof rt.length === 'number' ? rt.length : 1,
             kink: rt.kink, planar: rt.planar, vertical: rt.vertical, obstacles: (cfg.obstacles || []).concat(rt.obstacles || []) };
var pr = FFC.problem(spec), t0 = Date.now(), res;
if (rt.waypoints) {
  res = FFC.solve(pr, FFC.guide(pr, rt.waypoints, rt.length), { maxIt: 200 });
} else res = FFC.solve(pr, null, { enumerate: rt.enumerate });
var ok = res.ok && res.bendOk && res.clearOk && res.selfOk;
console.log(name + (ok ? '' : '  ** NOT WITHIN THE LIMITS **') + ': free ' + res.L.toFixed(1) + ' mm, cable ' + res.total.toFixed(1) +
            ' mm end to end, R min ' + res.rMin.toFixed(2) + ', twist max ' + res.twistMax.toFixed(1) + ' deg/mm, smallest gap (film) ' +
            res.clearance.toFixed(2) + ' mm, passes itself at ' + res.selfDist.toFixed(2) + ' mm, energy ' + res.energy.toFixed(3) + ', ' + (Date.now() - t0) + ' ms');
if (!ok && process.argv.indexOf('--force') < 0) {
  console.log('not written: outside the limits (--force writes it anyway)');
  process.exit(1);
}

// Closed tubes along the cable, one per piece: at each sample the cross-
// section runs from lo to hi along the width (up: the way that points up)
// and +-th/2 along the normal. hiAt(q, up) may lengthen hi per sample.
var ch = rt.channel, S = FFC.samples(pr, res.x, 4), hw = ch.width / 2;
var sEnd = pr.cable.insert + (pr.kink ? pr.kink.lead : pr.cable.lead) + pr.L + pr.cable.slotDepth;   // the outlet's outer face
function tubes(samples, lo, hiAt, th) {
  var shells = [], cur = null;
  samples.forEach(function (q, i) {
    if (!cur || q.piece !== samples[i - 1].piece) { cur = { V: [], F: [] }; shells.push(cur); }
    var g = q.g, up = g[2] < 0 ? V.scl(g, -1) : g, n = V.col(q.R, 2), hi = hiAt(q, up);
    var a = V.add(q.p, V.scl(up, lo)), b = V.add(q.p, V.scl(up, hi));
    cur.V.push(V.add(b, V.scl(n, th / 2)), V.add(a, V.scl(n, th / 2)), V.add(a, V.scl(n, -th / 2)), V.add(b, V.scl(n, -th / 2)));
  });
  shells.forEach(function (sh) {
    var m = sh.V.length / 4;
    for (var i = 0; i + 1 < m; i++)
      for (var k = 0; k < 4; k++) {
        var k2 = (k + 1) % 4, a = 4 * i, b = a + 4;
        sh.F.push([a + k, b + k, b + k2], [a + k, b + k2, a + k2]);
      }
    var l = 4 * (m - 1);
    sh.F.push([0, 1, 2], [0, 2, 3], [l, l + 2, l + 1], [l, l + 3, l + 2]);
    // outward for OpenSCAD (clockwise seen from outside): flip if the signed volume is positive
    var vol = 0;
    sh.F.forEach(function (f) {
      var A = sh.V[f[0]], B = sh.V[f[1]], C = sh.V[f[2]];
      vol += (A[0] * (B[1] * C[2] - B[2] * C[1]) - A[1] * (B[0] * C[2] - B[2] * C[0]) + A[2] * (B[0] * C[1] - B[1] * C[0])) / 6;
    });
    if (vol > 0) sh.F = sh.F.map(function (f) { return [f[0], f[2], f[1]]; });
    sh.vol = Math.abs(vol);
  });
  return shells;
}
var slot = tubes(S, -hw, function (q, up) {
  var hi = hw;
  if (ch.open_top != null && up[2] > 0.2) {   // reach up to open_top along the width
    var top = q.p[2] + up[2] * hw;
    if (top < ch.open_top) hi += (ch.open_top - top) / up[2];
  }
  return hi;
}, ch.thick);
var wall = ch.wall ? tubes(S.filter(function (q) { return q.s <= sEnd + 1e-6; }), -(hw + ch.wall), function () { return hw + ch.wall; }, ch.thick + 2 * ch.wall) : null;

function n4(v) { return +v.toFixed(4); }
function poly(sh) {
  return '  polyhedron(\n    points = [' + sh.V.map(function (v) { return '[' + v.map(n4).join(', ') + ']'; }).join(',\n      ') + '],\n' +
         '    faces = [' + sh.F.map(function (f) { return '[' + f.join(', ') + ']'; }).join(', ') + '],\n    convexity = 8);\n';
}
var mod = name.replace(/[^A-Za-z0-9_]/g, '_'), out = path.resolve(path.dirname(file), ch.out);
var txt = '// generated by cabling/channel.js from routes.json, route "' + name + '" -- do not edit\n' +
  '// slot ' + ch.width + ' x ' + ch.thick + ' mm along the FFC' + (ch.open_top != null ? ', open upwards to z = ' + ch.open_top : '') +
  ': free ' + res.L.toFixed(1) + ' mm, R min ' + res.rMin.toFixed(2) + ' mm, twist max ' + res.twistMax.toFixed(1) +
  ' deg/mm, smallest film-to-wall gap ' + res.clearance.toFixed(2) + ' mm, passes itself at ' + res.selfDist.toFixed(2) + ' mm\n' +
  'module ' + mod + '() union() {\n' + slot.map(poly).join('') + '}\n';
if (wall) txt += '// the slot with ' + ch.wall + ' mm wall all round, up to the outlet\nmodule ' + mod + '_wall() union() {\n' + wall.map(poly).join('') + '}\n';
fs.writeFileSync(out, txt);
console.log('-> ' + path.relative(process.cwd(), out) + ': module ' + mod + '() (' + slot.length + ' pieces, ' +
            slot.reduce(function (a, s) { return a + s.vol; }, 0).toFixed(0) + ' mm3)' +
            (wall ? ', ' + mod + '_wall() (' + wall.reduce(function (a, s) { return a + s.vol; }, 0).toFixed(0) + ' mm3)' : ''));
