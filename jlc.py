#!/usr/bin/env python3
"""JLCPCB upload packages from the boards' fab/ folders, into build/jlc/<board>/:
<board>_gerber.zip (copper, mask, silk, paste, outline, drill), <board>_bom.csv (one
designator each, no ranges: JLCPCB does not expand them) and <board>_cpl.csv (JLCPCB's
column names).

Rotation [2026-11-26, from JLCPCB's preview of the discant's Hall board]: KiCad gives a
bottom part's angle as seen from the top; JLCPCB shows the bottom seen from below, so the
angle is mirrored (-rot). 0402s at 45 and 135 deg stood 90 deg off in the preview without it.
ROT_FIX and POS_FIX add JLCPCB's own offsets per part, as the previews showed them.

    python3 jlc.py            all boards
"""
import os, re, csv, glob, zipfile

BOARDS = {"main_pcb": ("main_pcb/fab", "main_pcb"), "hall_discant": ("hall_pcb/discant/fab", "discant"),
          "hall_bass": ("hall_pcb/bass/fab", "bass"), "contact_panel": ("contact_pcb/fab", "contact")}
LAYERS = ["F_Cu", "B_Cu", "In1_Cu", "In2_Cu", "F_Mask", "B_Mask", "F_Silkscreen", "B_Silkscreen",
          "F_Paste", "B_Paste", "Edge_Cuts"]
# JLCPCB's own offsets, per part (its value, as in the BOM's Comment) and side: degrees added
# after the mirroring, as JLCPCB's preview showed them [2026-11-26]. Per part, not per
# footprint: the same SOT-23-6 (SRV05-4) sits right on the discant's bottom and 180 off on
# the main board's top, the Hall sensors' SOT-23 right and the BAT54C's 180 off. JLCPCB's
# angles count counter-clockwise, so a part shown 90 deg counter-clockwise off gets 270.
ROT_FIX = {
    ("ADS7128IRTER", "bottom"): 180,      # U1..U6, hall boards
    ("NAU7802SGI", "bottom"): 90,         # U7, discant [2026-11-26: 270 first, then seen 180 off by its pin 1]
    ("BAT54C", "top"): 180,               # D2, main board
    ("AO3401A", "top"): 180,              # Q2, Q3
    ("DMG1012T", "top"): 180,             # Q5 seen, Q4 the same part and angle
    ("USBLC6-2SC6", "top"): 270,          # U2, shown 90 counter-clockwise off
    ("SRV05-4", "top"): 180,              # U8 on the main board (right on the discant's bottom)
    ("TLV75518PDBVR", "top"): 180,        # U6
    ("TLV320DAC3100IRHBR", "top"): 270,   # U7, shown 90 counter-clockwise off
    ("LTST-S326KGJRKT", "top"): 270,      # D1: its flat (light) side faced down, it must face the board's edge at the wall (left, as J1)
}
# position offsets (mm, board x right, y up as in the pos file), per part and side: JLCPCB
# places these by their pads' middle, KiCad's footprints have their origin in the body's
# middle; the offset is the pads' middle from the origin, turned with the part [2026-11-26:
# the preview showed J1 too far left, U1 too far down; the amounts from the footprints. D1's
# pads lie 0 .. 0.65 off its origin, but shifted by 0.33 it stood too far right: none].
POS_FIX = {
    ("USB4105-GF-A", "top"): (1.3025, 0.0),          # J1: pads' middle 1.30 off along the plug's axis
    ("ESP32-S3-WROOM-1-N16R8", "top"): (0.0, 3.62),  # U1: no pads under the antenna's end
    ("LTST-S326KGJRKT", "top"): (-0.325, 0.0),       # D1: stood too far right with none, and with +0.33 [trial]
}


def expand(refs):
    out = []
    for p in refs.split(","):
        p = p.strip()
        m = re.fullmatch(r"([A-Za-z]+)(\d+)-([A-Za-z]+)?(\d+)", p)
        if m and m.group(3) in (None, m.group(1)):
            out += [f"{m.group(1)}{i}" for i in range(int(m.group(2)), int(m.group(4)) + 1)]
        elif p:
            out.append(p)
    return out


def main():
    for name, (fab, base) in BOARDS.items():
        out = f"build/jlc/{name}"
        os.makedirs(out, exist_ok=True)
        files = [f for f in glob.glob(f"{fab}/{base}-*") if any(f"-{k}." in f for k in LAYERS)]
        files += glob.glob(f"{fab}/{base}*.drl")
        with zipfile.ZipFile(f"{out}/{name}_gerber.zip", "w", zipfile.ZIP_DEFLATED) as z:
            for f in sorted(files):
                z.write(f, os.path.basename(f))
        pos = list(csv.reader(open(f"{fab}/{base}-pos.csv")))[1:]
        with open(f"{out}/{name}_cpl.csv", "w", newline="") as fo:
            w = csv.writer(fo)
            w.writerow(["Designator", "Val", "Package", "Mid X", "Mid Y", "Rotation", "Layer"])
            for ref, val, pkg, x, y, rot, side in pos:
                r = float(rot)
                if side == "bottom":
                    r = -r
                r = (r + ROT_FIX.get((val, side), 0)) % 360
                dx, dy = POS_FIX.get((val, side), (0, 0))
                w.writerow([ref, val, pkg, f"{float(x) + dx:.6f}mm", f"{float(y) + dy:.6f}mm", f"{r:g}",
                            "Top" if side == "top" else "Bottom"])
        refs = {p[0] for p in pos}
        rows = list(csv.reader(open(f"{fab}/{base}-bom.csv")))
        n = 0
        with open(f"{out}/{name}_bom.csv", "w", newline="") as fo:
            w = csv.writer(fo, quoting=csv.QUOTE_ALL)
            w.writerow(rows[0])
            for r in rows[1:]:
                d = expand(r[1])
                assert len(d) == int(r[4]), (name, r)
                missing = [x for x in d if x not in refs]
                assert not missing, (name, "not in the pos file", missing)
                n += len(d)
                w.writerow([r[0], ",".join(d), r[2], r[3], r[4]])
        print(f"{name}: {len(files)} gerber/drill files, {n} parts, {len(pos)} placements -> {out}/")


if __name__ == "__main__":
    main()
