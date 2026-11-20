// The discant's housing as printed, and a test piece of it [given 2026-11-20: standing on
// its front edge, the outer holders up (spec.md, Printing)].
//
// standing(): the housing's slope undone (its tray and the plates then lie level), then
// turned up about x so its +y, the holders, points up. Both fitted sizes of the plates'
// slots (thickness and width) then lie in the plane of the layers.
//
// "holder_test": the +x gauge's corner of the housing, standing as in the whole print:
// the outer holder with its overload stop's tongue and the pad under them, cut level in
// the pad's solid back (behind the lead groove), so the piece stands on the pad's full
// section; the bought plate can be tried in the slot (0.15 mm a face) before the 101 mm
// housing is printed. The slot is the same: the cut lies only in the pad, below the holder.
//
// make (Makefile) writes ../build/discant/print_<part>.stl; plate.py puts them on the plate.

use <gauge_link.scad>

part = "holder_test";            // "holder_test" or "housing"

tilt   = atan(3 / 16);           // the slope (gauge_link.scad, gauge_tilt)
test_x = [5.5, 56];              // the test piece in the gauge frame: from inside the holder (5.8; the
                                 //   contacts' boss ends at 5) past the tongue (52.6)
test_y = [59.5, 100];            //   from the pad's solid back (59.3; the groove starts at 59.8) past the holder's tip (89.6)

module standing() rotate([90, 0, 0]) rotate([-tilt, 0, 0]) children();

if (part == "housing") standing() import("../build/discant/housing.stl");
if (part == "holder_test") standing() intersection() {
    import("../build/discant/housing.stl");
    gauge_tilt_frame() translate([test_x[0], test_y[0], -40]) cube([test_x[1] - test_x[0], test_y[1] - test_y[0], 80]);
}
