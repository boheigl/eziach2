// Camera navigation for the phone pages (discant/, bass/, assembly/), inlined into each
// page by embed_parts.py. Always on in the view, no mode to switch:
//   one finger / left mouse button: turn round the centre, freely: about the camera's own
//     up and right axes, so it goes on in every direction from any view, over the top too
//     (a turntable stops at the pole); the model may end up tilted, Reset view rights it
//   two fingers: pinch to zoom, move together to pan; right button, middle button or
//     Shift + drag: pan; wheel: zoom towards the point under the cursor
//   double tap / double click on a surface: that point becomes the centre of turning and
//     zooming (the view swings to it); on empty background: nothing
//   single tap / click: o.onTap(hits) (e.g. press a key), if given
// Everything nearer to the camera than the centre less the view's height is cut away.
// The page keeps its own buttons; they call nav.orbit(), nav.home(), nav.look().
// ORTHOGRAPHIC VIEWS [given 2026-11-21]: a row of buttons is added under the page's "View"
// row: Ortho (parallel projection, the same scale at the centre as the perspective) and the
// six standard views +X -X +Y -Y +Z -Z (looking from that side; z up in the side views, x
// right and y up from +Z), which switch Ortho on. In Ortho, while the view is square to the
// model's axes (a standard view, also panned or zoomed), a mm grid lies behind the model,
// on whole mm of its frame (1 mm, every 10th bold; coarser when zoomed out), its pitch and
// the screen's axes shown in the view's corner; turned away from the axes it is hidden
// (a screen-parallel grid has no whole mm there, and its lines would jump while turning). The page's camera stays a
// PerspectiveCamera; in Ortho its projection matrix is replaced.
// o: { view, canvas, camera, scene, draw, home: {target: [x, y, z], azim, elev, dist},
//      ok(point) -> false for points cut away by a section (optional),
//      onTap(hits) (optional), status(text) (optional),
//      frame: {name, turn} (optional): the frame the views are named in; turn: it stands
//        turned 180 deg about z in the drawn one (the discant in the assembly) }
function viewerNav(o) {
  var camera = o.camera, view = o.view, canvas = o.canvas;
  // the camera's orientation; it looks at target from dist along its own +z
  var target = new THREE.Vector3(), quat = new THREE.Quaternion(), dist = 100;
  var MIN_D = 2, MAX_D = 2000;
  var X = new THREE.Vector3(1, 0, 0), Y = new THREE.Vector3(0, 1, 0), Z = new THREE.Vector3(0, 0, 1);
  var rq = new THREE.Quaternion();
  // turn about the camera's own axes: da about its up (as azimuth), de about its right (as elevation)
  function rot(da, de) {
    if (da) quat.multiply(rq.setFromAxisAngle(Y, da));
    if (de) quat.multiply(rq.setFromAxisAngle(X, -de));
    quat.normalize();
  }
  // a view given as azimuth and elevation about the world's y, upright
  function setAzEl(azim, elev) {
    quat.setFromAxisAngle(Y, azim); rot(0, elev);
  }

  var ortho = false;
  var baseUpdate = camera.updateProjectionMatrix.bind(camera);
  camera.updateProjectionMatrix = function () {   // the page's resize keeps Ortho and the grid
    baseUpdate();
    if (ortho) {
      var h = 2 * dist * Math.tan(camera.fov * Math.PI / 360), w = h * camera.aspect;
      camera.projectionMatrix.makeOrthographic(-w / 2, w / 2, h / 2, -h / 2, camera.near, camera.far);
      camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();
    }
    grid();
  };

  function place() {
    camera.quaternion.copy(quat);
    camera.position.copy(Z).applyQuaternion(quat).multiplyScalar(dist).add(target);
    // what lies in front of the centre by more than the view's height there is cut away,
    // so zooming in on a point opens the parts in front of it
    var h = 2 * dist * Math.tan(camera.fov * Math.PI / 360);
    camera.near = Math.max(0.05, dist - h); camera.far = dist + 4000;
    camera.updateProjectionMatrix(); camera.updateMatrixWorld();
    o.draw();
  }
  function setHome() {
    var h = o.home; target.set(h.target[0], h.target[1], h.target[2]);
    setAzEl(h.azim, h.elev); dist = h.dist; anim = null; marker.visible = false; place();
  }
  function clampD(d) { return Math.max(MIN_D, Math.min(MAX_D, d)); }

  // the ray under a point of the view, from the near plane, for either projection
  function rayAt(cx, cy) {
    var r = canvas.getBoundingClientRect();
    var x = (cx - r.left) / r.width * 2 - 1, y = -(cy - r.top) / r.height * 2 + 1;
    camera.updateMatrixWorld();
    var a = new THREE.Vector3(x, y, -1).unproject(camera), b = new THREE.Vector3(x, y, 1).unproject(camera);
    var ray = new THREE.Raycaster(a, b.sub(a).normalize(), 0, Infinity);
    ray.camera = camera;
    return ray;
  }
  // a point of the view (client coordinates) on the plane through the centre, facing the camera
  function onCentrePlane(cx, cy) {
    var ray = rayAt(cx, cy);
    var n = new THREE.Vector3(); camera.getWorldDirection(n);
    var pl = new THREE.Plane().setFromNormalAndCoplanarPoint(n, target), p = new THREE.Vector3();
    return ray.ray.intersectPlane(pl, p) ? p : null;
  }
  // zoom by f (< 1: closer), keeping the point under (cx, cy) where it is on the screen
  function zoomAt(f, cx, cy) {
    var nd = clampD(dist * f); f = nd / dist;
    var p = cx === undefined ? null : onCentrePlane(cx, cy);
    if (p) target.lerp(p, 1 - f);
    dist = nd; place();
  }
  function pan(dx, dy) {   // move the centre in the view plane by screen pixels
    var h = canvas.getBoundingClientRect().height || 1;
    var k = 2 * dist * Math.tan(camera.fov * Math.PI / 360) / h;
    var right = new THREE.Vector3().setFromMatrixColumn(camera.matrixWorld, 0);
    var up = new THREE.Vector3().setFromMatrixColumn(camera.matrixWorld, 1);
    target.addScaledVector(right, -dx * k).addScaledVector(up, dy * k);
  }
  function turn(dx, dy) {
    rot(-dx * 0.008, dy * 0.008);
  }

  // what lies under a point of the view: visible meshes only, not what a section cut away
  function shown(obj) { for (var q = obj; q; q = q.parent) if (!q.visible) return false; return true; }
  function hitsAt(cx, cy) {
    var ray = rayAt(cx, cy);                       // from the near plane: not what it cut away
    o.scene.updateMatrixWorld();
    var meshes = [];
    o.scene.traverse(function (q) { if (q.isMesh && !q.userData.navMarker && shown(q)) meshes.push(q); });
    return ray.intersectObjects(meshes, false).filter(function (h) {   // not the section's caps (nor the grid)
      return h.object.material.side !== THREE.BackSide && (!o.ok || o.ok(h.point));
    });
  }

  // the new centre: the camera stays, the view swings to the point (0.3 s)
  var anim = null;
  var marker = new THREE.Mesh(new THREE.SphereGeometry(1, 16, 12),
                              new THREE.MeshBasicMaterial({ color: 0xe0442b, depthTest: false, transparent: true, opacity: 0.85 }));
  marker.userData.navMarker = true; marker.renderOrder = 999; marker.visible = false; o.scene.add(marker);
  function centreOn(p) {
    var cam = camera.position.clone(), from = target.clone();
    anim = { t: 0, from: from, to: p.clone(), cam: cam };
    marker.position.copy(p); marker.visible = true;
  }
  function step(dt) {   // called by the page's loop; true while something moves
    if (!anim) { if (marker.visible) { marker.scale.setScalar(dist * 0.006); } return false; }
    anim.t = Math.min(1, anim.t + dt / 0.3);
    var s = anim.t * anim.t * (3 - 2 * anim.t);
    target.copy(anim.from).lerp(anim.to, s);
    // look from where the camera was at the moving centre, keeping its up as near as it goes
    var up = Y.clone().applyQuaternion(quat);
    dist = clampD(anim.cam.distanceTo(target));
    quat.setFromRotationMatrix(new THREE.Matrix4().lookAt(anim.cam, target, up));
    marker.scale.setScalar(dist * 0.006);
    place();
    if (anim.t >= 1) anim = null;
    return true;
  }

  // pointers: turn, pan, pinch; taps and double taps
  var pts = {}, prevMid = null, prevDist = 0, downAt = null, moved = 0, lastTap = null, multi = false;
  function midDist() {
    var a = Object.keys(pts).map(function (id) { return pts[id]; });
    return [[(a[0][0] + a[1][0]) / 2, (a[0][1] + a[1][1]) / 2], Math.hypot(a[0][0] - a[1][0], a[0][1] - a[1][1])];
  }
  view.addEventListener('pointerdown', function (e) {
    if (e.target.closest && e.target.closest('button')) return;
    e.preventDefault();
    try { view.setPointerCapture(e.pointerId); } catch (err) {}
    pts[e.pointerId] = [e.clientX, e.clientY, e.button === 1 || e.button === 2 || e.shiftKey];
    var n = Object.keys(pts).length;
    if (n === 1) { downAt = [e.clientX, e.clientY, performance.now()]; moved = 0; multi = false; anim = null; }
    if (n === 2) { var md = midDist(); prevMid = md[0]; prevDist = md[1]; multi = true; }
  });
  view.addEventListener('pointermove', function (e) {
    if (!pts[e.pointerId]) return;
    var n = Object.keys(pts).length, q = pts[e.pointerId];
    var dx = e.clientX - q[0], dy = e.clientY - q[1];
    pts[e.pointerId] = [e.clientX, e.clientY, q[2]];
    moved += Math.abs(dx) + Math.abs(dy);
    if (n === 1 && !multi) {
      if (moved < 4) return;   // a tap may wobble a little
      if (q[2]) pan(dx, dy); else turn(dx, dy);
    } else if (n === 2) {
      var md = midDist();
      if (prevMid) pan(md[0][0] - prevMid[0], md[0][1] - prevMid[1]);
      if (prevDist > 0 && md[1] > 0) { place(); zoomAt(prevDist / md[1], md[0][0], md[0][1]); }
      prevMid = md[0]; prevDist = md[1];
    }
    place();
  });
  function lift(e) {
    var was = pts[e.pointerId];
    delete pts[e.pointerId]; prevMid = null; prevDist = 0;
    if (Object.keys(pts).length === 2) { var md = midDist(); prevMid = md[0]; prevDist = md[1]; }
    if (!was || e.type === 'pointercancel' || multi || !downAt) return;
    var now = performance.now();
    if (moved > 8 || now - downAt[2] > 400 || Object.keys(pts).length) return;
    // a tap: a second one soon after, near the first, picks the centre
    var x = e.clientX, y = e.clientY;
    if (lastTap && now - lastTap[2] < 380 && Math.hypot(x - lastTap[0], y - lastTap[1]) < 30) {
      lastTap = null;
      var h = hitsAt(x, y);
      if (h.length) centreOn(h[0].point);
      o.draw();
      return;
    }
    lastTap = [x, y, now];
    if (o.onTap) o.onTap(hitsAt(x, y));
  }
  view.addEventListener('pointerup', lift);
  view.addEventListener('pointercancel', lift);
  view.addEventListener('contextmenu', function (e) { e.preventDefault(); });
  view.addEventListener('wheel', function (e) {
    e.preventDefault();
    zoomAt(Math.pow(1.0015, e.deltaMode === 1 ? e.deltaY * 33 : e.deltaY), e.clientX, e.clientY);
  }, { passive: false });

  // --- the mm grid, behind everything, in Ortho only
  var fr = o.frame || {}, tz = fr.turn ? -1 : 1;
  // the model's frame -> the page's world (x, z, -y), with the named frame's turn about z
  function W(x, y, z) { return new THREE.Vector3(tz * x, z, -tz * y); }
  var gridGrp = new THREE.Group(), gridMat = [
    new THREE.LineBasicMaterial({ color: 0xc9d1cd, depthWrite: false }),
    new THREE.LineBasicMaterial({ color: 0x9fa9a4, depthWrite: false })];
  var gridLines = [new THREE.LineSegments(new THREE.BufferGeometry(), gridMat[0]),
                   new THREE.LineSegments(new THREE.BufferGeometry(), gridMat[1])];
  gridLines.forEach(function (l) { l.renderOrder = -10; l.frustumCulled = false; l.userData.navMarker = true; gridGrp.add(l); });
  gridGrp.visible = false; o.scene.add(gridGrp);
  var label = document.createElement('p');
  label.style.cssText = 'position:absolute;right:10px;bottom:8px;margin:0;font:12px/1.3 var(--mono,monospace);' +
                        'color:var(--muted,#667);pointer-events:none;text-align:right';
  view.appendChild(label);
  var AXN = ['x', 'y', 'z'];
  // which of the model's axes a world direction is, with its sign ('' if none)
  function axisName(v) {
    for (var i = 0; i < 3; i++) for (var sg = -1; sg <= 1; sg += 2) {
      var a = W(i === 0 ? sg : 0, i === 1 ? sg : 0, i === 2 ? sg : 0);
      if (a.dot(v) > 0.99999) return (sg > 0 ? '+' : '−') + AXN[i];
    }
    return '';
  }
  function grid() {
    if (!ortho) { gridGrp.visible = false; label.textContent = ''; return; }
    var r0 = new THREE.Vector3(1, 0, 0).applyQuaternion(quat), u0 = new THREE.Vector3(0, 1, 0).applyQuaternion(quat);
    if (!axisName(r0) || !axisName(u0)) {
      gridGrp.visible = false;
      label.textContent = 'grid in the standard views only' + (fr.name ? ' (' + fr.name + ')' : '');
      return;
    }
    gridGrp.visible = true;
    var hPx = canvas.getBoundingClientRect().height || 1;
    var h = 2 * dist * Math.tan(camera.fov * Math.PI / 360), w = h * camera.aspect, pxmm = hPx / h;
    var step = 1; while (step * pxmm < 6) step *= 10;             // the fine lines at least 6 px apart
    var right = new THREE.Vector3(1, 0, 0).applyQuaternion(quat), up = new THREE.Vector3(0, 1, 0).applyQuaternion(quat);
    var back = new THREE.Vector3(0, 0, 1).applyQuaternion(quat);
    // the plane just in front of the far plane, centred on the view's axis
    var c = camera.position.clone().addScaledVector(back, -(camera.far - 1));
    var cu = c.dot(right), cv = c.dot(up);                        // its middle in the screen's axes
    var pts = [[], []];
    function lines(lo, hi, along, across, c0, len, cOff) {
      for (var k = Math.ceil(lo / step); k * step <= hi; k++) {
        var t = k * step - c0, major = (k % 10 === 0) ? 1 : 0;
        var p = c.clone().addScaledVector(across, t);
        pts[major].push(p.clone().addScaledVector(along, -len), p.clone().addScaledVector(along, len));
      }
    }
    lines(cu - w / 2, cu + w / 2, up, right, cu, h / 2 + 1);       // the vertical lines (across x)
    lines(cv - h / 2, cv + h / 2, right, up, cv, w / 2 + 1);       // the horizontal ones
    for (var i = 0; i < 2; i++) {
      gridLines[i].geometry.dispose();
      gridLines[i].geometry = new THREE.BufferGeometry().setFromPoints(pts[i]);
    }
    var ax = axisName(right), ay = axisName(up), from = axisName(back);
    label.textContent = 'grid ' + step + ' mm, bold ' + (10 * step) + ' mm · from ' + from.toUpperCase() +
      ': ' + ax + ' → , ' + ay + ' ↑' +
      (fr.name ? ' (' + fr.name + ')' : '');
  }

  // --- the buttons: Ortho and the six standard views, under the page's View row
  function setOrtho(on) {
    ortho = on; orthoBtn.setAttribute('aria-pressed', on ? 'true' : 'false'); place();
  }
  // look from side d (the model's frame) with up u: the camera's x = up x back
  function std(d, u) {
    var back = W(d[0], d[1], d[2]), upv = W(u[0], u[1], u[2]);
    var rt = new THREE.Vector3().crossVectors(upv, back);
    quat.setFromRotationMatrix(new THREE.Matrix4().makeBasis(rt, upv, back));
    anim = null; setOrtho(true);
  }
  var STD = [['+X', [1, 0, 0], [0, 0, 1]], ['−X', [-1, 0, 0], [0, 0, 1]], ['+Y', [0, 1, 0], [0, 0, 1]],
             ['−Y', [0, -1, 0], [0, 0, 1]], ['+Z', [0, 0, 1], [0, 1, 0]], ['−Z', [0, 0, -1], [0, 1, 0]]];
  var row = document.createElement('div'), viewRow = o.viewRow ||
            (view.parentNode && view.parentNode.querySelector('[aria-label="View"]'));
  row.className = 'row'; row.setAttribute('aria-label', 'Orthographic views');
  var orthoBtn = document.createElement('button');
  orthoBtn.type = 'button'; orthoBtn.textContent = 'Ortho'; orthoBtn.setAttribute('aria-pressed', 'false');
  orthoBtn.title = 'parallel projection with a mm grid';
  orthoBtn.addEventListener('click', function () { setOrtho(!ortho); });
  row.appendChild(orthoBtn);
  STD.forEach(function (v) {
    var b = document.createElement('button');
    b.type = 'button'; b.textContent = v[0]; b.title = 'look from ' + v[0] + (fr.name ? ' of the ' + fr.name : '');
    b.setAttribute('aria-label', 'Orthographic view from ' + v[0]);
    b.addEventListener('click', function () { std(v[1], v[2]); });
    row.appendChild(b);
  });
  if (viewRow && viewRow.parentNode) viewRow.parentNode.insertBefore(row, viewRow.nextSibling);

  return {
    place: place, step: step, home: setHome,
    orbit: function (da, de, dz) {
      rot(da, de); dist = clampD(dist * dz); place();
    },
    ortho: function (on) { if (on === undefined) return ortho; setOrtho(!!on); },
    view: function (name) { STD.forEach(function (v) { if (v[0].replace('−', '-') === name) std(v[1], v[2]); }); },
    look: function (t, d) { target.set(t[0], t[1], t[2]); dist = d; anim = null; marker.visible = false; place(); },
    hideMarker: function () { marker.visible = false; o.draw(); }
  };
}
