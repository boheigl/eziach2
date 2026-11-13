// Hall-sensor key with the spring under the cap: a low alternative to the
// switch key (../switch/)
//
// Everything that moves is above the board, which has no key holes. The key
// works like a linear Hall-effect keyboard switch:
//
// GUIDE. The cover plate (1.2 mm on the board's top, as ../discant/cover.scad)
// carries a fixed tube round each key. A plunger runs in it: a collar at its
// lower end in the tube's wider lower bore, and a pin above it in the narrower
// upper bore. Collar and pin are the two guide points; at rest they are
// guide_min apart, enough that a press at the cap's edge cannot jam it
// (jamming needs an offset beyond span / (2 mu)). The plunger goes in from
// below before the cover is screwed onto the board, so the step between the
// two bores holds it captive; the cap is then pressed onto the pin's top.
//
// SPRING. A stock compression spring (the one of ../switch/: d8 x 0.4 x 25,
// 8 active coils) stands on the cover plate round the tube and pushes the cap
// up. Its length between the plate and the cap's underside sets the force; at
// the lower stop it is still well above its minimum length.
//
// STOPS, both soft, so nothing clicks. Upper: a washer punched from 1 mm
// silicone or PU sheet sits on the collar and bears on the step in the bore.
// Lower: a stock O-ring (silicone, soft) lies in a shallow counterbore in the
// cap's underside round the pin and lands on the tube's top; it also centres
// the spring's top coil.
//
// SENSING. A ratiometric linear Hall sensor (SOT-23, e.g. DRV5055A3, +-85 mT)
// sits on the board's underside, exactly on the key's axis, and senses through
// the board. An axially magnetised magnet is pressed into the collar's lower
// face. Rest and bottom readings are calibrated per key; the actuation point
// and hysteresis are set as fractions of the stroke in firmware.
//
// Coordinates as in ../switch/pcb.scad: origin on the key's axis in the
// board's mid-plane, x along the row, y across it (+y towards the next higher
// board), z up. All parts at rest unless travel is set.
//
// make builds the parts into ../build/switch_hall/ (see Makefile).

/* [Board and staircase — as in ../switch/pcb.scad and ../discant/] */
pcb_t    = 1.6;
cu_t     = 0.035;    // copper and mask on each face
pitch    = 20;
margin_n = 5.3;      // row to the -y edge
margin_p = 9.4;      // row to the +y edge
stair    = [10, 16, 3];  // board k+1 relative to board k
cover_t  = 1.2;      // cover plate on the board's top: the spring seat

/* [Cap — as in ../switch/button.scad] */
cap_d    = 15;
cap_h    = 2;
cap_r    = 0.5;
cap_sock = 1.5;      // pin pressed this far into the cap
stroke   = 3;        // [given]

/* [Plunger: pin and collar] */
pin_d    = 3.6;
collar_d = 4.6;
collar_h = 2;
floor_gap = 0.3;     // collar above the board at the lower stop
gap      = 0.1;      // radial, pin and collar in their bores
guide_min = 4.5;     // collar's lower edge to the tube's top, at rest
mu       = 0.25;     // friction, plunger in the tube (POM, greased) [estimated]

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
oring_gap  = 0.1;    // radial, O-ring in its counterbore

/* [Upper stop: washer punched from 1 mm silicone or PU sheet] */
stop_t   = 1;
stop_od  = 4.5;      // hollow punches in 0.5 mm steps
stop_id  = 3.5;      // a little under the pin: it holds itself

/* [Spring — stock, as ../switch/: d8 x 0.4 x 25, 8 active coils] */
spring_wd = 0.4;
spring_od = 8;
spring_n  = 10;      // total coils: 8 active + one dead coil each end (assumed)
spring_l0 = 25;
spring_G  = 81500;
spring_lmin = 6.25;  // shortest recommended working length (DIN EN 13906-1), as ../switch/

/* [Hall sensor — SOT-23 on the underside, on the axis] */
sens_l   = 2.9;
sens_body_w = 1.3;
sens_w   = 2.4;      // across the leads
sens_h   = 1.1;
sens_el  = 0.55;     // element below the mounting face [unverified]

/* [Magnet — NdFeB N52, axial, in the collar's lower face] */
mag_d    = 3;
mag_l    = 1.5;
mag_Br   = 1.44;     // T
sens_range = 85;     // mT, DRV5055A3

/* [Position and output] */
travel   = 0;        // 0 .. stroke
part     = "all";    // all, plunger, cap, magnet, oring, stop, spring, tube, sensor, board

$fa = 2; $fs = 0.1;

// ---------------------------------------------------------------- derived
z_top    = pcb_t / 2 + cu_t;               // board's top surface
z_bot    = -pcb_t / 2 - cu_t;
z_seat   = pcb_t / 2 + cover_t;            // spring seat: top of the cover plate
z_cb     = z_top + floor_gap + stroke;     // collar's lower face at rest
z_step   = z_cb + collar_h + stop_t;       // step between the bores
z_tt     = z_cb + guide_min;               // tube top
oring_od = oring_id + 2 * oring_cs;
oring_out = oring_cs - oring_seat;         // O-ring below the cap's underside
cbore_d  = oring_od + 2 * oring_gap;
z_cu     = z_tt + oring_out + stroke;      // cap underside at rest
z_ct     = z_cu + cap_h;                   // cap top at rest
bore_lo  = collar_d + 2 * gap;
bore_hi  = pin_d + 2 * gap;
shroud_id = spring_od + 2 * shroud_gap;
shroud_od = shroud_id + 2 * shroud_wall;
skirt_id  = shroud_od + 2 * skirt_gap;
skirt_od  = skirt_id + 2 * skirt_wall;
z_sht    = z_seat + skirt_clear + stroke + overlap_min;   // shroud top
skirt_l  = z_cu - stroke - z_seat - skirt_clear;          // skirt below the cap's underside

// spring
spring_dm  = spring_od - spring_wd;
spring_na  = spring_n - 2;
spring_k   = spring_G * pow(spring_wd, 4) / (8 * pow(spring_dm, 3) * spring_na);
l_rest     = z_cu - z_seat;
l_bot      = l_rest - stroke;
f_rest     = spring_k * (spring_l0 - l_rest);
f_bot      = spring_k * (spring_l0 - l_bot);
tau_bot    = 8 * f_bot * spring_dm / (PI * pow(spring_wd, 3));   // uncorrected

// guide
span     = z_tt - z_cb;                    // guide points at rest
e_jam    = span / (2 * mu);

// field on the axis of a cylinder magnet, at distance s from its near face (mT)
function bz(s) = 1000 * mag_Br / 2 * ((s + mag_l) / sqrt(pow(s + mag_l, 2) + pow(mag_d / 2, 2))
                                     - s / sqrt(s * s + pow(mag_d / 2, 2)));
z_el     = z_bot - sens_el;
s_rest   = z_cb - z_el;
b_rest   = bz(s_rest);
b_bot    = bz(s_rest - stroke);
// neighbour on the same board (dipole, off axis), its change when pressed
mag_V    = PI * mag_d * mag_d / 4 * mag_l;
function bz_off(h, rho) = 1000 * mag_Br * mag_V / (4 * PI) * (2 * h * h - rho * rho) / pow(h * h + rho * rho, 2.5);
b_nb     = bz_off(s_rest + mag_l / 2, pitch) - bz_off(s_rest - stroke + mag_l / 2, pitch);

echo(str("plunger: collar d", collar_d, " x ", collar_h, " in d", bore_lo, ", pin d", pin_d, " in d", bore_hi,
         "; tube d", tube_od, " up to z = ", z_tt, ", step at ", z_step));
echo(str("guide span ", span, " at rest: jams only beyond ", e_jam, " off centre (cap edge ", cap_d / 2, ")"));
echo(str("spring ", l_rest, " long at rest, ", l_bot, " at the bottom; rate ", spring_k, " N/mm; ",
         f_rest / 9.81 * 1000, " g -> ", f_bot / 9.81 * 1000, " g (+", (f_bot / f_rest - 1) * 100, " %); tau ", tau_bot));
echo(str("field on the axis: ", b_rest, " mT at rest, ", b_bot, " mT at the bottom; neighbour pressed: ", b_nb, " mT"));
echo(str("spring hidden: skirt d", skirt_od, " / d", skirt_id, " x ", skirt_l, " under the cap over a shroud d",
         shroud_od, " / d", shroud_id, " up to z = ", z_sht, "; overlap at rest ", z_sht - (z_cu - skirt_l)));
echo(str("height: cap top ", z_ct, " .. board underside ", z_bot, " = ", z_ct - z_bot,
         "; sensor reaches ", z_bot - sens_h));

assert(e_jam >= cap_d / 2, "guide too short: a press at the cap's edge can jam it");
assert(l_bot >= spring_lmin, "spring too short at the lower stop");
assert(l_rest < spring_l0, "spring has no preload");
assert(tube_od <= spring_od - 2 * spring_wd - 0.5, "tube too wide for the spring");
assert((tube_od - bore_lo) / 2 >= 0.8, "tube wall too thin round the collar");
assert(z_step < z_tt - 1, "upper bore too short");
assert(z_tt > z_seat + 1, "tube does not rise above the cover");
assert(cbore_d <= spring_od - 2 * spring_wd, "O-ring counterbore wider than the spring's inside: the top coil loses its seat");
assert(oring_id > bore_hi && oring_id < tube_od, "O-ring does not land on the tube's top");
assert(oring_id >= pin_d, "O-ring too tight on the pin");
assert(oring_seat < oring_cs - 0.5, "O-ring hardly stands out of its counterbore");
assert(stop_od <= bore_lo - 0.2, "stop washer rubs in the lower bore");
assert(stop_id < pin_d && stop_id > pin_d - 0.3, "stop washer must sit a little tight on the pin");
assert(stop_od > bore_hi + 0.4, "stop washer hardly meets the step");
assert(mag_d <= collar_d - 1.2 && mag_l <= collar_h - 0.3, "magnet does not fit the collar");
assert(b_bot <= sens_range, "field beyond the sensor's range at the lower stop");
assert(sens_l / 2 < margin_n, "sensor beyond the board's edge");
// staircase: the next board's caps and cover must stay clear of this cap
assert(stair[1] - margin_n - cap_d / 2 >= 0.5, "cap runs into the next board's front edge");
assert(stair[1] - cap_d >= 0.5, "caps of neighbouring boards touch");
assert(skirt_od <= cap_d - 1, "skirt too wide for the cap");
assert(z_sht < z_cu - stroke - 0.5, "shroud reaches the cap at the lower stop");
assert(z_sht - (z_cu - skirt_l) >= overlap_min - 1e-6, "spring visible at rest");
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
module plunger() translate([0, 0, dz]) difference() {
    union() {
        translate([0, 0, z_cb]) cylinder(d = collar_d, h = collar_h);
        translate([0, 0, z_cb + collar_h - 0.01]) cylinder(d = pin_d, h = z_cu + cap_sock - z_cb - collar_h);
    }
    translate([0, 0, z_cb - 0.01]) cylinder(d = mag_d + 0.05, h = mag_l);   // magnet pocket
}
module magnet() translate([0, 0, z_cb + dz]) cylinder(d = mag_d, h = mag_l);
module oring() translate([0, 0, z_cu + oring_seat - oring_cs / 2 + dz])
    rotate_extrude() translate([oring_id / 2 + oring_cs / 2, 0]) circle(d = oring_cs);
module stop() translate([0, 0, z_cb + collar_h + dz]) difference() {
    cylinder(d = stop_od, h = stop_t);
    translate([0, 0, -1]) cylinder(d = pin_d, h = stop_t + 2);
}
// cover plate (one pitch of it) with the tube
module tube() difference() {
    union() {
        translate([-pitch / 2, -margin_n, pcb_t / 2]) cube([pitch, margin_n + margin_p, cover_t]);
        translate([0, 0, pcb_t / 2]) cylinder(d = tube_od, h = z_tt - pcb_t / 2);
        translate([0, 0, pcb_t / 2]) difference() {   // shroud round the spring
            cylinder(d = shroud_od, h = z_sht - pcb_t / 2);
            translate([0, 0, cover_t]) cylinder(d = shroud_id, h = z_sht);
        }
    }
    translate([0, 0, pcb_t / 2 - 0.01]) cylinder(d = bore_lo, h = z_step - pcb_t / 2 + 0.01);
    translate([0, 0, pcb_t / 2]) cylinder(d = bore_hi, h = z_tt);
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
    color("Ivory") plunger();
    color("SlateGray") magnet();
    color("DimGray") oring();
    color("Firebrick") stop();
    color("Silver") spring();
    color("Black") sensor();
}
else if (part == "cap")     { cap(); skirt(); }
else if (part == "plunger") plunger();
else if (part == "magnet")  magnet();
else if (part == "oring")   oring();
else if (part == "stop")    stop();
else if (part == "spring")  spring();
else if (part == "tube")    tube();
else if (part == "sensor")  sensor();
else if (part == "board")   board();
