#!/usr/bin/env python3
"""Writes main_pcb.kicad_pcb from design.py: footprints, nets, outline, screw holes, the
antenna's keepout, rules; reports pads off the board and parts that collide.
From ../hall_pcb/gen_pcb.py.
usage: gen_pcb.py [OUT]"""
import sys, os, json, uuid, pcbnew
import design as d

mm = pcbnew.FromMM
OX, OY = 100.0, 100.0            # board frame -> KiCad: x = OX + X, y = OY - Y
def P(x, y): return pcbnew.VECTOR2I(mm(float(OX + x)), mm(float(OY - y)))
def W(v): return (pcbnew.ToMM(v.x) - OX, OY - pcbnew.ToMM(v.y))
FPLIB = "/usr/share/kicad/footprints"
OUT = sys.argv[1] if len(sys.argv) > 1 else "main_pcb.kicad_pcb"

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
    f.SetReference(c["ref"]); f.SetValue(c["value"]); f.SetFPIDAsString(c["fp"])
    return f

def pad(f, num): return next(p for p in f.Pads() if p.GetNumber() == num)
def court(f):
    q = f.GetCourtyard(pcbnew.F_CrtYd).BBox()
    return (pcbnew.ToMM(q.GetLeft()) - OX, pcbnew.ToMM(q.GetRight()) - OX,
            OY - pcbnew.ToMM(q.GetBottom()), OY - pcbnew.ToMM(q.GetTop()))      # X0, X1, Y0, Y1

placed = {}
for c in d.C:
    f = load(c); b.Add(f)
    x, y, rot = c["pos"]
    if c["ref"] in ("J1", "D1"):
        # at the side wall: turned so that the mouth (lens) faces -X, then moved to its edge
        for rot in (0, 90, 180, 270):
            f.SetOrientationDegrees(rot); f.SetPosition(P(10, y))
            if c["ref"] == "J1":       # the pads behind the shell, away from the mouth
                ok = W(pad(f, "A6").GetPosition())[0] > 10.5
            else:                      # the lens: where the courtyard reaches further
                X0, X1, _, _ = court(f); ok = 10 - X0 > X1 - 10 + 0.2
            if ok: break
        if c["ref"] == "J1":
            # its body (the F.Fab outline) 2.25 beyond the edge: the mouth 0.2 inside the wall's
            # face (elec.scad usb_x1) [2026-11-20: by the courtyard before, which reaches 0.55
            # past the body, not 0.25, so the mouth stood 0.5 inside]
            X0 = min(pcbnew.ToMM(g.GetBoundingBox().GetLeft()) - OX for g in f.GraphicalItems() if g.GetLayer() == pcbnew.F_Fab)
            edge = -2.25
        else:
            X0 = court(f)[0]
            edge = -0.75                                   # D1: its lens (0.75 inside its courtyard) at the edge
        f.SetPosition(P(10 + edge - X0, y))
    else:
        f.SetOrientationDegrees(rot); f.SetPosition(P(x, y))
    for q in f.Pads():
        n = c["pins"].get(q.GetNumber())
        if n: q.SetNet(net(n))
    if c["ref"] == "U1":
        for z in list(f.Zones()): f.Remove(z)      # its keepout reaches beyond the board: ours below
    placed[c["ref"]] = f

# --- outline, screw holes, antenna keepout, rules ----------------------------------
o = d.OUTLINE
for i in range(len(o)):
    s = pcbnew.PCB_SHAPE(b); s.SetShape(pcbnew.SHAPE_T_SEGMENT)
    s.SetStart(P(*o[i])); s.SetEnd(P(*o[(i + 1) % len(o)])); s.SetLayer(pcbnew.Edge_Cuts); s.SetWidth(mm(0.1)); b.Add(s)
for x, y in d.HOLES:
    s = pcbnew.PCB_SHAPE(b); s.SetShape(pcbnew.SHAPE_T_CIRCLE)
    s.SetCenter(P(x, y)); s.SetEnd(P(x + d.HOLE_D / 2, y)); s.SetLayer(pcbnew.Edge_Cuts); s.SetWidth(mm(0.1)); b.Add(s)
    s = pcbnew.PCB_SHAPE(b); s.SetShape(pcbnew.SHAPE_T_CIRCLE)          # the screw head, drawn
    s.SetCenter(P(x, y)); s.SetEnd(P(x + d.HEAD_D / 2, y)); s.SetLayer(pcbnew.F_SilkS); s.SetWidth(mm(0.12)); b.Add(s)
X0, X1, Y0, Y1 = d.ANTENNA_KEEPOUT
z = pcbnew.ZONE(b); z.SetIsRuleArea(True)
z.SetDoNotAllowTracks(True); z.SetDoNotAllowVias(True); z.SetDoNotAllowCopperPour(True)
z.SetDoNotAllowPads(False); z.SetDoNotAllowFootprints(False)
ls = pcbnew.LSET(); [ls.AddLayer(l) for l in (pcbnew.F_Cu, pcbnew.In1_Cu, pcbnew.In2_Cu, pcbnew.B_Cu)]
z.SetLayerSet(ls); z.SetZoneName("antenna")
ol = z.Outline(); ol.NewOutline()
for px, py in ((X0, Y0), (X1, Y0), (X1, Y1), (X0, Y1)): ol.Append(mm(OX + px), mm(OY - py))
b.Add(z)

ds = b.GetDesignSettings()
ds.m_TrackMinWidth = mm(0.127); ds.m_ViasMinSize = mm(0.45); ds.m_MinThroughDrill = mm(0.2); ds.m_MinClearance = mm(0.127)
ds.m_CopperEdgeClearance = mm(0.25); ds.m_HoleClearance = mm(0.2)
ds.SetBoardThickness(mm(d.PCB_T))
nc = ds.m_NetSettings.GetDefaultNetclass(); nc.SetClearance(mm(0.127)); nc.SetTrackWidth(mm(0.127))
nc.SetViaDiameter(mm(0.45)); nc.SetViaDrill(mm(0.2))
for ref, f in placed.items():
    f.SetPath(pcbnew.KIID_PATH("/" + str(uuid.uuid5(uuid.NAMESPACE_DNS, "eziach-main-" + ref))))
b.BuildConnectivity()
pcbnew.SaveBoard(OUT, b)
pins = {}
for c in d.C:
    f = placed[c["ref"]]
    pins[c["ref"]] = {q.GetNumber(): c["pins"].get(q.GetNumber()) for q in f.Pads() if q.GetNumber()}
json.dump(pins, open(os.path.join(os.path.dirname(os.path.abspath(OUT)), "pins.json"), "w"), indent=1)

# --- report ----------------------------------------------------------------------
def inside(x, y): return 0 <= x <= d.W and 0 <= y <= d.H
off = sorted({ref for ref, f in placed.items() if ref != "J1"
              for p in f.Pads() if p.GetNumber() and not all(inside(*W(v)) for v in
                  (pcbnew.VECTOR2I(p.GetBoundingBox().GetLeft(), p.GetBoundingBox().GetTop()),
                   pcbnew.VECTOR2I(p.GetBoundingBox().GetRight(), p.GetBoundingBox().GetBottom())))})
box = {ref: court(f) for ref, f in placed.items() if f.GetCourtyard(pcbnew.F_CrtYd).OutlineCount()}
box["U1"] = (d.C[0]["pos"][0] - 9, d.C[0]["pos"][0] + 9, d.C[0]["pos"][1] - 12.75, d.C[0]["pos"][1] + 12.75)
def ovl(A, B, m=0.0):
    w = min(A[1], B[1]) - max(A[0], B[0]) + m; h = min(A[3], B[3]) - max(A[2], B[2]) + m
    return (round(w, 2), round(h, 2)) if w > 0.02 and h > 0.02 else None
ov = []
refs = sorted(box)
for i in range(len(refs)):
    for j in range(i):
        r = ovl(box[refs[i]], box[refs[j]])
        pair = {refs[i][:1], refs[j][:1]}
        if refs[i][0] == "P" and refs[j][0] == "P" or refs[i][:2] == "TP" and refs[j][:2] == "TP":
            continue                   # wire and test pads: their courtyards may touch, the copper keeps 0.35
        if r: ov.append((refs[i], refs[j]) + r)
def near(A, h):                   # the courtyard's nearest point to the hole's centre, against the head's radius
    px, py = min(max(h[0], A[0]), A[1]), min(max(h[1], A[2]), A[3])
    return (px - h[0]) ** 2 + (py - h[1]) ** 2 < (d.HEAD_D / 2) ** 2
heads = [(ref, h) for ref in refs for h in d.HOLES if near(box[ref], h)]
ant = [ref for ref in refs if ref != "U1" and ovl(box[ref], d.ANTENNA_KEEPOUT)]
print(f"{len(placed)} parts; pads off the board: {off}")
print(f"courtyard overlaps: {ov}")
jack = [ref for ref in refs if ovl(box[ref], d.JACK_ZONE)]
print(f"under screw heads: {heads}; in the antenna's keepout: {ant}")
print(f"under the earphone jack (keep low): {jack}")
for ref in ("J1", "D1"):
    print(ref, "courtyard X %.2f .. %.2f, Y %.2f .. %.2f" % box[ref], "rot", placed[ref].GetOrientationDegrees())
