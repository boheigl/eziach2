# Key prototype — 2 rows of 4

Eight Hall keys (`../switch_hall/`) in the discant's arrangement, on a stand-in for the
board [given 2026-11-17: 2 rows of 4, the discant's layout, no PCB]. To try the keys'
feel, stops and spring, the reach between two rows, and the cover screws' hold, before
the whole discant is printed. Tags as in `../discant/spec.md`.

## Layout [given: as the discant]

- Rows as on the discant (`../discant/hall.scad`): row 1 moved by (10, 16, 3) mm against
  row 0, 20 mm pitch. Row 0 at x = −30 … 30, row 1 at x = −20 … 40.
- Board, tray and cover lie in the slope plane, tilted up by atan(3/16) = 10.62°; the
  keys' axes are vertical, so every key part sits exactly as on the discant. The tray's
  bottom is parallel to the slope [given 2026-11-17]: on a table the keys lean back by
  it, as the discant's do.

## Mounting [given 2026-11-17: as the discant, with the tray]

The stack is the discant's (`../discant/spec.md` §2, §3), so the screws hold as they
will there:

- **Board stand-in**, 100 × 33.7 mm, 1.67 thick, no parts: ⌀2.2 holes at the screws.
  Printed (`board.stl`) or cut from a 1.6 mm blank PCB. Its top is the board's top, so the
  collar stops 0.3 above it at the bottom.
- **Base = the discant's tray**: a rim 0.3 clear of the board, 1.2 thick, up to its top;
  under the board a 0.8 mm ledge along its edge and a ⌀4.4 boss at every screw, from the
  floor up to the board's underside; the floor's top 3.32 and the bottom 4.52 under the
  board's top, as the discant's (there set by the board's parts). 103 × 36.7 mm.
- **Cover** as the discant's: a 2.4 mm plate over board and rim with each key's tube and
  shroud (`key.scad` `tube_body()` / `tube_cut()`). No thumb bar.
- Five **M2 × 6 countersunk brass screws** (DIN 965), the four corners and one between
  the rows, flush in 90° countersinks, through cover (2.4) and board (1.67) into ⌀1.7
  pilots in the bosses, stopping 0.4 above the tray's bottom: **1.93 mm of thread**, as
  on the discant. Screws per area about as the discant's (one per 680 mm² of board,
  there 640).

Checked by solid intersection (2026-11-17; controls overlapping): the keys, at rest and
pressed, touch neither cover, board nor base; base, board and cover meet only on their
faces. A section through a screw shows countersink, clearance, boss and pilot as on the
discant.

## To print and buy

| Part | Count | |
|---|---|---|
| `base.stl` (the tray) | 1 | printed (below) |
| `board.stl` | 1 | printed, or a 1.6 mm blank PCB cut to 100 × 33.7 with the five ⌀2.2 holes |
| `cover.stl` | 1 | printed |
| `cap.stl` (cap with skirt) | 8 | printed |
| `collar.stl` | 8 | printed |
| Bushing, sintered bronze, d3 × D5 × 4 | 8 | stock |
| Rod: dowel pin ISO 2338 ⌀3 h8 × 14, stainless A1 | 8 | stock |
| Spring Misumi UY8-25 | 8 | stock |
| O-ring 4 × 1.5 | 8 | stock |
| Stop washer ⌀4.5 / ⌀2.5, 1 mm silicone or PU | 8 | punched |
| Magnet ⌀3 × 1.5 N52 | 8 | optional: nothing senses it; it adds 0.08 g |
| Countersunk screw M2 × 6, brass, DIN 965 | 5 | stock |
| Slow 2-component epoxy | | as `../switch_hall/spec.md` §2 |

Assembly as `../switch_hall/spec.md` §2: the keys go into the cover; the board into the
tray, the cover onto it, then the screws (tightening as `../discant/spec.md` §3: stop
when the head is flush).

**To try on it:** the screws' hold (pull-out, about 100 … 200 N per screw estimated),
how far they can be tightened before the thread in the boss strips, and reopening (turn
back until the screw drops into its thread).

## Printing [given 2026-11-17: Bambu Lab X2D, PETG]

`make` writes `build/key_proto/plate.3mf`, every printed part already lying as printed and
arranged on the X2D's plate (main nozzle, 256 × 256), and `fit_test.3mf`, one key's piece
of cover with one cap and one collar. Any slicer opens them; Bambu Studio is not needed
for the plan, only for the last step (an X2D profile is in OrcaSlicer's newer builds too).

| Part | Lies | Why |
|---|---|---|
| tray | bottom down (the slope undone) | open top, ledge and bosses rise from the floor: no overhang |
| board | flat | |
| cover | underside down, tubes up | the flat plate on the bed; the tubes lean 10.6° (the keys stand vertical on the slope), shrouds and countersinks open upwards; no support |
| cap | top down | skirt, rod socket and O-ring seat open upwards |
| collar | magnet pocket up | the first layers (elephant foot) land on the rod's end, which is glued, not on the magnet's press fit |

Settings [chosen; values the printer's profile does not fix]:

- **Profile:** the slicer's system PETG profile for the X2D, 0.4 mm nozzle; temperatures,
  cooling and speeds from it. Textured PEI plate (PETG bonds too hard to smooth PEI).
- **Layers 0.2 mm** for the whole plate [given 2026-11-20, was 0.16]: the board's 1.67
  comes out 1.6 either way (8 layers; the collar's gap then 0.37 instead of 0.3, the
  screw 0.07 deeper, both harmless). Heights land within 0.1 instead of 0.08; the fits
  lie in the plate's plane, and the firmware takes each key's rest as it finds it.
- **Walls 3**, top and bottom 5 layers; infill 25 % gyroid (tray and cover; the bosses,
  tubes and caps are solid from the walls alone).
- **No supports.** Seam aligned or at the back. Brim only if the collars come loose
  (4.4 mm footprint).

**Bambu Studio projects:** `make bambu` (needs the Bambu Studio AppImage, `BAMBU=`) turns both
into projects for the X2D, `plate_x2d.3mf` and `fit_test_x2d.3mf`: printer "Bambu Lab X2D
0.4 nozzle", filament "Bambu PETG HF @BBL X2D 0.4 nozzle", process "0.20mm Standard @BBL
X2D" with the settings above laid over it (`bambu.py`), textured PEI plate, the layout kept,
sliced. Bambu Studio 2.09 estimates 11 min and 2.1 g for the fit test, 1 h 12 min and 33.9 g
for the plate. Press "Slice plate" once more before sending: the command line leaves the
plate's printer model id empty, which the GUI fills.

**For someone else printing on an X2D:** `make zip` packs the plate's project
(`plate_x2d.3mf`, not the fit test) with `PRINTING.txt`, the instructions, into `build/key_proto/key_proto_x2d.zip`.

**Fit test first** (`fit_test.3mf`, a few minutes): the press fits are the bushing's seat
⌀4.95 (bushing D5), the rod's socket in the cap ⌀2.95 (rod ⌀3) and the magnet's pocket
⌀3.05 (magnet ⌀3); the bushing slides in from below through ⌀5.1, and the rim over the
seat (0.8, inward 0.8) prints as a short overhang ring that may sag into the seat. Printed
holes come out small in PETG: if the bushing or rod does not go in, raise the slicer's
X-Y hole compensation (0.05 … 0.1 mm) rather than the model, and print the test again; if
a fit is loose, glue it (slow epoxy, `../switch_hall/spec.md` §2).

## Files

`make` builds into `build/key_proto/`: `base.stl`, `board.stl`, `cover.stl`, `cap.stl`,
`collar.stl` to print, and `keys.stl` / `keys_down.stl`, the key parts in place for
viewing; it has `../switch_hall/` build those first. The source is `proto.scad` (`part` =
base, board, cover, keys, all). `print.scad` turns the parts as printed (`print_*.stl`),
`plate.py` arranges them into `plate.3mf` and `fit_test.3mf`.
