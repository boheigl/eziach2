#!/usr/bin/env python3
"""Writes <dir>/viewer.html: the board read back from KiCad (outline, holes, parts,
pads, tracks, vias, open connections as air wires) into viewer_tmpl.html, for a
look in the browser. Board frame as design.py (X along the rows, Y up the slope).
usage: export_view.py BOARD.kicad_pcb [DRC.json]"""
import sys, os, json, math, pcbnew
import design as d

BOARD = sys.argv[1]
OX, OY = 150.0, 100.0
b = pcbnew.LoadBoard(BOARD)
def W(v): return [round(pcbnew.ToMM(v.x) - OX, 3), round(OY - pcbnew.ToMM(v.y), 3)]
LAY = {pcbnew.F_Cu: "F", pcbnew.B_Cu: "B"}

parts, pads = [], []
for f in b.GetFootprints():
    ref = f.GetReference()
    side = "B" if f.GetLayer() == pcbnew.B_Cu else "F"
    cy = f.GetCourtyard(pcbnew.B_CrtYd if side == "B" else pcbnew.F_CrtYd)
    poly = []
    if cy.OutlineCount():
        o = cy.Outline(0)
        poly = [W(o.CPoint(i)) for i in range(o.PointCount())]
    parts.append(dict(ref=ref, value=f.GetValue(), side=side, pos=W(f.GetPosition()),
                      rot=round(f.GetOrientationDegrees(), 1), body=poly))
    for p in f.Pads():
        if not p.IsOnCopperLayer(): continue
        sz = p.GetSize()
        shape = {pcbnew.PAD_SHAPE_CIRCLE: "c", pcbnew.PAD_SHAPE_OVAL: "o"}.get(p.GetShape(), "r")
        layers = [LAY[l] for l in (pcbnew.F_Cu, pcbnew.B_Cu) if p.IsOnLayer(l)]
        pads.append(dict(ref=ref, num=p.GetNumber(), net=p.GetNetname(), pos=W(p.GetPosition()),
                         w=round(pcbnew.ToMM(sz.x), 3), h=round(pcbnew.ToMM(sz.y), 3),
                         a=round(p.GetOrientationDegrees(), 1), shape=shape, layers=layers,
                         drill=round(pcbnew.ToMM(p.GetDrillSizeX()), 3)))
tracks, vias = [], []
for t in b.GetTracks():
    if t.GetClass() == "PCB_VIA":
        vias.append(dict(pos=W(t.GetPosition()), d=round(pcbnew.ToMM(t.GetWidth(pcbnew.F_Cu)), 3),
                         drill=round(pcbnew.ToMM(t.GetDrillValue()), 3), net=t.GetNetname()))
    else:
        tracks.append(dict(a=W(t.GetStart()), b=W(t.GetEnd()), w=round(pcbnew.ToMM(t.GetWidth()), 3),
                           layer=LAY.get(t.GetLayer(), "?"), net=t.GetNetname()))

# open connections: the unconnected pairs of KiCad's DRC report (its ratsnest)
import re
air = []
if len(sys.argv) > 2 and os.path.exists(sys.argv[2]):
    for u in json.load(open(sys.argv[2]))["unconnected_items"]:
        it = u["items"]
        if len(it) < 2: continue
        m = re.search(r"\[([^\]]*)\]", it[0]["description"])
        air.append(dict(a=[round(it[0]["pos"]["x"] - OX, 3), round(OY - it[0]["pos"]["y"], 3)],
                        b=[round(it[1]["pos"]["x"] - OX, 3), round(OY - it[1]["pos"]["y"], 3)],
                        net=m.group(1) if m else ""))

drc = None
if len(sys.argv) > 2 and os.path.exists(sys.argv[2]):
    j = json.load(open(sys.argv[2]))
    from collections import Counter
    drc = dict(unconnected=len(j["unconnected_items"]),
               violations=dict(Counter(v["type"] for v in j["violations"])))

keys = [dict(row=k, key=h, pos=[round(v, 3) for v in d.key_xy(k, h)], adc=d.GROUP_OF[(k, h)]) for k, h in d.KEYS]
data = dict(outline=[list(p) for p in d.OUTLINE], holes=[list(h) for h in d.HOLES], hole_d=d.HOLE_D,
            parts=parts, pads=pads, tracks=tracks, vias=vias, air=air, keys=keys, drc=drc,
            name=os.path.splitext(os.path.basename(BOARD))[0],
            channels=json.load(open(os.path.join(os.path.dirname(BOARD), "channels.json"))))
tmpl = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "viewer_tmpl.html")).read()
out = os.path.join(os.path.dirname(BOARD), "viewer.html")
if d.BOARD == "discant":
    lede = ("One board under all 46 discant keys, in the staircase's slope plane. A DRV5055 sensor under every key, "
            "six ADS7138 ADCs reading them, and the 5-wire bus through the bellows to the ESP32 in the bass. "
            "All parts sit on the underside, so the view starts from below.")
else:
    lede = ("One flat board under both rows of the 18 bass keys (the back row's tubes and pins are 10 mm longer). "
            "A DRV5055 sensor under every key, three ADS7138 ADCs reading them, and a 5-wire bus to the ESP32's "
            "second I2C port in the bass box. All parts sit on the underside, so the view starts from below.")
for k, v in (("__TITLE__", d.BOARD.capitalize() + " Hall Board"), ("__BOARD__", d.BOARD), ("__H1__", d.TITLE), ("__LEDE__", lede)):
    tmpl = tmpl.replace(k, v)
open(out, "w").write(tmpl.replace("/*DATA*/null", json.dumps(data, separators=(",", ":"))))
print(out, len(parts), "parts", len(pads), "pads", len(tracks), "tracks", len(vias), "vias", len(air), "air wires")
