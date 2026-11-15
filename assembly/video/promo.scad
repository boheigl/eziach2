// One frame of the eziach promo video (promo.py drives it): the bass in its own frame
// (../../bass/), the discant's pieces in the playing position (../../build/assembly/),
// moved further by RD (identity when played), light keys pressed one by one.
//
// RD: 4x4 matrix on the discant (played frame); DB: the discant frame -> played frame
// (to_bass(), read back by promo.py); DK/BK: each discant / bass key's travel;
// SHOW: which groups are drawn ("bass", "discant", "case", "keys", "inside"); XRAY: the
// cases drawn see-through; ARROW: a force arrow on the hand plate along y (N, sign:
// + push), GLOW: the gauges highlighted (+ push: blue, - pull: orange).
include <../../bass/layout.scad>

RD = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]];
DB = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]];
DK = [for (i = [0 : 45]) 0];
BK = [for (i = [0 : 17]) 0];
SHOW = ["bass", "discant", "case", "keys"];
XRAY = 0;
ARROW = 0;
GLOW = 0;
CLASH = false;     // instead: what the moved discant (case, cover, keys, gauges) shares with the bass

A = "../../build/assembly/"; BB = "../../build/bass/";
function on(g) = len([for (s = SHOW) if (s == g) 1]) > 0;
CASE = XRAY > 0 ? [0.96, 0.76, 0.38, 1 - XRAY * 0.88] : [0.96, 0.76, 0.38];
WOOD = [0.66, 0.45, 0.28];                 // lighter than real leather: the hand plate faces away from the light
GAUGE = GLOW == 0 ? [0.7, 0.72, 0.75] : GLOW > 0 ? [0.1, 0.45 + 0.3 * (1 - GLOW), 1] : [1, 0.55 + 0.25 * (1 + GLOW), 0.1];

// a key: cap, skirt and pin (as ../assembly.scad), top = the cap top over the board's middle
module key(top, sl) {
    $fn = 32;
    translate([0, 0, top - 2]) cylinder(d = 15, h = 2);
    translate([0, 0, top - 2 - sl]) difference() { cylinder(d = 12.4, h = sl); translate([0, 0, -1]) cylinder(d = 10.8, h = sl + 2); }
}
module discant_keys() for (k = [0 : 3], i = [0 : 12 - k])
    let(n = [0, 13, 25, 36][k] + i)
    translate([-120 + 20 * i + 10 * k, 16 * k, 3 * k - DK[n]]) key(15.066, 6.55);
module bass_keys() for (k = [0, 1], i = [0 : n_row - 1])
    translate(at_key(k, i) - [0, 0, BK[k * n_row + i]]) key(key_top + k * key_riser, 7.3);

module bass_solid() { for (f = ["case", "back_cover", "cover", "strap"]) import(str(BB, f, ".stl")); bass_keys(); }
module discant_solid() multmatrix(RD) {
    for (f = ["d_housing", "d_cover"]) import(str(A, f, ".stl"));
    import(str(BB, "discant_link.stl")); multmatrix(DB) discant_keys();
}
if (CLASH) intersection() { bass_solid(); discant_solid(); }
else {
if (on("bass")) {
    if (on("case")) {
        color(CASE) { import(str(BB, "case.stl")); import(str(BB, "back_cover.stl")); }
        color([0.36, 0.44, 0.53]) import(str(BB, "cover.stl"));
        color(WOOD) import(str(BB, "strap.stl"));
    }
    if (XRAY > 0 || on("inside")) {
        color([0.18, 0.5, 0.32]) import(str(BB, "boards.stl"));
        color([0.15, 0.15, 0.15]) import(str(BB, "connectors.stl"));
        color([0.18, 0.48, 0.31]) import(str(BB, "elec.stl"));
        color([0.24, 0.29, 0.34]) import(str(BB, "battery.stl"));
        color([0.85, 0.2, 0.15]) import(str(BB, "wires.stl"));
    }
    if (on("keys")) color([0.96, 0.95, 0.9]) bass_keys();
}
if (on("discant")) multmatrix(RD) {
    if (on("case")) {
        color(CASE) import(str(A, "d_housing.stl"));
        color([0.36, 0.44, 0.53]) import(str(A, "d_cover.stl"));
    }
    color([0.6, 0.6, 0.62]) import(str(A, "d_cables.stl"));
    color(GAUGE) import(str(BB, "discant_link.stl"));      // plates, pins, outer holders (played frame)
    if (XRAY > 0 || on("inside")) {
        color([0.18, 0.5, 0.32]) import(str(A, "d_boards.stl"));
        color([0.15, 0.15, 0.15]) import(str(A, "d_parts.stl"));
    }
    if (on("keys")) color([0.96, 0.95, 0.9]) multmatrix(DB) discant_keys();
}
}
// the push (or pull) on the hand plate
if (ARROW != 0) let(c = [(plate_x[0] + plate_x[1]) / 2, plate_y[0], (plate_z[0] + plate_z[1]) / 2], L = 45 + abs(ARROW) * 0.9, s = sign(ARROW))
    color(s > 0 ? [0.1, 0.45, 0.9] : [0.9, 0.35, 0.1])
    translate(c + [0, s > 0 ? -L - 4 : -4, 0]) rotate([-90, 0, 0]) {
        if (s > 0) { cylinder(d = 10, h = L - 20, $fn = 24); translate([0, 0, L - 20]) cylinder(d1 = 24, d2 = 0, h = 20, $fn = 24); }
        else { translate([0, 0, 20]) cylinder(d = 10, h = L - 20, $fn = 24); cylinder(d1 = 0, d2 = 24, h = 20, $fn = 24); }
    }
