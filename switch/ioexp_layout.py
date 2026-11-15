#!/usr/bin/env python3
"""The key board's -x end with its own I2C port expander [given: an I2C chip on every key
board]: writes ioexp.scad (copper, vias, bodies) for pcb.scad and checks clearances.

Part: NXP PCAL9555A, HWQFN24 (SOT994-1, 4 x 4 x 0.75), datasheet Rev. 2, 19 Dec 2014:
P0_0..P0_7 pins 1..8, VSS 9 (and the centre pad), P1_0..P1_7 10..17, A0 18, SCL 19,
SDA 20, VDD 21, INT 22, A1 23, A2 24; address 0100 A2 A1 A0 (20h..27h), A0..A2 straight
to VDD or VSS. Land pattern as KiCad's HVQFN-24-1EP_4x4mm_P0.5mm: pads 0.875 x 0.25 at
1.9375 from the centre; centre pad 2.5 x 2.5 here.

Frame: pcb.scad's, seen from +z. The chip is on the bottom face, so its pins run
clockwise in this view: 1..6 on the north side west to east, 7..12 east side north to
south, 13..17/18 south side east to west, 19..24 west side south to north.

Tracks come from the existing +y band (hole h at y = 5.4 + 0.3 (h - 1)): the four lowest
turn down first, round the chip's east side to its south pins; the next five go down
east of the chip into its east pins; the four highest turn down west of those into its
north pins. Nothing crosses. The west pins SCL, SDA, VDD, INT run straight west into a
JST SH connector (BM05B-SRSS-TB, vertical, on the bottom face, its plug from below) and
to three solder jumpers (A0..A2: the middle pad to the pin, bridged to VDD or GND). GND
on the top copper: the existing common bus along y = -4.5, on to a via in the centre
pad, to the connector's GND pin and to the jumpers' GND vias.
"""
import math, sys

TR = 0.15; CLR = 0.15; EDGE = 0.3; SCREW_CLR = 0.5; VIA_D = 0.6; VIA_DR = 0.3
def hole_x(k): return -120 + (k - 1) * 20
RING_IN, R_OUT = 4.5, 5.0
def lev(h): return 5.4 + (h - 1) * 0.3
X_START, Y_MIN, Y_MAX = -145.796, -5.3, 9.4
SCREWS = [(-142, 0), (-50, 0)]
QX, QY = -130.3, 1.0
PAD_L, PAD_W, PAD_C, EP = 0.875, 0.25, 1.9375, 2.5

items = []   # (layer, net, kind, data, width)
def track(layer, net, pts, w=TR): items.append((layer, net, "track", pts, w))
def rect(layer, net, cx, cy, sx, sy): items.append((layer, net, "rect", (cx - sx / 2, cy - sy / 2, cx + sx / 2, cy + sy / 2), 0))
def via(net, x, y):
    for L in ("B", "T"): items.append((L, net, "via", (x, y), VIA_D))

# --- the chip's pads
NAMES = {**{i: f"P0_{i - 1}" for i in range(1, 9)}, 9: "VSS", **{i: f"P1_{i - 10}" for i in range(10, 18)},
         18: "A0", 19: "SCL", 20: "SDA", 21: "VDD", 22: "INT", 23: "A1", 24: "A2"}
def pin_xy(i):
    if i <= 6:  return (QX - 1.25 + 0.5 * (i - 1), QY + PAD_C, PAD_W, PAD_L)
    if i <= 12: return (QX + PAD_C, QY + 1.25 - 0.5 * (i - 7), PAD_L, PAD_W)
    if i <= 18: return (QX + 1.25 - 0.5 * (i - 13), QY - PAD_C, PAD_W, PAD_L)
    return (QX - PAD_C, QY - 1.25 + 0.5 * (i - 19), PAD_L, PAD_W)
net_of = {}
# keys: south pins 13..16 <- holes 4..1, east 7, 8, 10, 11, 12 <- holes 9, 8, 7, 6, 5, north 6..3 <- holes 10..13
for h, i in zip(range(1, 5), (16, 15, 14, 13)): net_of[i] = f"KEY{h}"
for h, i in zip(range(5, 10), (12, 11, 10, 8, 7)): net_of[i] = f"KEY{h}"
for h, i in zip(range(10, 14), (6, 5, 4, 3)): net_of[i] = f"KEY{h}"
net_of.update({9: "GND", 18: "A0", 19: "SCL", 20: "SDA", 21: "VDD", 22: "INT", 23: "A1", 24: "A2"})
for i in range(1, 25):
    x, y, sx, sy = pin_xy(i); rect("B", net_of.get(i, f"NC{i}"), x, y, sx, sy)
rect("B", "GND", QX, QY, EP, EP)
via("GND", QX, QY)                                                # in the centre pad
track("B", "GND", [(QX + PAD_C, QY + 0.25), (QX + 1.0, QY + 0.25)], 0.2)   # VSS pin into the centre pad

# --- the keys
for h in range(1, 14):
    i = next(p for p, n in net_of.items() if n == f"KEY{h}")
    px, py, *_ = pin_xy(i)
    start = [(hole_x(h), RING_IN), (hole_x(h), lev(h))]
    if h <= 9:
        xv = QX + 2.65 + (9 - h) * 0.3
        if h <= 4:
            ys = QY - 2.65 - (4 - h) * 0.3
            track("B", f"KEY{h}", start + [(xv, lev(h)), (xv, ys), (px, ys), (px, py)])
        else:
            track("B", f"KEY{h}", start + [(xv, lev(h)), (xv, py), (px, py)])
    else:
        track("B", f"KEY{h}", start + [(px, lev(h)), (px, py)])
    # the ring the track starts in: its +y half is the key's
    items.append(("B", f"KEY{h}", "ring", (hole_x(h), 0), 0))

# --- the connector: JST SH, vertical (BM05B-SRSS-TB), on the bottom face west of the chip,
# its pins along x; the plug comes in from below (-z) and the wires go down. Footprint as
# KiCad's: pads 0.6 x 1.55 at 1.0 pitch, 1.325 off the centre (here towards +y); the two
# fixing pads 1.2 x 1.8 at +-3.3, 1.2 to the other side; body 7.1 x 3.0 (-1.9 .. 1.11).
CC = (-137.9, -2.8)
CON_NETS = {-2: "INT", -1: "VDD", 0: "SDA", 1: "SCL", 2: "GND"}     # pin 1 at -x
def cpad(tpin): return (CC[0] + tpin, CC[1] + 1.325)
for tpin, n in CON_NETS.items(): rect("B", n, *cpad(tpin), 0.6, 1.55)
for s in (-1, 1): rect("B", "MP", CC[0] + 3.3 * s, CC[1] - 1.2, 1.2, 1.8)
PTOP = CC[1] + 1.325 + 0.775            # the pads' upper ends
p = lambda i: pin_xy(i)[:2]
XW = QX - 2.375                         # the west pads' outer ends
# the bus: straight west from the chip's west pins, then down into the pads; nothing crosses
for n, i, tpin in (("SCL", 19, 1), ("SDA", 20, 0), ("VDD", 21, -1), ("INT", 22, -2)):
    x = cpad(tpin)[0]
    track("B", n, [p(i), (x, p(i)[1]), (x, PTOP - 0.3)])
# GND: a via under the body, on the top copper down into the common bus
GC = (cpad(2)[0], PTOP - 1.55 - 0.65)
via("GND", *GC); track("B", "GND", [(GC[0], PTOP - 1.0), GC])
track("T", "GND", [GC, (GC[0], -RING_IN), (hole_x(13), -RING_IN)])
# the address jumpers A1, A2 north of the bus (pads along y: VDD, pin, GND), A0 south of
# the chip below its pin (pads along x: VDD, pin, GND)
vx = {"A2": XW - 0.6, "A1": XW - 0.9}
JX, JW, JP = XW, 0.5, 0.85
JA2, JA1 = 5.1, 7.7
def jumper(name, y):
    for dy, n in ((JP, "VDD"), (0.0, name), (-JP, "GND")): rect("B", n, JX, y + dy, JW, 0.6)
jumper("A2", JA2); jumper("A1", JA1)
track("B", "A2", [p(24), (vx["A2"], p(24)[1]), (vx["A2"], JA2), (JX, JA2)])
track("B", "A1", [p(23), (vx["A1"], p(23)[1]), (vx["A1"], JA1), (JX, JA1)])
GX, VX = JX + 0.7, JX + 1.45            # the jumpers' GND and VDD vias
for y in (JA2 - JP, JA1 - JP): via("GND", GX, y); track("B", "GND", [(JX, y), (GX, y)])
for y in (JA2 + JP, JA1 + JP): via("VDD", VX, y); track("B", "VDD", [(JX, y), (VX, y)])
A0Y = -3.4; A0X = p(18)[0]
for dx, n in ((-0.85, "VDD"), (0.0, "A0"), (0.85, "GND")): rect("B", n, A0X + dx, A0Y, 0.5, 0.6)
track("B", "A0", [p(18), (A0X, A0Y)])
A0G = (QX, A0Y); via("GND", *A0G); track("B", "GND", [(A0X + 0.85, A0Y), A0G])
A0V = (A0X - 1.55, A0Y); via("VDD", *A0V); track("B", "VDD", [(A0X - 0.85, A0Y), A0V])
# the capacitor, 0402, upright beside the jumpers: VDD above, GND below
CAP = (VX, JA2 - 0.48)
rect("B", "VDD", CAP[0], CAP[1] + 0.48, 0.5, 0.5); rect("B", "GND", CAP[0], CAP[1] - 0.48, 0.5, 0.5)
track("B", "VDD", [(CAP[0], CAP[1] + 0.48), (VX, JA2 + JP)])
track("B", "GND", [(CAP[0], CAP[1] - 0.48), (GX, JA2 - JP)])
# VDD to the jumpers on the top copper, from a via on the bus's VDD run down to the pad
VV = (cpad(-1)[0], 0.1)
via("VDD", *VV)
track("T", "VDD", [VV, (VV[0], JA1 + JP), (VX, JA1 + JP), (VX, JA2 + JP)])
track("T", "VDD", [VV, (A0V[0], VV[1]), A0V])
# GND on the top copper: the centre pad and the jumpers' GND vias into the common bus
track("T", "GND", [(QX, -RING_IN), (QX, QY)])
track("T", "GND", [(GX, JA1 - JP), (GX, QY), (QX, QY)])
for k in range(1, 14): via("GND", hole_x(k), -RING_IN)

# --- checks -----------------------------------------------------------------------
def sd(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay; L = dx * dx + dy * dy
    t = 0 if L == 0 else max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / L))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)
def inter(a, b, c, d):
    def o(p, q, r): return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return o(a, b, c) * o(a, b, d) < 0 and o(c, d, a) * o(c, d, b) < 0
def ss(a, b, c, d): return 0 if inter(a, b, c, d) else min(sd(a, c, d), sd(b, c, d), sd(c, a, b), sd(d, a, b))
def segs(it):
    L, n, kind, d, w = it
    if kind == "track": return [(d[i], d[i + 1]) for i in range(len(d) - 1)], w / 2
    if kind == "via": return [(d, d)], w / 2
    if kind == "rect":
        x0, y0, x1, y1 = d; c = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
        return [(c[i], c[(i + 1) % 4]) for i in range(4)], 0
    if kind == "poly":
        return [(d[i], d[(i + 1) % len(d)]) for i in range(len(d))], 0
    return None, 0
def inside_rect(p, d): return d[0] <= p[0] <= d[2] and d[1] <= p[1] <= d[3]
def inside_poly(p, P):
    c = False
    for i in range(len(P)):
        (x1, y1), (x2, y2) = P[i], P[(i + 1) % len(P)]
        if (y1 > p[1]) != (y2 > p[1]) and p[0] < x1 + (p[1] - y1) * (x2 - x1) / (y2 - y1): c = not c
    return c
def dist(a, b):
    if a[2] == "ring" or b[2] == "ring":
        r, o = (a, b) if a[2] == "ring" else (b, a)
        s, h = segs(o); c = r[3]
        return min(sd(c, p, q) for p, q in s) - h - R_OUT
    sa, ha = segs(a); sb, hb = segs(b)
    for x, y in ((a, b), (b, a)):
        if x[2] == "rect":
            for p, q in segs(y)[0]:
                if inside_rect(p, x[3]): return -1
        if x[2] == "poly":
            for p, q in segs(y)[0]:
                if inside_poly(p, x[3]): return -1
    return min(ss(p, q, r, s) for p, q in sa for r, s in sb) - ha - hb
bad = []; near = []
for i in range(len(items)):
    for j in range(i):
        a, b = items[i], items[j]
        if a[0] != b[0] or a[1] == b[1]: continue
        if a[2] == "ring" and b[2] == "ring": continue
        # a ring's -y half is the common's: the GND vias in it belong there
        r, o = (a, b) if a[2] == "ring" else (b, a)
        if r[2] == "ring" and o[1] == "GND" and o[2] == "via" and o[3][1] < 0: continue
        dd = dist(a, b)
        near.append((round(dd, 3), a[1], a[2], b[1], b[2]))
        if dd < CLR - 1e-6: bad.append((round(dd, 3), a[0], a[1], a[2], b[1], b[2]))
# edges and screw holes
for it in items:
    if it[2] == "ring": continue
    s, h = segs(it)
    for p, q in s:
        for x, y in (p, q):
            ymax = (10.6 if x + h <= -142.038 else Y_MAX)
            if x - h < X_START + EDGE - 1e-6 or y - h < Y_MIN + EDGE - 1e-6 or y + h > ymax - EDGE + 1e-6:
                bad.append(("edge", it[0], it[1], it[2], round(x, 2), round(y, 2)))
        for sx, sy in SCREWS:
            if sd((sx, sy), p, q) - h - 1.1 < SCREW_CLR - 1e-6: bad.append(("screw", it[0], it[1], it[2], sx))
print("closest pairs of different nets:", sorted(near)[:6])
print("clearance violations:", len(bad))
for b in sorted(set(bad), key=str)[:30]: print("  ", b)

# --- ioexp.scad ------------------------------------------------------------------
def pts(l): return "[" + ", ".join(f"[{x:.4f}, {y:.4f}]" for x, y in l) + "]"
out = ["// written by ioexp_layout.py: the key board's -x end with its own I2C expander\n"]
for L in ("B", "T"):
    tr = [it for it in items if it[0] == L and it[2] == "track"]
    out.append(f"ioexp_tracks_{L} = [" + ",\n  ".join(f"[{it[4]}, {pts(it[3])}]" for it in tr) + "];\n")
pl = [it for it in items if it[0] == "B" and it[2] == "poly"]
out.append("ioexp_polys = [" + ",\n  ".join(pts(it[3]) for it in pl) + "];\n")
out.append(f"ioexp_con = [{CC[0]}, {CC[1]}];   // JST SH BM05B-SRSS-TB on the bottom face: footprint centre; body 7.1 x 3.0 x 4.25 (y -1.9 .. 1.11), plug from below\n")
rc = [it for it in items if it[0] == "B" and it[2] == "rect"]
out.append("ioexp_pads = [" + ",\n  ".join(f"[{d[0]:.4f}, {d[1]:.4f}, {d[2]:.4f}, {d[3]:.4f}]" for d in (it[3] for it in rc)) + "];\n")
vs = sorted({it[3] for it in items if it[2] == "via" and it[0] == "B"})
out.append("ioexp_vias = " + pts(vs) + ";\n")
out.append(f"ioexp_chip = [{QX}, {QY}];   // HWQFN24 body 4 x 4 x 0.75 on the bottom face\n")
out.append(f"ioexp_cap = [{CAP[0]}, {CAP[1]}];   // 0402 body 1.0 x 0.5 x 0.5\n")
out.append("ioexp_con_pins = [" + ", ".join(f'"{CON_NETS[k]}"' for k in range(-2, 3)) + "];   // pin 1 .. 5, from -x\n")
out.append("ioexp_pins = [" + ", ".join(f'["{NAMES[i]}", "{net_of.get(i, "-")}"]' for i in range(1, 25)) + "];\n")
open("ioexp.scad", "w").write("".join(out))
sys.exit(1 if bad else 0)
