#!/usr/bin/env node
// route.js: solve the cable routes in a JSON file, print a report and write
// one STL per route next to it.
//   node route.js [routes.json] [name ...]
'use strict';
var fs = require('fs'), path = require('path'), FFC = require('./ffc.js');

var file = process.argv[2] || path.join(__dirname, 'routes.json');
var only = process.argv.slice(3);
var cfg = JSON.parse(fs.readFileSync(file, 'utf8'));
var dir = path.dirname(file), failed = 0;

function f1(v) { return v.toFixed(1); }
function f2(v) { return v.toFixed(2); }

cfg.routes.forEach(function (rt) {
  if (only.length && only.indexOf(rt.name) < 0) return;
  var cable = Object.assign({}, cfg.cable || {}, rt.cable || {});
  var spec = { start: rt.start, target: rt.target, cable: cable, length: 1 };
  var t0 = Date.now(), res, pr;
  if (rt.length === 'auto') {
    var best = FFC.shortest(spec);
    if (!best) { console.log(rt.name + ': no length found that keeps rMin'); failed++; return; }
    spec.length = best.L + (rt.slack || 0);
    pr = FFC.problem(spec);
    res = FFC.solve(pr, best.x);
    res.shortest = best.L;
    res.shortestR = best.rMin;
  } else {
    spec.length = rt.length;
    pr = FFC.problem(spec);
    res = FFC.solve(pr, null);
  }
  var c = pr.cable;
  console.log(rt.name + (res.ok ? '' : '  ** NOT CONVERGED (end pose off by ' + res.err.toExponential(1) + ') **'));
  console.log('  free length   ' + f1(res.L) + ' mm' + (res.shortest ? '  (shortest keeping R' + c.rMin + ': ' + f1(res.shortest) + ' with R' + f2(res.shortestR) + ', + slack ' + (rt.slack || 0) + ')' : '') +
              '; straight gap ' + f1(res.gap));
  console.log('  cable length  ' + f1(res.total) + ' mm end to end (insert ' + c.insert + ' + lead ' + c.lead +
              ' + free + outlet ' + c.slotDepth + ' + tail ' + c.tail + '); connector to outlet centre ' + f1(res.toOutlet));
  console.log('  bend radius   min ' + f2(res.rMin) + ' mm at ' + f1(res.rMinAt) + ' mm into the free length' +
              (res.bendOk ? '' : '  ** below rMin ' + c.rMin + ' **'));
  console.log('  twist         max ' + f2(res.twistMax) + ' deg/mm, ruling tilt max ' + f2(res.etaMax));
  console.log('  solver        ' + res.iters + ' iterations, ' + (Date.now() - t0) + ' ms');
  if (!res.ok || !res.bendOk) failed++;
  var out = path.join(dir, rt.name + '.stl');
  fs.writeFileSync(out, Buffer.from(FFC.stl(FFC.mesh(pr, res.x), rt.name)));
  console.log('  -> ' + path.relative(process.cwd(), out));
});
process.exitCode = failed ? 1 : 0;
