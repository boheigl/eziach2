#!/usr/bin/env python3
"""Routes <board>/<board>.kicad_pcb (two layers; board from HALL_BOARD): every part sits on the underside
(B), which carries the tracks; the top (F) is a ground plane that tracks cross only
briefly (they cost F_COST times as much there). Grid maze router (A*, 45 degree) with
rip-up and reroute, from ../discant/main_pcb (git history). GND pads get a via to
the top plane first; afterwards both faces are filled with ground. KiCad's DRC
judges the result.
usage: route.py [BOARD] [first,nets,...]"""
import sys, heapq, math, time, json, os
import numpy as np, pcbnew
from scipy import ndimage
import design as d

BOARD = sys.argv[1] if len(sys.argv) > 1 else f"{d.BOARD}/{d.BOARD}.kicad_pcb"
OUTDIR = os.path.dirname(BOARD)
mm = pcbnew.FromMM; IU = 1e6
RES = 0.1
OX, OY = 150.0, 100.0
xs_ = [OX + x for x, y in d.OUTLINE]; ys_ = [OY - y for x, y in d.OUTLINE]
X_MIN, Y_MIN = min(xs_) - 0.5, min(ys_) - 0.5
NX = int((max(xs_) - min(xs_) + 1) / RES) + 1
NY = int((max(ys_) - min(ys_) + 1) / RES) + 1
CLR = 0.2
W_SIG, W_PWR = 0.2, 0.4
VIA_D, VIA_DR = 0.6, 0.3
LAYERS = [pcbnew.F_Cu, pcbnew.B_Cu]
LI = {pcbnew.F_Cu: 0, pcbnew.B_Cu: 1}
NL = 2
F_COST = 4.0                   # per cell on the top, the ground plane
POWER = d.POWER
VIA_COST = 20
WGT = 1.3
EDGE = 0.3
RIP_PEN = 25
RIP_BUDGET = 25 * 60
MAX_RIPS = 4

b = pcbnew.LoadBoard(BOARD)
netid = {}
def nid_of(name):
    return netid.setdefault(name, len(netid) + 1) if name else 0
def gx(x): return int(round((x - X_MIN) / RES))
def gy(y): return int(round((y - Y_MIN) / RES))
def wx(i): return X_MIN + i * RES
def wy(j): return Y_MIN + j * RES

R_SIG, R_PWR, R_VIA = CLR + W_SIG / 2, CLR + W_PWR / 2, CLR + VIA_D / 2
RADII = (R_SIG, R_PWR, R_VIA)
hard = {r: np.zeros((NL, NY, NX), np.int32) for r in RADII}     # pads, holes, edge
soft = {r: np.zeros((NL, NY, NX), np.int32) for r in RADII}     # tracks and vias
# drill to drill: KiCad's hole-to-hole rule (0.25 mm between the holes' edges) holds for
# vias of the same net too, so a via may not stand within HOLE_C of any other via's centre
HOLE_C = VIA_DR + 0.25 + 0.01
vcen = np.zeros((NY, NX), np.int32)      # via centres: net id
vblk = np.zeros((NY, NX), bool)          # cells closer than HOLE_C to some via centre

def stamp(o, layer, x0, y0, m, n):
    h, w = m.shape
    xs, ys = max(x0, 0), max(y0, 0); xe, ye = min(x0 + w, NX), min(y0 + h, NY)
    if xs >= xe or ys >= ye: return
    mm_ = m[ys - y0:ye - y0, xs - x0:xe - x0]
    s = o[layer, ys:ye, xs:xe]
    free = s == 0
    s[mm_ & free] = n
    s[mm_ & ~free & (s != n)] = -1

def stamp_rect(layers, cx, cy, w, h, ang, n):
    c, s = math.cos(ang), math.sin(ang)
    for r, o in hard.items():
        ex, ey = w / 2 + r, h / 2 + r
        hx = abs(ex * c) + abs(ey * s); hy = abs(ex * s) + abs(ey * c)
        i0, i1, j0, j1 = gx(cx - hx), gx(cx + hx) + 1, gy(cy - hy), gy(cy + hy) + 1
        X, Y = np.meshgrid(wx(np.arange(i0, i1)) - cx, wy(np.arange(j0, j1)) - cy)
        u = X * c + Y * s; v = -X * s + Y * c
        dx = np.maximum(np.abs(u) - w / 2, 0); dy = np.maximum(np.abs(v) - h / 2, 0)
        m = dx * dx + dy * dy <= r * r
        for L in layers: stamp(o, L, i0, j0, m, n)

terms, PADS = {}, []
for f in b.GetFootprints():
    for p in f.Pads():
        if p.GetAttribute() == pcbnew.PAD_ATTRIB_NPTH:
            pos = p.GetPosition(); dr = p.GetDrillSizeX() / IU + 0.2
            stamp_rect([0, 1], pos.x / IU, pos.y / IU, dr, dr, 0, -1); continue
        if not p.IsOnCopperLayer(): continue
        cu = [LI[l] for l in (pcbnew.F_Cu, pcbnew.B_Cu) if p.IsOnLayer(l)]
        if not cu: continue
        if p.GetAttribute() == pcbnew.PAD_ATTRIB_PTH: cu = [0, 1]
        pos = p.GetPosition(); x, y = pos.x / IU, pos.y / IU
        sz = p.GetSize(); w, h = sz.x / IU, sz.y / IU
        ang = -math.radians(p.GetOrientationDegrees())
        n = nid_of(p.GetNetname())
        stamp_rect(cu, x, y, w, h, ang, n if n else -1)
        if p.GetDrillSizeX() > 0:
            dr = max(p.GetDrillSizeX(), p.GetDrillSizeY()) / IU + 0.2
            stamp_rect([0, 1], x, y, dr, dr, 0, n if n else -1)
        if p.GetNetname():
            terms.setdefault(p.GetNetname(), []).append(dict(ref=f.GetReference(), num=p.GetNumber(), x=x, y=y, layers=cu))
name_of = {v: k for k, v in netid.items()}

pts = [(OX + x, OY - y) for x, y in d.OUTLINE]
I, J = np.meshgrid(np.arange(NX), np.arange(NY)); Xw, Yw = wx(I), wy(J)
ins = np.zeros((NY, NX), bool)
for k in range(len(pts)):
    (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
    c = (y1 > Yw) != (y2 > Yw)
    with np.errstate(divide="ignore", invalid="ignore"):
        ins ^= c & (Xw < x1 + (Yw - y1) * (x2 - x1) / (y2 - y1))
dist = np.full((NY, NX), 1e9)
for k in range(len(pts)):
    (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
    dx, dy = x2 - x1, y2 - y1; L2 = dx * dx + dy * dy
    t = np.clip(((Xw - x1) * dx + (Yw - y1) * dy) / L2, 0, 1)
    dist = np.minimum(dist, np.hypot(Xw - x1 - t * dx, Yw - y1 - t * dy))
for hx, hy in d.HOLES:
    dist = np.minimum(dist, np.hypot(Xw - OX - hx, Yw - OY + hy) - d.HOLE_D / 2)
for r, o in hard.items():
    o[:, ~ins | (dist < EDGE + (r - CLR))] = -1

# routes[net]: list of node paths [(L, j, i), ...] (a layer change at one cell is a via),
# plus vias standing alone (GND to the plane)
routes, gvias, stubs = {}, {}, {}
width_of = {}

DISCS = {}
def disc(r):
    if r not in DISCS:
        n = int(math.ceil(r / RES)); a = np.arange(-n, n + 1); X, Y = np.meshgrid(a, a)
        DISCS[r] = (X * X + Y * Y) * RES * RES <= r * r
    return DISCS[r]

def mark_via(n, j, i):
    vcen[j, i] = n
    m = disc(HOLE_C); k = m.shape[0] // 2
    j0, i0 = max(j - k, 0), max(i - k, 0); j1, i1 = min(j + k + 1, NY), min(i + k + 1, NX)
    vblk[j0:j1, i0:i1] |= m[j0 - (j - k):j1 - (j - k), i0 - (i - k):i1 - (i - k)]

def via_free(n, j, i):
    """no other via's drill too close: the cell is clear, or is this net's own via"""
    return not vblk[j, i] or vcen[j, i] == n

def rebuild_soft():
    """the tracks' and vias' clearance map from scratch; each net dilated only inside
    its own bounding box, which keeps a rip-up cheap"""
    for r in RADII: soft[r][:] = 0
    vcen[:] = 0; vblk[:] = False
    pad = int(math.ceil((VIA_D / 2 + R_VIA) / RES)) + 2
    for net in list(routes) + [n for n in gvias if n not in routes]:
        n = netid[net]; w = width_of.get(net, W_SIG)
        cells = [c for p in routes.get(net, []) for c in p]
        vias_ = [(a[1], a[2]) for p in routes.get(net, []) for a, c in zip(p, p[1:]) if a[1:] == c[1:] and a[0] != c[0]]
        vias_ += list(gvias.get(net, []))
        for j, i in vias_: mark_via(n, j, i)
        if not cells and not vias_: continue
        js = [c[1] for c in cells] + [v[0] for v in vias_]; is_ = [c[2] for c in cells] + [v[1] for v in vias_]
        j0, j1 = max(min(js) - pad, 0), min(max(js) + pad + 1, NY)
        i0, i1 = max(min(is_) - pad, 0), min(max(is_) + pad + 1, NX)
        cl = np.zeros((NL, j1 - j0, i1 - i0), bool); vi = np.zeros((j1 - j0, i1 - i0), bool)
        for L, j, i in cells: cl[L, j - j0, i - i0] = True
        for j, i in vias_: vi[j - j0, i - i0] = True
        for r in RADII:
            dv = ndimage.binary_dilation(vi, disc(VIA_D / 2 + r)) if vias_ else None
            for L in range(NL):
                m = ndimage.binary_dilation(cl[L], disc(w / 2 + r)) if cl[L].any() else np.zeros_like(vi)
                if dv is not None: m |= dv
                s = soft[r][L, j0:j1, i0:i1]
                free = s == 0
                s[m & free] = n; s[m & ~free & (s != n)] = -1

DIRS = [(1, 0, 1.0), (-1, 0, 1.0), (0, 1, 1.0), (0, -1, 1.0), (1, 1, 1.414), (1, -1, 1.414), (-1, 1, 1.414), (-1, -1, 1.414)]

def astar(n, sources, targets, tx, ty, width, rip=False, limit=700000):
    R = R_PWR if width > W_SIG else R_SIG
    ho, so = hard[R], soft[R]; hv, sv = hard[R_VIA], soft[R_VIA]
    best, prev, pq = {}, {}, []
    def h(i, j):
        dx, dy = abs(i - tx), abs(j - ty); return max(dx, dy) + 0.414 * min(dx, dy)
    for s in sources:
        best[s] = 0.0; heapq.heappush(pq, (WGT * h(s[2], s[1]), 0.0, s))
    n_exp = 0
    while pq:
        f_, g, u = heapq.heappop(pq)
        if g > best.get(u, 1e18): continue
        if u in targets:
            path = [u]
            while path[-1] in prev: path.append(prev[path[-1]])
            return path[::-1]
        n_exp += 1
        if n_exp > limit: return None
        L, j, i = u
        for di, dj, c in DIRS:
            i2, j2 = i + di, j + dj
            if not (0 <= i2 < NX and 0 <= j2 < NY): continue
            hv_ = ho[L, j2, i2]
            if hv_ != 0 and hv_ != n: continue
            sv_ = so[L, j2, i2]; cost = c * (F_COST if L == 0 else 1.0)
            if sv_ != 0 and sv_ != n:
                if not rip or sv_ == -1 or rips.get(sv_, 0) >= MAX_RIPS: continue
                cost += RIP_PEN
            w = (L, j2, i2); g2 = g + cost
            if g2 < best.get(w, 1e18):
                best[w] = g2; prev[w] = u; heapq.heappush(pq, (g2 + WGT * h(i2, j2), g2, w))
        ok, pen = via_free(n, j, i), 0
        if ok:
            # the vias this search has already put on the way here
            a, k = u, 0
            while a in prev and k < 14:
                p_ = prev[a]
                if p_[0] != a[0] and p_[1:] == a[1:] and p_[1:] != (j, i):
                    if (p_[1] - j) ** 2 + (p_[2] - i) ** 2 < (HOLE_C / RES) ** 2: ok = False
                    break
                a = p_; k += 1
        for l in range(NL):
            if not ok: break
            if hv[l, j, i] not in (0, n): ok = False; break
            s_ = sv[l, j, i]
            if s_ not in (0, n):
                if not rip or s_ == -1 or rips.get(s_, 0) >= MAX_RIPS: ok = False; break
                pen += RIP_PEN
        if ok:
            for L2 in range(NL):
                if L2 != L:
                    w = (L2, j, i); g2 = g + VIA_COST + pen
                    if g2 < best.get(w, 1e18):
                        best[w] = g2; prev[w] = u; heapq.heappush(pq, (g2 + WGT * h(i, j), g2, w))
    return None

def victims(n, path, width):
    R = R_PWR if width > W_SIG else R_SIG
    v = set()
    for a, c in zip(path, path[1:]):
        if a[1:] == c[1:]:
            for l in range(NL):
                s_ = soft[R_VIA][l, a[1], a[2]]
                if s_ > 0 and s_ != n: v.add(s_)
    for L, j, i in path:
        s_ = soft[R][L, j, i]
        if s_ > 0 and s_ != n: v.add(s_)
    return v

def stamp_path(n, path, width):
    for a, c in zip(path, path[1:]):
        if a[1:] == c[1:] and a[0] != c[0]: mark_via(n, a[1], a[2])
    for r in RADII:
        for L, j, i in path:
            m = disc(width / 2 + r); hh, ww = m.shape; stamp(soft[r], L, i - ww // 2, j - hh // 2, m, n)
        for a, c in zip(path, path[1:]):
            if a[1:] == c[1:]:
                m = disc(VIA_D / 2 + r); hh, ww = m.shape
                for l in range(NL): stamp(soft[r], l, a[2] - ww // 2, a[1] - hh // 2, m, n)

def term_cells(t):
    return {(L, gy(t["y"]), gx(t["x"])) for L in t["layers"]}

rips = {}
failed = []
def route_net(net, rip_ok=True):
    """returns the nets it tore up"""
    n = netid[net]
    width = W_PWR if net in POWER else W_SIG
    width_of[net] = width
    routes[net] = list(bus_paths.get(net, []))
    stubs[net] = []
    tree = set(c for p in routes[net] for c in p)
    rest = list(terms[net])
    if not tree:
        t0 = rest.pop(0); tree = term_cells(t0); stubs[net].append((t0, next(iter(tree))))
    torn = set()
    while rest:
        tl = list(tree)[:: max(1, len(tree) // 50)]
        rest.sort(key=lambda t: min(abs(gx(t["x"]) - c[2]) + abs(gy(t["y"]) - c[1]) for c in tl))
        t = rest.pop(0); tc = term_cells(t)
        if tc & tree: continue
        w_used = width
        path = astar(n, tree, tc, gx(t["x"]), gy(t["y"]), width)
        if path is None and width > W_SIG:
            w_used = W_SIG; path = astar(n, tree, tc, gx(t["x"]), gy(t["y"]), W_SIG)
        if path is None and rip_ok and time.time() - T_START < RIP_BUDGET:
            w_used = W_SIG
            p2 = astar(n, tree, tc, gx(t["x"]), gy(t["y"]), W_SIG, rip=True, limit=1200000)
            if p2 is not None:
                v = victims(n, p2, W_SIG)
                for m_ in v:
                    vn = name_of[m_]; rips[m_] = rips.get(m_, 0) + 1
                    routes.pop(vn, None); stubs.pop(vn, None); gvias.pop(vn, None); torn.add(vn)
                rebuild_soft()
                path = astar(n, tree, tc, gx(t["x"]), gy(t["y"]), W_SIG, limit=1200000)
        if path is None:
            failed.append((net, t["ref"], t["num"])); print("  FAILED", net, t["ref"], t["num"], flush=True); continue
        routes[net].append(path); stamp_path(n, path, w_used)
        if w_used < width: width_of[net] = W_SIG
        stubs[net].append((t, path[-1]))
        tree |= set(path)
    return torn

def route_gnd_pad(t):
    n = netid["GND"]; hv, sv = hard[R_VIA], soft[R_VIA]; ho, so = hard[R_SIG], soft[R_SIG]
    if 0 in t["layers"]: return True
    L = t["layers"][0]; i0, j0 = gx(t["x"]), gy(t["y"])
    seen = {(j0, i0): None}; q = [(j0, i0)]; hit = None
    for (j, i) in q:
        if via_free(n, j, i) and all(hv[l, j, i] in (0, n) and sv[l, j, i] in (0, n) for l in range(NL)): hit = (j, i); break
        for di, dj, c in DIRS[:4]:
            w = (j + dj, i + di)
            if w in seen or not (0 <= w[1] < NX and 0 <= w[0] < NY): continue
            if ho[L, w[0], w[1]] in (0, n) and so[L, w[0], w[1]] in (0, n): seen[w] = (j, i); q.append(w)
        if len(q) > 60000: break
    if hit is None: return False
    path = [hit]
    while seen[path[-1]] is not None: path.append(seen[path[-1]])
    nodes = [(L, j, i) for j, i in path[::-1]]
    routes.setdefault("GND", []).append(nodes); stamp_path(n, nodes, W_SIG)
    stubs.setdefault("GND", []).append((t, nodes[0]))
    gvias.setdefault("GND", set()).add(hit)
    stamp_path(n, [(1, hit[0], hit[1]), (0, hit[0], hit[1])], W_SIG)
    return True

t0 = time.time()
T_START = t0
bus_paths = {}

# GND fan-out before any signal: each GND pad gets its via to the plane while there is room.
# GND is never torn up (it is not routed again as a net), so mark it as ripped out.
rips[netid["GND"]] = MAX_RIPS
gnd_early = [t for t in terms["GND"] if not route_gnd_pad(t)]
print("GND fan-out:", len(terms["GND"]) - len(gnd_early), "of", len(terms["GND"]), flush=True)

pri = sys.argv[2].split(",") if len(sys.argv) > 2 and sys.argv[2] else []
first = sorted((k for k in terms if k.startswith("KEY")), key=lambda n: -len(terms[n]))
others = [n for n in terms if n != "GND" and not n.startswith("KEY")]
others.sort(key=lambda n: (n in POWER, len(terms[n])))
queue = list(first) + [n for n in pri if n in terms and n not in first and n != "GND"]
queue += [n for n in others if n not in queue]
done_ = 0
while queue:
    net = queue.pop(0)
    torn = route_net(net)
    for vn in torn:
        if vn not in queue: queue.append(vn)
    done_ += 1
    if torn: print(f"{net}: tore up {sorted(torn)}", flush=True)
    if done_ > 600: break
print("nets", round(time.time() - t0, 1), "s", flush=True)
# a net torn up and not routed again, or failed: one more try each without tearing
missing = [n for n in terms if n != "GND" and n not in routes]
for n in missing: route_net(n, rip_ok=False)
gnd_failed = [(t["ref"], t["num"]) for t in gnd_early if not route_gnd_pad(t)]
failed = [f for f in failed if True]
# what is still open: terminals not reached by their net's copper
def open_terms():
    out = []
    for net, T in terms.items():
        if net == "GND": continue
        cells = set(c for p in routes.get(net, []) for c in p)
        for t in T:
            if not (term_cells(t) & cells) and len(T) > 1: out.append((net, t["ref"], t["num"]))
    return out
still = open_terms() + [("GND",) + g for g in gnd_failed]
print("open:", still, flush=True)
json.dump(still, open(os.path.join(OUTDIR, "route_failed.json"), "w"))

# write the copper
def add_seg(net, L, a, c, w):
    t = pcbnew.PCB_TRACK(b); t.SetStart(pcbnew.VECTOR2I(mm(a[0]), mm(a[1]))); t.SetEnd(pcbnew.VECTOR2I(mm(c[0]), mm(c[1])))
    t.SetWidth(mm(w)); t.SetLayer(LAYERS[L]); t.SetNet(b.GetNetsByName()[net]); b.Add(t)
def add_via(net, p):
    v = pcbnew.PCB_VIA(b); v.SetPosition(pcbnew.VECTOR2I(mm(p[0]), mm(p[1]))); v.SetWidth(mm(VIA_D)); v.SetDrill(mm(VIA_DR))
    v.SetNet(b.GetNetsByName()[net]); v.SetViaType(pcbnew.VIATYPE_THROUGH); b.Add(v)
placed_vias = set()
for net, paths in routes.items():
    w = width_of.get(net, W_SIG)
    for p in paths:
        i = 0
        while i < len(p) - 1:
            a = p[i]
            if p[i + 1][0] != a[0]:
                k = i + 1
                while k + 1 < len(p) and p[k + 1][1:] == a[1:]: k += 1
                if (net, a[1], a[2]) not in placed_vias:
                    placed_vias.add((net, a[1], a[2])); add_via(net, (wx(a[2]), wy(a[1])))
                i = k; continue
            d0 = (p[i + 1][2] - a[2], p[i + 1][1] - a[1]); k = i + 1
            while k + 1 < len(p) and p[k + 1][0] == a[0] and (p[k + 1][2] - p[k][2], p[k + 1][1] - p[k][1]) == d0: k += 1
            e = p[k]; add_seg(net, a[0], (wx(a[2]), wy(a[1])), (wx(e[2]), wy(e[1])), w); i = k
    for t, node in stubs.get(net, []):
        x, y = wx(node[2]), wy(node[1])
        if abs(x - t["x"]) + abs(y - t["y"]) > 1e-6: add_seg(net, node[0], (t["x"], t["y"]), (x, y), W_SIG)
for net, vs in gvias.items():
    for (j, i) in vs:
        if (net, j, i) not in placed_vias:
            placed_vias.add((net, j, i)); add_via(net, (wx(i), wy(j)))

for lay in (pcbnew.F_Cu, pcbnew.B_Cu):
    z = pcbnew.ZONE(b); z.SetLayer(lay); z.SetNet(b.GetNetsByName()["GND"])
    ol = z.Outline(); ol.NewOutline()
    for x, y in pts: ol.Append(mm(x), mm(y))
    z.SetLocalClearance(mm(CLR)); z.SetMinThickness(mm(0.2)); z.SetPadConnection(pcbnew.ZONE_CONNECTION_THERMAL)
    z.SetThermalReliefGap(mm(0.25)); z.SetThermalReliefSpokeWidth(mm(0.3))
    b.Add(z)
pcbnew.ZONE_FILLER(b).Fill(b.Zones())
b.BuildConnectivity()
pcbnew.SaveBoard(BOARD, b)
print("done", round(time.time() - t0, 1), "open", len(still))
