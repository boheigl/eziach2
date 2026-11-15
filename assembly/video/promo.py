#!/usr/bin/env python3
"""Renders the eziach promo video: the instrument, force instead of bellows, the
Hall-effect keys, playing, inside, plugging together and packing away. OpenSCAD
draws each frame (promo.scad for the instrument, ../../switch_hall/video/
key_video.scad for the key in section), PIL adds captions and the gauges, GStreamer
encodes VP9/WebM.

usage: promo.py [OUT.webm]   (default ../../build/assembly/eziach_promo.webm)
       PROMO_FPS=10 for a draft; PROMO_STILLS=40,200,... only those frames, on a
       contact sheet next to OUT; PROMO_CHECK=k: every k-th frame of plugging and
       packing, the volume the moved discant shares with the bass (only the latch's
       tongue may touch, a few mm³)"""
import os, re, sys, json, math, hashlib, shutil, subprocess, tempfile
from multiprocessing import Pool
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "../.."))
OUT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build/assembly/eziach_promo.webm"))
WORK = os.path.join(os.path.dirname(OUT), "promo_frames")
FPS = int(os.environ.get("PROMO_FPS", 25))
W, H, VH, TOP = 1280, 720, 560, 160        # frame; the 3D view below the captions
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
KEY_SCAD = os.path.join(ROOT, "switch_hall/video/key_video.scad")

def scad_echo(path, *defs):
    with tempfile.TemporaryDirectory() as t:
        o = os.path.join(t, "x.echo")
        subprocess.run(["openscad", "-o", o, *defs, path], capture_output=True, text=True)
        return open(o).read() if os.path.exists(o) else ""

# --- the discant's two positions, read back from ../../bass/link.scad
def placement(which):
    with tempfile.TemporaryDirectory() as t:
        o = os.path.join(t, "m.stl")
        subprocess.run(["openscad", "-q", "-o", o, "--export-format", "asciistl", "-D", f'which="{which}"',
                        os.path.join(HERE, "frames.scad")], check=True)
        v = np.array([list(map(float, l.split()[1:])) for l in open(o) if l.strip().startswith("vertex")])
    cs = []
    for x in v:
        for c in cs:
            if np.linalg.norm(c[0] - x) < 3: c.append(x); break
        else: cs.append([x])
    cs.sort(key=lambda c: np.ptp(np.array(c), 0).max())      # by the cube's size: origin, x, y, z
    o_, ex, ey, ez = [np.mean(c, 0) for c in cs]
    M = np.eye(4); M[:3, 0], M[:3, 1], M[:3, 2], M[:3, 3] = (ex - o_) / 10, (ey - o_) / 10, (ez - o_) / 10, o_
    return M
DB = placement("bass"); DS = placement("store")
RS = DS @ np.linalg.inv(DB)                        # played -> stored, on the played pieces
assert all(abs(np.linalg.det(M[:3, :3]) - 1) < 1e-3 for M in (DB, DS)), "frames.scad: not a rotation"

def rot_to_axis_angle(R):
    a = math.acos(max(-1, min(1, (np.trace(R) - 1) / 2)))
    if a < 1e-9: return np.array([1.0, 0, 0]), 0.0
    if abs(a - math.pi) < 1e-6:
        w, V = np.linalg.eigh((R + np.eye(3)) / 2); return V[:, np.argmax(w)], a
    ax = np.array([R[2, 1] - R[1, 2], R[0, 2] - R[2, 0], R[1, 0] - R[0, 1]]) / (2 * math.sin(a))
    return ax, a
def axis_angle(ax, a):
    ax = ax / np.linalg.norm(ax); K = np.array([[0, -ax[2], ax[1]], [ax[2], 0, -ax[0]], [-ax[1], ax[0], 0]])
    return np.eye(3) + math.sin(a) * K + (1 - math.cos(a)) * K @ K
def T(x, y, z): M = np.eye(4); M[:3, 3] = [x, y, z]; return M

# --- the key: heights and the field on the sensor (as ../../switch_hall/key.scad)
g = dict(json.loads(re.search(r"GEOM = (\[.*\])", scad_echo(os.path.join(ROOT, "switch_hall/video/geom.scad"))).group(1)))
f = re.search(r"field on the axis: ([\d.]+) mT at rest, ([\d.]+) mT", scad_echo(os.path.join(ROOT, "switch_hall/key.scad"), "-D", 'part="none"'))
B_REST, B_BOT = float(f.group(1)), float(f.group(2))
D0 = g["z_cb"] - (g["z_bot"] - 0.55)               # magnet face to the Hall element at rest
def b_axis(z, R=1.5, L=1.5): return (z + L) / math.hypot(R, z + L) - z / math.hypot(R, z)
BR = B_REST / b_axis(D0)
K_TILT = B_BOT / (BR * b_axis(D0 - g["stroke"])) - 1   # key.scad's board tilt, spread over the travel
def field(t): return BR * b_axis(D0 - t) * (1 + K_TILT * t / g["stroke"])   # t: travel 0 .. 3

def ease(u): u = min(max(u, 0), 1); return u * u * (3 - 2 * u)
def lerp(a, b, u): return a + (b - a) * u
def lerpv(a, b, u): return [lerp(p, q, u) for p, q in zip(a, b)]

class State:
    def __init__(s):
        s.view = "inst"                              # "inst" or "key"
        s.RD = np.eye(4); s.DK = [0.0] * 46; s.BK = [0.0] * 18
        s.show = ["bass", "discant", "case", "keys"]; s.xray = 0.0; s.arrow = 0.0; s.glow = 0.0
        s.cam = [0, 40, -50, 62, 0, 215, 900]         # centre x y z, tilt, 0, turn, distance
        s.T = 0.0; s.kcam = [0, 7, 74, 10, 70]
        s.title = ""; s.text = ""; s.meter = None; s.graph = False; s.card = None; s.fade = None
        s.labels = []                                 # (text, 3D anchor, label's place on the frame)
    def copy(s):
        c = State(); c.__dict__.update({k: (v.copy() if isinstance(v, (list, np.ndarray)) else v) for k, v in s.__dict__.items()})
        c.fade = None; return c

frames = []; st = State()
def hold(sec):
    for _ in range(int(round(sec * FPS))): frames.append(st.copy())
def anim(sec, fn, e=True):
    n = int(round(sec * FPS))
    for k in range(n): fn(ease((k + 1) / n) if e else (k + 1) / n); frames.append(st.copy())
def cut_to(new, sec=0.6):
    a = st.copy(); n = max(1, int(round(sec * FPS)))
    for k in range(n):
        f_ = new.copy(); f_.fade = (a, 1 - (k + 1) / n); frames.append(f_)
def cam_anim(cam):
    c0 = list(st.cam); return lambda u: st.cam.__setitem__(slice(None), lerpv(c0, cam, u))

PACK_CAM0 = [0, 70, -70, 70, 0, 230, 820]; PACK_CAM1 = [0, 30, -70, 72, 0, 210, 620]; PACK_CAM2 = [0, 30, -66, 68, 0, 150, 620]
# 1 title
st.title = "eziach"; st.text = "The Steirische Harmonika without bellows"
anim(5, lambda u: st.cam.__setitem__(slice(None), [0, 40, -72, 62, 0, lerp(0, 55, u), lerp(760, 720, u)]), e=False)

# 2 force instead of bellows: the hand plate (lit from the camera's left), then the gauges
st.title = "Force instead of bellows"
st.text = "Two strain-gauge flexures between the halves feel the hand's push and pull.\nDirection picks the push or pull note, force sets the loudness."
anim(1.5, cam_anim([0, 30, -66, 80, 0, 35, 650]))
def force(u, peak, arrow=True):
    v = peak * math.sin(math.pi * u); st.arrow = v if arrow else 0; st.glow = max(-1, min(1, v / 40)); st.meter = v
    on = abs(v) > 8
    for n in (14, 16, 18, 27, 29): st.DK[n] = 3.0 if on else 0.0
anim(2.5, lambda u: force(u, 60), e=False)
anim(2.5, lambda u: force(u, -45), e=False)
st.arrow = 0; st.glow = 0; st.DK = [0.0] * 46; st.meter = 0
g_ = st.copy(); g_.xray = 0.95; g_.cam = [5, 22, -133, 115, 0, 200, 250]
g_.title = "Strain gauges"
g_.text = "Two flexure plates carry the treble side. On each, a half bridge of two gauges\nback to back reads the bending - axial load and temperature cancel out."
cut_to(g_, 0.8); st = g_
def gauges(u, peak, u0):
    force(u, peak, arrow=False); st.cam[5] = lerp(200, 225, u0 + u * 0.5)
anim(2.5, lambda u: gauges(u, 50, 0), e=False)
anim(2.5, lambda u: gauges(u, -40, 0.5), e=False)
st.glow = 0; st.DK = [0.0] * 46; st.meter = None

# 3 the Hall-effect key
k = st.copy(); k.view = "key"; k.title = "Contactless Hall-effect keys"
k.text = "A magnet in every key, a Hall sensor under the board: the whole travel is read,\nnot just a click. Actuation point and hysteresis are set in firmware."
k.graph = True; k.xray = 0; cut_to(k); st = k
for _ in range(2):
    anim(1.3, lambda u: setattr(st, "T", g["stroke"] * u)); hold(0.4)
    anim(1.1, lambda u: setattr(st, "T", g["stroke"] * (1 - u))); hold(0.3)
st.text = "Soft stops at both ends - an O-ring below, a silicone washer above:\nno click, no wear on any contact. Nothing that moves touches the board."
hold(3)

# 4 playing: from behind the bass, where both keyboards face the camera
n = st.copy(); n.view = "inst"; n.graph = False; n.T = 0; n.cam = [0, 45, -72, 60, 0, 200, 720]
n.title = "46 treble keys, 18 bass keys"
n.text = "Four stepped rows in the treble, two in the bass; every key is read on its own,\nso any chord works - no matrix, no ghosting."
cut_to(n); st = n
rows = [(0, 13), (13, 12), (25, 11), (36, 10)]
def wave(u):
    t = u * 1.0
    for r, (a, cnt) in enumerate(rows):
        for i in range(cnt):
            c = (i + 0.5 * r) / 14.5 * 0.75 + 0.05
            st.DK[a + i] = 3.0 * max(0.0, 1 - abs(t - c) / 0.08)
    for i in range(18):
        c = (i % 9) / 9 * 0.75 + 0.1; st.BK[i] = 3.0 * max(0.0, 1 - abs(t - c) / 0.08)
    st.cam[5] = lerp(200, 235, u)
anim(5, wave, e=False); st.DK = [0.0] * 46; st.BK = [0.0] * 18

# 5 inside: the cases fade, then go, and the parts are named
st.title = "Inside"
st.text = "One sensor board per side: ADS7138 ADCs on I²C. In the bass: ESP32-S3, audio DAC\nwith headphone jack, USB-C for charging and MIDI, and the Li-ion battery."
IN_CAM = [0, 30, -70, 70, 0, 230, 600]
anim(1.5, lambda u: setattr(st, "xray", u))
anim(1.5, cam_anim(IN_CAM))
st.show = ["bass", "discant", "inside"]; st.xray = 0
st.labels = [("treble key board: 46 Hall sensors, 6 ADCs", (5, 70, -132), (60, 520)),
             ("bass key board: 18 sensors, 3 ADCs", (-40, 8, -6), (60, 200)),
             ("main board: ESP32-S3, audio DAC, charger, USB-C", (85, -8, -110), (60, 360)),
             ("Li-ion battery", (5, -6, -100), (1220, 360)),
             ("strain gauges", (5, 22, -133), (1220, 520))]
anim(5, lambda u: st.cam.__setitem__(5, lerp(230, 260, u)), e=False)
st.labels = []; st.show = ["bass", "discant", "case", "keys"]; st.xray = 1
anim(1.0, lambda u: setattr(st, "xray", 1 - u))

# 6 plug together, pack away
st.title = "Plug and play"
st.text = "The halves plug together on the gauges. Spring contacts carry power and I²C,\nand plugging in switches the instrument on."
anim(1.2, cam_anim(PACK_CAM0))
P1 = T(0, 18, 0); P2 = T(0, 160, -40)
RSr = RS[:3, :3]; ax, ang = rot_to_axis_angle(RSr)
P3 = T(0, 0, -10) @ RS                              # just under the socket (link.scad: travel 9.3 above the playing mount), already turned
def slide_off(u): st.RD = T(0, 18 * u, 0)
anim(1.2, slide_off); hold(0.3)
st.title = "Packs flat"
st.text = "Stored, the treble side plugs in under the bass's deck and the bass covers its keys:\n283 x 40 x 152 mm, 1.7 litres - into any bag."
def away(u):
    p = lerpv(P1[:3, 3], P2[:3, 3], u); M = np.eye(4); M[:3, 3] = p; st.RD = M
anim(1.5, away)
P2b = T(0, 140, 0) @ P3                            # turned, well behind the socket, at its height
def turn(u):
    M = np.eye(4); M[:3, :3] = axis_angle(ax, ang * u); M[:3, 3] = lerpv(P2[:3, 3], P2b[:3, 3], u); st.RD = M
anim(2.5, lambda u: (turn(u), st.cam.__setitem__(slice(None), lerpv(PACK_CAM0, PACK_CAM1, u))))
def slide_in(u): M = P3.copy(); M[:3, 3] = lerpv(P2b[:3, 3], P3[:3, 3], u); st.RD = M
anim(1.5, slide_in)
def up(u): M = RS.copy(); M[:3, 3] = lerpv(P3[:3, 3], RS[:3, 3], u); st.RD = M
anim(1.2, up); hold(0.5)
anim(4, lambda u: st.cam.__setitem__(slice(None), lerpv(PACK_CAM1, PACK_CAM2, u)), e=False)

# 7 end card
c = st.copy(); c.card = True; cut_to(c, 0.8); st = c; hold(4)

# ---------------------------------------------------------------- render
def scad_job(s):
    if s.view == "key":
        P = [[n, 1, 0, 0] for n in ["board", "sensor", "tube", "bushing", "collar", "magnet", "rod", "stop", "spring", "oring", "cap"]]
        cx, cz, tilt, turn, dist = s.kcam
        return KEY_SCAD, ["-D", "P=" + json.dumps(P), "-D", "cut=true", "-D", f"T={s.T:.4f}",
                          f"--camera={cx},0,{cz},{tilt},0,{turn},{dist}"], True
    r = lambda M: json.dumps([[round(float(v), 5) for v in row] for row in M])
    cam = ",".join(f"{v:.3f}" for v in s.cam)
    return os.path.join(HERE, "promo.scad"), ["-D", "RD=" + r(s.RD), "-D", "DB=" + r(DB),
            "-D", "DK=" + json.dumps([round(v, 3) for v in s.DK]), "-D", "BK=" + json.dumps([round(v, 3) for v in s.BK]),
            "-D", "SHOW=" + json.dumps(s.show), "-D", f"XRAY={s.xray:.3f}", "-D", f"ARROW={s.arrow:.2f}",
            "-D", f"GLOW={s.glow:.3f}", f"--camera={cam}"], False

def key_of(s): return hashlib.sha1(json.dumps(scad_job(s)[:2]).encode()).hexdigest()[:16]

def render(item):
    k, (path, args, manifold) = item
    out = os.path.join(WORK, "views", k + ".png")
    if os.path.exists(out): return
    cmd = ["openscad", "-q", "-o", out + ".tmp.png", f"--imgsize={W},{VH}", "--projection=p", "--colorscheme=Tomorrow", *args, path]
    if manifold: cmd[2:2] = ["--backend=manifold", "--render"]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=os.path.dirname(path))
    if r.returncode or not os.path.exists(out + ".tmp.png"): raise RuntimeError(" ".join(cmd[:6]) + "\n" + r.stderr[-800:])
    os.replace(out + ".tmp.png", out)

def project(p, cam, w=W, h=VH, fov=22.5):
    """Where OpenSCAD's --camera (gimbal, perspective) draws point p: it turns the scene
    by 90 - rx about x and -rz about z, and looks along +y from distance d (checked
    against rendered markers to 2 px)."""
    cx, cy, cz, rx, ry, rz, d = cam
    a, b = math.radians(90 - rx), math.radians(-rz)
    Rx = np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]])
    Rz = np.array([[math.cos(b), -math.sin(b), 0], [math.sin(b), math.cos(b), 0], [0, 0, 1]])
    v = Rx @ Rz @ (np.array(p, float) - [cx, cy, cz]); f = 1 / math.tan(math.radians(fov) / 2) * h / 2 / (v[1] + d)
    return w / 2 + v[0] * f, h / 2 - v[2] * f

def F(p, s): return ImageFont.truetype(p, s)
def overlay(img, s):
    c = Image.new("RGB", (W, H), (248, 248, 248)); c.paste(img, (0, TOP)); d = ImageDraw.Draw(c)
    if s.card:
        d.rectangle([0, 0, W, H], fill=(28, 32, 38))
        d.text((W // 2, 230), "eziach", font=F(FONT_B, 96), anchor="mm", fill=(240, 196, 90))
        d.text((W // 2, 320), "The Steirische Harmonika without bellows", font=F(FONT, 30), anchor="mm", fill=(230, 230, 230))
        for i, t in enumerate(["Force sensing instead of bellows: push, pull and loudness",
                               "Contactless Hall-effect keys, silent and adjustable",
                               "ESP32-S3 synthesis, headphone jack, USB-C MIDI, battery",
                               "Plugs together to play, packs to 1.7 litres"]):
            d.text((W // 2, 410 + i * 44), t, font=F(FONT, 22), anchor="mm", fill=(190, 196, 204))
        return c
    d.text((40, 22), s.title, font=F(FONT_B, 40), fill=(30, 30, 30))
    d.multiline_text((40, 78), s.text, font=F(FONT, 22), fill=(70, 70, 70), spacing=8)
    for text, p3, (lx, ly) in s.labels:             # names with leader lines to the parts
        ax_, ay_ = project(p3, s.cam); ay_ += TOP
        fnt = F(FONT_B, 17); right = lx > W / 2
        bb = d.textbbox((lx, ly), text, font=fnt, anchor="rm" if right else "lm")
        d.rounded_rectangle([bb[0] - 8, bb[1] - 6, bb[2] + 8, bb[3] + 6], 6, fill=(255, 255, 255), outline=(150, 150, 150))
        d.text((lx, ly), text, font=fnt, anchor="rm" if right else "lm", fill=(30, 30, 30))
        ex = bb[0] - 8 if right else bb[2] + 8
        d.line([ex, ly, ax_, ay_], fill=(60, 60, 60), width=2)
        d.ellipse([ax_ - 5, ay_ - 5, ax_ + 5, ay_ + 5], fill=(230, 89, 26), outline=(255, 255, 255))
    if s.meter is not None:                         # pull <- | -> push
        x0, x1, y = 760, 1220, 640; xm = (x0 + x1) / 2
        d.rounded_rectangle([x0 - 20, y - 70, x1 + 20, y + 50], 12, fill=(255, 255, 255), outline=(200, 200, 200))
        d.rectangle([x0, y - 12, x1, y + 12], fill=(232, 232, 232))
        v = max(-60, min(60, s.meter)); xe = xm + v / 60 * (x1 - xm)
        d.rectangle([min(xm, xe), y - 12, max(xm, xe), y + 12], fill=(26, 115, 230) if v > 0 else (230, 89, 26))
        d.line([xm, y - 18, xm, y + 18], fill=(60, 60, 60), width=2)
        d.text((x0, y - 50), "PULL", font=F(FONT_B, 20), fill=(230, 89, 26) if v < -8 else (170, 170, 170))
        d.text((x1, y - 50), "PUSH", font=F(FONT_B, 20), anchor="ra", fill=(26, 115, 230) if v > 8 else (170, 170, 170))
        d.text((xm, y - 50), f"{abs(v):.0f} N", font=F(FONT_B, 20), anchor="ma", fill=(40, 40, 40))
        d.text((xm, y + 22), "pull notes" if v < -8 else "push notes" if v > 8 else "-", font=F(FONT, 16), anchor="ma", fill=(90, 90, 90))
    if s.graph:                                     # field at the sensor over the travel
        x0, y0, gw, gh = 900, 260, 330, 300
        d.rounded_rectangle([x0 - 50, y0 - 50, x0 + gw + 25, y0 + gh + 60], 12, fill=(255, 255, 255), outline=(200, 200, 200))
        d.text((x0 - 35, y0 - 40), "field at the sensor (mT)", font=F(FONT_B, 16), fill=(40, 40, 40))
        bmax = 45
        px = lambda t: x0 + t / g["stroke"] * gw
        py = lambda b: y0 + gh - b / bmax * gh
        d.line([x0, y0, x0, y0 + gh, x0 + gw, y0 + gh], fill=(90, 90, 90), width=2)
        for b in (0, 10, 20, 30, 40): d.text((x0 - 8, py(b)), str(b), font=F(FONT, 13), anchor="rm", fill=(90, 90, 90))
        for t in (0, 1, 2, 3): d.text((px(t), y0 + gh + 8), f"{t}", font=F(FONT, 13), anchor="ma", fill=(90, 90, 90))
        d.text((x0 + gw / 2, y0 + gh + 30), "key travel (mm)", font=F(FONT, 14), anchor="ma", fill=(90, 90, 90))
        thr = field(1.8)
        d.line([x0, py(thr), x0 + gw, py(thr)], fill=(230, 89, 26), width=2)
        d.text((x0 + 6, py(thr) - 20), "actuation point (adjustable)", font=F(FONT, 13), fill=(230, 89, 26))
        pts = [(px(t), py(field(t))) for t in np.linspace(0, g["stroke"], 60)]
        d.line(pts, fill=(26, 115, 230), width=3)
        bx, by = px(s.T), py(field(s.T)); on = field(s.T) >= thr
        d.ellipse([bx - 8, by - 8, bx + 8, by + 8], fill=(26, 115, 230) if not on else (20, 160, 80))
        d.text((x0 + gw, y0 - 40), f"{field(s.T):.1f} mT", font=F(FONT_B, 16), anchor="ra", fill=(40, 40, 40))
        d.text((x0 + gw, y0 + 10), "NOTE ON" if on else "", font=F(FONT_B, 18), anchor="ra", fill=(20, 160, 80))
    return c

def clash(M):
    """Volume (mm³) the discant moved by M shares with the bass (promo.scad CLASH)."""
    with tempfile.TemporaryDirectory() as t:
        o = os.path.join(t, "c.stl")
        r = subprocess.run(["openscad", "--backend=manifold", "-o", o, "--export-format", "binstl", "-D", "CLASH=true",
                            "-D", "RD=" + json.dumps(M.round(5).tolist()), "-D", "DB=" + json.dumps(DB.round(5).tolist()),
                            os.path.join(HERE, "promo.scad")], capture_output=True, text=True, cwd=HERE)
        if not os.path.exists(o): return 0.0              # empty: nothing shared
        b = open(o, "rb").read(); n = int.from_bytes(b[80:84], "little")
        tri = np.frombuffer(b[84:84 + 50 * n], dtype=np.dtype([("n", "<3f4"), ("v", "<9f4"), ("a", "<u2")]))["v"].reshape(-1, 3, 3).astype(float)
        return abs(np.einsum("ij,ij->i", tri[:, 0], np.cross(tri[:, 1], tri[:, 2])).sum()) / 6

if __name__ == "__main__":
    os.makedirs(os.path.join(WORK, "views"), exist_ok=True)
    if os.environ.get("PROMO_CHECK"):                # the packing path against the bass, every k-th frame
        k = int(os.environ["PROMO_CHECK"])
        idx = [i for i, s in enumerate(frames) if s.title in ("Plug and play", "Packs flat") and not s.card][::k]
        Ms = [frames[i].RD for i in idx]
        with Pool(os.cpu_count()) as p: vols = p.map(clash, Ms)
        for i, v in zip(idx, vols): print(f"frame {i:5d} {frames[i].title:14s} shared {v:9.2f} mm³", flush=True)
        sys.exit(0)
    stills = [int(v) for v in os.environ.get("PROMO_STILLS", "").split(",") if v]
    if stills: frames = [frames[min(i, len(frames) - 1)] for i in stills]
    need = {}
    for s in frames:
        for t in [s] + ([s.fade[0]] if s.fade else []):
            if not t.card: need[key_of(t)] = scad_job(t)
    if not stills: print(f"{len(frames)} frames, {len(frames) / FPS:.1f} s, {len(need)} views to draw", flush=True)
    with Pool(os.cpu_count()) as p:
        for i, _ in enumerate(p.imap_unordered(render, need.items())):
            if i % 50 == 0: print(f"  {i}/{len(need)}", flush=True)
    blank = Image.new("RGB", (W, VH), (248, 248, 248))
    def frame(s):
        img = blank if s.card else Image.open(os.path.join(WORK, "views", key_of(s) + ".png")).convert("RGB")
        out = overlay(img, s)
        if s.fade:
            o = s.fade[0]
            prev = overlay(blank if o.card else Image.open(os.path.join(WORK, "views", key_of(o) + ".png")).convert("RGB"), o)
            out = Image.blend(out, prev, s.fade[1])
        return out
    if stills:
        sheet = Image.new("RGB", (1280, 360 * ((len(frames) + 1) // 2)))
        for i, s in enumerate(frames): sheet.paste(frame(s).resize((640, 360)), ((i % 2) * 640, (i // 2) * 360))
        sheet.save(os.path.splitext(OUT)[0] + "_sheet.png"); sys.exit(0)
    fr = os.path.join(WORK, "frames"); shutil.rmtree(fr, ignore_errors=True); os.makedirs(fr)
    for i, s in enumerate(frames): frame(s).save(os.path.join(fr, f"{i:05d}.png"))
    subprocess.run(["gst-launch-1.0", "-q", "multifilesrc", f"location={fr}/%05d.png", "index=0",
                    f"caps=image/png,framerate={FPS}/1", "!", "pngdec", "!", "videoconvert", "!",
                    "vp9enc", "end-usage=cq", "cq-level=18", "cpu-used=4", "threads=4", "deadline=1", "!",
                    "webmmux", "!", "filesink", f"location={OUT}"], check=True)
    print(OUT, os.path.getsize(OUT) // 1024, "kB")
    if shutil.which("ffmpeg"):                      # and H.264/MP4 beside it, for players without VP9
        mp4 = os.path.splitext(OUT)[0] + ".mp4"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-framerate", str(FPS), "-i", f"{fr}/%05d.png",
                        "-c:v", "libx264", "-crf", "18", "-preset", "slow", "-pix_fmt", "yuv420p",
                        "-movflags", "+faststart", mp4], check=True)
        print(mp4, os.path.getsize(mp4) // 1024, "kB")
