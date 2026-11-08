// Outer holder for the strain-gauge flexure plate
//
// One piece: a jaw on each outer arm — the fixed mounting points — joined by a
// pair of yokes that bridge over and under the plate. It is printed as part of the
// discant's housing [given]: its +y end grows out of the gauge pad on the back face
// (discant/gauge_link.scad), so it cannot slide on. The jaws are open channels
// through to the -y end instead, and the plate slides in from there, its +y edge
// first, until that edge lands on the pad.
//
// The yokes sit across the plate rather than beyond it, so nothing projects
// past the plate's +y edge, and they are held clear of its faces: the gap
// between them is the exit for the gauge leads, which leave in +y. In y they
// sit between the inner holder's front face and the plate's edge, the one
// stretch of plate that neither of them occupies.
//
// Two of them rather than one keeps the jaws tied together symmetrically —
// with only the upper yoke the lower halves hang off the outboard walls.
//
// ASSEMBLY ORDER: the plate goes in FIRST, then the inner holder onto it, from the
// same side. The plate passes between the yokes, which that holder, 8.8 mm tall
// where the gap is 4.8, cannot do. Then a dowel pin across each jaw, just beyond
// the arm's tip, keeps the plate from pulling out.
//
// Each jaw is a C in cross-section: plates above and below the arm, joined by
// the wall outboard of the plate. The pad sets the insertion depth.
//
// Coordinates as in inner_holder.scad: origin at the centre of the plate, material
// from z = -plate_t/2 to +plate_t/2.

/* [Flexure plate — from the STEP, do not edit] */
plate_t    = 2.5;    // plate thickness
plate_x    = 15;     // plate half width
plate_top  = 12.5;   // the plate's +y edge
plate_bot  = -12.5;  // the plate's -y edge, where the arms end
arm_inner  = 12;     // inner face of the outer arms

/* [What it has to clear] */
inner_x    = 11.5;   // outer face of inner_holder.scad — must not be touched
inner_front = 4.5;   // +y face of inner_holder.scad

/* [Holder] */
wall       = 4;      // material above, below and outboard of the plate
fit        = 0.3;    // clearance on the plate thickness, total (0.15 per face)
w_clear    = 0.2;    // clearance to the plate — same slide fit as holder.scad
clear      = 0.5;    // clearance to the inner holder
yoke_clear = 1.0;    // minimum gap from the yokes back to the inner holder.
                     // The yokes then fill whatever is left up to the plate
                     // edge, so they are as deep as the gap allows.
pin_d      = 1.5;    // dowel pin (ISO 2338, 1.5 x 10) across each jaw, past the arm's tip
pin_clear  = 0.05;   // tip to pin
pin_wall   = 0.75;   // jaw left beyond the pin
root       = 0.5;    // the +y end reaches this far into the pad, so the two are one solid

/* [Lead gap] */
cable_h    = 4.8;    // free height kept around the plate for the leads; the
                     // yoke starts above it

/* [Lead-in] */
lead_in    = 1.5;    // flare where the arms enter the jaws, 0 disables it
lead_c     = 0.6;    // how much it is flared, per side

$fa = 2; $fs = 0.2;

z_in     = plate_t / 2 + fit / 2;            // pocket half height
z_out    = z_in + wall;                      // outer half height
x_jaw    = max(arm_inner, inner_x + clear);  // inner face of the jaws
x_pocket = plate_x + w_clear;                // outer face of the pocket
x_out    = x_pocket + wall;                  // outer face of the jaws
y_mouth  = plate_bot - w_clear;              // where the arm tips seat
pin_x    = (arm_inner + plate_x) / 2;        // in the middle of the arm
pin_y    = plate_bot - pin_clear - pin_d / 2;
y_back   = pin_y - pin_d / 2 - pin_wall;     // -y end of the part
y_front  = plate_top + root;                 // +y end, inside the pad
y_yoke   = inner_front + yoke_clear;         // -y face of the yokes
yoke     = y_front - y_yoke;                 // resulting yoke depth, root included
z_yoke   = cable_h / 2;                      // inner face of the yokes

echo(str("outer holder ", 2 * x_out, " x ", y_front - y_back, " x ", 2 * z_out, " mm"));
echo(str("two yokes at y = ", y_yoke, " .. ", y_front, " (flush with the plate), ",
         yoke, " mm deep, ", z_out - z_yoke, " mm thick, faces at z = +-", z_yoke));
echo(str("gap back to the inner holder: ", y_yoke - inner_front, " mm"));
echo(str("lead gap between them: ", 2 * z_yoke, " mm, ", z_yoke - (plate_t / 2),
         " mm clear of each plate face"));
echo(str("dowel pins d", pin_d, " at x = +-", pin_x, ", y = ", pin_y, ", ", pin_clear, " beyond the arm tips"));
echo(str("inner face at x = ", x_jaw, ", so ", x_jaw - inner_x,
         " mm clear of the inner holder"));
echo(str("plate clearances: ", w_clear, " mm per side, ", fit / 2,
         " mm per face, ", w_clear, " mm at the arm tips"));

// Flare at the -y opening, where the plate enters the jaw pockets, so a printed
// edge does not catch on the way in.
module mouth() {
    hull() {
        translate([x_jaw - 1, y_back + lead_in, -z_in])
            cube([x_pocket - x_jaw + 1, 0.01, 2 * z_in]);
        translate([x_jaw - 1, y_back - 0.01, -z_in - lead_c])
            cube([x_pocket - x_jaw + 1 + lead_c, 0.01, 2 * (z_in + lead_c)]);
    }
}

module jaw() {
    difference() {
        translate([x_jaw, y_back, -z_out])
            cube([x_out - x_jaw, y_front - y_back, 2 * z_out]);

        // channel the arm sits in, open inboard and at both ends
        translate([x_jaw - 1, y_back - 1, -z_in])
            cube([x_pocket - x_jaw + 1, y_front - y_back + 2, 2 * z_in]);

        if (lead_in > 0) mouth();
        translate([pin_x, pin_y, -z_out - 1]) cylinder(d = pin_d, h = 2 * z_out + 2);
    }
}

module outer_holder() {
    jaw();
    mirror([1, 0, 0]) jaw();

    // yokes over and under the plate, with the lead gap left between them
    for (s = [0, 1])
        mirror([0, 0, s])
            translate([-x_out, y_yoke, z_yoke])
                cube([2 * x_out, yoke, z_out - z_yoke]);
}

outer_holder();
