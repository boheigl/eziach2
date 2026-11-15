#!/usr/bin/env python3
"""Writes <board>/<board>.kicad_pcb from design.py (board from HALL_BOARD): footprints,
nets, outline, placement, and the ADC channel table (<board>/channels.json).
usage: gen_pcb.py [OUT]"""
import sys, os, json, math, uuid, pcbnew
import numpy as np
import design as d

mm = pcbnew.FromMM
OX, OY = 150.0, 100.0            # board frame -> KiCad: x = OX + X, y = OY - Y
def P(x, y): return pcbnew.VECTOR2I(mm(float(OX + x)), mm(float(OY - y)))
def W(v): return (pcbnew.ToMM(v.x) - OX, OY - pcbnew.ToMM(v.y))     # KiCad -> board frame
FPLIB = "/usr/share/kicad/footprints"
OUT = sys.argv[1] if len(sys.argv) > 1 else f"{d.BOARD}/{d.BOARD}.kicad_pcb"
os.makedirs(os.path.dirname(OUT), exist_ok=True)

b = pcbnew.BOARD()
b.SetCopperLayerCount(2)
nets = {}
def net(name):
    if name not in nets:
        n = pcbnew.NETINFO_ITEM(b, name); b.Add(n); nets[name] = n
    return nets[name]

def load(c):
    lib, name = c["fp"].split(":")
    f = pcbnew.FootprintLoad(f"{FPLIB}/{lib}.pretty", name)
    f.SetReference(c["ref"]); f.SetValue(c["value"]); f.SetFPIDAsString(c["fp"])
    return f

def place(f, x, y, side, rot):
    b.Add(f)
    if side == "B":
        f.Flip(f.GetPosition(), pcbnew.FLIP_DIRECTION_TOP_BOTTOM)
    f.SetOrientationDegrees(rot)
    f.SetPosition(P(x, y))

def pad(f, num): return next(p for p in f.Pads() if p.GetNumber() == num)
def connect(f, c):
    for q in f.Pads():
        n = c["pins"].get(q.GetNumber())
        if n: q.SetNet(net(n))

byref = {c["ref"]: c for c in d.C}
placed = {}

# --- sensors: the OUT and VCC pins face the ADC that reads the key ---------------
for c in d.C:
    if c["group"] != "sensors" or not c["ref"].startswith("U"): continue
    k, h = [(k, h) for (k, h) in d.KEYS if d.key_net(k, h) == c["pins"]["2"]][0]
    a = d.GROUP_OF[(k, h)]
    s = 1 if d.ADC_Y[a] > d.key_xy(k, h)[1] else -1
    f = load(c); x, y = c["pos"]
    best = None
    for rot in (0, 90, 180, 270):
        place(f, x, y, "B", rot)
        v = s * W(pad(f, "2").GetPosition())[1]
        if best is None or v > best[0] + 1e-6: best = (v, rot)
        b.Remove(f)
    place(f, x, y, "B", best[1])
    connect(f, c); placed[c["ref"]] = f
    # its capacitor beside it, along X, pads across the row
    cc = byref["C" + c["ref"][1:]]
    fc = load(cc); place(fc, *cc["pos"], "B", 90); connect(fc, cc); placed[cc["ref"]] = fc

# --- ADCs, their channels and small parts ------------------------------------------
channels = {}
for a, g in enumerate(d.GROUPS):
    ref = f"U{a + 1}"; c = byref[ref]
    f = load(c); x0, y0 = c["pos"]
    # the chip's own frame: its pads at rotation 0, then turned by ADC_ROT; R maps the
    # chip frame to the board (fitted from the pads, whatever KiCad's sign on the underside)
    place(f, x0, y0, "B", 0)
    loc = {q.GetNumber(): np.subtract(W(q.GetPosition()), (x0, y0)) for q in f.Pads()}
    f.SetOrientationDegrees(d.ADC_ROT); f.SetPosition(P(x0, y0))
    world = {q.GetNumber(): np.subtract(W(q.GetPosition()), (x0, y0)) for q in f.Pads()}
    A_ = np.array([loc[k] for k in loc]); B_ = np.array([world[k] for k in loc])
    U_, _, Vt = np.linalg.svd(A_.T @ B_); R = (U_ @ Vt).T
    phi = math.degrees(math.atan2(R[1, 0], R[0, 0]))
    def to_board(v): return (x0 + (R @ v)[0], y0 + (R @ v)[1])
    # keys to AIN pins by angle round the chip: both sorted, best cyclic match
    pins = sorted(d.ADC_AIN, key=lambda p: math.atan2(world[p][1], world[p][0]))
    pa = [math.atan2(world[p][1], world[p][0]) for p in pins]
    keys = sorted(g, key=lambda q: math.atan2(d.key_xy(*q)[1] + d.SENS_DY - y0, d.key_xy(*q)[0] - x0))
    ka = [math.atan2(d.key_xy(*q)[1] + d.SENS_DY - y0, d.key_xy(*q)[0] - x0) for q in keys]
    best = None
    for shift in range(len(pins)):
        cost = 0
        for i, q in enumerate(keys):
            da = abs((pa[(i + shift) % len(pins)] - ka[i] + math.pi) % (2 * math.pi) - math.pi); cost += da
        if best is None or cost < best[0]: best = (cost, shift)
    for i, q in enumerate(keys):
        p = pins[(i + best[1]) % len(pins)]
        c["pins"][p] = d.key_net(*q)
        channels.setdefault(f"{0x10 + a:02X}h", {})[f"AIN{d.ADC_AIN[p]}"] = {"row": q[0], "key": q[1]}
    connect(f, c); placed[ref] = f
    # caps and the address resistor: just outside the pin they serve, pads radial; laid
    # out in the chip's frame, then turned with it
    for fmt, pin, along in d.ADC_SMALL:
        r = fmt.format(a + 1)
        if r not in byref: continue
        cs = byref[r]; dx, dy = loc[pin]
        if abs(dx) > abs(dy):
            nx, ny, t, rot = (1 if dx > 0 else -1), 0, dy, 0
        else:
            nx, ny, t, rot = 0, (1 if dy > 0 else -1), dx, 90
        if along:
            (ax, ay), (bx, by) = loc[along[0]], loc[along[1]]
            ta, tb = (ay, by) if nx else (ax, bx)
            t_ = ta + along[2] * (tb - ta)
        else:
            t_ = t * 2.6
        dist = 3.5
        v = np.array([nx * dist + (0 if nx else t_), ny * dist + (0 if ny else t_)])
        fs = load(cs); place(fs, *to_board(v), "B", 0)
        # pads radial: the turn of the two that puts pad 1 nearest the chip on the radial line
        out = R @ np.array([nx, ny], float)
        best_r = None
        for rr in (rot + phi, rot - phi, rot + phi + 180, rot - phi + 180):
            fs.SetOrientationDegrees(rr % 360); fs.SetPosition(P(*to_board(v)))
            p1, p2 = np.array(W(pad(fs, "1").GetPosition())), np.array(W(pad(fs, "2").GetPosition()))
            e = p2 - p1; sc = -np.dot(e / np.linalg.norm(e), out)
            if best_r is None or sc < best_r[0]: best_r = (sc, rr)
        fs.SetOrientationDegrees(best_r[1] % 360); fs.SetPosition(P(*to_board(v)))
        connect(fs, cs); placed[r] = fs

# --- the rest at its given position ---------------------------------------------
for c in d.C:
    if c["ref"] in placed: continue
    f = load(c); place(f, *c["pos"], c["side"], c["rot"])
    if "Horizontal" in c["fp"]:
        # side entry: turn it so that its opening (the mounting pads' side) faces +Y
        for rot in (0, 90, 180, 270):
            f.SetOrientationDegrees(rot)
            if W(pad(f, "MP").GetPosition())[1] - W(pad(f, "3").GetPosition())[1] > 1: break
        f.SetPosition(P(*c["pos"]))
    connect(f, c); placed[c["ref"]] = f

# --- outline, screw holes, rules ------------------------------------------------
o = d.OUTLINE
for i in range(len(o)):
    s = pcbnew.PCB_SHAPE(b); s.SetShape(pcbnew.SHAPE_T_SEGMENT)
    s.SetStart(P(*o[i])); s.SetEnd(P(*o[(i + 1) % len(o)])); s.SetLayer(pcbnew.Edge_Cuts); s.SetWidth(mm(0.1)); b.Add(s)
for x, y in d.HOLES:
    s = pcbnew.PCB_SHAPE(b); s.SetShape(pcbnew.SHAPE_T_CIRCLE)
    s.SetCenter(P(x, y)); s.SetEnd(P(x + d.HOLE_D / 2, y)); s.SetLayer(pcbnew.Edge_Cuts); s.SetWidth(mm(0.1)); b.Add(s)

ds = b.GetDesignSettings()
ds.m_TrackMinWidth = mm(0.2); ds.m_ViasMinSize = mm(0.6); ds.m_MinThroughDrill = mm(0.3); ds.m_MinClearance = mm(0.2)
ds.m_CopperEdgeClearance = mm(0.3); ds.m_HoleClearance = mm(0.25)
ds.SetBoardThickness(mm(d.PCB_T))
nc = ds.m_NetSettings.GetDefaultNetclass(); nc.SetClearance(mm(0.2)); nc.SetTrackWidth(mm(0.2))
nc.SetViaDiameter(mm(0.6)); nc.SetViaDrill(mm(0.3))
for ref, f in placed.items():
    f.SetPath(pcbnew.KIID_PATH("/" + str(uuid.uuid5(uuid.NAMESPACE_DNS, "eziach-hall-" + ref))))
b.BuildConnectivity()
pcbnew.SaveBoard(OUT, b)
json.dump(channels, open(os.path.join(os.path.dirname(OUT), "channels.json"), "w"), indent=1)
json.dump({r: c["pins"] for r, c in byref.items()}, open(os.path.join(os.path.dirname(OUT), "pins.json"), "w"), indent=1)

# --- report: pads off the board, overlapping courtyards ----------------------------
def inside(x, y):
    c = False
    for i in range(len(o)):
        (x1, y1), (x2, y2) = o[i], o[(i + 1) % len(o)]
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1): c = not c
    return c and all(math.hypot(x - hx, y - hy) > d.HOLE_D / 2 + 0.3 for hx, hy in d.HOLES)
off = []
for ref, f in placed.items():
    for p in f.Pads():
        bb = p.GetBoundingBox()
        for v in (pcbnew.VECTOR2I(bb.GetLeft(), bb.GetTop()), pcbnew.VECTOR2I(bb.GetRight(), bb.GetBottom())):
            if not inside(*W(v)): off.append((ref, p.GetNumber()))
items = []
for ref, f in placed.items():
    s = f.GetCourtyard(pcbnew.B_CrtYd if f.GetLayer() == pcbnew.B_Cu else pcbnew.F_CrtYd)
    if s.OutlineCount() == 0: continue
    q = s.BBox(); items.append((ref, [pcbnew.ToMM(q.GetLeft()), pcbnew.ToMM(q.GetRight()), pcbnew.ToMM(q.GetTop()), pcbnew.ToMM(q.GetBottom())]))
ov = []
for i in range(len(items)):
    for j in range(i):
        A, B = items[i][1], items[j][1]
        w = min(A[1], B[1]) - max(A[0], B[0]); h = min(A[3], B[3]) - max(A[2], B[2])
        if w > 0.02 and h > 0.02: ov.append((items[i][0], items[j][0], round(w, 2), round(h, 2)))
# holes against courtyards
hov = [(ref, hx, hy) for ref, A in items for hx, hy in d.HOLES
       if A[0] - 1.6 < OX + hx < A[1] + 1.6 and A[2] - 1.6 < OY - hy < A[3] + 1.6]
print(f"{len(placed)} parts; pads off the board: {off}; courtyard overlaps: {ov}; holes on parts: {hov}")
print("board", round(o[1][0] - o[0][0], 1), "x", round(o[2][1] - o[0][1], 1), "mm (front edge x back)")
