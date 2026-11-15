// One frame of the key's assembly video (key_video.py drives it): every part of
// ../key.scad at its own offset, shown or not, optionally cut in half.
//
// P: [[name, shown (0/1), dx, dz], ...] for the parts below; cut: take away the half
// towards the viewer (y < 0); T: the key's travel (0 .. stroke); L: [[x, z, "text"], ...]
// numbers standing in front of the parts.
include <../key.scad>
part = "none";
P = [];
cut = false;
T = 0;
L = [];

COL = [["board", "SeaGreen"], ["sensor", "Black"], ["tube", "Gainsboro"], ["bushing", "Peru"],
       ["collar", "Ivory"], ["magnet", "SlateGray"], ["rod", "Silver"], ["stop", "Firebrick"],
       ["spring", "LightSteelBlue"], ["oring", "DimGray"], ["cap", "Ivory"]];
function col(n) = [for (c = COL) if (c[0] == n) c[1]][0];
module draw(n) {
    if (n == "board") board();
    else if (n == "sensor") sensor();
    else if (n == "tube") tube();
    else if (n == "bushing") bushing();
    else if (n == "collar") translate([0, 0, -T]) collar();
    else if (n == "magnet") translate([0, 0, -T]) magnet();
    else if (n == "rod") translate([0, 0, -T]) rod();
    else if (n == "stop") translate([0, 0, -T]) stop();
    else if (n == "spring") spring_t();
    else if (n == "oring") translate([0, 0, -T]) oring();
    else if (n == "cap") translate([0, 0, -T]) { cap(); skirt(); }
}
// the spring at the key's travel (key.scad's spring() reads travel, a constant here)
module spring_t() {
    l = z_cu - T - z_seat; n = spring_n; r = spring_dm / 2;
    function zc(a) = let(t = a / 360)
        t < 1 ? t * spring_wd : t > n - 1 ? l - (n - t) * spring_wd
      : spring_wd + (t - 1) / (n - 2) * (l - 2 * spring_wd);
    translate([0, 0, z_seat + spring_wd / 2]) for (i = [0 : 36 * n - 1]) hull() for (a = [i, i + 1] * 10)
        translate([r * cos(a), r * sin(a), min(zc(a), l - spring_wd)]) sphere(d = spring_wd, $fn = 8);
}
for (p = P) if (p[1] > 0) color(col(p[0])) translate([p[2], 0, p[3]])
    if (cut) intersection() { draw(p[0]); translate([-50, 0, -50]) cube(100); }
    else draw(p[0]);
for (l = L) color("Black") translate([l[0], -6, l[1]]) rotate([90, 0, 0])
    linear_extrude(0.4) text(l[2], size = 2.6, halign = "center", valign = "top", font = "DejaVu Sans:style=Bold");
