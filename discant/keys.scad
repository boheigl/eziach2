// The discant's 46 keys (../switch_hall/) in place: cap with skirt, plunger, magnet,
// O-ring and stop washer of every key, at rest or (down = true) at the lower stop; from
// the key's STLs in ../build/switch_hall/ (its Makefile builds them). The springs are
// left out: hidden in the shrouds, checked in the key's own model, and their helix makes
// the file a hundred times larger. row = k shows row k only (-1: all).
//
// make builds   openscad -o ../build/discant/keys.stl keys.scad
//               openscad -o ../build/discant/keys_down.stl -D down=true keys.scad

include <hall.scad>

down  = false;
row   = -1;
parts = ["cap", "plunger", "magnet", "oring", "stop"];
K     = "../build/switch_hall/";

for (i = [0 : len(hall_keys) - 1]) if (row < 0 || key_row(i) == row) at_key(key_row(i), key_x(i))
    for (p = parts) import(str(K, p, down ? "_down" : "", ".stl"));
