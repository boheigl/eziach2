#!/usr/bin/env node
// route.js: solve the cable routes in a JSON file, print a report and write
// STLs next to it: <name>.stl (the best option), <name>_opt<k>.stl (every
// topological option when there are obstacles) and <name>_obstacles.stl.
//   node route.js [routes.json] [name ...]
// Obstacles: cfg.obstacles apply to every route, route.obstacles to one;
// route.budget_s limits the search for topological options (seconds).
'use strict';
var fs = require('fs'), path = require('path'), FFC = require('./ffc.js');

var file = process.argv[2] || path.join(__dirname, 'routes.json');
var only = process.argv.slice(3);
var cfg = JSON.parse(fs.readFileSync(file, 'utf8'));
var dir = path.dirname(file), failed = 0;

function f1(v) { return v.toFixed(1); }
function f2(v) { return v.toFixed(2); }
function feasible(r) { return r.ok && r.bendOk && r.clearOk && r.selfOk; }
function write(name, data) {
  var out = path.join(dir, name);
  fs.writeFileSync(out, Buffer.from(data));
  return path.relative(process.cwd(), out);
}

cfg.routes.forEach(function (rt) {
  if (only.length && only.indexOf(rt.name) < 0) return;
  var cable = Object.assign({}, cfg.cable || {}, rt.cable || {});
  var obstacles = (cfg.obstacles || []).concat(rt.obstacles || []);
  var spec = { start: rt.start, target: rt.target, cable: cable, obstacles: obstacles, length: 1,
               kink: rt.kink, planar: rt.planar };
  var t0 = Date.now(), pr, options;
  if (rt.length === 'auto') {
    // every option at its own shortest length, plus slack
    var sh = FFC.shortest(spec);
    if (!sh) { console.log(rt.name + ': no length found within the limits'); failed++; return; }
    options = sh.options.map(function (o) {
      var p = FFC.problem(Object.assign({}, spec, { length: o.L + (rt.slack || 0) }));
      var r = FFC.solve(p, o.x);
      r.shortest = o.L; r.shortestR = o.rMin; r.sides = o.sides; r.pr = p;
      return r;
    });
  } else {
    pr = FFC.problem(Object.assign({}, spec, { length: rt.length }));
    var sol = FFC.solve(pr, null, Object.assign({ enumerate: rt.enumerate }, rt.budget_s ? { budget: rt.budget_s * 1000 } : {}));
    options = sol.options.map(function (r) { r.pr = pr; return r; });
    if (sol.options.truncated) console.log('  (search stopped after budget_s = ' + rt.budget_s + ' s: options may be missing)');
  }
  // best: within the limits first, then (auto) shortest or (fixed) least energy
  var order = options.map(function (r, i) { return i; }).sort(function (a, b) {
    var A = options[a], B = options[b];
    if (feasible(A) !== feasible(B)) return feasible(A) ? -1 : 1;
    return rt.length === 'auto' ? A.L - B.L : A.energy - B.energy;
  });
  var res = options[order[0]], c = res.pr.cable;

  console.log(rt.name + (res.ok ? '' : '  ** NOT CONVERGED (end pose off by ' + res.err.toExponential(1) + ') **'));
  if (obstacles.length) {
    console.log('  options       ' + options.length + ' topological (side of the film each obstacle lies on), best first:');
    order.forEach(function (i, rank) {
      var o = options[i];
      console.log('    ' + (rank + 1) + '. [' + o.sides.join(' ') + ']  ' +
                  (feasible(o) ? 'free ' + f1(o.L) + ' mm' + (o.shortest ? ' (shortest ' + f1(o.shortest) + ')' : '') +
                                 ', energy ' + o.energy.toFixed(3) + ', R min ' + f2(o.rMin) + ', gap ' + f2(o.clearance)
                               : 'not found'));
    });
  }
  console.log('  free length   ' + f1(res.L) + ' mm' + (res.shortest ? '  (shortest keeping R' + c.rMin + ': ' + f1(res.shortest) + ' with R' + f2(res.shortestR) + ', + slack ' + (rt.slack || 0) + ')' : '') +
              '; straight gap ' + f1(res.gap));
  console.log('  cable length  ' + f1(res.total) + ' mm end to end (insert ' + c.insert + ' + lead ' + c.lead +
              ' + free + outlet ' + c.slotDepth + ' + tail ' + c.tail + '); connector to outlet centre ' + f1(res.toOutlet));
  console.log('  bend radius   min ' + f2(res.rMin) + ' mm at ' + f1(res.rMinAt) + ' mm into the free length' +
              (c.rMin > 0 ? ' (limit R' + c.rMin + (res.rMin < c.rMin * 1.01 ? ', reached' : '') + ')' : '') +
              (res.bendOk ? '' : '  ** below the limit **'));
  if (obstacles.length)
    console.log('  obstacles     ' + obstacles.length + ', smallest gap ' + f2(res.clearance) + ' mm at ' + f1(res.clearAt) +
                ' mm into the free length (asked ' + c.clearance + ')' + (res.clearOk ? '' : '  ** INSIDE AN OBSTACLE **') +
                '; passes itself at ' + (isFinite(res.selfDist) ? f2(res.selfDist) + ' mm' : '-') + (res.selfOk ? '' : '  ** TOO CLOSE TO ITSELF **'));
  console.log('  twist         max ' + f2(res.twistMax) + ' deg/mm, ruling tilt max ' + f2(res.etaMax));
  console.log('  solver        ' + (Date.now() - t0) + ' ms');
  if (!feasible(res)) failed++;

  console.log('  -> ' + write(rt.name + '.stl', FFC.stl(FFC.mesh(res.pr, res.x), rt.name)));
  if (obstacles.length) {
    order.forEach(function (i, rank) {
      var o = options[i];
      if (feasible(o)) write(rt.name + '_opt' + (rank + 1) + '.stl', FFC.stl(FFC.mesh(o.pr, o.x), rt.name + ' option ' + (rank + 1)));
    });
    console.log('  -> ' + rt.name + '_opt<k>.stl for each option found');
    var V = [], F = [];
    obstacles.forEach(function (o) {
      var m = FFC.obstacleMesh(o), b = V.length;
      V = V.concat(m.V); m.F.forEach(function (f) { F.push([f[0] + b, f[1] + b, f[2] + b]); });
    });
    console.log('  -> ' + write(rt.name + '_obstacles.stl', FFC.stl({ V: V, F: F }, rt.name + ' obstacles')));
  }
});
process.exitCode = failed ? 1 : 0;
