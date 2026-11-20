#!/usr/bin/env python3
"""Writes contact_pcb/contact.kicad_pcb: the two small boards of the spring contacts
between bass and discant, as one panel of two in a frame, broken out after assembly
(milled gaps and tabs with mouse bites: JLCPCB cuts V-grooves only in panels of at least
70 x 70 mm; its economic assembly takes 10 x 10 and up, the panel is 17.2 x 26.8).

  pins (bass)    three PG2541-03-003P strips (3 spring pins each, 2.54 pitch, SMD,
                 C49451741), nine wire pads on the back, one wire per pin, as the main
                 board expects (../main_pcb/design.py, WIRES)
  pads (discant) nine round pads (ENIG), the same grid; on the back the 3.3 V pair, the
                 three GND and DET are tied, five wire pads (3V3, GND, SDA, SCL, INT)

Both boards are drawn in the gauges' frame (x across, z up, as ../bass/link.scad and
../discant/gauge_link.scad) and seen from their front, the mating face: the pin board
looks along +y, so its right is +x; the pad board looks along -y, so its right is -x.
A pin at (x, z) meets the pad at the same (x, z).
usage: gen_pcb.py [OUT]"""
import sys, os, pcbnew

mm = pcbnew.FromMM
OX, OY = 150.0, 100.0                         # board frame -> KiCad: x = OX + u, y = OY - v
def P(u, v): return pcbnew.VECTOR2I(mm(OX + u), mm(OY - v))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "contact.kicad_pcb")

# --- the grid, shared with the scad models ------------------------------------------
PX, PZ = 2.54, 3.0           # pins along a strip (x), strips apart (z): the strips are 2.5 wide
W, H, T = 10.0, 9.0, 1.6     # each board: x, z, thickness (x: the discant's outer holders are 5.8 off the middle)
PAD_D = 2.2                  # the strip's recommended pad, also the contact pads
BACK = (1.2, 1.4)            # the wire pads on the back: x, z (room for an AWG 30 lap joint)
VIA, VIA_DR = 0.45, 0.2
TW, TW_P = 0.2, 0.3          # tracks: signal, supply
CLR = 0.15
# the nets per grid point (column -1..1 along x, row -1..1 along z)
GRID = {(-1, 1): "3V3_A", (0, 1): "SDA", (1, 1): "SCL",
        (-1, 0): "GND_A", (0, 0): "GND_B", (1, 0): "GND_C",
        (-1, -1): "3V3_B", (0, -1): "INT", (1, -1): "DET"}
# each pad's via, in the gaps between pads (0.64 clear of the four around it) or beside
VIAS = {(-1, 1): (-3.81, 1.5), (0, 1): (-1.27, 1.5), (1, 1): (3.81, 1.5),
        (-1, 0): (-4.4, 0.0), (0, 0): (1.27, 1.5), (1, 0): (4.4, 0.0),
        (-1, -1): (-3.81, -1.5), (0, -1): (-1.27, -1.5), (1, -1): (3.81, -1.5)}
def grid_xz(c, r): return (c * PX, r * PZ)
def back_xz(c, r): return (c * PX, r * 2.65)   # the wire pads, inside the cavity behind (+/-3.6), 0.2 clear of the vias
# the pad board's nets: duplicates tied, DET to GND (switches the bass on)
PAD_NET = {"3V3_A": "3V3", "3V3_B": "3V3", "GND_A": "GND", "GND_B": "GND", "GND_C": "GND", "DET": "GND",
           "SDA": "SDA", "SCL": "SCL", "INT": "INT"}
WIRES_DISCANT = {"3V3": (-1, 1), "SDA": (0, 1), "SCL": (1, 1), "GND": (0, 0), "INT": (0, -1)}

# the panel: the boards 1 mm apart (GAP, milled), a frame round them (RAIL wide, GAP
# off), each board held by one tab on either side (x edges, TAB long, its middle TAB_Z
# from the board's middle towards the panel's end); mouse bites: BITE_N holes BITE_D on
# the tab's board side, touching the board's edge, across the whole tab.
# [2026-11-18, review/contact_pcb.md MAJOR 2] JLCPCB asks for tabs of 5 mm with mouse
# bites (was 2 mm): seven holes at 0.75 fill them; TAB_Z keeps the nearest hole 0.45 mm
# from the copper of the via at the middle row (x 4.4, z 0)
GAP, RAIL = 1.6, 2.0                 # 1.6 [2026-11-19, review MINOR: 1.0 was JLCPCB's least slot, 1.6-2 advised]
TAB, TAB_Z = 5.0, 1.875
BITE_D, BITE_P, BITE_N = 0.5, 0.75, 7
BOARDS = {"pins": dict(vc=+(H + GAP) / 2, mirror=+1, prefix="B_"),      # bass, upper half of the panel
          "pads": dict(vc=-(H + GAP) / 2, mirror=-1, prefix="D_")}      # discant, lower half

b = pcbnew.BOARD()
b.SetCopperLayerCount(2)
ds = b.GetDesignSettings()
ds.m_TrackMinWidth = mm(0.15); ds.m_ViasMinSize = mm(0.4); ds.m_MinThroughDrill = mm(0.2)
ds.m_CopperEdgeClearance = mm(0.3); ds.m_MinClearance = mm(CLR)
ds.m_HoleToHoleMin = mm(0.25)
nc = ds.m_NetSettings.GetDefaultNetclass()
nc.SetClearance(mm(CLR)); nc.SetTrackWidth(mm(TW)); nc.SetViaDiameter(mm(VIA)); nc.SetViaDrill(mm(VIA_DR))
ds.SetBoardThickness(mm(T))

nets = {}
def net(name):
    if name not in nets:
        n = pcbnew.NETINFO_ITEM(b, name); b.Add(n); nets[name] = n
    return nets[name]

def seg(layer, a, c, n, w=TW):
    t = pcbnew.PCB_TRACK(b); t.SetStart(P(*a)); t.SetEnd(P(*c)); t.SetLayer(layer); t.SetWidth(mm(w)); t.SetNet(n); b.Add(t)
def via(at, n):
    v = pcbnew.PCB_VIA(b); v.SetPosition(P(*at)); v.SetDrill(mm(VIA_DR)); v.SetWidth(mm(VIA)); v.SetNet(n); b.Add(v)
def line(layer, a, c, w=0.1):
    s = pcbnew.PCB_SHAPE(b); s.SetShape(pcbnew.SHAPE_T_SEGMENT); s.SetStart(P(*a)); s.SetEnd(P(*c)); s.SetLayer(layer); s.SetWidth(mm(w)); b.Add(s)
def rect(layer, u0, v0, u1, v1, w=0.1):
    for a, c in (((u0, v0), (u1, v0)), ((u1, v0), (u1, v1)), ((u1, v1), (u0, v1)), ((u0, v1), (u0, v0))): line(layer, a, c, w)
def text(layer, s, at, h=0.6, mirror=False):
    t = pcbnew.PCB_TEXT(b); t.SetText(s); t.SetPosition(P(*at)); t.SetLayer(layer)
    t.SetTextSize(pcbnew.VECTOR2I(mm(h), mm(h))); t.SetTextThickness(mm(h * 0.15)); t.SetMirrored(mirror); b.Add(t)

def footprint(ref, value, at, attrs=0):
    f = pcbnew.FOOTPRINT(b); f.SetReference(ref); f.SetValue(value); f.SetPosition(P(*at))
    f.SetAttributes(attrs); f.Reference().SetVisible(False); f.Value().SetVisible(False)
    f.Reference().SetLayer(pcbnew.F_Fab); f.Value().SetLayer(pcbnew.F_Fab)
    b.Add(f); return f
def smd_pad(f, num, at, size, shape, layer_front, paste, n):
    sx, sz = size if isinstance(size, tuple) else (size, size)
    p = pcbnew.PAD(f); p.SetNumber(num); p.SetAttribute(pcbnew.PAD_ATTRIB_SMD)
    p.SetShape(shape); p.SetSize(pcbnew.VECTOR2I(mm(sx), mm(sz)))
    ls = pcbnew.LSET()
    for l in ((pcbnew.F_Cu, pcbnew.F_Mask) if layer_front else (pcbnew.B_Cu, pcbnew.B_Mask)): ls.AddLayer(l)
    if paste: ls.AddLayer(pcbnew.F_Paste)
    p.SetLayerSet(ls); f.Add(p); p.SetPosition(P(*at)); p.SetNet(n); return p

NOPOS = pcbnew.FP_EXCLUDE_FROM_POS_FILES | pcbnew.FP_EXCLUDE_FROM_BOM
for name, bd in BOARDS.items():
    vc, m, pre = bd["vc"], bd["mirror"], bd["prefix"]
    uv = lambda x, z: (m * x, z + vc)
    netname = (lambda g: pre + g) if name == "pins" else (lambda g: pre + PAD_NET[g])
    # front: the pins' strips, or the contact pads
    if name == "pins":
        for r in (1, 0, -1):
            ref = f"J{2 - r}"
            f = footprint(ref, "PG2541-03-003P", uv(0, r * PZ), pcbnew.FP_SMD)
            f.SetFPIDAsString("contact_pcb:PG2541-03-003P")
            for i, c in enumerate((-1, 0, 1) if m > 0 else (1, 0, -1)):
                smd_pad(f, str(i + 1), uv(*grid_xz(c, r)), PAD_D, pcbnew.PAD_SHAPE_CIRCLE, True, True, net(netname(GRID[(c, r)])))
            x0, z0 = uv(0, r * PZ)
            rect(pcbnew.F_Fab, x0 - 3.8, z0 - 1.25, x0 + 3.8, z0 + 1.25)
            rect(pcbnew.F_CrtYd, x0 - 4.0, z0 - 1.4, x0 + 4.0, z0 + 1.4, 0.05)
    else:
        f = footprint("K1", "contact pads", uv(0, 0), NOPOS)
        for (c, r), g in GRID.items():
            smd_pad(f, f"{c + 2 + 3 * (1 - r)}", uv(*grid_xz(c, r)), PAD_D, pcbnew.PAD_SHAPE_CIRCLE, True, False, net(netname(g)))
    # each grid point: front track to its via, back track to its wire pad
    wp = footprint("W1" if name == "pins" else "W2", "wire pads", uv(0, 0), NOPOS)
    for (c, r), g in GRID.items():
        n = net(netname(g))
        wd = TW_P if g.startswith(("3V3", "GND")) else TW
        a, v_, w_ = uv(*grid_xz(c, r)), uv(*VIAS[(c, r)]), uv(*back_xz(c, r))
        if name == "pads" and (c, r) == (-1, 0):
            # tied to the middle GND pad on the front: its via would cut the 3.3 V pair's track
            seg(pcbnew.F_Cu, a, uv(*grid_xz(0, 0)), n, wd)
        else:
            seg(pcbnew.F_Cu, a, v_, n, wd); via(v_, n); seg(pcbnew.B_Cu, v_, w_, n, wd)
        smd_pad(wp, f"{c + 2 + 3 * (1 - r)}", w_, BACK, pcbnew.PAD_SHAPE_RECT, False, False, n)
        # its name on the back, below the pad, read from the back [2026-11-19, review MINOR 1:
        # unlabelled, the back's mirrored layout invited a crossed wire]
        lbl = g.split("_")[0] if name == "pins" else PAD_NET[g]
        if name == "pins" or (c, r) in WIRES_DISCANT.values() and WIRES_DISCANT.get(PAD_NET[g]) == (c, r):
            text(pcbnew.B_SilkS, lbl, (w_[0], w_[1] - BACK[1] / 2 - 0.42), 0.55, mirror=True)
    if name == "pads":
        g = net(pre + "GND")
        seg(pcbnew.B_Cu, uv(*back_xz(-1, 0)), uv(*back_xz(1, 0)), g, TW_P)       # the three GND
        seg(pcbnew.B_Cu, uv(*back_xz(1, -1)), uv(*back_xz(1, 0)), g, TW_P)       # DET to GND
        seg(pcbnew.B_Cu, uv(*VIAS[(-1, 1)]), uv(*VIAS[(-1, -1)]), net(pre + "3V3"), TW_P)   # the 3.3 V pair

# outline: the frame's outside, and the milled gaps as closed cut-outs: one round each
# board's outer end (tab to tab), one H between the boards (both boards' split edges and
# their sides up to the tabs)
def poly(pts):
    for a, c in zip(pts, pts[1:] + pts[:1]): line(pcbnew.Edge_Cuts, a, c, 0.05)
xb, xg = W / 2, W / 2 + GAP                     # board's side, gap's outside
zi, zo = GAP / 2, GAP / 2 + H                   # board's split edge, its outer end
zt0, zt1 = (H + GAP) / 2 + TAB_Z - TAB / 2, (H + GAP) / 2 + TAB_Z + TAB / 2   # the tab
PW, PH = 2 * (xg + RAIL), 2 * (zo + GAP + RAIL)
rect(pcbnew.Edge_Cuts, -PW / 2, -PH / 2, PW / 2, PH / 2, 0.05)
for sz in (1, -1):
    poly([(-xg, sz * zt1), (-xg, sz * (zo + GAP)), (xg, sz * (zo + GAP)), (xg, sz * zt1),
          (xb, sz * zt1), (xb, sz * zo), (-xb, sz * zo), (-xb, sz * zt1)])
poly([(-xg, zt0), (-xb, zt0), (-xb, zi), (xb, zi), (xb, zt0), (xg, zt0),
      (xg, -zt0), (xb, -zt0), (xb, -zi), (-xb, -zi), (-xb, -zt0), (-xg, -zt0)])
# mouse bites: non-plated holes in each tab, touching the board's edge
mb = footprint("MB", "mouse bites", (0, 0), NOPOS)
k = 0
for sz in (1, -1):
    for sx in (1, -1):
        for i in range(BITE_N):
            z = sz * ((zt0 + zt1) / 2 + (i - (BITE_N - 1) / 2) * BITE_P)
            p = pcbnew.PAD(mb); k += 1; p.SetNumber(""); p.SetAttribute(pcbnew.PAD_ATTRIB_NPTH)
            p.SetShape(pcbnew.PAD_SHAPE_CIRCLE); p.SetSize(pcbnew.VECTOR2I(mm(BITE_D), mm(BITE_D)))
            p.SetDrillSize(pcbnew.VECTOR2I(mm(BITE_D), mm(BITE_D)))
            ls = pcbnew.LSET(); ls.AddLayer(pcbnew.F_Mask); ls.AddLayer(pcbnew.B_Mask); p.SetLayerSet(ls)
            mb.Add(p); p.SetPosition(P(sx * (xb + BITE_D / 2), z))
text(pcbnew.F_SilkS, "PINS (BASS)", (0, zo + GAP + RAIL / 2), 0.8)
text(pcbnew.F_SilkS, "PADS (DISCANT)", (0, -(zo + GAP + RAIL / 2)), 0.8)

pcbnew.SaveBoard(OUT, b)
print(OUT, len(nets), "nets")
