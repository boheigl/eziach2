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
// o: { view, canvas, camera, scene, draw, home: {target: [x, y, z], azim, elev, dist},
//      ok(point) -> false for points cut away by a section (optional),
//      onTap(hits) (optional), status(text) (optional) }
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

  // a point of the view (client coordinates) on the plane through the centre, facing the camera
  function onCentrePlane(cx, cy) {
    var r = canvas.getBoundingClientRect();
    var ndc = new THREE.Vector2((cx - r.left) / r.width * 2 - 1, -(cy - r.top) / r.height * 2 + 1);
    var ray = new THREE.Raycaster(); ray.setFromCamera(ndc, camera);
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
    var r = canvas.getBoundingClientRect();
    var ndc = new THREE.Vector2((cx - r.left) / r.width * 2 - 1, -(cy - r.top) / r.height * 2 + 1);
    var ray = new THREE.Raycaster(); ray.setFromCamera(ndc, camera);
    ray.near = camera.near;                        // not what the near plane cut away
    o.scene.updateMatrixWorld();
    var meshes = [];
    o.scene.traverse(function (q) { if (q.isMesh && !q.userData.navMarker && shown(q)) meshes.push(q); });
    return ray.intersectObjects(meshes, false).filter(function (h) {   // not the section's caps
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

  return {
    place: place, step: step, home: setHome,
    orbit: function (da, de, dz) {
      rot(da, de); dist = clampD(dist * dz); place();
    },
    look: function (t, d) { target.set(t[0], t[1], t[2]); dist = d; anim = null; marker.visible = false; place(); },
    hideMarker: function () { marker.visible = false; o.draw(); }
  };
}
