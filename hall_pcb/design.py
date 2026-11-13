"""Hall-sensor key boards: the one source of parts, nets and placement.

One board per side of the instrument [given]: the environment variable
HALL_BOARD picks "discant" (default) or "bass". Every key of ../switch_hall/ has
a linear Hall sensor on the board's underside, exactly under its axis; ADS7138
8-channel I2C ADCs digitise them; no controller on the board [given]. The ESP32
in the bass reads them: the discant over the existing 5-wire bus through the
bellows, the bass on the ESP32's second I2C bus inside the bass box (the ADCs'
eight addresses would not cover both boards on one bus).

Board frame (millimetres): X along the rows, Y across them in the board's plane,
0 on the row-0 keys' axes. Side "B" is the board's underside, where every part
sits; the top carries only copper, so the cover with the key tubes lies flat on it.

gen_pcb.py writes the board, route.py routes it, gen_sch.py draws the schematic.
"""
import math, os

BOARD = os.environ.get("HALL_BOARD", "discant")
assert BOARD in ("discant", "bass"), BOARD
PCB_T = 1.6
PITCH = 20
SENS_EL = 0.55                       # Hall element below the package's mounting face [unverified]

MARGIN_X = 8                         # outermost key's axis to the slanted end
MARGIN_Y = 8                         # first / last row's axis to the front / back edge
HOLE_D = 2.2                         # M2 screws: cover through the board into the housing

if BOARD == "discant":
    # --- staircase, as ../discant/ and ../switch_hall/key.scad -------------------
    STAIR = (10, 16, 3)                  # row k+1 relative to row k: x, y, z
    ROWS = 4
    N_HOLES = 13                         # row k has 13 - k keys
    D = math.hypot(STAIR[1], STAIR[2])   # rows apart in the board's plane: 16.279
    TAN = STAIR[2] / STAIR[1]            # the board's tilt against each row: 10.6 deg
    # the key's axis is vertical, the board tilted: it meets the sensor's element this far
    # down the slope from where it meets the board's top
    SENS_DY = -(PCB_T + SENS_EL) * TAN
    def key_xy(k, h):
        """key h (1-based) of row k on the board"""
        return (-120 + (h - 1) * PITCH + k * STAIR[0], k * D)
    KEYS = [(k, h) for k in range(ROWS) for h in range(1, N_HOLES - k + 1)]
    # outline: a trapezoid, its slanted ends parallel to the staircase's ends
    Y_FRONT, Y_BACK = -MARGIN_Y, (ROWS - 1) * D + MARGIN_Y
    def x_left(y):  return -120 - MARGIN_X + STAIR[0] * y / D
    def x_right(y): return 120 + MARGIN_X - STAIR[0] * y / D
    # screws between keys, clear of the tubes' shrouds (r 5.1) and of the ADCs
    HOLES = [(-80, 1.5 * D), (0, 1.5 * D), (80, 1.5 * D),
             (-50, -5.0), (50, -5.0), (-60, 3 * D + 5.0), (60, 3 * D + 5.0)]
    TITLE = "Discant Hall-sensor board"
    BUS_TITLE = "Bus to the ESP32 in the bass (through the bellows)"
else:
    # --- bass: 2 x 9 keys, as ../bass/layout.scad: front row x = -80 .. 80 at y = 0,
    # back row x = -70 .. 90 at y = 16 and 10 mm higher. The board is flat under both
    # rows [chosen]: the back row's tubes and pins are 10 mm longer, so the sensor sees
    # the same magnet travel and nothing is tilted.
    STAIR = (10, 16, 0)
    ROWS = 2
    N_HOLES = 9
    D = 16.0
    TAN = 0.0
    SENS_DY = 0.0
    def key_xy(k, h):
        return (-80 + (h - 1) * PITCH + k * STAIR[0], k * D)
    KEYS = [(k, h) for k in range(ROWS) for h in range(1, N_HOLES + 1)]
    # outline: a parallelogram, both ends slanting with the rows' 10 mm offset
    Y_FRONT, Y_BACK = -MARGIN_Y, (ROWS - 1) * D + MARGIN_Y
    def x_left(y):  return -80 - MARGIN_X + STAIR[0] * y / D
    def x_right(y): return 80 + MARGIN_X + STAIR[0] * y / D
    HOLES = [(-50, -5.0), (50, -5.0), (-40, D + 5.0), (60, D + 5.0)]
    TITLE = "Bass Hall-sensor board"
    BUS_TITLE = "Second I2C bus of the ESP32 (inside the bass box)"

OUTLINE = [(x_left(Y_FRONT), Y_FRONT), (x_right(Y_FRONT), Y_FRONT),
           (x_right(Y_BACK), Y_BACK), (x_left(Y_BACK), Y_BACK)]

# --- parts --------------------------------------------------------------------
C = []
def part(ref, value, fp, pins, pos=None, side="B", rot=0, pinfo=None, group=None, title=None):
    C.append(dict(ref=ref, value=value, fp=fp, pins=pins, pos=pos, side=side, rot=rot,
                  pinfo=pinfo or {}, group=group, title=title))

R0402 = "Resistor_SMD:R_0402_1005Metric"
C0402 = "Capacitor_SMD:C_0402_1005Metric"
C0805 = "Capacitor_SMD:C_0805_2012Metric"
SOT23 = "Package_TO_SOT_SMD:SOT-23"
# TI RTE (WQFN-16, 3 x 3, 0.5 pitch); exposed pad assumed 1.68 square [unverified]
WQFN16 = "Package_DFN_QFN:WQFN-16-1EP_3x3mm_P0.5mm_EP1.68x1.68mm"
JST5 = "Connector_JST:JST_SH_BM05B-SRSS-TB_1x05-1MP_P1.00mm_Vertical"
# side entry, about 2.95 high [unverified]: the discant's housing stays thin under it
JST5_SIDE = "Connector_JST:JST_SH_SM05B-SRSS-TB_1x05-1MP_P1.00mm_Horizontal"

# sensors: DRV5055A3 (+-85 mT), SOT-23: 1 VCC, 2 OUT, 3 GND [datasheet]; 100 nF beside it
# (the datasheet asks for at least 10 nF)
def key_net(k, h): return f"KEY{k}_{h}"
for n, (k, h) in enumerate(KEYS):
    x, y = key_xy(k, h)
    part(f"U{100 + n + 1}", "DRV5055A3QDBZR", SOT23, {"1": "+3V3", "2": key_net(k, h), "3": "GND"},
         (x, y + SENS_DY), group="sensors", pinfo={"1": "VCC", "2": "OUT", "3": "GND"},
         title=f"row {k}, key {h}")
    part(f"C{100 + n + 1}", "100n", C0402, {"1": "+3V3", "2": "GND"}, (x + 2.7, y + SENS_DY), rot=90,
         group="sensors")

# ADCs: ADS7138IRTER [datasheet SBAS976A]; pins: AIN2..AIN5 1..4, AIN6 5, AIN7 6,
# AVDD 7, DECAP 8, GND 9, DVDD 10, ADDR 11, ALERT 12, SCL 13, SDA 14, AIN0 15,
# AIN1 16, thermal pad to GND. ALERT is its own pin, so all 8 channels are inputs.
ADC_AIN = {"15": 0, "16": 1, "1": 2, "2": 3, "3": 4, "4": 5, "5": 6, "6": 7}
# address by a resistor on ADDR: none -> 10h; to GND 11k/33k/100k -> 11h/12h/13h;
# to DECAP 100k/33k/11k/0R -> 14h/15h/16h/17h [datasheet Table 2]
ADDR_R = [None, ("11k", "GND"), ("33k", "GND"), ("100k", "GND"), ("100k", "DECAP"), ("33k", "DECAP")]

if BOARD == "discant":
    # which keys each ADC reads: rows 0 and 1 (less the rightmost of row 1) by the three
    # lower ADCs, between rows 0 and 1; the rest by the three upper ones, between rows 2 and 3
    lower = sorted([(k, h) for k, h in KEYS if k == 0 or (k == 1 and h < N_HOLES - 1)], key=lambda q: key_xy(*q)[0])
    upper = sorted([(k, h) for k, h in KEYS if (k, h) not in lower], key=lambda q: key_xy(*q)[0])
    GROUPS = [lower[0:8], lower[8:16], lower[16:24], upper[0:7], upper[7:14], upper[14:22]]
    ADC_Y = [0.5 * D] * 3 + [2.5 * D] * 3
else:
    # three ADCs between the rows, six keys each, by X
    both = sorted(KEYS, key=lambda q: key_xy(*q)[0])
    GROUPS = [both[0:6], both[6:12], both[12:18]]
    ADC_Y = [0.5 * D] * 3
assert sum(len(g) for g in GROUPS) == len(KEYS) and all(len(g) <= 8 for g in GROUPS)
for a, g in enumerate(GROUPS):
    x = sum(key_xy(*q)[0] for q in g) / len(g)
    pins = {"7": "+3V3", "8": f"DECAP{a}", "9": "GND", "10": "+3V3", "11": f"ADDR{a}", "12": "INT",
            "13": "SCL", "14": "SDA", "17": "GND"}
    # channels: gen_pcb.py assigns the keys to the AIN pins by angle round the chip, so
    # the tracks fan out without crossing; it writes the table to <board>/channels.json
    for p in ADC_AIN: pins[p] = None
    part(f"U{a + 1}", "ADS7138IRTER", WQFN16, pins, (x, ADC_Y[a]), group="adc",
         title=f"ADC {a}, address {0x10 + a:02X}h",
         pinfo={**{p: f"AIN{c}" for p, c in ADC_AIN.items()}, "7": "AVDD", "8": "DECAP", "9": "GND",
                "10": "DVDD", "11": "ADDR", "12": "ALERT", "13": "SCL", "14": "SDA", "17": "EP"})
    part(f"C{10 * a + 11}", "1u", C0402, {"1": "+3V3", "2": "GND"}, group="adc")       # AVDD
    part(f"C{10 * a + 12}", "1u", C0402, {"1": f"DECAP{a}", "2": "GND"}, group="adc")  # DECAP
    part(f"C{10 * a + 13}", "1u", C0402, {"1": "+3V3", "2": "GND"}, group="adc")       # DVDD
    if ADDR_R[a]:
        v, to = ADDR_R[a]
        part(f"R{a + 1}", v, R0402, {"1": f"ADDR{a}", "2": f"DECAP{a}" if to == "DECAP" else "GND"}, group="adc")
    else:
        # 10h: ADDR left open; the net still needs its pin alone
        pins["11"] = None
GROUP_OF = {q: a for a, g in enumerate(GROUPS) for q in g}
# small parts round each ADC: (ref suffix, pin it serves), placed by gen_pcb.py
ADC_SMALL = [("C{}1", "7"), ("C{}2", "8"), ("C{}3", "10"), ("R{}", "11")]

# connector: JST SH 5 pins, vertical, underside, as on the switch boards (../switch/ioexp.scad):
# pins along X from -X: INT, 3V3, SDA, SCL, GND
# discant: side entry at the back edge between keys 1 and 2 of row 3, its opening to
#   the back, straight in front of the link board's pocket in the housing's back wall
#   (../discant/gauge_link.scad), so the plug's wires run straight into it;
# bass: vertical, at the -x end between the rows, where the wires drop into the box
if BOARD == "discant":
    CONN_XY = (-80.0, Y_BACK - 3.0 - 2.575)   # opening 3 inside the back edge: room for the plug
    part("J1", "SM05B-SRSS-TB", JST5_SIDE, {"1": "INT", "2": "+3V3", "3": "SDA", "4": "SCL", "5": "GND", "MP": "GND"},
         CONN_XY, group="bus", title=BUS_TITLE,
         pinfo={"1": "INT", "2": "3V3", "3": "SDA", "4": "SCL", "5": "GND", "MP": "MP"})
    part("C1", "10u", C0805, {"1": "+3V3", "2": "GND"}, (CONN_XY[0] + 5.6, CONN_XY[1]), rot=90, group="bus")
    # pull-ups: INT here (the ALERTs are open drain); SDA/SCL only if the host has none
    # [unverified: fit or leave out once the bus is measured]
    for i, (r, v, n) in enumerate([("R11", "10k", "INT"), ("R12", "4k7 (DNP?)", "SDA"), ("R13", "4k7 (DNP?)", "SCL")]):
        part(r, v, R0402, {"1": n, "2": "+3V3"}, (CONN_XY[0] - 6.0, CONN_XY[1] + 1.3 - 1.3 * i), group="bus")
else:
    CONN_XY = (-76.0, 0.5 * D)
    part("J1", "BM05B-SRSS-TB", JST5, {"1": "INT", "2": "+3V3", "3": "SDA", "4": "SCL", "5": "GND", "MP": "GND"},
         CONN_XY, group="bus", title=BUS_TITLE,
         pinfo={"1": "INT", "2": "3V3", "3": "SDA", "4": "SCL", "5": "GND", "MP": "MP"})
    part("C1", "10u", C0805, {"1": "+3V3", "2": "GND"}, (CONN_XY[0] + 1.0, CONN_XY[1] + 4.5), group="bus")
    part("R11", "10k", R0402, {"1": "INT", "2": "+3V3"}, (CONN_XY[0] - 1.6, CONN_XY[1] - 4.5), rot=90, group="bus")
    part("R12", "4k7 (DNP?)", R0402, {"1": "SDA", "2": "+3V3"}, (CONN_XY[0], CONN_XY[1] - 4.5), rot=90, group="bus")
    part("R13", "4k7 (DNP?)", R0402, {"1": "SCL", "2": "+3V3"}, (CONN_XY[0] + 1.6, CONN_XY[1] - 4.5), rot=90, group="bus")

POWER = {"+3V3"}
