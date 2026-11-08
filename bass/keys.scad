// The 18 keys at rest: the discant's button parts (switch/button.scad, unchanged).
// part = "static" leaves out the key that the phone page moves (front row, x = 0)
// and, of the others, all but button and felt.
//
// make builds   openscad -o ../build/bass/keys.stl keys.scad

include <layout.scad>
part = "all";
K = "../build/switch/";
for (k = [0, 1], i = [0 : n_row - 1])
    if (part == "all" || key_xy(k, i) != [0, 0])
        translate([key_xy(k, i)[0], key_xy(k, i)[1], board_z[k]]) {
            import(str(K, "button.stl")); import(str(K, "felt.stl"));
            if (part == "all")
                for (p = ["washer", "sleeve", "screw", "spring"]) import(str(K, p, ".stl"));
        }
