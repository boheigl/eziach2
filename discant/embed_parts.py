#!/usr/bin/env python3
# Writes the phone page with its parts embedded: each STL becomes an inactive
# <script type="text/plain" id="d-NAME"> block of base64 little-endian float32
# x,y,z, three vertices per triangle, put where the page has
# its "parts: filled in by embed_parts.py" comment.
#   python3 embed_parts.py phone.html ../build/discant/phone.html [--keys board.scad] NAME=part.stl ...
# --keys fills the page's /*KEYS*/[] with [row, key, x] of every key (hall_keys in the
# board's data, ../hall_pcb/<board>/board.scad). A <script src="x.js"> with a relative
# path (viewer_nav.js) is put into the page inline.
import base64, re, struct, sys

MARK = '<!-- parts: filled in by embed_parts.py -->'


def triangles(stl):
    t = open(stl, 'rb').read()
    if t[:5] == b'solid':   # ASCII STL
        v = [float(x) for m in re.findall(rb'vertex\s+([^\n]+)', t) for x in m.split()]
    else:                   # binary STL: 50 bytes per triangle, normal first
        n = struct.unpack('<I', t[80:84])[0]
        v = [x for i in range(n) for x in struct.unpack('<12f', t[84 + 50 * i:132 + 50 * i])[3:]]
    return base64.b64encode(struct.pack('<%df' % len(v), *v)).decode()


page, out = sys.argv[1:3]
args = sys.argv[3:]
s = open(page).read()
if args[:1] == ['--keys']:
    m = re.search(r'hall_keys = (\[.*?\]\]);', open(args[1]).read())
    keys = [[k[0], k[1], k[2]] for k in eval(m.group(1))]
    s = s.replace('/*KEYS*/[]', repr(keys))
    args = args[2:]
# scripts of this project the page loads by a relative src (viewer_nav.js) go in inline
import os
def _inline(m):
    return '<script>\n' + open(os.path.join(os.path.dirname(os.path.abspath(page)), m.group(1))).read() + '</script>'
s = re.sub(r'<script src="([^":]+\.js)"></script>', _inline, s)
assert s.count(MARK) == 1, 'the page needs exactly one parts comment'
blocks = []
for arg in args:
    name, stl = arg.split('=', 1)
    blocks.append('<script type="text/plain" id="d-%s">%s</script>' % (name, triangles(stl)))
open(out, 'w').write(s.replace(MARK, '\n'.join(blocks)))
