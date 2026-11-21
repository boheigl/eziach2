#!/usr/bin/env python3
"""The keys' spacings for the phone page, along the bass's x, y and z.

    python3 key_dims.py key_marks.stl key_dims.json

key_marks.stl (assembly.scad, part "key_marks") has a small cube on the middle of every
cap's top and a larger one on each side of its rim along x (for the cap's diameter), the
bass's 18 and the discant's 46 as played. For each half this picks a key
near the middle of the front row, its neighbour in that row and the key of the next row
between them, and writes the ways from the first to the other two as runs along x, then
y, then z (runs under 0.05 mm left out): [{"a": [x, y, z], "b": [x, y, z], "t": "20",
"s": [x, y, z]}, ...] in the bass's frame; s is the side its label goes to, across the run:
the row's pitch away from the next row, the runs to that row's key towards it, so that
the two runs along x (20 and 10, on one line) keep their labels apart.
"""
import json, re, struct, sys


def cubes(stl):
    t = open(stl, 'rb').read()
    if t[:5] == b'solid':           # ASCII STL, as OpenSCAD writes it
        verts = [tuple(float(x) for x in m.split()) for m in re.findall(rb'vertex\s+([^\n]+)', t)]
    else:
        n = struct.unpack('<I', t[80:84])[0]
        pts = [struct.unpack('<12f', t[84 + 50 * i:132 + 50 * i])[3:] for i in range(n)]
        verts = [p[j:j + 3] for p in pts for j in (0, 3, 6)]
    groups = []                     # the cubes lie at least 10 apart: join vertices within 1 mm
    for v in verts:
        for g in groups:
            if all(abs(v[k] - g[0][k]) < 1 for k in range(3)):
                g.append(v); break
        else:
            groups.append([v])
    # [middle, size]: the caps' middles are 0.4 cubes, their rims' marks 0.8
    return [(tuple(sum(v[k] for v in g) / len(g) for k in range(3)), max(v[0] for v in g) - min(v[0] for v in g)) for g in groups]


def rows(pts):
    """the keys sorted into rows (same y within 2 mm), each sorted along x"""
    out = []
    for p in sorted(pts, key=lambda p: p[1]):
        if out and abs(out[-1][0][1] - p[1]) < 2: out[-1].append(p)
        else: out.append([p])
    return [sorted(r) for r in out]


def fmt(v):
    return ('%.2f' % abs(v)).rstrip('0').rstrip('.')


def chain(a, b, sy):
    """from a to b along x, y and z in turn; labels of runs along x to the side sy (+-1 in y),
    the others to +x, away from the run along x before them"""
    out, p = [], list(a)
    for k in range(3):
        q = list(p); q[k] = b[k]
        if abs(q[k] - p[k]) >= 0.05:
            out.append({'a': [round(c, 3) for c in p], 'b': [round(c, 3) for c in q], 't': fmt(q[k] - p[k]),
                        's': [0, sy, 0] if k == 0 else [1, 0, 0]})
        p = q
    return out


def half(pts, rims, front_n):
    """front row (front_n keys) and the row next to it: a near the front row's middle,
    b its neighbour, c the next row's key between them; and the diameter of the cap after b
    (rim to rim along x, its label towards the next row)"""
    rs = rows(pts)
    i0 = [i for i, r in enumerate(rs) if len(r) == front_n][0]
    front = rs[i0]
    nxt = rs[i0 + 1] if i0 + 1 < len(rs) else rs[i0 - 1]
    j = len(front) // 2
    a, b = front[j - 1], front[j]
    c = min(nxt, key=lambda p: abs(p[0] - (a[0] + b[0]) / 2))
    towards = 1 if c[1] > a[1] else -1
    d = front[j + 1]
    r = sorted([p for p in rims if abs(p[1] - d[1]) < 0.5 and abs(p[2] - d[2]) < 0.5 and abs(p[0] - d[0]) < 10], key=lambda p: p[0])
    assert len(r) == 2, r
    dia = {'a': [round(x, 3) for x in r[0]], 'b': [round(x, 3) for x in r[1]], 't': '\u2300' + fmt(r[1][0] - r[0][0]), 's': [0, towards, 0]}
    return chain(a, b, -towards) + chain(a, c, towards) + [dia]


marks, out = sys.argv[1:3]
cs = cubes(marks)
pts = [p for p, s in cs if s < 0.6]
rims = [p for p, s in cs if s >= 0.6]
bass = [p for p in pts if p[2] > -50]          # the bass's caps stand at z 14 and 24, the discant's under it
disc = [p for p in pts if p[2] <= -50]
assert len(bass) == 18 and len(disc) == 46 and len(rims) == 2 * 64, (len(bass), len(disc), len(rims))
dims = half(bass, rims, 9) + half(disc, rims, 13)
json.dump(dims, open(out, 'w'))
for d in dims: print(d['t'], d['a'], '->', d['b'])
