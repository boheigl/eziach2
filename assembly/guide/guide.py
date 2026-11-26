#!/usr/bin/env python3
"""Builds the illustrated assembly guide (Aufbauanleitung) from steps.md and the built
models: every ```view block in steps.md becomes a picture that OpenSCAD renders from the
parts in ../../build/ (or from a module of the sources), so the pictures follow every
change of the models; the text is steps.md's. One self-contained HTML file, the
pictures embedded.

usage: guide.py [OUT.html]   (default ../../build/assembly/guide.html)
       GUIDE_ONLY=3,7  render only those views (by number, for trying a camera)

A view block (one item per line, `key: value`):
    frame:  bass | discant | assembly | key     where the parts' names point (build/<frame>/)
    new:    the parts this step adds, drawn in the accent colour (wires keep their colours)
    show:   parts already in place, drawn in their own colours
    ghost:  parts drawn see-through, for orientation
    cam:    az el [zoom] [dx dy dz]   the eye's direction round the focus (az 0: from -y, 90:
            from +x, 180: from +y; el up), zoom > 1 closer, dx.. shift the aimed-at point
    focus:  the parts the camera frames (default: new, else show)
    wire:   the single wires of the sources' modules drawn this many times thicker (to be seen)
    caption: a line under the picture
A part is a built STL by name (`case`, `wires_*`, `assembly/d_housing` for another frame),
a module of a source (`bass/elec.scad:jack()`), or in frame key one of the key's parts
(cap, rod, collar, magnet, stop, spring, oring, bushing, tube, board, sensor). Each may end
in `@dx,dy,dz` (moved, for exploded views) and `=colour`.

In the text, values come from the sources, so they follow them too:
    {{scad:FILE:EXPR}}        EXPR evaluated in FILE (included), rounded to mm
    {{cut:FILE:EXPR[:EXTRA]}} a wire's cut length: EXPR + 2 x 20 mm (+ EXTRA), up to 10 mm
    {{table:main_pads}}       the main board's wire pads, from ../../main_pcb/design.py
    {{table:contact_grid}}    the contact boards' pins, from ../../contact_pcb/gen_pcb.py
Tables in the text are Markdown's (| a | b |).

Caches every rendered picture and every module's STL under build/assembly/guide/ by a
hash of what goes in (the STLs' size and time, the sources' times), so a rebuild renders
only what changed."""
import os, re, sys, ast, json, html, glob, base64, hashlib, shutil, subprocess, datetime, io
from multiprocessing import Pool
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "../.."))
BUILD = os.path.join(ROOT, "build")
OUT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(BUILD, "assembly/guide.html"))
CACHE = os.path.join(os.path.dirname(OUT), "guide")
W, H = 1600, 1000                     # rendered; stored at half the size, smoothed
ACCENT = "#E8701A"                    # the step's new parts; the page uses the same
WIRE_COLS = ["red", "black", "blue", "yellow", "green", "white", "orange", "brown"]
WIRE_RGB = {"red": "#D2302C", "black": "#2A2A2A", "blue": "#2F6FD0", "yellow": "#E6C21E", "green": "#2E9E4A",
            "white": "#F4F4F0", "orange": "#F08A24", "brown": "#7B4A26"}
# own colours of parts by name (first match), for show; ghost is always light grey
COLOURS = [("wires_", None), ("case", "#D9C7A2"), ("housing", "#D9C7A2"), ("d_housing", "#D9C7A2"),
           ("back_cover", "#C9B48C"), ("cover_screws", "#B08D57"), ("cover", "#EDE3CC"), ("d_cover", "#EDE3CC"),
           ("battery", "#5C6F82"), ("boards", "#2F7A4F"), ("board", "#2F7A4F"), ("d_boards", "#2F7A4F"),
           ("main_pcb", "#2F7A4F"), ("laminate", "#2F7A4F"), ("elec", "#3E5C48"), ("connectors", "#EDEDE6"),
           ("d_parts", "#3A3A3A"), ("board_parts", "#3A3A3A"), ("contact_pins", "#C9A13B"), ("keys", "#F3EFE6"),
           ("strap", "#8A5A35"), ("lever", "#9A8F80"), ("latch_rod", "#9AA0A6"), ("stop_screws", "#6E6E6E"),
           ("gauge_link", "#A7AEB5"), ("d_cables", "#A7AEB5"), ("store_discant", "#EDE3CC"), ("d_played", "#EDE3CC")]
KEY_COLS = {"board": "#2F7A4F", "sensor": "#222222", "tube": "#DADADA", "bushing": "#B8863B", "collar": "#F3EFE6",
            "magnet": "#6B7580", "rod": "#B9BDC2", "stop": "#B33A3A", "spring": "#9FB4CF", "oring": "#555555",
            "cap": "#F3EFE6"}
GHOST = "[0.80, 0.80, 0.78, 0.22]"

def own_colour(name):
    n = os.path.basename(name).split(":")[0].replace(".stl", "")
    for k, c in COLOURS:
        if n.startswith(k): return c
    return "#B5B5B0"

def rgb(c, a=1.0):
    c = c.lstrip("#"); return "[%.3f, %.3f, %.3f, %.2f]" % (int(c[0:2], 16) / 255, int(c[2:4], 16) / 255, int(c[4:6], 16) / 255, a)

def openscad(args, cwd=None):
    cmd = ["openscad", *args]
    if not os.environ.get("DISPLAY") and shutil.which("xvfb-run") and any(a.endswith(".png") for a in args):
        cmd = ["xvfb-run", "-a", *cmd]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    return r

def stamp(path):
    s = os.stat(path); return f"{s.st_size}:{int(s.st_mtime)}"

SCAD_STAMP = None
def scad_stamp():
    global SCAD_STAMP
    if SCAD_STAMP is None:
        fs = sorted(glob.glob(os.path.join(ROOT, "**/*.scad"), recursive=True))
        SCAD_STAMP = hashlib.sha1("".join(f + stamp(f) for f in fs if "/build/" not in f).encode()).hexdigest()
    return SCAD_STAMP

# --- parts -> STL files ------------------------------------------------------------
def parse_item(s, frame):
    m = re.match(r"^(.*?)(?:@([-\d.]+),([-\d.]+),([-\d.]+))?(?:=(#?\w+))?$", s.strip())
    name, off, col = m.group(1), [float(m.group(i) or 0) for i in (2, 3, 4)], m.group(5)
    return name, off, col

def stl_files(name, frame, ws=1.0):
    """[(file, colour_or_None)] for a part: one per wire colour where it is wires"""
    if frame == "key" and ":" not in name and "/" not in name:     # a part of the key (../../switch_hall)
        return [(f, KEY_COLS.get(name)) for f, _ in stl_files(f'switch_hall/video/key_video.scad:draw("{name}")', frame)]
    if ":" in name:                                   # a module of a source: render it to STL once
        src, call = name.split(":", 1)
        wires = re.search(r"strands|wires", call) is not None and "draw(" not in call
        out = []
        for c in (WIRE_COLS if wires else [None]):
            w = ws if wires else 1.0
            key = hashlib.sha1(f"{src}|{call}|{c}|{w}|{scad_stamp()}".encode()).hexdigest()[:16]
            f = os.path.join(CACHE, "parts", key + ".stl")
            if not os.path.exists(f) and not os.path.exists(f + ".empty"):
                os.makedirs(os.path.dirname(f), exist_ok=True)
                sc = f + ".scad"
                with open(sc, "w") as fh:
                    head = (f"use <{os.path.join(ROOT, src)}>\n" if w == 1.0 else       # thicker: the wire sizes set over
                            f'include <{os.path.join(ROOT, src)}>\npart = "none";\nawg30 = {0.55 * w:.3f};\nawg26 = {0.9 * w:.3f};\n')
                    fh.write(head + (f'let($wire_color = "{c}") ' if c else "") + call.strip().rstrip(";") + ";\n")
                r = openscad(["--backend=manifold", "-o", f, sc])
                if not os.path.exists(f):
                    if "empty" in r.stderr.lower(): open(f + ".empty", "w").close()
                    else: raise RuntimeError(f"{name}: {r.stderr[-600:]}")
            if os.path.exists(f): out.append((f, WIRE_RGB[c] if c else None))
        return out
    base = name if "/" in name else f"{frame}/{name}"
    files = sorted(glob.glob(os.path.join(BUILD, base + ".stl")))
    if not files: raise SystemExit(f"guide: no part {name!r} (looked for build/{base}.stl)")
    out = []
    for f in files:
        b = os.path.basename(f)[:-4]
        wc = re.match(r"(?:d_)?wires_(\w+)$", b)
        out.append((f, WIRE_RGB.get(wc.group(1)) if wc else None))
    return out

BBOX = {}
def bbox(f):
    k = f + stamp(f)
    if k in BBOX: return BBOX[k]
    d = open(f, "rb").read()
    if d[:5] == b"solid" and b"facet" in d[:400]:
        v = np.array(re.findall(rb"vertex\s+(\S+)\s+(\S+)\s+(\S+)", d), dtype=float)
    else:
        n = int.from_bytes(d[80:84], "little")
        a = np.frombuffer(d[84:84 + 50 * n], dtype=np.uint8).reshape(n, 50)[:, 12:48].copy()
        v = a.view("<f4").reshape(-1, 3).astype(float)
    BBOX[k] = (v.min(0), v.max(0)) if len(v) else None
    return BBOX[k]

# --- steps.md -----------------------------------------------------------------------
def parse_view(text):
    v = {"frame": "bass", "new": [], "show": [], "ghost": [], "cam": "0 30", "focus": [], "caption": ""}
    for line in text.strip().splitlines():
        if not line.strip() or line.strip().startswith("#"): continue
        k, _, val = line.partition(":")
        k = k.strip()
        if k in ("new", "show", "ghost", "focus"): v[k] += val.split()
        else: v[k] = val.strip()
    return v

def scene(v, n):
    """the scene's .scad text and its camera"""
    frame = v["frame"]
    lines = [f"// guide view {n}"]
    focus_files, stamps = [], []
    # see-through parts last: drawn first they would hide what lies behind them (depth test)
    groups = [("show", v["show"]), ("new", v["new"]), ("ghost", v["ghost"])]
    for role, items in groups:
        for it in items:
            name, off, col = parse_item(it, frame)
            for f, own in stl_files(name, frame, float(v.get("wire", 1))):
                if role == "ghost": c = GHOST
                elif col: c = rgb(col if col.startswith("#") else col)
                elif own and (role == "show" or own in WIRE_RGB.values() or frame == "key" and role == "show"): c = rgb(own)
                elif role == "new": c = rgb(ACCENT)
                else: c = rgb(own or own_colour(name))
                if col and not col.startswith("#"): c = f'"{col}"'
                body = f'import("{f}");'
                lines.append(f"color({c}) translate({json.dumps(off)}) {body}")
                stamps.append(f + stamp(f))
                if not v["focus"] and (role == "new" or (role == "show" and not v["new"])):
                    focus_files.append((f, off))
    for it in v["focus"]:                             # the parts framed: drawn or not
        name, off, _ = parse_item(it, frame)
        focus_files += [(f, off) for f, _ in stl_files(name, frame, float(v.get("wire", 1)))]
    # camera: aimed at the focus's box, from az / el, far enough to take it in
    bs = []
    for f, off in focus_files:
        b = bbox(f)
        if b: bs.append((b[0] + off, b[1] + off))
    lo = np.min([b[0] for b in bs], 0); hi = np.max([b[1] for b in bs], 0)
    c = v["cam"].split(); az, el = float(c[0]), float(c[1]); zoom = float(c[2]) if len(c) > 2 else 1.0
    shift = np.array([float(x) for x in c[3:6]]) if len(c) >= 6 else np.zeros(3)
    ctr = (lo + hi) / 2 + shift
    a, e = np.radians(az), np.radians(el)
    d = np.array([np.cos(e) * np.sin(a), -np.cos(e) * np.cos(a), np.sin(e)])
    # the box's size seen from d: its corners projected across the view
    up = np.array([0, 0, 1.0]); right = np.cross(d, up); right /= np.linalg.norm(right) or 1; up2 = np.cross(right, d)
    cs = np.array([[x, y, z] for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])]) - ctr
    half_w = np.abs(cs @ right).max(); half_h = np.abs(cs @ up2).max(); depth = np.abs(cs @ d).max()
    t = np.tan(np.radians(22.5 / 2))                   # OpenSCAD's vertical field of view
    dist = max(half_h / t, half_w / (t * W / H)) * 1.12 / zoom + depth
    eye = ctr + d * dist
    cam = ",".join(f"{x:.2f}" for x in [*eye, *ctr])
    return "\n".join(lines) + "\n", cam, "|".join(stamps)

def render(job):
    n, text, cam, key, out = job
    if os.path.exists(out): return n, out, None
    sc = out[:-5] + ".scad"
    open(sc, "w").write(text)
    png = out[:-5] + ".png"
    r = openscad(["-q", "-o", png, f"--imgsize={W},{H}", f"--camera={cam}", "--projection=p",
                  "--colorscheme=Tomorrow", sc], cwd=os.path.dirname(sc))
    if not os.path.exists(png): return n, None, r.stderr[-800:]
    im = Image.open(png).convert("RGB").resize((W // 2, H // 2), Image.LANCZOS)
    im.save(out, "WEBP", quality=84, method=6); os.remove(png)
    return n, out, None

# --- values from the sources ---------------------------------------------------------
def scad_values(exprs):
    """{(file, expr): value} by OpenSCAD's echo, cached by the sources' stamp"""
    cf = os.path.join(CACHE, "values.json")
    try: cache = json.load(open(cf))
    except Exception: cache = {}
    if cache.get("stamp") != scad_stamp(): cache = {"stamp": scad_stamp()}
    by_file = {}
    for f, e in exprs:
        if f"{f}|{e}" not in cache: by_file.setdefault(f, []).append(e)
    for f, es in by_file.items():
        sc = os.path.join(CACHE, "values.scad")
        with open(sc, "w") as fh:
            fh.write(f"include <{os.path.join(ROOT, f)}>\npart = \"none\";\n")
            for n, e in enumerate(es): fh.write(f'echo(str("GUIDE{n}=", {e}));\n')
        r = openscad(["-o", sc[:-5] + ".echo", sc])
        got = dict(re.findall(r'ECHO: "GUIDE(\d+)=([^"]*)"', open(sc[:-5] + ".echo").read() if os.path.exists(sc[:-5] + ".echo") else ""))
        for n, e in enumerate(es):
            if str(n) not in got: raise SystemExit(f"guide: {f}: {e} gives nothing\n{r.stderr[-600:]}")
            cache[f"{f}|{e}"] = float(got[str(n)])
    json.dump(cache, open(cf, "w"))
    return {k: cache[f"{k[0]}|{k[1]}"] for k in exprs}

SIG_COL = [(r"^(\+3V3|3V3|BATP)", "rot"), (r"^GND", "schwarz"), (r"^SDA", "blau"), (r"^SCL", "gelb"), (r"^INT", "grün"),
           (r"^DET", "weiß"), (r"^TS", "orange"), (r"^EAR_L", "weiß"), (r"^EAR_R", "rot")]
def colour_of(net, name=""):
    if "NTC return" in name: return "braun"
    for p, c in SIG_COL:
        if re.match(p, net): return c
    return ""

def table_main_pads():
    src = open(os.path.join(ROOT, "main_pcb/design.py")).read()
    m = re.search(r"^WIRES = (\[.*?\])\n(?=\S)", src, re.S | re.M)
    wires = ast.literal_eval(m.group(1))
    jm = re.search(r'enumerate\((\(\(".*?\)\))\)', src[src.index("JACK_PADS"):], re.S)
    jack = ast.literal_eval(jm.group(1))
    run = lambda name: "#4" if name.startswith("contacts") else "#5" if name.startswith("bass keys") else "#6"
    de = {"contacts": "Kontakte", "bass keys": "Bass-Tasten", "battery -": "Akku −", "battery +": "Akku +", "battery NTC": "Akku-NTC",
          "NTC return": "NTC-Rückleitung", "jack tip (left)": "Klinke Spitze (links)", "jack ring (right)": "Klinke Ring (rechts)", "jack sleeve": "Klinke Hülse"}
    def deu(n):
        for k, v in de.items():
            if n.startswith(k): return n.replace(k, v)
        return n
    rows = ["| Pad | Netz | Draht | Lauf | Farbe |", "|---|---|---|---|---|"]
    for i, (net, name) in enumerate(wires):
        rows.append(f"| P{i + 1} | `{net}` | {deu(name).replace('3.3 V', '3,3 V')} | {run(name)} | {colour_of(net, name)} |")
    for i, (net, name) in enumerate(jack):
        rows.append(f"| P{19 + i} | `{net}` | {deu(name)} | #7 | {colour_of(net, name)} |")
    return "\n".join(rows)

def table_contact_grid():
    src = open(os.path.join(ROOT, "contact_pcb/gen_pcb.py")).read()
    grid = ast.literal_eval(re.search(r"^GRID = (\{.*?\})", src, re.S | re.M).group(1))
    xs = sorted({c for c, r in grid}); rs = sorted({r for c, r in grid}, reverse=True)
    rows = ["| | links | Mitte | rechts |", "|---|---|---|---|"]
    for r in rs:
        rows.append(f"| {'oben' if r > 0 else 'unten'} | " + " | ".join(f"{grid[(c, r)]} ({colour_of(grid[(c, r)])})" for c in xs) + " |")
    return "\n".join(rows)

def fill(md):
    exprs = []
    for m in re.finditer(r"\{\{(scad|cut):([^:}]+):([^}]+?)\}\}", md):
        e = m.group(3).rsplit(":", 1)[0] if m.group(1) == "cut" and re.search(r":\d+$", m.group(3)) else m.group(3)
        exprs.append((m.group(2), e))
    vals = scad_values(exprs) if exprs else {}
    def sub(m):
        kind = m.group(1)
        if kind == "table": return {"main_pads": table_main_pads, "contact_grid": table_contact_grid}[m.group(2)]()
        e, extra = m.group(3), 0
        if kind == "cut" and re.search(r":\d+$", e): e, extra = e.rsplit(":", 1); extra = int(extra)
        v = vals[(m.group(2), e)]
        return str(round(v)) if kind == "scad" else str(int(-(-(v + 40 + extra) // 10) * 10))
    md = re.sub(r"\{\{(table):(\w+)()\}\}", sub, md)
    return re.sub(r"\{\{(scad|cut):([^:}]+):([^}]+?)\}\}", sub, md)

# --- the page -------------------------------------------------------------------------
def inline(s):
    s = html.escape(s, quote=False)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<![*\w])\*([^*]+)\*(?!\w)", r"<em>\1</em>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
    return s

def blocks(md):
    """steps.md -> a list of (kind, data): h1, h2 (chapter), h3 (step), p, ul, ol, note, view, parts"""
    out, buf = [], []
    lines = md.splitlines(); i = 0
    def flush():
        if buf: out.append(("p", " ".join(buf))); buf.clear()
    while i < len(lines):
        l = lines[i]
        if l.startswith("```view"):
            flush(); j = i + 1
            while not lines[j].startswith("```"): j += 1
            out.append(("view", "\n".join(lines[i + 1:j]))); i = j + 1; continue
        if l.startswith("<!--"):
            flush()
            while "-->" not in lines[i]: i += 1
            i += 1; continue
        m = re.match(r"^(#{1,3}) (.*)", l)
        if m: flush(); out.append(("h" + str(len(m.group(1))), m.group(2).strip())); i += 1; continue
        if re.match(r"^\s*([-*]|\d+\.) ", l):
            flush(); kind = "ol" if re.match(r"^\s*\d+\.", l) else "ul"; items = []
            while i < len(lines) and (re.match(r"^\s*([-*]|\d+\.) ", lines[i]) or (lines[i].startswith("   ") and lines[i].strip())):
                if re.match(r"^\s*([-*]|\d+\.) ", lines[i]): items.append(re.sub(r"^\s*([-*]|\d+\.) ", "", lines[i]))
                else: items[-1] += " " + lines[i].strip()
                i += 1
            out.append((kind, items)); continue
        if l.startswith("> "):
            flush(); txt = []
            while i < len(lines) and lines[i].startswith(">"): txt.append(lines[i][1:].strip()); i += 1
            out.append(("note", " ".join(txt))); continue
        if l.startswith("|"):
            flush(); rows = []
            while i < len(lines) and lines[i].startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(re.match(r"^:?-+:?$", c) for c in cells): rows.append(cells)
                i += 1
            out.append(("table", rows)); continue
        if l.startswith("Teile:"): flush(); out.append(("parts", l[6:].strip())); i += 1; continue
        if not l.strip(): flush(); i += 1; continue
        buf.append(l.strip()); i += 1
    flush()
    return out

def main():
    md = fill(open(os.path.join(HERE, "steps.md")).read())
    bl = blocks(md)
    only = {int(x) for x in os.environ.get("GUIDE_ONLY", "").split(",") if x}
    os.makedirs(os.path.join(CACHE, "img"), exist_ok=True)
    jobs, nview = [], 0
    for k, d in bl:
        if k != "view": continue
        nview += 1
        if only and nview not in only: continue
        v = parse_view(d)
        text, cam, st = scene(v, nview)
        key = hashlib.sha1((text + cam + st + str((W, H))).encode()).hexdigest()[:16]
        jobs.append((nview, text, cam, key, os.path.join(CACHE, "img", key + ".webp")))
    todo = [j for j in jobs if not os.path.exists(j[4])]
    print(f"guide: {nview} views, {len(todo)} to render", flush=True)
    imgs, errs = {}, []
    with Pool(min(4, os.cpu_count() or 1)) as p:
        for n, out, err in p.imap_unordered(render, jobs):
            if err: errs.append(f"view {n}: {err}")
            else: imgs[n] = out
            if out and any(j[0] == n for j in todo): print(f"  RENDER   view {n}", flush=True)
    if errs: raise SystemExit("guide: " + "\n".join(errs))
    if only: print("guide: rendered", ", ".join(imgs[n] for n in sorted(imgs))); return
    page(bl, imgs)
    # old pictures nobody uses any more
    keep = {j[4] for j in jobs}
    for f in glob.glob(os.path.join(CACHE, "img", "*")):
        if f not in keep: os.remove(f)

def git_rev():
    r = subprocess.run(["git", "log", "-1", "--format=%h %cs"], capture_output=True, text=True, cwd=ROOT)
    d = subprocess.run(["git", "status", "--porcelain", "--untracked-files=no"], capture_output=True, text=True, cwd=ROOT)
    return (r.stdout.strip() or "?") + (" + Änderungen" if d.stdout.strip() else "")

def page(bl, imgs):
    title = next(d for k, d in bl if k == "h1")
    toc, body, nview, step, chap = [], [], 0, 0, 0
    open_step = False; open_chap = False
    def close_step():
        nonlocal open_step
        if open_step: body.append("</div></article>"); open_step = False
    for k, d in bl:
        if k == "h1": continue
        if k == "h2":
            close_step()
            if open_chap: body.append("</section>")
            chap += 1; step = 0; cid = f"k{chap}"
            body.append(f'<section class="chap" id="{cid}"><h2><span class="cn">{chap}</span>{inline(d)}</h2>')
            toc.append(f'<li class="tc"><a href="#{cid}"><span class="cn">{chap}</span>{inline(d)}</a></li>'); open_chap = True
            continue
        if k == "h3":
            close_step(); step += 1; sid = f"s{chap}-{step}"
            body.append(f'<article class="step" id="{sid}"><h3><span class="sn">{chap}.{step}</span>{inline(d)}</h3><div class="sb">')
            toc.append(f'<li class="ts"><a href="#{sid}"><span class="sn">{chap}.{step}</span>{inline(d)}</a></li>'); open_step = True
            continue
        if k == "view":
            nview += 1; v = parse_view(d)
            src = "data:image/webp;base64," + base64.b64encode(open(imgs[nview], "rb").read()).decode()
            cap = inline(v["caption"]) if v["caption"] else ""
            if float(v.get("wire", 1)) != 1: cap += f" (Drähte {float(v['wire']):g}× so dick gezeichnet)".replace(".", ",")
            leg = '<span class="lg"><i></i>neu in diesem Schritt</span>' if v["new"] and v["frame"] != "key" else ""
            body.append(f'<figure><img src="{src}" alt="{html.escape(v["caption"] or "Ansicht")}" loading="lazy" width="{W//2}" height="{H//2}">'
                        f'<figcaption>{leg}{cap}</figcaption></figure>')
        elif k == "p": body.append(f"<p>{inline(d)}</p>")
        elif k in ("ul", "ol"): body.append(f"<{k}>" + "".join(f"<li>{inline(x)}</li>" for x in d) + f"</{k}>")
        elif k == "table":
            head, *rows = d
            body.append('<div class="tw"><table><thead><tr>' + "".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>"
                        + "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in rows) + "</tbody></table></div>")
        elif k == "note": body.append(f'<p class="note">{inline(d)}</p>')
        elif k == "parts":
            chips = "".join(f"<li>{inline(x.strip())}</li>" for x in d.split(";") if x.strip())
            body.append(f'<div class="parts"><span>Teile</span><ul>{chips}</ul></div>')
    close_step()
    if open_chap: body.append("</section>")
    stand = datetime.date.today().strftime("%d.%m.%Y")
    out = TEMPLATE.replace("{TITLE}", html.escape(title)).replace("{TOC}", "".join(toc)).replace("{BODY}", "\n".join(body)) \
                  .replace("{STAND}", f"{stand}, Stand der Modelle: {html.escape(git_rev())}").replace("{ACCENT}", ACCENT)
    open(OUT, "w").write(out)
    print(f"guide: {OUT} ({len(out) // 1024} kB)")

TEMPLATE = open(os.path.join(HERE, "page.html")).read()

if __name__ == "__main__":
    main()
