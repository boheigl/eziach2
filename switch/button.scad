// Button for the middle hole of the switch board
//
// A stem that sits in the board's middle hole, with a cap on top of it. The
// stem runs up through the board and stands above the top face. The cap sits
// centred on the stem, and its upper edge is rounded.
//
// A washer sits against the stem's lower face, centred on the axis: M3 washer
// to ISO 7093 / DIN 9021, d3.2 / d9 x 0.8. It is wider than the stem and reaches out over
// the copper half-rings (r = 4 .. 5) on the board's underside, which stand
// 0.5 beyond it all round. If it is metal,
// it bridges the two halves of the ring.
// Beneath it sits a standard metal spacer sleeve for M3, and beneath that a
// second, identical washer. Both washers run in the guide tube, so the sleeve
// spaces the two guide points apart: with the washers stacked directly, the
// guide was 1.6 mm long and the button could tilt ~7 deg and jam when pressed
// off centre near the start of its stroke. The upper washer stays on top,
// because it closes the contact between the two half-rings.
//
// MOVING ASSEMBLY. Button, washers, sleeve and screw move together along z, between
// two stops:
//   upper stop (travel = 0): the upper washer bears on the copper half-rings.
//     The stem's lower face then sits cu_t (0.035) below the laminate.
//   lower stop (travel = stroke): the cap's underside lands on the cover's
//     top face.
// The parts are modelled with the stem flush with the laminate and then moved
// down by cu_t + travel; set travel to show any position.
//
// GUIDE. A 3D-printed tube, fixed to the board's underside around the middle
// hole, guides the assembly from below: the washers run in its bore with the
// same radial clearance as the stem in the board hole, so the assembly is held
// at two points, the stem in the hole and the washers in the tube. The tube's
// top face sits on the board's underside, its inner 0.3 mm on the edge of the
// copper rings, the rest on the solder mask; its wall stays
// clear of the connector body and of the board edge. It is closed at the
// bottom by a floor, which carries the spring. It is to be glued on, or held by
// whatever carries the board; the board has no fixing holes for it.
//
// SPRING. A compression spring stands on the floor of the tube and pushes the
// lower washer up, so the assembly rests at the upper stop. It surrounds the
// screw head and bears on the washer's annulus outside it. The spring is a
// bought part: 8 mm outside, 0.4 mm wire, 25 mm free length. It goes in
// preloaded so that it pushes with spring_f0 (120 g) at the upper stop: the
// preload follows from the estimated rate, and the floor, and with it the
// tube's length, from the preload. At the lower stop it is shorter by the stroke, which must stay above its
// solid length, and the screw head must stay clear of the floor. Ends closed
// and ground (one dead coil each); drawn at its working length for the current
// travel. It has 8 active coils; one closed dead coil at each end is assumed.
// It is soft and heavily preloaded, so the force rises little over the stroke.
// Being narrower than the bore, it is centred by a collar on the floor, which
// stays clear of the lower washer at the lower stop.
//
// An M3 self-tapping screw for plastics clamps washer, sleeve and washer to
// the stem from
// below. Pan head as ISO 7045 (d5.6 x 2.4) with a cross recess, bearing on the
// lower washer. The thread is drawn plain, at its major diameter, with a pointed tip.
// The stem carries a blind pilot hole for it, open at the lower face: d2.5,
// the usual core hole for an M3 tapping screw in thermoplastic, and 1 mm deeper
// than the screw reaches, to take the chips. That leaves the cap solid above it.
//
// Coordinates as in pcb.scad: origin at the centre of the board, laminate from
// z = -pcb_t/2 to +pcb_t/2. The middle hole is at x = 0, so the button's axis
// is the z axis.
//
// make builds   openscad -o ../build/switch/button.stl -D 'part="button"' button.scad
//              openscad -o ../build/switch/washer.stl -D 'part="washer"' button.scad   (both, in place)
//              openscad -o ../build/switch/sleeve.stl -D 'part="sleeve"' button.scad
//              openscad -o ../build/switch/screw.stl  -D 'part="screw"'  button.scad
//              openscad -o ../build/switch/guide.stl  -D 'part="guide"'  button.scad
//              openscad -o ../build/switch/spring.stl -D 'part="spring"' button.scad
// (moving parts at the upper stop unless travel is set)

/* [Board — as in pcb.scad, do not edit here] */
pcb_t   = 1.6;   // board thickness
hole_d  = 8;     // hole diameter
cu_t    = 0.035; // copper below the laminate

/* [Stem] */
gap     = 0.2;   // radial clearance to the hole
cover_t = 1.2;   // cover plate (discant/cover.scad): the cap now lands on it
stem_h  = 5.6 + cu_t + cover_t;  // from the underside of the laminate: keeps the stroke
                 // at 3.965 with the cap landing on the cover instead of the board

/* [Cap] */
cap_d   = 15;
cap_h   = 2;
cap_r   = 0.5;   // rounding of the upper edge

/* [Washer] */
washer_od = 9;    // ISO 7093 / DIN 9021, M3
washer_id = 3.2;
washer_t  = 0.8;

/* [Spacer sleeve — standard metal part for M3, between the washers] */
sleeve_od = 6;
sleeve_id = 3.2;
sleeve_l  = 5;    // the cover's d8 openings guide the stem as well, 1.2 above
                  // the board, so 5 mm keeps the guide span of before

/* [Screw — M3 tapping screw, pan head] */
screw_d   = 3;    // thread major diameter
screw_l   = 12;   // length under the head: washer + sleeve + washer + 4.4 in the stem
tip_l     = 1;    // pointed tip, part of screw_l
tip_d     = 1.2;  // diameter at the point
head_d    = 5.6;  // as ISO 7045
head_k    = 2.4;
head_r    = 1.2;  // rounding where the side meets the dome
slot_w    = 0.6;  // cross recess, simplified
slot_l    = 3;
slot_t    = 1.2;

/* [Pilot hole in the stem] */
pilot_d   = 2.5;  // core hole for M3 in thermoplastic
chip_room = 1;    // beyond the screw tip

/* [Guide tube — 3D printed] */
guide_gap   = 0.2;  // radial clearance to the washers
guide_wall  = 2;
floor_t     = 1.5;  // floor of the tube
head_clear  = 0.5;  // minimum, screw head to floor at the lower stop
collar_h    = 1.5;  // centring collar for the spring, on the floor
collar_gap  = 0.3;  // radial clearance around the spring

/* [Spring — compression, spring steel: d8 x 0.4 x 25, 8 active coils] */
spring_wd   = 0.4;  // wire diameter
spring_od   = 8;    // outside diameter
spring_n    = 10;   // total coils: 8 active (from the supplier) + one dead coil at each end (assumed)
spring_l0   = 25;   // free length
spring_f0   = 0.12 * 9.81; // force at the upper stop, N: 120 g; sets the preload and the tube length
spring_G    = 81500; // shear modulus, N/mm^2

/* [Position] */
travel  = 0;      // 0 = upper stop .. stroke = lower stop

/* [Output] */
part    = "all";  // "all", "button", "washer", "sleeve", "screw", "guide" or "spring"

$fa = 2; $fs = 0.1;

stem_d = hole_d - 2 * gap;
z0     = -pcb_t / 2;          // flush with the underside of the laminate
z_cap  = z0 + stem_h;         // stem top, cap underside
z_top  = z_cap + cap_h;

echo(str("stem d", stem_d, " x ", stem_h, ", z = ", z0, " .. ", z_cap, "; ",
         z_cap - pcb_t / 2, " mm above the top face"));
echo(str("cap d", cap_d, " x ", cap_h, ", z = ", z_cap, " .. ", z_top,
         ", upper edge R", cap_r));
echo(str("button height ", z_top - z0, " mm overall"));
z_slv   = z0 - washer_t;                 // top of the sleeve
z_bear  = z_slv - sleeve_l - washer_t;   // underside of the lower washer, where the head bears
echo(str("washers d", washer_od, " / d", washer_id, " x ", washer_t, " at z = ", z0 - washer_t,
         " .. ", z0, " and ", z_bear, " .. ", z_bear + washer_t, "; sleeve d", sleeve_od, " / d",
         sleeve_id, " x ", sleeve_l, " between them; stack ", z0 - z_bear, " mm"));

// travel
z_cu    = -pcb_t / 2 - cu_t;              // underside of the copper
stroke  = z_cap - cu_t - (pcb_t / 2 + cu_t + cover_t);   // washer on copper .. cap on the cover
assert(travel >= 0 && travel <= stroke, str("travel must lie in 0 .. ", stroke));
dz      = -cu_t - travel;                 // shift of the moving parts

// spring constants, needed for the floor position
spring_dm   = spring_od - spring_wd;                // mean diameter
spring_na   = spring_n - 2;                         // active coils
spring_k    = spring_G * pow(spring_wd, 4) / (8 * pow(spring_dm, 3) * spring_na);
spring_pre  = spring_f0 / spring_k;                 // compression at the upper stop

// guide tube
guide_id = washer_od + 2 * guide_gap;
guide_od = guide_id + 2 * guide_wall;
guide_z1 = z_cu;                                         // top, on the copper
floor_z  = z_bear - cu_t - (spring_l0 - spring_pre);    // top of the floor, from the spring
guide_z0 = floor_z - floor_t;                            // bottom of the tube
echo(str("stroke ", stroke, " mm: upper stop washer on the copper, lower stop cap on the cover"));
echo(str("guide tube d", guide_od, " / d", guide_id, ", z = ", guide_z0, " .. ", guide_z1,
         " (", guide_z1 - guide_z0, " long), floor ", floor_t, " at z = ", guide_z0,
         " .. ", floor_z, "; washers ", guide_gap, " clear"));

// spring, between the floor and the lower washer
spring_id   = spring_od - 2 * spring_wd;
spring_solid = spring_n * spring_wd;
l_up   = (z_bear - cu_t) - floor_z;                 // length at the upper stop
l_down = l_up - stroke;                             // at the lower stop
l_now  = l_up - travel;
assert(spring_id >= head_d + 0.6, "spring too narrow for the screw head");
assert(spring_od <= guide_id - 0.6, "spring too wide for the tube");
assert(l_down >= spring_solid + 0.3, "spring goes solid before the lower stop");
assert(spring_l0 > l_up, "spring has no preload at the upper stop");
assert(z_bear - head_k - cu_t - stroke - floor_z >= head_clear, "screw head hits the floor");
assert(l_down - collar_h >= 0.5, "lower washer hits the centring collar");
echo(str("spring d", spring_wd, " wire, d", spring_od, " / d", spring_id, ", ", spring_n,
         " coils (", spring_na, " active), free ", spring_l0, ", solid ", spring_solid));
echo(str("spring length ", l_up, " at the upper stop, ", l_down, " at the lower stop; rate ~",
         round(spring_k * 1000) / 1000, " N/mm, force ~", round(spring_k * (spring_l0 - l_up) * 100) / 100,
         " N .. ", round(spring_k * (spring_l0 - l_down) * 100) / 100, " N"));
z_tip   = z_bear + screw_l;         // screw point
z_hole  = z_tip + chip_room;        // bottom of the pilot hole

assert(z_hole < z_cap + cap_h - 1, "pilot hole too deep for the cap");
echo(str("screw M3 x ", screw_l, ", head z = ", z_bear - head_k, " .. ", z_bear,
         ", point at z = ", z_tip, "; ", z_tip - z0, " mm into the stem"));
echo(str("pilot hole d", pilot_d, ", z = ", z0, " .. ", z_hole, " (", z_hole - z0,
         " deep), ", z_top - z_hole, " mm of material above it"));

// profile in (r, z) for rotate_extrude: stem, then the cap with its rounded edge
module profile()
    union() {
        translate([0, z0]) square([stem_d / 2, stem_h]);
        translate([0, z_cap]) square([cap_d / 2, cap_h - cap_r]);
        translate([0, z_cap]) square([cap_d / 2 - cap_r, cap_h]);
        translate([cap_d / 2 - cap_r, z_top - cap_r]) circle(r = cap_r);
    }

// screw profile in (r, z), bearing face at z = 0, head below, shank above
module screw_profile()
    union() {
        // head: cylindrical side, rounded into the flat underside
        hull() {
            translate([0, -head_k]) square([head_d / 2 - head_r, head_k]);
            translate([0, -head_k + head_r]) square([head_d / 2, head_k - head_r]);
            translate([head_d / 2 - head_r, -head_k + head_r]) circle(r = head_r);
        }
        square([screw_d / 2, screw_l - tip_l]);
        polygon([[0, screw_l - tip_l], [screw_d / 2, screw_l - tip_l],
                 [tip_d / 2, screw_l], [0, screw_l]]);
    }

module screw()
    translate([0, 0, z_bear]) difference() {
        rotate_extrude() screw_profile();
        for (a = [0, 90])
            rotate(a) translate([-slot_l / 2, -slot_w / 2, -head_k - 1])
                cube([slot_l, slot_w, slot_t + 1]);
    }

// moving parts
translate([0, 0, dz]) {
    if (part == "all" || part == "button")
        difference() {
            rotate_extrude() profile();
            translate([0, 0, z0 - 1]) cylinder(d = pilot_d, h = z_hole - z0 + 1);
        }
    if (part == "all" || part == "screw")
        screw();
    if (part == "all" || part == "washer")
        for (z = [z0 - washer_t, z_bear])
            translate([0, 0, z]) difference() {
                cylinder(d = washer_od, h = washer_t);
                translate([0, 0, -1]) cylinder(d = washer_id, h = washer_t + 2);
            }
    if (part == "all" || part == "sleeve")
        translate([0, 0, z_slv - sleeve_l]) difference() {
            cylinder(d = sleeve_od, h = sleeve_l);
            translate([0, 0, -1]) cylinder(d = sleeve_id, h = sleeve_l + 2);
        }
}

// fixed guide tube with its floor
if (part == "all" || part == "guide")
    translate([0, 0, guide_z0]) difference() {
        cylinder(d = guide_od, h = guide_z1 - guide_z0);
        translate([0, 0, floor_t]) cylinder(d = guide_id, h = guide_z1 - guide_z0);
    }
// centring collar for the spring, standing on the floor inside the bore
if (part == "all" || part == "guide")
    translate([0, 0, floor_z]) difference() {
        cylinder(d = guide_id + 0.01, h = collar_h);
        translate([0, 0, -1]) cylinder(d = spring_od + 2 * collar_gap, h = collar_h + 2);
    }

// spring: the wire's centre line climbs one wire diameter per dead coil and
// shares the rest among the active coils; swept as a polyhedron, with a round
// section in the plane through the axis
function spring_z(t, len) =   // t in coils, 0 .. spring_n; centre-line height above the floor
    let(dead = spring_wd, pa = (len - spring_wd - 2 * dead) / spring_na)
    spring_wd / 2 + (t <= 1 ? t * dead
                   : t <= spring_n - 1 ? dead + (t - 1) * pa
                   : dead + spring_na * pa + (t - spring_n + 1) * dead);

module spring(len) {
    seg = 48;                 // per coil
    sec = 10;                 // around the wire
    steps = spring_n * seg;
    pts = [for (i = [0 : steps]) let(t = i / seg, a = 360 * t, zc = spring_z(t, len))
               for (j = [0 : sec - 1]) let(p = 360 * j / sec)
                   [(spring_dm / 2 + spring_wd / 2 * cos(p)) * cos(a),
                    (spring_dm / 2 + spring_wd / 2 * cos(p)) * sin(a),
                    zc + spring_wd / 2 * sin(p)]];
    faces = concat(
        [for (i = [0 : steps - 1]) for (j = [0 : sec - 1])
            [i * sec + j, i * sec + (j + 1) % sec, (i + 1) * sec + (j + 1) % sec, (i + 1) * sec + j]],
        [[for (j = [sec - 1 : -1 : 0]) j]],
        [[for (j = [0 : sec - 1]) steps * sec + j]]);
    polyhedron(points = pts, faces = faces);
}

if (part == "all" || part == "spring")
    translate([0, 0, floor_z]) spring(l_now);
