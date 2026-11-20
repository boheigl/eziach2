#!/usr/bin/env python3
"""Routes <board>/<board>.kicad_pcb (two layers; board from HALL_BOARD): every part sits on the underside
(B), which carries the tracks; the top (F) is a ground plane that tracks cross only
briefly (they cost F_COST times as much there), except the bus (design.BUS) in its lanes
(design.BUS_LANES), where the top is its main road. Grid maze router (A*, 45 degree) with
rip-up and reroute, from ../discant/main_pcb (git history). GND pads get a via to
the top plane first; afterwards both faces are filled with ground. KiCad's DRC
judges the result.
usage: route.py [BOARD] [first,nets,...]
       ROUTE_COMPLETE=NET:REF:PAD route.py BOARD   (a routed board: join that pad, see below;
                                                    GND:REF:PAD joins a ground pad cut off)"""
import sys, heapq, math, time, json, os, collections
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
TIME_LIMIT = 40 * 60          # then only quick searches, so the board is written before build.sh's timeout
QUICK = 150000
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

def rect_mask(cx, cy, w, h, ang, r):
    """the cells within r of a w x h rectangle turned by ang: (i0, j0, mask)"""
    c, s = math.cos(ang), math.sin(ang)
    ex, ey = w / 2 + r, h / 2 + r
    hx = abs(ex * c) + abs(ey * s); hy = abs(ex * s) + abs(ey * c)
    i0, i1, j0, j1 = gx(cx - hx), gx(cx + hx) + 1, gy(cy - hy), gy(cy + hy) + 1
    X, Y = np.meshgrid(wx(np.arange(i0, i1)) - cx, wy(np.arange(j0, j1)) - cy)
    u = X * c + Y * s; v = -X * s + Y * c
    dx = np.maximum(np.abs(u) - w / 2, 0); dy = np.maximum(np.abs(v) - h / 2, 0)
    return i0, j0, dx * dx + dy * dy <= r * r

def stamp_rect(layers, cx, cy, w, h, ang, n):
    for r, o in hard.items():
        i0, j0, m = rect_mask(cx, cy, w, h, ang, r)
        for L in layers: stamp(o, L, i0, j0, m, n)

# No via hole in or at an SMD pad, its own net's neither: solder would run down it
# (review/hall_pcb.md). The vias are tented (mask over both faces) and the pads' mask
# openings are their copper, so a via's drill keeps HOLE_GAP from the pad's copper (the
# fab's mask expansion and a mask web); its ring may touch the pad, or a short neck
# joins them. Exposed thermal pads are the exception: there vias are wanted (GND, at
# least 1.5 mm both ways; test points and wire pads excluded).
HOLE_GAP = 0.15
novia = np.zeros((NY, NX), bool)
def is_thermal(f, p, w, h):
    return p.GetNetname() == "GND" and min(w, h) >= 1.5 and "TestPoint" not in f.GetFPID().GetLibItemName().wx_str()
def mark_novia(cx, cy, w, h, ang):
    i0, j0, m = rect_mask(cx, cy, w, h, ang, VIA_DR / 2 + HOLE_GAP)
    hh, ww = m.shape
    xs, ys = max(i0, 0), max(j0, 0); xe, ye = min(i0 + ww, NX), min(j0 + hh, NY)
    if xs < xe and ys < ye: novia[ys:ye, xs:xe] |= m[ys - j0:ye - j0, xs - i0:xe - i0]

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
        if p.GetAttribute() == pcbnew.PAD_ATTRIB_SMD and not is_thermal(f, p, w, h): mark_novia(x, y, w, h, ang)
        if p.GetDrillSizeX() > 0:
            dr = max(p.GetDrillSizeX(), p.GetDrillSizeY()) / IU + 0.2
            stamp_rect([0, 1], x, y, dr, dr, 0, n if n else -1)
        if p.GetNetname():
            terms.setdefault(p.GetNetname(), []).append(dict(ref=f.GetReference(), num=p.GetNumber(), x=x, y=y, layers=cu, w=w, h=h))
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
# the bus's lanes on the top
lane = np.zeros((NY, NX), bool)
for x0, x1, y0, y1 in d.BUS_LANES:
    lane |= (Xw >= OX + x0) & (Xw <= OX + x1) & (Yw >= OY - y1) & (Yw <= OY - y0)
BUS_IDS = {netid[n] for n in d.BUS if n in netid}
BUS_BOT = 1.6                  # the bus on the underside, per cell: the lanes are its way

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
    for net in list(routes) + [n for n in set(gvias) | set(bus_paths) if n not in routes]:
        n = netid[net]; w = width_of.get(net, W_SIG)
        paths = routes.get(net, bus_paths.get(net, []))      # a torn-up net keeps its fan-outs
        cells = [c for p in paths for c in p]
        vias_ = [(a[1], a[2]) for p in paths for a, c in zip(p, p[1:]) if a[1:] == c[1:] and a[0] != c[0]]
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
    bus = n in BUS_IDS
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
            sv_ = so[L, j2, i2]
            if L == 0: cost = c * (1.0 if bus and lane[j2, i2] else F_COST)
            else: cost = c * (BUS_BOT if bus else 1.0)
            if sv_ != 0 and sv_ != n:
                if not rip or rips.get(sv_, 0) >= MAX_RIPS: continue
                cost += RIP_PEN * (2 if sv_ == -1 else 1)
            w = (L, j2, i2); g2 = g + cost
            if g2 < best.get(w, 1e18):
                best[w] = g2; prev[w] = u; heapq.heappush(pq, (g2 + WGT * h(i2, j2), g2, w))
        ok, pen = via_free(n, j, i) and not novia[j, i], 0
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
                if not rip or rips.get(s_, 0) >= MAX_RIPS: ok = False; break
                pen += RIP_PEN * (2 if s_ == -1 else 1)
        if ok:
            for L2 in range(NL):
                if L2 != L:
                    w = (L2, j, i); g2 = g + VIA_COST + pen
                    if g2 < best.get(w, 1e18):
                        best[w] = g2; prev[w] = u; heapq.heappush(pq, (g2 + WGT * h(i, j), g2, w))
    return None

def victims(n, path, width):
    """the nets whose clearance the path enters; a cell in two nets' clearance (-1)
    gives every net with copper near it"""
    R = R_PWR if width > W_SIG else R_SIG
    v, shared = set(), []
    for a, c in zip(path, path[1:]):
        if a[1:] == c[1:]:
            for l in range(NL):
                s_ = soft[R_VIA][l, a[1], a[2]]
                if s_ > 0 and s_ != n: v.add(s_)
                elif s_ == -1: shared.append((a[1], a[2]))
    for L, j, i in path:
        s_ = soft[R][L, j, i]
        if s_ > 0 and s_ != n: v.add(s_)
        elif s_ == -1: shared.append((j, i))
    if shared:
        k = int(math.ceil((VIA_D / 2 + W_PWR / 2 + R_VIA) / RES)) + 1
        near = {}
        for net, ps in routes.items():
            m_ = netid[net]
            if m_ == n or rips.get(m_, 0) >= MAX_RIPS: continue
            for p in ps:
                for c in p: near.setdefault(c[1:], set()).add(m_)
        for j, i in set(shared):
            for jj in range(j - k, j + k + 1):
                for ii in range(i - k, i + k + 1):
                    v |= near.get((jj, ii), set())
    return {m_ for m_ in v if rips.get(m_, 0) < MAX_RIPS}

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
def route_net(net, rip_ok=True, rip_until=None):
    """returns the nets it tore up"""
    n = netid[net]
    width = W_PWR if net in POWER else W_SIG
    width_of[net] = width
    routes[net] = list(bus_paths.get(net, []))
    stubs[net] = []
    # a pin with a fan-out is reached at its pad or anywhere on its fan-out; the tree
    # starts from the first pin alone, so every pin's piece gets joined
    tcells = lambda t: term_cells(t) | set(fan_of.get((net, t["ref"], t["num"]), ()))
    rest = list(terms[net])
    t0 = rest.pop(0); tree = tcells(t0); stubs[net].append((t0, next(iter(term_cells(t0)))))
    torn = set()
    while rest:
        tl = list(tree)[:: max(1, len(tree) // 50)]
        rest.sort(key=lambda t: min(abs(gx(t["x"]) - c[2]) + abs(gy(t["y"]) - c[1]) for c in tl))
        t = rest.pop(0); tc = tcells(t)
        if tc & tree: continue
        w_used = width
        lim = QUICK if time.time() - T_START > TIME_LIMIT else 700000
        path = astar(n, tree, tc, gx(t["x"]), gy(t["y"]), width, limit=lim)
        if path is None and width > W_SIG:
            w_used = W_SIG; path = astar(n, tree, tc, gx(t["x"]), gy(t["y"]), W_SIG, limit=lim)
        if path is None and rip_ok and time.time() - T_START < (rip_until or RIP_BUDGET):
            w_used = W_SIG
            # up to three rounds: a shared cell (-1) may hide a net that only shows once
            # its neighbour is gone
            # searched backwards, from the terminal to the tree: a terminal shut in costs
            # its rip penalties at the start, instead of the search flooding the board
            # from the tree with everything cheaper than the way into the pocket
            ti, tj = gx(t["x"]), gy(t["y"])
            near_ = min(tree, key=lambda c: (c[2] - ti) ** 2 + (c[1] - tj) ** 2)
            for _ in range(3):
                p2 = astar(n, tc, tree, near_[2], near_[1], W_SIG, rip=True, limit=500000)
                if p2 is None: break
                p2 = p2[::-1]
                v = victims(n, p2, W_SIG)
                for m_ in v:
                    vn = name_of[m_]; rips[m_] = rips.get(m_, 0) + 1
                    routes.pop(vn, None); stubs.pop(vn, None); gvias.pop(vn, None); torn.add(vn)
                rebuild_soft()
                path = astar(n, tree, tc, gx(t["x"]), gy(t["y"]), W_SIG, limit=700000)
                if path is not None or not v: break
        if path is None:
            failed.append((net, t["ref"], t["num"])); print("  FAILED", net, t["ref"], t["num"], flush=True); continue
        routes[net].append(path); stamp_path(n, path, w_used)
        if w_used < width: width_of[net] = W_SIG
        if path[-1] in term_cells(t): stubs[net].append((t, path[-1]))    # else it ends on the pin's fan-out
        tree |= set(path) | tc
    return torn

def route_gnd_pad(t):
    n = netid["GND"]; hv, sv = hard[R_VIA], soft[R_VIA]; ho, so = hard[R_SIG], soft[R_SIG]
    if 0 in t["layers"]: return True
    L = t["layers"][0]; i0, j0 = gx(t["x"]), gy(t["y"])
    seen = {(j0, i0): None}; q = [(j0, i0)]; hit = None
    for (j, i) in q:
        if via_free(n, j, i) and not novia[j, i] and all(hv[l, j, i] in (0, n) and sv[l, j, i] in (0, n) for l in range(NL)): hit = (j, i); break
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
COMPLETE = os.environ.get("ROUTE_COMPLETE")
gnd_early = [] if COMPLETE else [t for t in terms["GND"] if not route_gnd_pad(t)]
print("GND fan-out:", len(terms["GND"]) - len(gnd_early), "of", len(terms["GND"]), flush=True)

# The ADCs' pins fan out next, before any net: a short track from each signal pin to a via
# just outside the pin row. No via may stand in a pad (novia), so without these the pins
# end up enclosed by +3V3 and the bus round the chip, and the key lines, routed last, find
# no way out. The fan-outs are part of their nets from the start (bus_paths) and stay
# when a net is torn up. DECAP (one capacitor beside the pin) and GND (done above) need none.
# The vias stand on a ring FAN_R round the chip's middle, not at the pins' toes: there the
# ring is long enough for them all, and the tracks spread out on their way to it.
ADC_REFS = {f.GetReference() for f in b.GetFootprints() if f.GetValue().startswith("ADS7128")}
ADC_AT = {f.GetReference(): (f.GetPosition().x / IU, f.GetPosition().y / IU) for f in b.GetFootprints() if f.GetReference() in ADC_REFS}
FAN_R = float(os.environ.get("ROUTE_FAN_R", 2.5))
fan_ids, fan_of = set(), {}
def fan_out(net, t, fan_r=FAN_R):
    n = netid[net]; hv, sv = hard[R_VIA], soft[R_VIA]; ho, so = hard[R_SIG], soft[R_SIG]
    L = t["layers"][0]; i0, j0 = gx(t["x"]), gy(t["y"]); cx, cy = ADC_AT[t["ref"]]
    seen = {(j0, i0): None}; q = collections.deque([(j0, i0)]); hit = None
    while q:
        j, i = q.popleft()
        if math.hypot(wx(i) - cx, wy(j) - cy) >= fan_r and via_free(n, j, i) and not novia[j, i] \
                and all(hv[l, j, i] in (0, n) and sv[l, j, i] in (0, n) for l in range(NL)):
            hit = (j, i); break
        for di, dj, c in DIRS:
            w = (j + dj, i + di)
            if w in seen or not (0 <= w[1] < NX and 0 <= w[0] < NY): continue
            if ho[L, w[0], w[1]] in (0, n) and so[L, w[0], w[1]] in (0, n): seen[w] = (j, i); q.append(w)
        if len(seen) > 20000: break
    if hit is None: return False
    path = [hit]
    while seen[path[-1]] is not None: path.append(seen[path[-1]])
    nodes = [(L, j, i) for j, i in path[::-1]] + [(1 - L, hit[0], hit[1])]
    bus_paths.setdefault(net, []).append(nodes); fan_ids.add(id(nodes)); fan_of[(net, t["ref"], t["num"])] = nodes
    stamp_path(n, nodes, W_SIG)
    return True
fans = [] if COMPLETE else [(net, t) for net, T in terms.items() if net != "GND" and not net.startswith("DECAP")
        for t in T if t["ref"] in ADC_REFS]
# the middle pins of each side first: the corner pins can still turn aside
fans.sort(key=lambda f: math.hypot(f[1]["x"] - ADC_AT[f[1]["ref"]][0], f[1]["y"] - ADC_AT[f[1]["ref"]][1]))
left = [(net, t) for net, t in fans if not fan_out(net, t)]
# a pin left over: its ADC's fan-outs are done again, that pin first
for net_l, t_l in list(left):
    ref = t_l["ref"]
    mine = [(net, t) for net, t in fans if t["ref"] == ref]
    for net, t in mine:
        nodes = fan_of.pop((net, t["ref"], t["num"]), None)
        if nodes is not None:
            bus_paths[net] = [p for p in bus_paths[net] if p is not nodes]; fan_ids.discard(id(nodes))
    rebuild_soft()
    order = [f for f in mine if f in left] + [f for f in mine if f not in left]
    redo = [(net, t) for net, t in order if not fan_out(net, t)]
    left = [f for f in left if f[1]["ref"] != ref] + redo
for r_ in (2.0, 3.0, 3.5):                   # a last chance for the few left, nearer or farther
    left = [(net, t) for net, t in left if not fan_out(net, t, r_)]
fan_failed = [(net, t["ref"], t["num"]) for net, t in left]
print("ADC fan-out:", len(fans) - len(fan_failed), "of", len(fans), "failed:", fan_failed, flush=True)

pri = sys.argv[2].split(",") if len(sys.argv) > 2 and sys.argv[2] else []
# order: the short nets local to each ADC (DECAP, ADDR) first, then the given nets (the bus
# and whatever failed last try), then power, the key lines last: routed earlier, the key
# lines fill the ADCs' surroundings and leave no way in for the bus and +3V3
keys = sorted((k for k in terms if k.startswith("KEY")), key=lambda n: -len(terms[n]))
others = [n for n in terms if n != "GND" and not n.startswith("KEY") and n not in POWER]
local = sorted((n for n in others if n not in pri), key=lambda n: len(terms[n]))
queue = [n for n in local if len(terms[n]) <= 3]
queue += [n for n in pri if n in terms and n != "GND" and n not in queue]
queue += [n for n in sorted(POWER) if n in terms and n not in queue]
queue += [n for n in local + keys if n not in queue]
# Completion [2026-11-19]: on a routed board one pad left unjoined (a run's best ends
# with one open connection more often than with none). The board's copper goes into the
# maps as paths. The pad's piece of its net (its fan-out, say) is joined to the rest; where
# no way is free, only the paths of other nets in the way are taken out, and those nets
# are joined up again the same way (their other copper, fan-outs included, stays). The
# nets that changed are written anew; the ground fill is redone.
changed, pw_c = set(), {}
if COMPLETE:
    queue = []
    c_net, c_ref, c_num = COMPLETE.split(":")
    def raster(L, a, c):
        i0, j0, i1, j1 = gx(a[0]), gy(a[1]), gx(c[0]), gy(c[1])
        k_ = max(abs(i1 - i0), abs(j1 - j0), 1)
        return [(L, j0 + round((j1 - j0) * k / k_), i0 + round((i1 - i0) * k / k_)) for k in range(k_ + 1)]
    old_items = {}
    for t in list(b.GetTracks()):
        net = t.GetNetname()
        if net not in netid: continue
        old_items.setdefault(net, []).append(t)
        if t.GetClass() == "PCB_VIA":
            p = t.GetPosition(); path = [(0, gy(p.y / IU), gx(p.x / IU)), (1, gy(p.y / IU), gx(p.x / IU))]
        elif t.GetLayer() in LI:
            path = raster(LI[t.GetLayer()], (t.GetStart().x / IU, t.GetStart().y / IU), (t.GetEnd().x / IU, t.GetEnd().y / IU))
            pw_c[id(path)] = W_PWR if t.GetWidth() / IU > W_SIG + 0.01 else W_SIG
            if pw_c[id(path)] > W_SIG: width_of[net] = W_PWR
        else: continue
        routes.setdefault(net, []).append(path)
    rebuild_soft()
    for k_ in list(rips):
        if k_ != netid["GND"]: rips[k_] = 0
    def pieces(net):
        """the net's pieces that hold a terminal: cells joined by adjacency, vias and pads"""
        cells = {c for p in routes.get(net, []) for c in p}
        vias_at = {a[1:] for p in routes.get(net, []) for a, c in zip(p, p[1:]) if a[1:] == c[1:] and a[0] != c[0]}
        for t in terms[net]: cells |= term_cells(t)
        par = {c: c for c in cells}
        def find(c):
            while par[c] != c: par[c] = par[par[c]]; c = par[c]
            return c
        for (L, j, i) in cells:
            for dj in (-1, 0, 1):
                for di in (-1, 0, 1):
                    if (L, j + dj, i + di) in cells: par[find((L, j, i))] = find((L, j + dj, i + di))
            if (j, i) in vias_at:          # the faces meet at vias only
                for L2 in range(NL):
                    if (L2, j, i) in cells: par[find((L, j, i))] = find((L2, j, i))
        roots = set()
        for t in terms[net]:
            rw, rh = int(t["w"] / 2 / RES) + 1, int(t["h"] / 2 / RES) + 1
            r_ = max(rw, rh)
            inpad = [(L, j, i) for L in t["layers"] for j in range(gy(t["y"]) - r_, gy(t["y"]) + r_ + 1)
                     for i in range(gx(t["x"]) - r_, gx(t["x"]) + r_ + 1) if (L, j, i) in cells
                     and abs(wx(i) - t["x"]) <= t["w"] / 2 + RES and abs(wy(j) - t["y"]) <= t["h"] / 2 + RES]
            ins = inpad or list(term_cells(t))
            for c in ins[1:]: par[find(c)] = find(ins[0])
            roots.add(find(ins[0]))
        groups = {}
        for c in cells: groups.setdefault(find(c), set()).add(c)
        held = {find(r) for r in roots}
        pieces.loose = set().union(*[g for r, g in groups.items() if r not in held]) if len(groups) > len(held) else set()
        return [groups[r] for r in held]
    K_NEAR = int(math.ceil((VIA_D + W_PWR / 2 + CLR) / RES)) + 1
    def take_out(n, p2):
        """the other nets' paths near p2 come out; returns those nets"""
        near = {}
        for a, c in zip(p2, p2[1:] + p2[-1:]):
            via = a[1:] == c[1:] and a[0] != c[0]
            for dj in range(-K_NEAR, K_NEAR + 1):
                for di in range(-K_NEAR, K_NEAR + 1):
                    for L in (range(NL) if via else (a[0],)): near[(L, a[1] + dj, a[2] + di)] = True
        hit = set()
        for net, ps in list(routes.items()):
            if net == "GND" or netid[net] == n: continue
            keep = []
            for p in ps:
                vp = any(x[1:] == y[1:] for x, y in zip(p, p[1:]))
                if any((near.get(c) or (vp and any(near.get((L, c[1], c[2])) for L in range(NL)))) for c in p): hit.add(net)
                else: keep.append(p)
            routes[net] = keep
        return hit
    def join_net(net, until):
        n = netid[net]
        for _ in range(12):
            ps = pieces(net)
            if len(ps) <= 1: break
            ps.sort(key=len); isl = ps[0]; rest = set().union(*ps[1:])
            c0 = next(iter(isl)); tx, ty = c0[2], c0[1]
            path = astar(n, rest, isl, tx, ty, W_SIG, limit=2000000)
            k = 0
            while path is None and k < 4 and time.time() - T_START < until:
                near_ = min(rest, key=lambda c: (c[2] - tx) ** 2 + (c[1] - ty) ** 2)
                p2 = astar(n, isl, rest, near_[2], near_[1], W_SIG, rip=True, limit=2000000)
                if p2 is None: break
                hit = take_out(n, p2)
                for h_ in hit:
                    changed.add(h_)
                    if h_ not in pending: pending.append(h_)
                rebuild_soft()
                path = astar(n, rest, isl, tx, ty, W_SIG, limit=2000000)
                k += 1
            if path is None: return False
            routes[net].append(path); pw_c[id(path)] = W_SIG; stamp_path(n, path, W_SIG); changed.add(net)
        ok_ = len(pieces(net)) <= 1
        # copper left without a pad (a piece cut off by a path taken out) goes
        loose = pieces.loose
        if loose:
            routes[net] = [p for p in routes[net] if not all(c in loose for c in p)]
            changed.add(net); rebuild_soft()
        return ok_
    def join_gnd(ref, num):
        """[2026-11-20] GND:REF:PAD: a ground pad whose fill pieces are cut off from the main
        ground (enclosed by other nets' tracks on both faces, so no stitching via fits) gets
        a track from the pad to the largest ground piece of either face, within 12 mm;
        paths in the way come out as in join_net. Returns the nets taken out."""
        n = netid["GND"]
        t = next(t for t in terms["GND"] if t["ref"] == ref and t["num"] == num)
        zs = {z.GetLayer(): z for z in b.Zones() if z.GetNetname() == "GND"}
        ho, so = hard[R_SIG], soft[R_SIG]
        tg, R_ = set(), int(12 / RES)
        for L in LAYERS:
            p = zs[L].GetFilledPolysList(L)
            k = max(range(p.OutlineCount()), key=lambda k: abs(p.Outline(k).Area()))
            o, l = p.Outline(k), LI[L]
            for j in range(max(gy(t["y"]) - R_, 0), min(gy(t["y"]) + R_, NY)):
                for i in range(max(gx(t["x"]) - R_, 0), min(gx(t["x"]) + R_, NX)):
                    if ho[l, j, i] not in (0, n) or so[l, j, i] not in (0, n): continue
                    P = pcbnew.VECTOR2I(mm(wx(i)), mm(wy(j)))
                    if o.PointInside(P) and not any(p.Hole(k, h).PointInside(P) for h in range(p.HoleCount(k))):
                        tg.add((l, j, i))
        src = set(term_cells(t)); tx, ty = gx(t["x"]), gy(t["y"])
        print("completion: GND", ref, num, "targets", len(tg), flush=True)
        hit_all = []
        path = astar(n, tg, src, tx, ty, W_SIG, limit=2000000)
        k = 0
        while path is None and k < 4:
            p2 = astar(n, tg, src, tx, ty, W_SIG, rip=True, limit=2000000)
            if p2 is None: break
            for h_ in take_out(n, p2):
                changed.add(h_)
                if h_ not in hit_all: hit_all.append(h_)
            rebuild_soft()
            path = astar(n, tg, src, tx, ty, W_SIG, limit=2000000)
            k += 1
        if path is None:
            print("completion: GND", ref, num, "NOT joined", flush=True); return hit_all
        routes.setdefault("GND", []).append(path); pw_c[id(path)] = W_SIG; stamp_path(n, path, W_SIG); changed.add("GND")
        print("completion: GND", ref, num, "joined, path", len(path), "cells, taken out", hit_all, flush=True)
        return hit_all
    pending = [c_net]
    if c_net == "GND":
        pending = join_gnd(c_ref, c_num)
    while pending and time.time() - T_START < 40 * 60:
        net = pending.pop(0)
        ok_ = join_net(net, 40 * 60)
        print("completion:", net, "joined" if ok_ else "NOT joined", "| pending", pending, flush=True)
done_ = 0
if os.environ.get("ROUTE_FANOUT_ONLY"):      # to look at the fan-outs alone: write them and stop
    queue = []; routes.update({k: list(v) for k, v in bus_paths.items()})
while queue:
    net = queue.pop(0)
    torn = route_net(net)
    for vn in torn:
        if vn not in queue: queue.append(vn)
    done_ += 1
    if torn: print(f"{net}: tore up {sorted(torn)}", flush=True)
    if done_ > 600: break
print("nets", round(time.time() - t0, 1), "s", flush=True)
# what is still open: terminals not reached by their net's copper
def open_terms():
    out = []
    for net, T in terms.items():
        if net == "GND": continue
        # a pin's own fan-out does not reach it: a path to the pad or to the fan-out does
        cells = set(c for p in routes.get(net, []) if id(p) not in fan_ids for c in p)
        for t in T:
            tc = term_cells(t) | set(fan_of.get((net, t["ref"], t["num"]), ()))
            if not (tc & cells) and len(T) > 1: out.append((net, t["ref"], t["num"]))
    return out
# Finishing round [2026-11-19]: the open nets once more, now tearing up others again until
# FINISH (tearing stops at RIP_BUDGET in the main pass, and a try used about half of
# build.sh's 50 minutes); the nets torn up go back into the queue.
FINISH = 42 * 60
# the nets locked by MAX_RIPS in the main pass are often the ones round the open terminal:
# the finishing round may tear them up again (GND stays fixed)
for k_ in list(rips):
    if k_ != netid["GND"]: rips[k_] = 0
for round_ in range(3):
    if os.environ.get("ROUTE_FANOUT_ONLY") or COMPLETE or time.time() - T_START > FINISH: break
    q2 = sorted({o[0] for o in open_terms()} | {n for n in terms if n != "GND" and n not in routes})
    if not q2: break
    print(f"finishing round {round_ + 1}: {q2}", flush=True)
    while q2 and time.time() - T_START < FINISH:
        net = q2.pop(0)
        for vn in route_net(net, rip_until=FINISH):
            if vn not in q2: q2.append(vn)
# a net torn up and not routed again, or failed: one more try each without tearing
missing = [n for n in terms if n != "GND" and n not in routes and not os.environ.get("ROUTE_FANOUT_ONLY")]
for n in missing: route_net(n, rip_ok=False)
gnd_failed = [(t["ref"], t["num"]) for t in gnd_early if not route_gnd_pad(t)]
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
write = routes
if COMPLETE:
    for net in changed:
        for t in old_items.get(net, []): b.Remove(t)
    for z in list(b.Zones()): b.Remove(z)
    write = {net: routes.get(net, []) for net in changed}
    stubs = {}
for net, paths in write.items():
    for p in paths:
        w = W_SIG if id(p) in fan_ids else (pw_c.get(id(p), W_SIG) if COMPLETE else width_of.get(net, W_SIG))
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

# Tracks on a face can cut pieces off its ground fill; a piece holding a GND pad's via or
# a thermal spoke is then cut off from ground (KiCad keeps it, it is not an empty island).
# Each piece but the largest gets a stitching via at a free cell, into the other face's
# largest piece; then the faces are filled again.
gid = netid["GND"]; hv, sv = hard[R_VIA], soft[R_VIA]
def stitch():
    """[2026-11-20] by groups, not by pieces: pieces joined by GND vias or through-hole pads
    form a group; a group without the largest pieces is cut off even when it holds vias
    (two cut-off pieces on the two faces, tied only to each other: U8's ground on the
    discant). Each such group gets a via from one of its pieces into the other face's
    largest piece."""
    zs = {z.GetLayer(): z for z in b.Zones()}
    polys = {L: zs[L].GetFilledPolysList(L) for L in LAYERS}
    big = {L: max(range(p.OutlineCount()), key=lambda k: abs(p.Outline(k).Area())) for L, p in polys.items()}
    def inside(L, k, P):
        p = polys[L]
        return p.Outline(k).PointInside(P) and not any(p.Hole(k, h).PointInside(P) for h in range(p.HoleCount(k)))
    par = {(L, k): (L, k) for L, p in polys.items() for k in range(p.OutlineCount())}
    def find(a):
        while par[a] != a: a = par[a]
        return a
    ties = [t.GetPosition() for t in b.GetTracks() if t.GetClass() == "PCB_VIA" and t.GetNetname() == "GND"]
    ties += [p.GetPosition() for f in b.GetFootprints() for p in f.Pads()
             if p.GetNetname() == "GND" and p.GetAttribute() == pcbnew.PAD_ATTRIB_PTH]
    for P in ties:
        hit = [(L, k) for L, p in polys.items() for k in range(p.OutlineCount()) if inside(L, k, P)]
        for h in hit[1:]: par[find(h)] = find(hit[0])
    par[find((LAYERS[0], big[LAYERS[0]]))] = find((LAYERS[1], big[LAYERS[1]]))
    main = find((LAYERS[0], big[LAYERS[0]]))
    groups = {}
    for key in par: groups.setdefault(find(key), []).append(key)
    added = 0
    for root, members in groups.items():
        if root == main: continue
        done = False
        for L, k in members:
            Lo = LAYERS[1 - LI[L]]
            o = polys[L].Outline(k); bb = o.BBox()
            i0, i1 = gx(bb.GetX() / IU), gx((bb.GetX() + bb.GetWidth()) / IU)
            j0, j1 = gy(bb.GetY() / IU), gy((bb.GetY() + bb.GetHeight()) / IU)
            for j in range(max(j0, 0), min(j1 + 1, NY)):
                for i in range(max(i0, 0), min(i1 + 1, NX)):
                    if not (not vblk[j, i] and not novia[j, i] and all(hv[l, j, i] in (0, gid) and sv[l, j, i] in (0, gid) for l in range(NL))):
                        continue
                    at = pcbnew.VECTOR2I(mm(wx(i)), mm(wy(j)))
                    if inside(L, k, at) and inside(Lo, big[Lo], at):
                        add_via("GND", (wx(i), wy(j))); stamp_path(gid, [(0, j, i), (1, j, i)], W_SIG); added += 1; done = True; break
                if done: break
            if done: break
        if not done:
            bb = polys[members[0][0]].Outline(members[0][1]).BBox()
            print("stitching: group cut off, no free cell:", len(members), "pieces near",
                  round(bb.GetX() / IU, 1), round(bb.GetY() / IU, 1), flush=True)
    return added
for _ in range(1):
    n_st = stitch()
    print("stitching vias:", n_st, flush=True)
    if not n_st: break
    pcbnew.ZONE_FILLER(b).Fill(b.Zones())
# two vias of a net in one spot (one hole drilled twice): one goes
seen_v = set()
for t in list(b.GetTracks()):
    if t.GetClass() != "PCB_VIA": continue
    k_ = (t.GetNetname(), t.GetPosition().x, t.GetPosition().y)
    if k_ in seen_v: b.Remove(t)
    else: seen_v.add(k_)
pcbnew.ZONE_FILLER(b).Fill(b.Zones())
b.BuildConnectivity()
pcbnew.SaveBoard(BOARD, b)
print("done", round(time.time() - t0, 1), "open", len(still))
