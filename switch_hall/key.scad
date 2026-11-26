// Hall-sensor key with the spring under the cap: the key of discant and bass, lower
// than the earlier contact key (in the git history)
//
// Everything that moves is above the board, which has no key holes. The key
// works like a linear Hall-effect keyboard switch:
//
// GUIDE [given 2026-11-14: metal, less friction; the 4 mm bushing]. The cover plate
// (2.4 mm on the board's top, as ../discant/cover.scad) carries a fixed tube round each
// key, with a sintered bronze sleeve bearing pressed into it (d3 x D5 x 4, oil-
// impregnated, a stock part). It goes in from below and bears on a rim at the tube's top
// (rim_t), which takes the collar's pull at the upper stop. The plunger is a stock stainless dowel pin d3 h8 (ISO 2338, 14 long) running
// in it, with a printed collar on its lower end that carries the magnet and the stop
// washer and does not touch the tube. One bushing is the whole guide: steel in oiled
// bronze runs at mu about 0.1, so a press jams only beyond bush_l / (2 mu) = 20 mm off
// the axis, and still beyond 8 dry (mu 0.25): the cap's edge is at 7.5.
//
// ASSEMBLY, before the cover is screwed onto the board: rod pressed and glued into the
// cap, magnet glued into the collar; bushing into the tube from below, against the
// rim; spring round the tube, O-ring into the cap; rod with cap from above through the
// bushing; cover turned over onto its caps, stop washer over the rod's end, collar
// glued on (the spring holds it against the bushing while the glue sets).
//
// SPRING. A stock compression spring (Misumi UY8-25, stainless) stands on a seat
// round the tube and pushes the cap up. Its length between the plate and the cap's underside sets the force; at
// the lower stop it is still well above its minimum length.
//
// STOPS, both soft, so nothing clicks. Upper: a washer punched from 1 mm
// silicone or PU sheet sits on the collar and bears on the bushing's lower face.
// Lower: a stock O-ring (silicone, soft) lies in a shallow counterbore in the
// cap's underside round the pin and lands on the tube's top; it also centres
// the spring's top coil.
//
// SENSING. A ratiometric linear Hall sensor (SOT-23, e.g. DRV5055A3, +-85 mT)
// sits on the board's underside, exactly on the key's axis, and senses through
// the board. An axially magnetised magnet is glued into the collar's lower
// face. Rest and bottom readings are calibrated per key; the actuation point
// and hysteresis are set as fractions of the stroke in firmware.
//
// Coordinates (the key frame): origin on the key's axis in the
// board's mid-plane, x along the row, y across it (+y towards the next higher
// board), z up. All parts at rest unless travel is set.
//
// make builds the parts into ../build/switch_hall/ (see Makefile).

/* [Board and staircase — as in ../discant/] */
pcb_t    = 1.6;
cu_t     = 0.035;    // copper and mask on each face
pitch    = 20;
margin_n = 5.3;      // row to the -y edge
margin_p = 9.4;      // row to the +y edge
stair    = [10, 16, 3];  // board k+1 relative to board k
cover_t  = 2.4;      // cover plate on the board's top [given 2026-11-14: thicker, 1.2 before]
// The discant has one sensor board for all four rows, in the staircase's slope
// plane (../hall_pcb/): it is tilted against each row by atan(3 / 16). The board
// is drawn flat here; the tilt only lifts the collar (its edge up the slope would
// otherwise come closer to the board) and lengthens the way through the board to
// the sensor. 0 for a board square to the keys.
board_tilt = atan(3 / 16);
// The cover (../discant/cover.scad) is a flat plate on the tilted board [given:
// variant A], so its top is tilted too: the skirt's lower edge keeps skirt_clear
// from it at the lower stop on the up-slope side as well (tilt_rise below).
// Bass back row: the board lies flat under both rows and the back row stands
// 10 mm higher, so its spring seat, tube top and everything above rise by riser;
// collar, magnet and step keep their place at the board [chosen].
riser = 0;

/* [Cap — as the earlier contact key's] */
cap_d    = 15;
cap_r    = 0.5;
cap_roof = 0.5;      // the cap's top over the rod's socket (cap_h and cap_sock follow from the rod, below)
stroke   = 3;        // [given]

/* [Plunger: a steel rod in a bronze bushing, a printed collar on its lower end] */
rod_d    = 3;        // a stock dowel pin ISO 2338 3 h8, stainless A1 (not magnetic) [given 2026-11-21]
rod_l0   = 14;       //   its stock length; the bass's back row (riser) 24
bush_d   = 3;        // sintered bronze sleeve bearing, oil-impregnated: d3 x D5 x 4 [stock]
bush_od  = 5.05;     // nominal D5, the bought ones measure 5.05 [given 2026-11-26]
bush_l   = 4;        // [given: 4, not 3: margin when it runs dry]
bush_fit = 0.05;     // pressed into the printed tube: its seat 0.05 under D (5.0)
bush_slip = 0.15;    // the bore below the seat: the bushing slides through it [2026-11-26: 0.1 over
                     // a nominal 5 did not let the 5.05 ones in; printed holes come out small]
rim_t    = 0.8;      // the tube's top rim over the bushing: its stop against the collar's pull
rod_clear = 0.2;     // radial, the rod above the bushing, where it does not guide
pin_d    = rod_d;    // (the rod, as the cap and the O-ring see it)
collar_d = 4.4;      // printed: carries magnet and stop washer, no longer guides
collar_h = 3;        // the rod glued 1.5 deep into it, over the magnet and its web (mag_seat)
floor_gap = 0.3;     // collar above the board at the lower stop
mu       = 0.1;      // steel in oiled sintered bronze [estimated]
mu_dry   = 0.25;     // dry or dirty [estimated]

/* [Tube — part of the cover] */
tube_od  = 6.6;

/* [Hiding the spring: a skirt under the cap over a shroud on the cover] */
shroud_gap  = 0.3;   // radial, spring to the shroud's inside
shroud_wall = 0.8;
skirt_gap   = 0.3;   // radial, shroud to the skirt: they never touch
skirt_wall  = 0.8;
skirt_clear = 0.3;   // skirt above the cover at the lower stop
overlap_min = 1;     // skirt over the shroud at rest

/* [Felt] */
/* [Lower stop: stock O-ring under the cap] */
oring_id   = 4;      // 4 x 1.5, silicone 50 Shore A (or NBR 70)
oring_cs   = 1.5;
oring_seat = 0.5;    // depth of the counterbore in the cap's underside
oring_gap  = 0.05;   // radial, O-ring in its counterbore (the counterbore stays inside the spring)

/* [Upper stop: washer punched from 1 mm silicone or PU sheet] */
stop_t   = 1;
stop_od  = 4.5;      // hollow punches in 0.5 mm steps
stop_id  = 2.5;      // a little under the rod: it holds itself (punched, stretched over it)

/* [Spring — standard part: Misumi UY8-25, SUS304-WPB, d8 x 0.45 x 25] */
spring_wd = 0.45;
spring_od = 8;
spring_n  = 12;      // total coils, from the catalogue's solid height 5.4 (drawing only)
spring_l0 = 25;
spring_rate = 0.098; // N/mm, catalogue (±10 %); stainless, weakly magnetic
spring_lmin = 6.25;  // the catalogue's shortest working length (L1)
spring_rest = 13.1;  // length at rest: 119 g, 149 g at the bottom [given 2026-11-15]
seat_floor = 0.8;    // the cover plate left under the spring's seat, at its thinnest [given 2026-11-15]

/* [Hall sensor — SOT-23 on the underside, on the axis] */
sens_l   = 2.9;
sens_body_w = 1.3;
sens_w   = 2.4;      // across the leads
sens_h   = 1.1;
sens_el  = 0.55;     // element below the mounting face [unverified]

/* [Magnet — NdFeB N52, axial, in the collar's lower face] */
// [2026-11-23: the bought ones are 3 x 1 (yourmagnets.net, 200 pieces), 3 x 1.5 before]: the
// magnet stays in the collar's lower face, as near the sensor as before, and a printed web
// mag_web over it takes the half millimetre, so the rod, the cap and every height above
// stay as they were (mag_seat = 1.5, the old magnet's length)
mag_d    = 3.1;      // nominal 3, the bought ones measure 3.1 [given 2026-11-26]
mag_c    = 0.15;     // the pocket over it: a slip fit, glued (slow epoxy) [given 2026-11-26: it
                     // was 0.05 over a nominal 3, a press fit the magnets did not go into]
mag_pocket = mag_d + mag_c;   // 3.25: the collar's wall 0.58 round it, printed holes come out a little small
mag_l    = 1;
mag_web  = 0.5;      // the collar's floor between the magnet's pocket and the rod
mag_seat = mag_l + mag_web;   // where the rod's end sits, over the collar's lower face
mag_Br   = 1.44;     // T
sens_range = 85;     // mT, DRV5055A3

/* [Position and output] */
travel   = 0;        // 0 .. stroke
part     = "all";    // all, plunger, cap, magnet, oring, stop, spring, tube, tube_body, tube_cut, sensor, board

$fa = 2; $fs = 0.1;

// ---------------------------------------------------------------- derived
z_top    = pcb_t / 2 + cu_t;               // board's top surface
z_bot    = -pcb_t / 2 - cu_t;
// the bushing stands spring_lift higher than the old printed guide's top (collar's edge + 4.5):
// shroud and skirt rise with it
spring_lift = collar_h + stop_t + bush_l + rim_t - 4.5 - (cover_t - 1.2);
z_lvl    = pcb_t / 2 + cover_t + riser + spring_lift;   // the level the shroud and skirt are reckoned from
z_cb     = z_top + floor_gap + collar_d / 2 * tan(board_tilt) + stroke;   // collar's lower face at rest
z_step   = z_cb + collar_h + stop_t;       // the bushing's lower face: the upper stop
z_bush   = [z_step, z_step + bush_l];      // the bushing
z_tt     = z_bush[1] + rim_t + riser;      // tube top: the rim over the bushing (the bass's back row: riser higher)
oring_od = oring_id + 2 * oring_cs;
oring_out = oring_cs - oring_seat;         // O-ring below the cap's underside
cbore_d  = oring_od + 2 * oring_gap;
z_cu     = z_tt + oring_out + stroke;      // cap underside at rest
rod_l    = rod_l0 + riser;                 // the pin: from the magnet up into the cap
cap_sock = rod_l - (z_cu - z_cb - mag_seat);  // so deep in the cap: pressed and glued, it carries the spring's force
cap_h    = cap_sock + cap_roof;            // the cap grows with the pin (3.2 with the 14 mm pin; 3 with 13.8 cut from bar)
z_ct     = z_cu + cap_h;                   // cap top at rest
function key_cap_top() = z_ct;             // for ../discant/cover.scad (the thumb bar follows the caps)
function key_cap_low() = z_cu - stroke;     // the cap's underside pressed (../discant/cover.scad: the bar's web)
function key_bore_lo() = bore_lo;          // for ../discant/cover.scad (run down through the plate)
bore_lo  = bush_od + bush_slip;           // the bushing's way in; the collar runs in it without contact
bore_hi  = rod_d + 2 * rod_clear;          // above the bushing
shroud_id = spring_od + 2 * shroud_gap;
shroud_od = shroud_id + 2 * shroud_wall;
// spring seat: a level floor between tube and shroud, spring_rest under the cap's
// underside, so both halves have the same spring length and force. It may not come
// lower than seat_floor above the board at its outer edge on the discant's up-slope side
// (its board tilted by atan(3 / 16)); on the bass's flat board the collar, and with it
// the cap, sit lower by the tilt's lift (z_cb).
z_seat_min = z_top + shroud_id / 2 * 3 / 16 + seat_floor + riser
           - collar_d / 2 * (3 / 16 - tan(board_tilt));
z_seat   = z_cu - spring_rest;
skirt_id  = shroud_od + 2 * skirt_gap;
skirt_od  = skirt_id + 2 * skirt_wall;
// the tilted plate's top under the skirt's edge, above the level seat
tilt_rise = max(0, z_top + cover_t / cos(board_tilt) - (pcb_t / 2 + cover_t)) + skirt_od / 2 * tan(board_tilt);
z_sht    = z_lvl + skirt_clear + tilt_rise + stroke + overlap_min;   // shroud top
skirt_l  = z_cu - stroke - z_lvl - skirt_clear - tilt_rise;          // skirt below the cap's underside

// spring
spring_dm  = spring_od - spring_wd;
spring_k   = spring_rate;
l_rest     = z_cu - z_seat;
l_bot      = l_rest - stroke;
f_rest     = spring_k * (spring_l0 - l_rest);
f_bot      = spring_k * (spring_l0 - l_bot);
tau_bot    = 8 * f_bot * spring_dm / (PI * pow(spring_wd, 3));   // uncorrected

// guide
span     = bush_l;                         // the guide's length
e_jam    = span / (2 * mu);
e_dry    = span / (2 * mu_dry);

// field on the axis of a cylinder magnet, at distance s from its near face (mT)
function bz(s) = 1000 * mag_Br / 2 * ((s + mag_l) / sqrt(pow(s + mag_l, 2) + pow(mag_d / 2, 2))
                                     - s / sqrt(s * s + pow(mag_d / 2, 2)));
z_el     = z_top - (pcb_t + 2 * cu_t + sens_el) / cos(board_tilt);   // on the axis
s_rest   = z_cb - z_el;
b_rest   = bz(s_rest);
b_bot    = bz(s_rest - stroke);
// neighbour on the same board (dipole, off axis), its change when pressed
mag_V    = PI * mag_d * mag_d / 4 * mag_l;
function bz_off(h, rho) = 1000 * mag_Br * mag_V / (4 * PI) * (2 * h * h - rho * rho) / pow(h * h + rho * rho, 2.5);
b_nb     = bz_off(s_rest + mag_l / 2, pitch) - bz_off(s_rest - stroke + mag_l / 2, pitch);

echo(str("plunger: rod d", rod_d, " in a bushing d", bush_d, " x D", bush_od, " x ", bush_l, " at z = ", z_bush,
         "; collar d", collar_d, " x ", collar_h, " in d", bore_lo, "; tube d", tube_od, " up to z = ", z_tt));
echo(str("guide: jams only beyond ", e_jam, " off centre, dry beyond ", e_dry, " (cap edge ", cap_d / 2, ")"));
echo(str("spring ", l_rest, " long at rest, ", l_bot, " at the bottom; rate ", spring_k, " N/mm; ",
         f_rest / 9.81 * 1000, " g -> ", f_bot / 9.81 * 1000, " g (+", (f_bot / f_rest - 1) * 100, " %); tau ", tau_bot));
echo(str("field on the axis: ", b_rest, " mT at rest, ", b_bot, " mT at the bottom; neighbour pressed: ", b_nb, " mT"));
echo(str("spring hidden: skirt d", skirt_od, " / d", skirt_id, " x ", skirt_l, " under the cap over a shroud d",
         shroud_od, " / d", shroud_id, " up to z = ", z_sht, "; overlap at rest ", z_sht - (z_cu - skirt_l)));
echo(str("height: cap top ", z_ct, " .. board underside ", z_bot, " = ", z_ct - z_bot,
         "; sensor reaches ", z_bot - sens_h));

assert(e_dry >= cap_d / 2, "guide too short: a press at the cap's edge can jam it once the bushing runs dry");
assert((tube_od - (bush_od - bush_fit)) / 2 >= 0.8 - 1e-6, "tube wall too thin round the bushing");
assert(l_bot >= spring_lmin, "spring too short at the lower stop");
assert(l_rest < spring_l0, "spring has no preload");
assert(tube_od <= spring_od - 2 * spring_wd - 0.5, "tube too wide for the spring");
assert((tube_od - bore_lo) / 2 >= 0.7 - 1e-6, "tube wall too thin round the bushing's way in");   // no load there; 0.75 before 2026-11-26
assert(z_seat >= z_seat_min - 1e-6, "spring seat too deep: the plate under it too thin");
assert(bore_lo > collar_d + 0.4, "collar touches the lower bore");
assert(z_tt > z_seat + 1, "tube does not rise above the cover");
assert(cbore_d <= spring_od - 2 * spring_wd, "O-ring counterbore wider than the spring's inside: the top coil loses its seat");
assert(oring_id > bore_hi && oring_id < tube_od, "O-ring does not land on the tube's top");
assert(oring_id >= pin_d, "O-ring too tight on the pin");
assert(oring_seat < oring_cs - 0.5, "O-ring hardly stands out of its counterbore");
assert(stop_od <= bore_lo - 0.2, "stop washer rubs in the lower bore");
assert(stop_id < pin_d && stop_id >= pin_d - 0.5, "stop washer must sit a little tight on the rod (silicone stretches)");
assert(stop_od > bush_d + 0.8, "stop washer hardly meets the bushing's face");
assert(mag_pocket <= collar_d - 1.1 && mag_seat <= collar_h - 1.5, "magnet does not fit the collar, or the rod's glued length is short");
assert(mag_web >= 0.4, "the web over the magnet is too thin to print (two layers)");
assert(b_bot <= sens_range, "field beyond the sensor's range at the lower stop");
assert(sens_l / 2 < margin_n, "sensor beyond the board's edge");
// staircase: the next board's caps and cover must stay clear of this cap
assert(stair[1] - margin_n - cap_d / 2 >= 0.5, "cap runs into the next board's front edge");
assert(stair[1] - cap_d >= 0.5, "caps of neighbouring boards touch");
assert(skirt_od <= cap_d - 1, "skirt too wide for the cap");
assert(z_sht < z_cu - stroke - 0.5, "shroud reaches the cap at the lower stop");
assert(z_sht - (z_cu - skirt_l) >= overlap_min - 1e-6, "spring visible at rest");
assert(cap_sock >= 2.5 - 1e-6, "the pin is glued less than 2.5 into the cap");
assert(travel >= 0 && travel <= stroke, str("travel must lie in 0 .. ", stroke));

// ---------------------------------------------------------------- geometry
dz = -travel;

module cap() translate([0, 0, z_cu + dz]) difference() {
    hull() {
        cylinder(d = cap_d, h = cap_h - cap_r);
        translate([0, 0, cap_h - cap_r]) rotate_extrude() translate([cap_d / 2 - cap_r, 0]) circle(r = cap_r);
    }
    translate([0, 0, -0.01]) cylinder(d = pin_d - 0.05, h = cap_sock);   // press fit
    translate([0, 0, -0.01]) cylinder(d = cbore_d, h = oring_seat + 0.01);    // O-ring seat
}
// skirt, one piece with the cap: hides the spring
module skirt() translate([0, 0, z_cu - skirt_l + dz]) difference() {
    cylinder(d = skirt_od, h = skirt_l + 0.01);
    translate([0, 0, -1]) cylinder(d = skirt_id, h = skirt_l + 2);
}
// the printed collar: magnet pocket from below, a web over it, the rod glued in from above
module collar() translate([0, 0, z_cb + dz]) difference() {
    cylinder(d = collar_d, h = collar_h);
    translate([0, 0, -0.01]) cylinder(d = mag_pocket, h = mag_l + 0.01);
    translate([0, 0, mag_seat]) cylinder(d = rod_d, h = collar_h);
}
// the steel rod: from the collar's web up into the cap
module rod() translate([0, 0, z_cb + mag_seat + dz]) cylinder(d = rod_d, h = rod_l);
module plunger() { collar(); rod(); }
// the bushing, fixed in the tube
module bushing() translate([0, 0, z_bush[0]]) difference() {
    cylinder(d = bush_od, h = bush_l);
    translate([0, 0, -1]) cylinder(d = bush_d, h = bush_l + 2);
}
module magnet() translate([0, 0, z_cb + dz]) cylinder(d = mag_d, h = mag_l);
module oring() translate([0, 0, z_cu + oring_seat - oring_cs / 2 + dz])
    rotate_extrude() translate([oring_id / 2 + oring_cs / 2, 0]) circle(d = oring_cs);
module stop() translate([0, 0, z_cb + collar_h + dz]) difference() {
    cylinder(d = stop_od, h = stop_t);
    translate([0, 0, -1]) cylinder(d = pin_d, h = stop_t + 2);
}
// tube, shroud and the level spring seat in between, from the board's top up: added
// to the cover plate (here, and in ../discant/cover.scad); tube_cut() is taken out after
module tube_body() {
    translate([0, 0, z_top]) cylinder(d = tube_od, h = z_tt - z_top);
    translate([0, 0, z_top]) cylinder(d = shroud_od, h = z_sht - z_top);
}
// [given 2026-11-26: the bushing is hard to start, the bore leaning against the plate's
// underside] lead-ins: a 45 deg funnel at the way in, entry_c wide where the bore meets the
// board's top on its high side (the plane leans by board_tilt, so it reaches entry_lean
// further up there), and a 45 deg lead-in into the seat instead of a step
entry_c    = 0.5;
entry_lean = (bore_lo / 2 + entry_c) * tan(board_tilt);
module tube_cut() {
    translate([0, 0, z_top - 0.01]) cylinder(d = bore_lo, h = z_step - z_top + 0.01);
    let(z1 = z_top + entry_lean + entry_c, z0 = z_top - entry_lean - 1)
        translate([0, 0, z0]) cylinder(d1 = bore_lo + 2 * (z1 - z0), d2 = bore_lo, h = z1 - z0);
    translate([0, 0, z_bush[0] - 0.01]) cylinder(d = bush_od - bush_fit, h = bush_l + 0.01);   // the bushing's seat
    translate([0, 0, z_bush[0] - 0.01]) cylinder(d1 = bore_lo, d2 = bush_od - bush_fit - 0.02, h = (bore_lo - bush_od + bush_fit) / 2 + 0.02);
    translate([0, 0, z_top]) cylinder(d = bore_hi, h = z_tt);   // through the rim
    translate([0, 0, z_seat]) difference() {   // the spring's room above the seat
        cylinder(d = shroud_id, h = z_sht);
        translate([0, 0, -1]) cylinder(d = tube_od, h = z_sht + 2);
    }
}
// cover plate (one pitch of it, drawn flat) with the tube
module tube() difference() {
    union() {
        translate([-pitch / 2, -margin_n, pcb_t / 2]) cube([pitch, margin_n + margin_p, cover_t]);
        tube_body();
    }
    tube_cut();
}
// spring drawn at its working length: a helix of short hulls
module spring() {
    l = z_cu + dz - z_seat;
    n = spring_n;
    steps = 36 * n;
    r = spring_dm / 2;
    // dead coils closed at the ends, active coils spread over the rest
    function zc(a) = let(t = a / 360)
        t < 1 ? t * spring_wd
      : t > n - 1 ? l - (n - t) * spring_wd
      : spring_wd + (t - 1) / (n - 2) * (l - 2 * spring_wd);
    translate([0, 0, z_seat + spring_wd / 2]) for (i = [0 : steps - 1]) hull() for (a = [i, i + 1] * 360 / 36)
        translate([r * cos(a), r * sin(a), min(zc(a), l - spring_wd)]) sphere(d = spring_wd, $fn = 8);
}
module sensor() translate([0, 0, z_bot - sens_h]) {
    translate([-sens_body_w / 2, -sens_l / 2, 0]) cube([sens_body_w, sens_l, sens_h]);
    for (p = [[-1, -0.95], [-1, 0.95], [1, 0]]) translate([p[0] * (sens_w / 2 - 0.25) - 0.25, p[1] - 0.2, 0])
        cube([0.5, 0.4, 0.15]);
}
// one key's share of the board: one pitch long, no hole
module board() translate([-pitch / 2, -margin_n, -pcb_t / 2]) cube([pitch, margin_n + margin_p, pcb_t]);

if (part == "all") {
    color("SeaGreen") board();
    color("Gainsboro") tube();
    color("Ivory") cap();
    color("Ivory") skirt();
    color("Ivory") collar();
    color("Silver") rod();
    color("Peru") bushing();
    color("SlateGray") magnet();
    color("DimGray") oring();
    color("Firebrick") stop();
    color("Silver") spring();
    color("Black") sensor();
}
else if (part == "cap")     { cap(); skirt(); }
else if (part == "plunger") plunger();
else if (part == "collar")  collar();
else if (part == "rod")     rod();
else if (part == "bushing") bushing();
else if (part == "magnet")  magnet();
else if (part == "oring")   oring();
else if (part == "stop")    stop();
else if (part == "spring")  spring();
else if (part == "tube")    tube();
else if (part == "tube_body") tube_body();   // for the cases that cannot use this file (another tilt or riser)
else if (part == "tube_cut")  tube_cut();
else if (part == "sensor")  sensor();
else if (part == "board")   board();
