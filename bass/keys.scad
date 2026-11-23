// The 18 keys (../switch_hall/: cap with skirt, plunger, magnet, O-ring, stop washer) at
// rest, or at the lower stop (down = true); the back row's with the riser (bass1_*), the
// front row's flat (bass0_*), from ../build/switch_hall/. The springs are left out: hidden
// in the shrouds, checked in the key's own model. part = "static" leaves out the key the
// 3D view moves (front row, x = 0).
//
// make builds   openscad -o ../build/bass/keys.stl keys.scad

include <layout.scad>
part = "all";
down = false;
K = "../build/switch_hall/";
for (k = [0, 1], i = [0 : n_row - 1])
    if (part == "all" || key_xy(k, i) != [0, 0])
        translate(at_key(k, i)) for (p = ["cap", "plunger", "magnet", "oring", "stop"])
            import(str(K, "bass", k, "_", p, down ? "_down" : "", ".stl"));
