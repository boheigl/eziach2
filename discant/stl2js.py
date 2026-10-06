#!/usr/bin/env python3
# Writes an STL's triangles as a JS file for array.html: one base64 string of
# little-endian float32 x,y,z, three vertices per triangle, in board 0's frame.
#   python3 stl2js.py ../build/discant/housing.stl ../build/discant/housing.js HOUSING_TRIS
import base64, os, re, struct, sys

stl, js, var = sys.argv[1:4]
t = open(stl, 'rb').read()
if t[:5] == b'solid':   # ASCII STL
    v = [float(x) for m in re.findall(rb'vertex\s+([^\n]+)', t) for x in m.split()]
else:                   # binary STL: 50 bytes per triangle, normal first
    n = struct.unpack('<I', t[80:84])[0]
    v = [x for i in range(n) for x in struct.unpack('<12f', t[84 + 50 * i:132 + 50 * i])[3:]]
data = base64.b64encode(struct.pack('<%df' % len(v), *v)).decode()
with open(js, 'w') as f:
    f.write("// generated from %s (%s): triangles as little-endian float32 x,y,z in board 0's frame\n"
            % (os.path.basename(stl), os.path.basename(stl).replace('.stl', '.scad')))
    f.write('window.%s = "%s";\n' % (var, data))
