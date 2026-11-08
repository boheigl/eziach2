#!/usr/bin/env python3
"""3D of the routed board for the assembly, in the band frame of ../main_pcb.scad
(X, Y as design.py, Z square to the hole's floor, 0 on the floor):
  kicad_board.stl   laminate with its holes   (kicad-cli)
  kicad_copper.stl  pads, tracks and vias on both faces   (kicad-cli)
  kicad_parts.stl   one body per part: its fabrication outline, raised to the
                    part's height; the ZIFs as actuator bar, body and nails
No 3D models are installed, so the parts are these boxes.
usage: export_3d.py OUT_DIR"""
import sys, os, struct, subprocess, tempfile
import pcbnew
import design as d

PCB_Z, PCB_T = 1.1, 1.6           # as main_pcb.scad
OX, OY = 100.0, 100.0
out = sys.argv[1]
os.makedirs(out, exist_ok=True)

def read_stl(f):
    b = open(f, "rb").read()
    if b[:5] == b"solid" and b"facet" in b[:400]:
        v = [tuple(map(float, l.split()[1:4])) for l in b.decode().splitlines() if l.strip().startswith("vertex")]
        return [v[i:i + 3] for i in range(0, len(v), 3)]
    n = struct.unpack("<I", b[80:84])[0]
    tris = []
    for i in range(n):
        f9 = struct.unpack("<9f", b[84 + 50 * i + 12:84 + 50 * i + 48])
        tris.append([f9[0:3], f9[3:6], f9[6:9]])
    return tris

def write_stl(f, tris):
    with open(f, "wb") as o:
        o.write(b"main_pcb export_3d".ljust(80, b" ") + struct.pack("<I", len(tris)))
        for t in tris:
            o.write(struct.pack("<3f", 0, 0, 0))
            for v in t: o.write(struct.pack("<3f", *v))
            o.write(b"\0\0")

def kicad(args, name):
    tmp = tempfile.mktemp(suffix=".stl")
    subprocess.run(["kicad-cli", "pcb", "export", "stl", "--user-origin", "0x0mm", "-f", "-o", tmp] + args + ["main_pcb.kicad_pcb"],
                   check=True, capture_output=True)
    raw = read_stl(tmp)
    tk = 1.51            # KiCad's default stackup; its upper face moves up to PCB_T
    tris = [[(x - OX, y + OY, PCB_Z + (z + PCB_T - tk if z > tk / 2 else z)) for x, y, z in t] for t in raw]
    os.remove(tmp)
    write_stl(os.path.join(out, name), tris)

kicad(["--board-only"], "kicad_board.stl")

def box(x0, x1, y0, y1, z0, z1):
    p = [(x, y, z) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    q = [(0, 2, 1), (1, 2, 3), (4, 5, 6), (5, 7, 6), (0, 1, 4), (1, 5, 4), (2, 6, 3), (3, 6, 7), (0, 4, 2), (2, 4, 6), (1, 3, 5), (3, 7, 5)]
    return [[p[a], p[b], p[c]] for a, b, c in q]

# height above the board, by footprint
H = {"R_0402": 0.5, "C_0402": 0.6, "L_0402": 0.6, "C_0603": 0.9, "C_1206": 1.8, "D_SOD-882": 0.5, "D_SOD-123": 1.35,
     "SOT-23-5": 1.45, "SOT-23-6": 1.45, "SOT-23": 1.1, "TSSOP": 1.2, "VQFN": 1.0, "USB_C": 3.31, "ESP32": 3.1}
def height(fp):
    for k, v in H.items():
        if k in fp: return v
    return None

b = pcbnew.LoadBoard("main_pcb.kicad_pcb")
parts = []
for f in b.GetFootprints():
    fp = f.GetFPIDAsString(); ref = f.GetReference()
    bottom = f.GetLayer() == pcbnew.B_Cu
    zb = (PCB_Z, -1) if bottom else (PCB_Z + PCB_T, 1)          # face, direction
    def body(x0, x1, y0, y1, h):
        za, zz = zb[0], zb[0] + zb[1] * h
        parts.extend(box(x0, x1, y0, y1, min(za, zz), max(za, zz)))
    if "FFC" in fp:
        # local frame from the pads: pad n at (-6.5 + n - 1, -3.375), the nails' middle at (0, -1.205);
        # the mouth at +2.475, the tails' tips at -4.275 (design.py)
        P = {}
        for p in f.Pads():
            P.setdefault(p.GetNumber(), []).append((pcbnew.ToMM(p.GetPosition().x) - OX, OY - pcbnew.ToMM(p.GetPosition().y)))
        p1, p14 = P["1"][0], P["14"][0]
        mp = [sum(c) / len(P["MP"]) for c in zip(*P["MP"])]
        a1 = [(p14[k] - p1[k]) / 13 for k in (0, 1)]
        mid = [(p1[k] + p14[k]) / 2 for k in (0, 1)]
        a2 = [(mp[k] - mid[k]) / (3.375 - 1.205) for k in (0, 1)]
        o = [mid[k] - a2[k] * (-3.375) for k in (0, 1)]
        def to(u, v): return [o[k] + a1[k] * u + a2[k] * v for k in (0, 1)]
        def lbox(u0, u1, v0, v1, h):
            a, c = to(u0, v0), to(u1, v1)
            body(min(a[0], c[0]), max(a[0], c[0]), min(a[1], c[1]), max(a[1], c[1]), h)
        m = 2.475
        lbox(-10.5, 10.5, m - 1.1, m, 2.5)          # actuator bar
        lbox(-7.8, 7.8, -4.275, m, 2.5)             # body
        lbox(-10.15, 10.15, m - 5.2, m - 2.2, 2.5)  # fitting nails
        continue
    h = height(fp)
    if h is None: continue
    lay = pcbnew.B_Fab if bottom else pcbnew.F_Fab
    xs, ys = [], []
    for g in f.GraphicalItems():
        if g.GetLayer() == lay and g.GetClass() == "PCB_SHAPE":      # outlines, not the reference text
            r = g.GetBoundingBox()
            xs += [r.GetLeft(), r.GetRight()]; ys += [r.GetTop(), r.GetBottom()]
    if not xs:
        for p in f.Pads():
            r = p.GetBoundingBox(); xs += [r.GetLeft(), r.GetRight()]; ys += [r.GetTop(), r.GetBottom()]
    x0, x1 = pcbnew.ToMM(min(xs)) - OX, pcbnew.ToMM(max(xs)) - OX
    y0, y1 = OY - pcbnew.ToMM(max(ys)), OY - pcbnew.ToMM(min(ys))
    body(x0, x1, y0, y1, h)
write_stl(os.path.join(out, "kicad_parts.stl"), parts)

# copper of both faces as flat boxes: tracks as rectangles, vias and pads by their outline's box
CU = 0.035
cu = []
def face(layer):
    return (PCB_Z + PCB_T, PCB_Z + PCB_T + CU) if layer == pcbnew.F_Cu else (PCB_Z - CU, PCB_Z)
for t_ in b.GetTracks():
    if t_.GetClass() == "PCB_VIA":
        p = t_.GetPosition(); r = pcbnew.ToMM(t_.GetWidth(pcbnew.F_Cu)) / 2
        x, y = pcbnew.ToMM(p.x) - OX, OY - pcbnew.ToMM(p.y)
        for L in (pcbnew.F_Cu, pcbnew.B_Cu):
            cu.extend(box(x - r, x + r, y - r, y + r, *face(L)))
        continue
    L = t_.GetLayer()
    if L not in (pcbnew.F_Cu, pcbnew.B_Cu): continue
    a_, c_ = t_.GetStart(), t_.GetEnd()
    ax, ay = pcbnew.ToMM(a_.x) - OX, OY - pcbnew.ToMM(a_.y); cx, cy = pcbnew.ToMM(c_.x) - OX, OY - pcbnew.ToMM(c_.y)
    w = pcbnew.ToMM(t_.GetWidth()) / 2; dx, dy = cx - ax, cy - ay; n = (dx * dx + dy * dy) ** 0.5
    if n < 1e-6: continue
    ux, uy = dx / n * w, dy / n * w          # extended by w at both ends, as the round caps
    px, py = -dy / n * w, dx / n * w
    z0, z1 = face(L)
    q = [(ax - ux + px, ay - uy + py), (ax - ux - px, ay - uy - py), (cx + ux - px, cy + uy - py), (cx + ux + px, cy + uy + py)]
    P = [(x, y, z) for z in (z0, z1) for x, y in q]
    for a1, a2, a3 in [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4), (1, 2, 6), (1, 6, 5), (2, 3, 7), (2, 7, 6), (3, 0, 4), (3, 4, 7)]:
        cu.append([P[a1], P[a2], P[a3]])
for f in b.GetFootprints():
    for p in f.Pads():
        for L in (pcbnew.F_Cu, pcbnew.B_Cu):
            if not p.IsOnLayer(L): continue
            r = p.GetBoundingBox()
            cu.extend(box(pcbnew.ToMM(r.GetLeft()) - OX, pcbnew.ToMM(r.GetRight()) - OX,
                          OY - pcbnew.ToMM(r.GetBottom()), OY - pcbnew.ToMM(r.GetTop()), *face(L)))
write_stl(os.path.join(out, "kicad_copper.stl"), cu)
print(len(parts) // 12, "bodies")
