#!/usr/bin/env python3
"""The page "Hauptplatine Lötpads": the main board's wire pads (P1 .. P15, through-hole)
and the jack's (P19 .. P21, SMD), zoomed, labelled and listed, with the whole board's top
and bottom for orientation. Everything is read from main_pcb.kicad_pcb (pads, places,
nets, values; kicad-cli for the pictures) and drc.json (the starved thermals), so the
page follows the board.

usage: pads_page.py [OUT.html]   (default ../build/main_pcb/pads.html); needs kicad-cli.
Run by build.sh after routing, and by make -C main_pcb pads."""
import os, re, sys, json, html, subprocess, tempfile, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
PCB = os.path.join(HERE, "main_pcb.kicad_pcb")
OUT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "../build/main_pcb/pads.html"))

# --- the board --------------------------------------------------------------------------
src = open(PCB).read()
pads = {}                                   # n: dict(x, y, net, value, tht)
for f in re.split(r"\n\t\(footprint ", src)[1:]:
    ref = re.search(r'\(property "Reference" "P(\d+)"', f)
    if not ref: continue
    at = re.search(r"\n\t\t\(at ([-\d.]+) ([-\d.]+)", f)
    pads[int(ref.group(1))] = dict(x=float(at.group(1)), y=float(at.group(2)),
                                   net=re.search(r'\(net \d+ "([^"]*)"\)', f).group(1),
                                   value=re.search(r'\(property "Value" "([^"]*)"', f).group(1),
                                   tht="THTPad" in f.split("\n", 1)[0])
wire = sorted(n for n in pads if pads[n]["tht"])
jack = sorted(n for n in pads if pads[n]["value"].startswith("jack"))
if not wire: raise SystemExit("pads_page: no wire pads P.. in " + PCB)
edge_y = max(float(m.group(2)) for blk in re.findall(r"\(gr_\w+.*?\(layer \"Edge\.Cuts\"\)", src, re.S)
             for m in re.finditer(r"\((?:start|end|mid) ([-\d.]+) ([-\d.]+)\)", blk))

def export(layers, out):
    r = subprocess.run(["kicad-cli", "pcb", "export", "svg", "--layers", layers, "--mode-single", "--exclude-drawing-sheet",
                        "--fit-page-to-board", "-o", out, PCB], capture_output=True, text=True)
    if not os.path.exists(out): raise SystemExit("pads_page: kicad-cli: " + r.stderr[-500:])
    return open(out).read()
with tempfile.TemporaryDirectory() as t:
    f_svg = export("F.Cu,F.Silkscreen,Edge.Cuts", os.path.join(t, "f.svg"))
    b_svg = export("B.Cu,B.Silkscreen,Edge.Cuts", os.path.join(t, "b.svg"))
vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', f_svg).group(1).split()]

# where the SVG puts the board's origin: the offset that lands the most wire pads on the
# exported pads' circles (kicad-cli's fit-to-board margin is not stated)
circ = [(float(a), float(b)) for a, b in re.findall(r'<circle cx="([-\d.]+)" cy="([-\d.]+)" r="0\.75', f_svg)]
best = None
for cx, cy in circ:
    ox, oy = pads[wire[0]]["x"] - cx, pads[wire[0]]["y"] - cy
    hit = sum(any(abs(pads[n]["x"] - ox - a) < 0.02 and abs(pads[n]["y"] - oy - b) < 0.02 for a, b in circ) for n in wire)
    if best is None or hit > best[0]: best = (hit, ox, oy)
if best[0] < len(wire): raise SystemExit(f"pads_page: only {best[0]} of {len(wire)} pads found in the SVG")
OX, OY = best[1], best[2]
X = lambda n: pads[n]["x"] - OX
Y = lambda n: pads[n]["y"] - OY

def inner(s):
    s = s[s.index("<g "):s.rindex("</svg>")]
    s = re.sub(r"<title>.*?</title>|<desc>.*?</desc>", "", s, flags=re.S)
    for a, b in [("#C83434", "var(--cu)"), ("#4D7FC4", "var(--cu)"), ("#F2EDA1", "var(--silk)"), ("#02FFEE", "var(--silk)"),
                 ("#FFFFFF", "var(--hole)"), ("#D0D2CD", "var(--edge)"), ("#000000", "var(--edge)")]:
        s = s.replace(a, b)
    return s

# --- names, groups, colours -----------------------------------------------------------------
GROUPS = [("c", "contacts", "Kontakte (Diskant)"), ("k", "bass keys", "Bass-Tastenplatine"),
          ("b", ("battery", "NTC"), "Akku"), ("j", "jack", "Klinke")]
def group(n):
    for g, p, _ in GROUPS:
        if pads[n]["value"].startswith(p): return g
    return "b"
DE = [("contacts ", "Kontakte "), ("bass keys ", "Bass-Tasten "), ("battery -", "Akku −"), ("battery +", "Akku +"),
      ("battery NTC", "Akku-NTC"), ("NTC return", "NTC-Rückleitung"), ("jack tip (left)", "Klinke Spitze (links)"),
      ("jack ring (right)", "Klinke Ring (rechts)"), ("jack sleeve", "Klinke Hülse"), ("3.3 V", "3,3 V")]
def deu(v):
    for a, b in DE: v = v.replace(a, b)
    return v
def short(n):
    v, net = pads[n]["value"], pads[n]["net"]
    for k, s in [("battery -", "BAT−"), ("battery +", "BAT+"), ("NTC return", "NTC⏚"), ("battery NTC", "TS"),
                 ("jack tip", "Spitze L"), ("jack ring", "Ring R"), ("jack sleeve", "Hülse ⏚")]:
        if v.startswith(k): return s
    return v.split()[-1] if v.split()[-1] in ("INT", "SDA", "SCL", "GND", "DET") else ("3V3" if "3.3" in v else net)
COL = [(r"^(\+3V3|BATP|EAR_R)", "rot"), (r"^GND", "schwarz"), (r"^SDA", "blau"), (r"^SCL", "gelb"), (r"^INT", "grün"),
       (r"^(DET|EAR_L)", "weiß"), (r"^TS", "orange")]
def colour(n):
    if pads[n]["value"].startswith("NTC return"): return "braun"
    for p, c in COL:
        if re.match(p, pads[n]["net"]): return c
    return ""

# --- the zoomed picture's labels ----------------------------------------------------------
rows = sorted({round(Y(n), 2) for n in wire})            # SVG y of the two rows: upper first
lab = []
for n in wire:
    up = round(Y(n), 2) == rows[0]
    ty = Y(n) - 1.25 if up else Y(n) + 1.75
    lab.append(f'<text x="{X(n):.3f}" y="{ty:.3f}" class="pl">P{n}</text>'
               f'<text x="{X(n):.3f}" y="{ty + (-0.62 if up else 0.62):.3f}" class="pn g{group(n)}">{html.escape(short(n))}</text>')
edge = edge_y - OY
for g, _, name in GROUPS[:3]:
    ns = [n for n in wire if group(n) == g]
    if not ns: continue
    x0, x1 = min(X(n) for n in ns) - 0.6, max(X(n) for n in ns) + 0.6
    lab.append(f'<rect x="{x0:.3f}" y="{edge + 2.05:.3f}" width="{x1 - x0:.3f}" height="0.28" class="b{g}"/>'
               f'<text x="{(x0 + x1) / 2:.3f}" y="{edge + 3.0:.3f}" class="gt">{name}</text>')
jx = sum(X(n) for n in jack) / len(jack) if jack else 0
for n in jack:                                           # labels away from the jack pads' middle
    side = 1 if X(n) >= jx else -1; tx = X(n) + side * 0.85; anc = "start" if side > 0 else "end"
    lab.append(f'<text x="{tx:.3f}" y="{Y(n) + 0.15:.3f}" class="pl" style="text-anchor:{anc}">P{n}</text>'
               f'<text x="{tx + side * 1.25:.3f}" y="{Y(n) + 0.17:.3f}" class="pn gj" style="text-anchor:{anc}">{html.escape(short(n))}</text>')
if jack:
    lab.append(f'<text x="{jx:.3f}" y="{min(Y(n) for n in jack) - 1.0:.3f}" class="gt">Klinke (Lötfahnen)</text>')
allp = wire + jack
x0 = min(X(n) for n in allp) - 2.2; x1 = max(X(n) for n in allp) + 5.0
y0 = min(Y(n) for n in allp) - 2.6; y1 = max(edge + 3.6, max(Y(n) for n in allp) + 2.6)
lab.append(f'<line x1="{x0 + 0.4:.3f}" y1="{edge:.3f}" x2="{x1 - 0.3:.3f}" y2="{edge:.3f}" class="edgeln"/>'
           f'<text x="{x1 - 0.5:.3f}" y="{edge - 0.35:.3f}" class="et" text-anchor="end">Platinenkante</text>')
zoom_vb = f"{x0:.2f} {y0:.2f} {x1 - x0:.2f} {y1 - y0:.2f}"
whole_vb = " ".join(f"{v:.1f}" for v in vb)
frame = f'<rect x="{x0:.2f}" y="{y0:.2f}" width="{x1 - x0:.2f}" height="{y1 - y0:.2f}" fill="none" stroke="var(--gc)" stroke-width="0.25"/>'

# --- the notes from the DRC -----------------------------------------------------------------
gnd = [n for n in wire if pads[n]["net"] == "GND"]
starved = set()
try:
    for v in json.load(open(os.path.join(HERE, "drc.json"))).get("violations", []):
        if v["type"] == "starved_thermal":
            for it in v["items"]:
                m = re.search(r"of P(\d+)\b", it["description"])
                if m: starved.add(int(m.group(1)))
except (OSError, ValueError): pass
pl = lambda ns: ", ".join(f"P{n}" for n in ns[:-1]) + (" und " if len(ns) > 1 else "") + (f"P{ns[-1]}" if ns else "")
note = (f"{pl(gnd)} hängen an der Massefläche, außen nur über Thermalstege. Beim Löten brauchen sie eine heißere Spitze"
        + (f"; der DRC meldet {pl(sorted(starved))} als „starved thermal“." if starved else "."))

rowsy = {rows[0]: "oben", rows[-1]: "unten"}
table = "".join(
    f'<tr><td class="m">P{n}</td><td class="m">{html.escape(pads[n]["net"])}</td><td><span class="dot b{group(n)}"></span>{html.escape(deu(pads[n]["value"]))}</td>'
    f'<td>{colour(n)}</td><td>{("THT, Reihe " + rowsy[round(Y(n), 2)]) if pads[n]["tht"] else "SMD unter der Lötfahne"}</td></tr>'
    for n in allp)

stand = datetime.date.today().strftime("%d.%m.%Y")
rev = subprocess.run(["git", "log", "-1", "--format=%h", "--", "main_pcb.kicad_pcb"], capture_output=True, text=True, cwd=HERE).stdout.strip()
page = f'''<title>Hauptplatine Lötpads</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;600&display=swap">
<style>
/* Layout: one column, the zoomed pad rows first, the whole board as context below */
:root {{
  --bg:#f3f5f2; --fg:#1d2420; --muted:#5b6660; --panel:#0f3b2a; --cu:#c98a3d; --silk:#e9ecdf; --hole:#0b2419; --edge:#9fb3a7;
  --gc:#3a86c8; --gk:#c0662a; --gb:#b83a52; --gj:#7a5bc0; --line:#cfd6d0;
  --sans:"IBM Plex Sans", system-ui, sans-serif; --mono:"IBM Plex Mono", ui-monospace, monospace;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{
  --bg:#121815; --fg:#e3e9e5; --muted:#97a39c; --panel:#0c3022; --line:#2a352f; --gc:#6aaee6; --gk:#e08a4e; --gb:#e06a80; --gj:#a98ae6; color-scheme:dark }} }}
:root[data-theme="dark"] {{ --bg:#121815; --fg:#e3e9e5; --muted:#97a39c; --panel:#0c3022; --line:#2a352f; --gc:#6aaee6; --gk:#e08a4e; --gb:#e06a80; --gj:#a98ae6; color-scheme:dark }}
body {{ background:var(--bg); color:var(--fg); font:15px/1.5 var(--sans);
  padding-left:max(16px, env(safe-area-inset-left, 0px)); padding-right:max(16px, env(safe-area-inset-right, 0px)); padding-block:20px 32px }}
main {{ max-width:960px; margin:0 auto; display:grid; gap:18px }}
h1 {{ margin:0; font-size:clamp(22px,4vw,28px); text-wrap:balance }}
h2 {{ margin:0; font-size:15px; letter-spacing:.06em; text-transform:uppercase; color:var(--muted) }}
p {{ margin:0; max-width:68ch }}
.board {{ background:var(--panel); border-radius:8px; padding:10px; overflow-x:auto }}
.board svg {{ display:block; width:100%; height:auto; min-width:520px }}
.pl {{ font:600 0.42px var(--mono); fill:var(--silk); text-anchor:middle }}
.pn {{ font:600 0.5px var(--mono); text-anchor:middle }}
.gc, .bc {{ fill:var(--gc) }} .gk, .bk {{ fill:var(--gk) }} .gb, .bb {{ fill:var(--gb) }} .gj, .bj {{ fill:var(--gj) }}
span.bc {{ background:var(--gc) }} span.bk {{ background:var(--gk) }} span.bb {{ background:var(--gb) }} span.bj {{ background:var(--gj) }}
.gt {{ font:0.55px var(--sans); fill:var(--silk); text-anchor:middle }}
.edgeln {{ stroke:var(--edge); stroke-width:0.06; stroke-dasharray:0.3 0.2 }}
.et {{ font:0.42px var(--sans); fill:var(--edge) }}
table {{ border-collapse:collapse; width:100%; font-variant-numeric:tabular-nums }}
th, td {{ text-align:left; padding:6px 8px; border-bottom:1px solid var(--line); vertical-align:top }}
th {{ font-size:13px; color:var(--muted); font-weight:600 }}
td.m {{ font-family:var(--mono) }}
.tw {{ overflow-x:auto }}
.dot {{ display:inline-block; width:10px; height:10px; border-radius:50%; margin-right:6px; vertical-align:-1px }}
.two {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:18px }}
.two > * {{ min-width:0; display:grid; gap:8px }}
.two .board svg {{ min-width:0 }}
.foot {{ color:var(--muted); font-size:13px }}
</style>
<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs><g id="front">{inner(f_svg)}</g><g id="back">{inner(b_svg)}</g></defs></svg>
<main>
  <h1>Hauptplatine: die Lötpads für die Drähte</h1>
  <p>{len(wire)} durchkontaktierte Pads für die Drähte (Ring ⌀1,5, Bohrung ⌀0,7), versetzt in zwei Reihen, und {len(jack)} SMD-Pads 1,0 × 1,0 für die Klinke, direkt unter ihren Lötfahnen. Der Draht kommt von der Bauteilseite, wird oben gelötet und unten bündig abgeschnitten. Die Unterkante der Platine liegt unten im Bass. Die Reihenfolge ist so gewählt, dass sich die Drähte beim Auffächern nicht kreuzen.</p>
  <div class="board" role="img" aria-label="Oberseite der Hauptplatine, vergrößert auf die Drahtpads und die Klinken-Pads">
    <svg viewBox="{zoom_vb}"><use href="#front"/>{"".join(lab)}</svg>
  </div>
  <div class="two">
    <section><h2>Ganze Platine, Oberseite</h2><div class="board"><svg viewBox="{whole_vb}"><use href="#front"/>{frame}</svg></div></section>
    <section><h2>Unterseite, von oben durchgesehen</h2><div class="board"><svg viewBox="{whole_vb}"><use href="#back"/>{frame}</svg></div></section>
  </div>
  <section style="display:grid;gap:8px">
    <h2>Belegung</h2>
    <div class="tw"><table>
      <thead><tr><th>Pad</th><th>Netz</th><th>Draht</th><th>Farbe</th><th>Art</th></tr></thead>
      <tbody>{table}</tbody></table></div>
    <p style="color:var(--muted)">{html.escape(note)}</p>
  </section>
  <p class="foot">Erzeugt am {stand} von <code>main_pcb/pads_page.py</code> aus <code>main_pcb.kicad_pcb</code> (Stand {html.escape(rev or "?")}) und <code>drc.json</code>.</p>
</main>
'''
os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, "w").write(page)
print(f"pads_page: {OUT} ({len(page) // 1024} kB, {len(wire)} wire pads, {len(jack)} jack pads)")
