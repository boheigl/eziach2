#!/usr/bin/env python3
"""Renders the Hall-sensor key's build-and-assembly video: the parts in a row, then
step by step into the key, then the key pressed in section. OpenSCAD draws each
frame (key_video.scad, the parts of ../key.scad), PIL adds captions and the parts
list, GStreamer encodes VP9/WebM (no H.264 encoder on this machine).

usage: key_video.py [OUT.webm]   (default ../../build/switch_hall/key_assembly.webm)
       KEY_VIDEO_FPS=10 for a quick draft; KEY_VIDEO_STILLS=40,200,... only those
       frames, on a contact sheet next to OUT"""
import os, re, sys, json, math, hashlib, shutil, subprocess
from multiprocessing import Pool
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "../../build/switch_hall/key_assembly.webm"))
WORK = os.path.join(os.path.dirname(OUT), "key_video_frames")
FPS = int(os.environ.get("KEY_VIDEO_FPS", 25))
W, H, VW, VH, TOP = 1280, 720, 900, 600, 120   # frame; the 3D view, below the captions, left of the parts list
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# the key's heights, from the model itself
import tempfile
with tempfile.TemporaryDirectory() as t:
    r = subprocess.run(["openscad", "-o", os.path.join(t, "g.echo"), os.path.join(HERE, "geom.scad")],
                       capture_output=True, text=True)
    m = re.search(r"GEOM = (\[.*\])", open(os.path.join(t, "g.echo")).read() if os.path.exists(os.path.join(t, "g.echo")) else "")
if not m: sys.exit("no GEOM echo from geom.scad:\n" + r.stderr[-500:])
G = dict(json.loads(m.group(1)))

# parts in the order they are put together: name, label, what it is, its lowest z at rest
PARTS = [
    ("magnet",  "Magnet",            "NdFeB d3 x 1.5, axial",           G["z_cb"]),
    ("collar",  "Collar",            "printed, carries magnet + washer", G["z_cb"]),
    ("rod",     "Rod",               "stainless d3 h6",                  G["z_cb"] + G["mag_l"]),
    ("stop",    "Stop washer",       "1 mm silicone, upper stop",        G["z_cb"] + G["collar_h"]),
    ("bushing", "Sleeve bearing",    "sintered bronze d3 x D5 x 4",      G["z_bush0"]),
    ("tube",    "Cover with tube",   "printed, 2.4 mm plate",            G["pcb_t"] / 2),
    ("board",   "Board + Hall sensor", "DRV5055 on the underside",       G["z_bot"] - G["sens_h"]),
    ("spring",  "Spring",            "d8 x 0.45, 12 coils",               G["z_seat"]),
    ("oring",   "O-ring",            "4 x 1.5 silicone, lower stop",     G["z_cu"] + G["oring_seat"] - G["oring_cs"]),
    ("cap",     "Cap with skirt",    "printed, hides the spring",        G["z_cu"] - G["skirt_l"]),
]
NAMES = [p[0] for p in PARTS] + ["sensor"]
WIDTH = {"magnet": 3, "collar": 4.4, "rod": 3, "stop": 4.5, "bushing": 5, "tube": 20, "board": 20,
         "spring": 8, "oring": 7, "cap": 15}
COLOR = {"board": (46, 139, 87), "sensor": (0, 0, 0), "tube": (190, 190, 190), "bushing": (205, 133, 63),
         "collar": (225, 225, 205), "magnet": (112, 128, 144), "rod": (170, 170, 170), "stop": (178, 34, 34),
         "spring": (176, 196, 222), "oring": (105, 105, 105), "cap": (225, 225, 205)}

# the row: every part standing on z = 0, 4 mm apart
LINE = {}
x = 0
for n, *_, zb in PARTS:
    LINE[n] = [x + WIDTH[n] / 2, -zb]
    x += WIDTH[n] + 4
row_w = x - 4
for n in LINE: LINE[n][0] -= row_w / 2
LINE["sensor"] = LINE["board"]

def ease(u): u = min(max(u, 0), 1); return u * u * (3 - 2 * u)
def lerp(a, b, u): return a + (b - a) * u
def lerpv(a, b, u): return [lerp(p, q, u) for p, q in zip(a, b)]

# ---------------------------------------------------------------- the state per frame
class State:
    def __init__(s):
        s.pos = {n: [0.0, 0.0] for n in NAMES}       # dx, dz
        s.shown = {n: True for n in NAMES}
        s.cut = False; s.T = 0.0; s.labels = False
        s.cam = [0, 8, 62, 25, 72]                    # centre x, centre z, tilt, turn, distance
        s.title = ""; s.text = ""; s.hl = set(); s.fade = None   # fade: (other state, weight)
    def copy(s):
        c = State(); c.pos = {k: list(v) for k, v in s.pos.items()}; c.shown = dict(s.shown)
        c.cut, c.T, c.labels, c.cam = s.cut, s.T, s.labels, list(s.cam)
        c.title, c.text, c.hl = s.title, s.text, set(s.hl); return c

frames = []
st = State()
def hold(sec):
    for _ in range(int(round(sec * FPS))): frames.append(st.copy())
def anim(sec, f):
    n = int(round(sec * FPS))
    for k in range(n):
        f(ease((k + 1) / n)); frames.append(st.copy())
def move(parts, to, via=None, cam=None):
    """parts from where they are to `to` (dx, dz), through `via` (dz only, at the
    target's dx) for the last bit: in from above or below"""
    a = {n: list(st.pos[n]) for n in parts}; c0 = list(st.cam)
    def f(u):
        for n in parts:
            if via is None:
                st.pos[n] = lerpv(a[n], to, u)
            else:
                mid = [to[0], via]
                st.pos[n] = lerpv(a[n], mid, min(u / 0.6, 1)) if u < 0.6 else lerpv(mid, to, (u - 0.6) / 0.4)
        if cam: st.cam = lerpv(c0, cam, u)
    return f
def cam_to(cam):
    c0 = list(st.cam)
    return lambda u: st.cam.__setitem__(slice(None), lerpv(c0, cam, u))

# 1 the finished key, turning
st.title = "Hall-effect key"; st.text = "Build and assembly of one key"
anim(4, lambda u: st.cam.__setitem__(3, lerp(-35, 25, u)))
# 2 cut open
st.title = "Section"; st.text = "Cut through the key's axis"
a = st.copy(); b = st.copy(); b.cut = True
for k in range(int(FPS * 1.0)):
    f = b.copy(); f.fade = (a, 1 - (k + 1) / (FPS * 1.0)); frames.append(f)
st.cut = True; hold(1.5)
# 3 the parts in a row
st.title = "The parts"; st.text = "Ten parts; the board carries the sensor"
row_cam = [0, 3, 76, 0, 240]
def explode(u):
    for n in NAMES: st.pos[n] = lerpv([0, 0], LINE[n], u)
    st.cam = lerpv([0, 8, 62, 25, 72], row_cam, u)
anim(3, explode); st.labels = True; hold(4); st.labels = False

# 4 assembly, step by step, in section: each part shows up in its step, near its place
def appear(parts, at, sec=0.4):
    """fade the parts in at `at` (dx, dz)"""
    a = st.copy()
    for n in parts: st.shown[n] = True; st.pos[n] = list(at)
    b = st.copy(); k_ = max(1, int(round(sec * FPS)))
    for k in range(k_):
        f = b.copy(); f.fade = (a, 1 - (k + 1) / k_); frames.append(f)
def step(i, title, text):
    st.title = f"Step {i}"; st.text = title + ("\n" + text if text else "")
# from the row to an empty stage with the collar alone
a_ = st.copy()
for n in NAMES: st.shown[n] = False; st.pos[n] = [0, 0]
st.shown["collar"] = True; st.cam = [0, 9, 62, 20, 68]
step(1, "Press the magnet into the collar", "from below, into its pocket"); st.hl = {"collar", "magnet"}
b_ = st.copy()
for k in range(int(FPS * 0.8)):
    f = b_.copy(); f.fade = (a_, 1 - (k + 1) / (FPS * 0.8)); frames.append(f)
hold(0.5)
appear(["magnet"], [0, -8]); anim(1.5, move(["magnet"], [0, 0])); hold(1)
step(2, "Glue the rod into the collar", "from above"); st.hl = {"rod"}
appear(["rod"], [0, 12]); anim(1.5, move(["rod"], [0, 0])); hold(1)
step(3, "Push the stop washer over the rod", "it sits on the collar: the upper stop"); st.hl = {"stop"}
appear(["stop"], [0, 12]); anim(1.5, move(["stop"], [0, 0])); hold(1)
step(4, "Press the sleeve bearing into the tube", "from below, against the shoulder"); st.hl = {"tube", "bushing"}
anim(1.2, cam_to([0, 16, 62, 20, 105]))
appear(["tube"], [0, 22]); appear(["bushing"], [0, 12]); anim(1.5, move(["bushing"], [0, 22])); hold(1)
step(5, "Put the cover over the plunger", "the rod runs in the bearing, the collar keeps\nthe plunger captive"); st.hl = {"tube", "bushing", "collar", "rod"}
anim(2.5, move(["tube", "bushing"], [0, 0], cam=[0, 6, 64, 20, 85])); hold(1)
step(6, "Screw the cover onto the board", "the Hall sensor sits on the underside, on the key's axis"); st.hl = {"board", "sensor"}
appear(["board", "sensor"], [0, -12]); anim(2, move(["board", "sensor"], [0, 0])); hold(1)
step(7, "Drop the spring over the tube", "it stands on the cover's seat"); st.hl = {"spring"}
appear(["spring"], [0, 16]); anim(2, move(["spring"], [0, 0])); hold(1)
step(8, "Lay the O-ring into the cap", "into the counterbore: the lower stop"); st.hl = {"cap", "oring"}
anim(1.2, cam_to([0, 17, 62, 20, 120]))
appear(["cap"], [0, 20]); appear(["oring"], [0, 10]); anim(1.5, move(["oring"], [0, 20])); hold(1)
step(9, "Press the cap onto the rod", "the skirt hides the spring"); st.hl = {"cap", "oring"}
anim(2.5, move(["cap", "oring"], [0, 0], cam=[0, 8, 64, 20, 76])); hold(1.5)
st.hl = set()

# 5 working
st.title = "Pressed"; st.text = "3 mm travel: the magnet comes 3 mm closer to the sensor\n7.6 mT at rest, 39.9 mT at the bottom; 119 g -> 149 g"
anim(1.0, cam_to([0, 7, 74, 10, 86]))
for _ in range(2):
    anim(1.2, lambda u: setattr(st, "T", G["stroke"] * u)); hold(0.6)
    anim(1.0, lambda u: setattr(st, "T", G["stroke"] * (1 - u))); hold(0.5)
st.title = "Stops"; st.text = "Up: the washer on the bearing's lower face\nDown: the O-ring on the tube's top - both soft, no click"
hold(3)
# 6 closed again, turning
st.title = "Hall-effect key"; st.text = "Nothing moving touches the board"
a = st.copy(); b = st.copy(); b.cut = False
for k in range(int(FPS * 1.0)):
    f = b.copy(); f.fade = (a, 1 - (k + 1) / (FPS * 1.0)); frames.append(f)
st.cut = False
c0 = list(st.cam)
anim(4, lambda u: st.cam.__setitem__(slice(None), [0, lerp(c0[1], 8, u), lerp(c0[2], 62, u), lerp(10, 370, u), lerp(c0[4], 80, u)]))
hold(1)

# ---------------------------------------------------------------- render
def scad_args(s):
    P = [[n, int(s.shown[n]), round(s.pos[n][0], 3), round(s.pos[n][1], 3)] for n in NAMES]
    L = [[round(LINE[n][0], 3), -3.5, str(i + 1)] for i, (n, *_r) in enumerate(PARTS)] if s.labels else []
    cx, cz, tilt, turn, dist = s.cam
    return ["-D", "P=" + json.dumps(P), "-D", f"cut={'true' if s.cut else 'false'}", "-D", f"T={s.T:.4f}",
            "-D", "L=" + json.dumps(L), f"--camera={cx:.3f},0,{cz:.3f},{tilt:.2f},0,{turn:.2f},{dist:.2f}"]

def key_of(s): return hashlib.sha1(json.dumps(scad_args(s)).encode()).hexdigest()[:16]

def render(args):
    k, a = args
    out = os.path.join(WORK, "views", k + ".png")
    if os.path.exists(out): return
    r = subprocess.run(["openscad", "-q", "--backend=manifold", "--render", "-o", out + ".tmp.png",
                        f"--imgsize={VW},{VH}", "--projection=p", "--colorscheme=Tomorrow", *a,
                        os.path.join(HERE, "key_video.scad")], capture_output=True, text=True)
    if r.returncode or not os.path.exists(out + ".tmp.png"): raise RuntimeError(r.stderr[-800:])
    os.replace(out + ".tmp.png", out)

def overlay(img, s):
    c = Image.new("RGB", (W, H), (248, 248, 248)); c.paste(img, (0, TOP))
    d = ImageDraw.Draw(c)
    f_t, f_x = ImageFont.truetype(FONT_B, 34), ImageFont.truetype(FONT, 21)
    f_n, f_s = ImageFont.truetype(FONT_B, 17), ImageFont.truetype(FONT, 13)
    d.text((32, 16), s.title, font=f_t, fill=(30, 30, 30))
    d.multiline_text((32, 60), s.text, font=f_x, fill=(70, 70, 70), spacing=6)
    # the parts list
    x0 = VW + 8
    d.rectangle([x0, 0, W, H], fill=(236, 236, 232))
    d.text((x0 + 16, 22), "Parts", font=ImageFont.truetype(FONT_B, 22), fill=(30, 30, 30))
    for i, (n, label, what, _z) in enumerate(PARTS):
        y = 66 + i * 63
        if n in s.hl: d.rounded_rectangle([x0 + 8, y - 6, W - 10, y + 50], 8, fill=(255, 236, 170))
        d.rounded_rectangle([x0 + 16, y + 2, x0 + 40, y + 26], 5, fill=COLOR[n], outline=(90, 90, 90))
        d.text((x0 + 28, y + 14), str(i + 1), font=f_s, anchor="mm", fill=(255, 255, 255) if sum(COLOR[n]) < 400 else (0, 0, 0))
        d.text((x0 + 50, y), label, font=f_n, fill=(30, 30, 30))
        d.text((x0 + 50, y + 24), what, font=f_s, fill=(90, 90, 90))
    return c

if __name__ == "__main__":
    os.makedirs(os.path.join(WORK, "views"), exist_ok=True)
    stills = [int(v) for v in os.environ.get("KEY_VIDEO_STILLS", "").split(",") if v]
    if stills: frames = [frames[min(i, len(frames) - 1)] for i in stills]
    need = {}
    for s in frames:
        for t in [s] + ([s.fade[0]] if s.fade else []): need[key_of(t)] = scad_args(t)
    if not stills: print(f"{len(frames)} frames, {len(frames) / FPS:.1f} s, {len(need)} views to draw", flush=True)
    with Pool(os.cpu_count()) as p:
        for i, _ in enumerate(p.imap_unordered(render, need.items())):
            if i % 50 == 0: print(f"  {i}/{len(need)}", flush=True)
    if stills:
        cols = 2; sheet = Image.new("RGB", (640 * cols, 360 * ((len(frames) + 1) // cols)))
        for i, s in enumerate(frames):
            img = Image.open(os.path.join(WORK, "views", key_of(s) + ".png")).convert("RGB")
            sheet.paste(overlay(img, s).resize((640, 360)), ((i % cols) * 640, (i // cols) * 360))
        sheet.save(os.path.splitext(OUT)[0] + "_sheet.png"); sys.exit(0)
    fr = os.path.join(WORK, "frames"); shutil.rmtree(fr, ignore_errors=True); os.makedirs(fr)
    for i, s in enumerate(frames):
        img = Image.open(os.path.join(WORK, "views", key_of(s) + ".png")).convert("RGB")
        if s.fade:
            img = Image.blend(img, Image.open(os.path.join(WORK, "views", key_of(s.fade[0]) + ".png")).convert("RGB"), s.fade[1])
        overlay(img, s).save(os.path.join(fr, f"{i:05d}.png"))
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
