#!/usr/bin/env python3
"""Writes main_pcb.kicad_pcb from design.py: footprints, nets, outline, placement."""
import sys, json, uuid, pcbnew
import design as d

mm = pcbnew.FromMM
OX, OY = 100.0, 100.0            # band frame -> board: x = OX + X, y = OY - Y
def P(x, y): return pcbnew.VECTOR2I(mm(OX + x), mm(OY - y))
FPLIB = "/usr/share/kicad/footprints"

b = pcbnew.BOARD()
b.SetCopperLayerCount(4)
nets = {}
def net(name):
    if name not in nets:
        n = pcbnew.NETINFO_ITEM(b, name); b.Add(n); nets[name] = n
    return nets[name]

def load(c):
    lib, name = c["fp"].split(":")
    f = pcbnew.FootprintLoad(f"{FPLIB}/{lib}.pretty", name)
    f.SetReference(c["ref"]); f.SetValue(c["value"])
    f.SetFPIDAsString(c["fp"])
    return f

def pad_center(f):
    xs = [p.GetPosition().x for p in f.Pads() if p.GetNumber() not in ("41", "")]
    ys = [p.GetPosition().y for p in f.Pads() if p.GetNumber() not in ("41", "")]
    return (min(xs) + max(xs)) // 2, (min(ys) + max(ys)) // 2

def place(f, x, y, side, rot):
    b.Add(f)                                   # Flip needs the board
    if side == "B":
        f.Flip(f.GetPosition(), pcbnew.FLIP_DIRECTION_TOP_BOTTOM)
    f.SetOrientationDegrees(rot)
    f.SetPosition(P(x, y))

placed = {}
zifmap = {f"J{k + 1}": {} for k in range(4)}
# ZIFs and the diodes behind them
def zif(c, k):
    x, y = c["pos"]
    want = 1 if k < 3 else -1                  # tails towards +X (top) or -X (underside)
    f = load(c); place(f, x, y, c["side"], 90)
    tail = [p for p in f.Pads() if p.GetNumber() == "1"][0].GetPosition().x
    if (tail - f.GetPosition().x) * want < 0:
        f.SetOrientationDegrees(270)
    # the pads by position: conductor 1 at +Y (smallest board y)
    sig = sorted([p for p in f.Pads() if p.GetNumber() not in ("MP", "")], key=lambda p: p.GetPosition().y)
    for i, p in enumerate(sig):
        n = c["pins"][f"c{i + 1}"]
        zifmap[c["ref"]][p.GetNumber()] = n
        if n: p.SetNet(net(n))
    for p in f.Pads():
        if p.GetNumber() == "MP": p.SetNet(net("GND"))
    return f, sig

rows = {}
for k in range(4):
    c = next(q for q in d.C if q["ref"] == f"J{k + 1}")
    f, sig = zif(c, k)
    placed[c["ref"]] = f; rows[k] = sig

tails = {}
for k in range(4):
    sgn = 1 if k < 3 else -1
    for ci, p in enumerate(rows[k]):
        cnum = ci + 1
        if cnum == 1: continue
        h = 15 - cnum
        if not d.used(k, h): continue
        ref = f"D{(k + 1) * 100 + h}"
        c = next(q for q in d.C if q["ref"] == ref)
        px = pcbnew.ToMM(p.GetPosition().x) - OX; py = OY - pcbnew.ToMM(p.GetPosition().y)
        off = 0.9 + 0.9 + (1.75 if cnum % 2 else 0.0)
        f = load(c)
        if k == 2:                             # no room behind ZIF 2: in front of its mouth,
            sgn = -1                           #   under the film; tracks run back under the ZIF
            dx = d.ZIF_MOUTH[2] - 0.7 - (1.75 if cnum % 2 else 0.0)
            place(f, dx, py, "F", 180)
        else:
            place(f, px + sgn * off, py, "F" if k < 3 else "B", 0 if sgn > 0 else 180)
        placed[ref] = f
        for q in f.Pads():
            if q.GetNumber() in c["pins"]: q.SetNet(net(c["pins"][q.GetNumber()]))
        # pad 1 (cathode) must point away from the ZIF
        pos1 = [q for q in f.Pads() if q.GetNumber() == "1"][0].GetPosition().x
        if (pos1 - f.GetPosition().x) * sgn < 0:
            f.SetOrientationDegrees(180 if sgn > 0 else 0)

for c in d.C:
    ref = c["ref"]
    if ref in placed: continue
    f = load(c)
    side = d.SIDE.get(ref, c["side"])
    if ref in d.PLACE: x, y, rot = d.PLACE[ref]
    else: (x, y), rot = c["pos"], c["rot"]
    place(f, x, y, side, rot)
    if ref == "U1":                            # the body's middle, not the footprint's origin
        cx, cy = pad_center(f); o = f.GetPosition()
        f.SetPosition(pcbnew.VECTOR2I(o.x + mm(OX + x) - cx, o.y + mm(OY - y) - cy))
    placed[ref] = f
    for q in f.Pads():
        n = c["pins"].get(q.GetNumber())
        if n: q.SetNet(net(n))
    if ref == "U1":                            # no radio: the antenna keepout does not apply
        for z in list(f.Zones()): f.Remove(z)
    if ref == "U1":                            # the footprint's thermal vias would cut the
        for q in list(f.Pads()):               #   column bus on In2: route.py sets its own
            if q.GetAttribute() == pcbnew.PAD_ATTRIB_PTH: f.Remove(q)
    if ref == "J5":
        for q in f.Pads():
            if q.GetNumber() == "S1": q.SetNet(net("GND"))

# outline and locating holes
o = d.OUTLINE
for i in range(len(o)):
    s = pcbnew.PCB_SHAPE(b); s.SetShape(pcbnew.SHAPE_T_SEGMENT)
    s.SetStart(P(*o[i])); s.SetEnd(P(*o[(i + 1) % len(o)])); s.SetLayer(pcbnew.Edge_Cuts); s.SetWidth(mm(0.1)); b.Add(s)
for x, y in d.PINS:
    s = pcbnew.PCB_SHAPE(b); s.SetShape(pcbnew.SHAPE_T_CIRCLE)
    s.SetCenter(P(x, y)); s.SetEnd(P(x + 1.1, y)); s.SetLayer(pcbnew.Edge_Cuts); s.SetWidth(mm(0.1)); b.Add(s)

ds = b.GetDesignSettings()
ds.m_TrackMinWidth = mm(0.127); ds.m_ViasMinSize = mm(0.45); ds.m_MinThroughDrill = mm(0.2); ds.m_MinClearance = mm(0.127)
ds.m_CopperEdgeClearance = mm(0.25); ds.m_HoleClearance = mm(0.2)
ds.SetBoardThickness(mm(1.6))
nc = ds.m_NetSettings.GetDefaultNetclass(); nc.SetClearance(mm(0.127)); nc.SetTrackWidth(mm(0.127)); nc.SetViaDiameter(mm(0.45)); nc.SetViaDrill(mm(0.2))
for ref, f in placed.items():
    f.SetPath(pcbnew.KIID_PATH("/" + str(uuid.uuid5(uuid.NAMESPACE_DNS, "eziach-main-" + ref))))
json.dump(zifmap, open("zif_pads.json", "w"), indent=1)
b.BuildConnectivity()
out = sys.argv[1] if len(sys.argv) > 1 else "main_pcb.kicad_pcb"
pcbnew.SaveBoard(out, b)

# report: pads off the board, and overlapping bodies
pts = [(OX + x, OY - y) for x, y in o]
def inside(x, y):
    c = False
    for i in range(len(pts)):
        (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % len(pts)]
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1): c = not c
    return c
off = []
for ref, f in placed.items():
    for p in f.Pads():
        bb = p.GetBoundingBox()
        for x, y in ((bb.GetLeft(), bb.GetTop()), (bb.GetRight(), bb.GetBottom()), (bb.GetLeft(), bb.GetBottom()), (bb.GetRight(), bb.GetTop())):
            if p.GetAttribute() != 2 and not inside(pcbnew.ToMM(x), pcbnew.ToMM(y)):
                off.append((ref, p.GetNumber(), round(pcbnew.ToMM(x) - OX, 2), round(OY - pcbnew.ToMM(y), 2)))
print("pads off the board:", sorted({(r, n) for r, n, *_ in off})[:20], off[:6])
items = []
for ref, f in placed.items():
    if ref == "U1":
        bx = [OX + 5.5, OX + 31.2, OY - 10.2, OY + 7.8]
    else:
        lay = pcbnew.F_CrtYd if f.GetLayer() == pcbnew.F_Cu else pcbnew.B_CrtYd
        s = f.GetCourtyard(lay)
        if s.OutlineCount() == 0: continue
        q = s.BBox(); bx = [pcbnew.ToMM(q.GetLeft()), pcbnew.ToMM(q.GetRight()), pcbnew.ToMM(q.GetTop()), pcbnew.ToMM(q.GetBottom())]
    items.append((ref, f.GetLayer(), bx))
ov = []
for i in range(len(items)):
    for j in range(i):
        a, bb = items[i], items[j]
        if a[1] != bb[1]: continue
        A, B = a[2], bb[2]
        w = min(A[1], B[1]) - max(A[0], B[0]); h = min(A[3], B[3]) - max(A[2], B[2])
        if w > 0.02 and h > 0.02: ov.append((a[0], bb[0], round(w, 2), round(h, 2)))
print("courtyard overlaps:", len(ov), [o_ for o_ in ov if o_[0][0] != "D" and o_[1][0] != "D" or (o_[0][0]=="D") != (o_[1][0]=="D") and "J" not in o_[0]+o_[1]])
pm = {r: [(p.GetNumber(), round(pcbnew.ToMM(p.GetPosition().x) - OX, 2), round(OY - pcbnew.ToMM(p.GetPosition().y), 2)) for p in placed[r].Pads() if p.GetNumber() in ("1","2","13","14","15","26","27","40")] for r in ("U1",)}
print(pm)
