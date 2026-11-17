#!/usr/bin/env python3
"""Arranges the prototype's printed parts on the Bambu Lab X2D's plate and writes 3MF
files any slicer opens (OrcaSlicer, Bambu Studio, PrusaSlicer): one object per part,
already lying as printed (print.scad), set on the bed and placed.

    python3 plate.py BUILD_DIR      reads BUILD_DIR/print_<part>.stl, writes
                                    BUILD_DIR/plate.3mf     everything for one prototype
                                    BUILD_DIR/fit_test.3mf  one tube, cap and collar, to try
                                                            the press fits first

Plate: the X2D's main nozzle prints 256 x 256 (the left part of the plate is the second
nozzle's too; this plate uses only one). Positions are part centres in mm, origin at the
plate's front left corner.
"""
import os, struct, sys, zipfile
from xml.sax.saxutils import escape

PLATE = [  # part, count, centres
    ("tray",   1, [(70, 40)]),
    ("cover",  1, [(70, 100)]),
    ("board",  1, [(70, 155)]),
    ("cap",    8, [(150 + 22 * i, 40 + 22 * j) for j in range(2) for i in range(4)]),
    ("collar", 8, [(150 + 12 * i, 100 + 12 * j) for j in range(2) for i in range(4)]),
]
FIT_TEST = [
    ("tube",   1, [(118, 128)]),
    ("cap",    1, [(143, 128)]),
    ("collar", 1, [(160, 128)]),
]
BED = 256


def read_stl(path):
    """Triangles of a binary or ASCII STL, as lists of three (x, y, z)."""
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet" in data[:400]:
        v = [tuple(float(c) for c in line.split()[1:4])
             for line in data.decode().splitlines() if line.strip().startswith("vertex")]
    else:
        n = struct.unpack("<I", data[80:84])[0]
        v = []
        for i in range(n):
            f = struct.unpack("<9f", data[84 + 50 * i + 12: 84 + 50 * i + 48])
            v += [f[0:3], f[3:6], f[6:9]]
    return [v[i:i + 3] for i in range(0, len(v), 3)]


def mesh_xml(tris):
    """Vertices (shared, set on the bed and centred in x, y) and triangles."""
    xs = [p[0] for t in tris for p in t]; ys = [p[1] for t in tris for p in t]; zs = [p[2] for t in tris for p in t]
    dx, dy, dz = -(min(xs) + max(xs)) / 2, -(min(ys) + max(ys)) / 2, -min(zs)
    index, verts, faces = {}, [], []
    for t in tris:
        ids = []
        for p in t:
            key = (round(p[0] + dx, 5), round(p[1] + dy, 5), round(p[2] + dz, 5))
            if key not in index:
                index[key] = len(verts); verts.append(key)
            ids.append(index[key])
        if len(set(ids)) == 3:
            faces.append(ids)
    size = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    xml = ["<mesh><vertices>"]
    xml += ['<vertex x="%g" y="%g" z="%g"/>' % v for v in verts]
    xml.append("</vertices><triangles>")
    xml += ['<triangle v1="%d" v2="%d" v3="%d"/>' % tuple(f) for f in faces]
    xml.append("</triangles></mesh>")
    return "".join(xml), size


def write_3mf(path, layout, build, title):
    objects, items = [], []
    for oid, (name, count, centres) in enumerate(layout, start=1):
        xml, size = mesh_xml(read_stl(os.path.join(build, "print_%s.stl" % name)))
        for cx, cy in centres:
            assert size[0] / 2 <= cx <= BED - size[0] / 2 and size[1] / 2 <= cy <= BED - size[1] / 2, \
                "%s off the plate at (%g, %g)" % (name, cx, cy)
        objects.append('<object id="%d" name="%s" type="model">%s</object>' % (oid, escape(name), xml))
        items += ['<item objectid="%d" transform="1 0 0 0 1 0 0 0 1 %g %g 0"/>' % (oid, cx, cy) for cx, cy in centres]
        print("  %-7s %d x  %.1f x %.1f x %.1f mm" % (name, count, *size))
    model = ('<?xml version="1.0" encoding="UTF-8"?>\n'
             '<model unit="millimeter" xml:lang="en-US" '
             'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">'
             '<metadata name="Title">%s</metadata><resources>%s</resources><build>%s</build></model>'
             % (escape(title), "".join(objects), "".join(items)))
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml",
                   '<?xml version="1.0" encoding="UTF-8"?>\n'
                   '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                   '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                   '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
                   '</Types>')
        z.writestr("_rels/.rels",
                   '<?xml version="1.0" encoding="UTF-8"?>\n'
                   '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                   '<Relationship Target="/3D/3dmodel.model" Id="rel0" '
                   'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
        z.writestr("3D/3dmodel.model", model)
    print("wrote", path)


if __name__ == "__main__":
    build = sys.argv[1] if len(sys.argv) > 1 else "../build/key_proto"
    write_3mf(os.path.join(build, "plate.3mf"), PLATE, build, "Key prototype 2 x 4")
    write_3mf(os.path.join(build, "fit_test.3mf"), FIT_TEST, build, "Key prototype fit test")
