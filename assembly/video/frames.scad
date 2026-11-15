// Four small cubes at the discant frame's origin and unit points, moved by
// ../../bass/link.scad's to_bass() (which = "bass") or to_store() ("store"): promo.py
// reads the two transforms back from their centres; the cubes' sizes (0.2, 0.4, 0.6,
// 0.8) tell them apart, since the STL's vertex order does not.
use <../../bass/link.scad>
which = "bass";
module marks() for (i = [0 : 3]) translate([[0, 0, 0], [10, 0, 0], [0, 10, 0], [0, 0, 10]][i]) cube(0.2 * (i + 1), center = true);
if (which == "bass") to_bass() marks(); else to_store() marks();
