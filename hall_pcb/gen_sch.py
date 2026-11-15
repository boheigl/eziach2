#!/usr/bin/env python3
"""Writes <board>/<board>.kicad_sch from design.py (board from HALL_BOARD). Run gen_pcb.py first: it
assigns the keys to the ADC channels and writes the pins with their nets
(discant/pins.json). Every pin ends in a net label: the netlist is the design
table, drawn. From ../discant/main_pcb (git history).
usage: gen_sch.py [DIR]"""
import json, uuid, sys, os
import design as d

G = 1.27
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_DNS, "eziach-hall-" + s))
ROOT = U("root")
POWER = {"+3V3", "GND"}
DIR = sys.argv[1] if len(sys.argv) > 1 else d.BOARD
PINS = json.load(open(os.path.join(DIR, "pins.json")))

def font(s=1.27): return f"(effects (font (size {s} {s})))"
def q(s): return '"' + str(s).replace('"', "'") + '"'

def pins_of(c):
    """[(number, name, net)]"""
    return [(p, c["pinfo"].get(p, p), n) for p, n in PINS[c["ref"]].items()]

lib, items = {}, []
def symbol(key, pins, two):
    """A box with its pins left and right; returns {number: (x, y)} in lib coordinates (y up)."""
    n = len(pins)
    if two:
        half = 2 * G * 2
        pos = {pins[0][0]: (-half - 2 * G, 0, 0), pins[1][0]: (half + 2 * G, 0, 180)}
        box = (-half, 1.27, half, -1.27)
    else:
        rows = (n + 1) // 2
        w = 10 * G * 2 if max(len(str(p[1])) for p in pins) > 4 else 6 * G * 2
        pos = {}
        for i, p in enumerate(pins):
            col, r = (0, i) if i < rows else (1, i - rows)
            y = (rows - 1 - 2 * r) * G
            pos[p[0]] = (-w / 2 - 2 * G, y, 0) if col == 0 else (w / 2 + 2 * G, y, 180)
        box = (-w / 2, rows * G + G, w / 2, -rows * G - G)
    if key not in lib:
        pin_s = ""
        for num, name, _net in pins:
            x, y, a = pos[num]
            kind = "power_in" if _net in POWER and not two and n > 3 else "passive"
            pin_s += f'(pin {kind} line (at {x:.2f} {y:.2f} {a}) (length {2 * G:.2f}) (name {q(name)} {font()}) (number {q(num)} {font()}))\n'
        lib[key] = (f'(symbol {q("hall:" + key)} (pin_names (offset 0.5)) (exclude_from_sim no) (in_bom yes) (on_board yes)\n'
                    f'(property "Reference" "U" (at 0 0 0) {font()}) (property "Value" {q(key)} (at 0 0 0) {font()})\n'
                    f'(property "Footprint" "" (at 0 0 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                    f'(property "Datasheet" "" (at 0 0 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                    f'(property "Description" "" (at 0 0 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                    f'(symbol {q(key + "_0_1")} (rectangle (start {box[0]:.2f} {box[1]:.2f}) (end {box[2]:.2f} {box[3]:.2f}) (stroke (width 0.254) (type default)) (fill (type background))))\n'
                    f'(symbol {q(key + "_1_1")} {pin_s}))\n')
    return pos, box

missing = set()
def lcsc(c):
    """JLCPCB / LCSC part number from design.LCSC; none for pads"""
    if c["fp"].startswith("TestPoint"): return ""
    n = d.LCSC.get((c["value"], c["fp"]))
    if n is None: missing.add((c["value"], c["fp"]))
    return n or ""

def snap(v): return round(v / G) * G

def instance(c, x, y):
    pins = pins_of(c)
    two = len(pins) == 2
    key = c["ref"][0:1] + "2" if two else c["value"]
    pos, box = symbol(key, pins, two)
    u = U(c["ref"])
    pin_s = "".join(f'(pin {q(p[0])} (uuid {U(c["ref"] + "/" + p[0])}))\n' for p in pins)
    items.append(f'(symbol (lib_id {q("hall:" + key)}) (at {x:.2f} {y:.2f} 0) (unit 1) (exclude_from_sim no) (in_bom {"no" if c["fp"].startswith("TestPoint") else "yes"}) (on_board yes) (dnp no) (uuid {u})\n'
                 f'(property "Reference" {q(c["ref"])} (at {x:.2f} {y + box[1] * -1 - 1.27:.2f} 0) {font()})\n'
                 f'(property "Value" {q(c["value"])} (at {x:.2f} {y - box[3] * -1 + 1.27 + 1.27:.2f} 0) {font()})\n'
                 f'(property "Footprint" {q(c["fp"])} (at {x:.2f} {y:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'(property "Datasheet" "" (at {x:.2f} {y:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'(property "Description" "" (at {x:.2f} {y:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'(property "LCSC" {q(lcsc(c))} (at {x:.2f} {y:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'{pin_s}(instances (project {q(d.BOARD)} (path {q("/" + ROOT)} (reference {q(c["ref"])}) (unit 1)))))\n')
    for num, name, net in pins:
        px, py, a = pos[num]
        X, Y = x + px, y - py
        if net is None:
            items.append(f'(no_connect (at {X:.2f} {Y:.2f}) (uuid {U(c["ref"] + "/nc/" + num)}))\n')
        else:
            ang, just = (180, "right") if a == 0 else (0, "left")
            items.append(f'(global_label {q(net)} (shape passive) (at {X:.2f} {Y:.2f} {ang}) (effects (font (size 1.27 1.27)) (justify {just})) (uuid {U(c["ref"] + "/l/" + num)}))\n')
    return box

def text(s, x, y, size=3):
    items.append(f'(text {q(s)} (exclude_from_sim no) (at {x:.2f} {y:.2f} 0) (effects (font (size {size} {size})) (justify left)) (uuid {U("t" + s)}))\n')

TITLES = {"sensors": "Hall sensors DRV5055A3 under every key, 100 nF each (title: row, key)",
          "adc": f"ADS7128: 8-channel 12-bit ADCs on I2C, addresses 10h..{0x10 + len(d.GROUPS) - 1:02X}h; ALERTs wired together to INT",
          "bus": d.BUS_TITLE + ": JST SH, as on the switch boards"}
LAY = {"bus": (30, 40, 120), "adc": (30, 200, 400), "sensors": (220, 40, 560)}
for g, (x0, y0, _h) in LAY.items():
    text(TITLES[g], x0, y0 - 12)
    x, y = snap(x0 + 25), snap(y0)
    cs = [c for c in d.C if c["group"] == g]
    if g == "sensors":
        us = [c for c in cs if c["ref"].startswith("U")]
        for i, c in enumerate(us):
            cx, cy = snap(x0 + 25 + (i // 12) * 75), snap(y0 + (i % 12) * 40)
            instance(c, cx, cy)
            if c.get("title"): text(c["title"], cx - 12, cy - 9, 1.27)
            instance(next(q for q in cs if q["ref"] == "C" + c["ref"][1:]), snap(cx + 32), cy)
        continue
    col = 0
    for c in cs:
        n = len(pins_of(c))
        h = 15 if n <= 3 else ((n + 1) // 2) * 2.54 + 18
        if y + h > y0 + _h:
            col += 1; y = snap(y0); x = snap(x0 + 25 + col * 62)
        instance(c, x, snap(y + h / 2 - 7))
        if c.get("title") and n > 3: text(c["title"], x - 12, y - 4, 1.27)
        y = snap(y + h)

# power flags
lib["PWR_FLAG"] = (f'(symbol "hall:PWR_FLAG" (power) (pin_names (offset 0)) (exclude_from_sim no) (in_bom no) (on_board no)\n'
                   f'(property "Reference" "#FLG" (at 0 0 0) {font()}) (property "Value" "PWR_FLAG" (at 0 0 0) {font()})\n'
                   f'(property "Footprint" "" (at 0 0 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                   f'(property "Datasheet" "" (at 0 0 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                   f'(property "Description" "" (at 0 0 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                   f'(symbol "PWR_FLAG_1_1" (pin power_out line (at 0 0 90) (length 0) (name "pwr" {font()}) (number "1" {font()}))))\n')
for i, n in enumerate(sorted(POWER)):
    x, y = snap(30 + i * 30), snap(180)
    r = f"#FLG{i + 1:02d}"
    items.append(f'(symbol (lib_id "hall:PWR_FLAG") (at {x:.2f} {y:.2f} 0) (unit 1) (exclude_from_sim no) (in_bom no) (on_board no) (dnp no) (uuid {U(r)})\n'
                 f'(property "Reference" {q(r)} (at {x:.2f} {y + 3:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'(property "Value" "PWR_FLAG" (at {x:.2f} {y + 5:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'(property "Footprint" "" (at {x:.2f} {y:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'(property "Datasheet" "" (at {x:.2f} {y:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'(property "Description" "" (at {x:.2f} {y:.2f} 0) (effects (font (size 1.27 1.27)) (hide yes)))\n'
                 f'(pin "1" (uuid {U(r + "/1")}))\n(instances (project {q(d.BOARD)} (path {q("/" + ROOT)} (reference {q(r)}) (unit 1)))))\n')
    items.append(f'(global_label {q(n)} (shape passive) (at {x:.2f} {y:.2f} 0) (effects (font (size 1.27 1.27)) (justify left)) (uuid {U("fl" + n)}))\n')

s = (f'(kicad_sch (version 20250114) (generator "eziach") (generator_version "9.0") (uuid {ROOT}) (paper "A0")\n'
     f'(title_block (title {q(d.TITLE)}) (comment 1 "Generated by gen_sch.py from design.py"))\n'
     f'(lib_symbols\n{"".join(lib.values())})\n{"".join(items)}\n(sheet_instances (path "/" (page "1"))) (embedded_fonts no))\n')
open(os.path.join(DIR, d.BOARD + ".kicad_sch"), "w").write(s)
print(len(d.C), "parts", len(items), "items")
for m in sorted(missing): print("no LCSC number:", *m)
