"""Main PCB of the discant: the one source of parts, nets and placement.

gen_sch.py writes the KiCad schematic from it, gen_pcb.py the board. Positions
are in the band frame of ../main_pcb.scad: X up the staircase, Y towards the
slanted wall, millimetres. Side "F" is the board's top, "B" the side towards the
hole's floor. rot is the KiCad orientation in degrees.
"""

# where the cables land, from main_pcb.scad (echo "cable k: ends on the band frame")
ZIF_PITCH = 19.105
ZIF_MOUTH = [11.2, 30.3, 49.5]   # top ZIFs: mouth, X: the 21 mm actuator bar clear of the hole-1 tubes
ZIF_Y = 0.388
ZIF3_MOUTH = 54.9                # underside ZIF: mouth towards +X
ZIF3_Y = -0.015
ZIF_D = 6.75                     # mouth to the tails' tips (FFC3B drawing)
ZIF_ORG = 2.475                  # mouth to the footprint's origin

N_HOLES = 13

def used(k, h):                  # board k has holes 1 .. 13 - k
    return h <= N_HOLES - k

C = []                           # components

def part(ref, value, fp, pins, pos=None, side="B", rot=0, pinfo=None, title=None, group=None):
    C.append(dict(ref=ref, value=value, fp=fp, pins=pins, pos=pos, side=side, rot=rot,
                  pinfo=pinfo or {}, title=title, group=group))

R0402 = "Resistor_SMD:R_0402_1005Metric"
C0402 = "Capacitor_SMD:C_0402_1005Metric"
C0603 = "Capacitor_SMD:C_0603_1608Metric"
C0805 = "Capacitor_SMD:C_0805_2012Metric"
C1206 = "Capacitor_SMD:C_1206_3216Metric"
ZIF = "Connector_FFC-FPC:JUSHUO_AFA07-S14FCA-00_1x14-1MP_P1.0mm_Horizontal"

def R(ref, val, a, b, pos=None, side="B", rot=0, group=None):
    part(ref, val, R0402, {"1": a, "2": b}, pos, side, rot, group=group)
def Cc(ref, val, a, b="GND", pos=None, side="B", rot=0, fp=C0402, group=None):
    part(ref, val, fp, {"1": a, "2": b}, pos, side, rot, group=group)

# --- key scan ----------------------------------------------------------------
# FFC conductor c: 1 = the board's common, c = 2 .. 14 = hole 15 - c (pcb.scad).
# Conductor 1 lies at +Y. gen_pcb.py turns conductors into pads by position.
def conductor_net(k, c):
    if c == 1:
        return f"ROW{k}"
    h = 15 - c
    return f"KEY{k}_{h}" if used(k, h) else None

for k in range(4):
    if k < 3:
        pos = (ZIF_MOUTH[k] + ZIF_ORG, ZIF_Y); side = "F"
    else:
        pos = (ZIF3_MOUTH - ZIF_ORG, ZIF3_Y); side = "B"
    part(f"J{k + 1}", "AFA07-S14FCA-00", ZIF,
         {f"c{c}": conductor_net(k, c) for c in range(1, 15)}, pos, side, group="scan",
         title=f"Cable {k}: board {k}, {13 - k} keys")

DIODE = "Diode_SMD:D_SOD-882"
for k in range(4):
    for h in range(1, N_HOLES + 1):
        if used(k, h):
            part(f"D{(k + 1) * 100 + h}", "Schottky 30 V", DIODE,
                 {"1": f"COL{h}", "2": f"KEY{k}_{h}"}, group="diodes")

hc154 = {"24": "+3V3", "12": "GND", "18": "GND", "19": "GND",
         "23": "A0", "22": "A1", "21": "A2", "20": "A3"}
y_pins = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "13", "14", "15", "16", "17"]
# which output drives which column is free (firmware keeps a table): this order
# fans out to the bus rows without crossing. Y0 .. Y10 on one side of the chip take
# holes 13 .. 3, Y11 and Y12 on the other side holes 1 and 2.
Y_HOLE = [13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 1, 2, None, None, None]
for p, h in zip(y_pins, Y_HOLE):
    hc154[p] = f"COL{h}" if h else None
part("U2", "74HC154PW", "Package_SO:TSSOP-24_4.4x7.8mm_P0.65mm", hc154, (35.8, -3.0), "B", 180, group="scan",
     pinfo={"24": "VCC", "12": "GND", "18": "G1", "19": "G2", "23": "A0", "22": "A1", "21": "A2", "20": "A3",
            **{p: f"Y{i}" for i, p in enumerate(y_pins)}})
Cc("C20", "100n", "+3V3", pos=(39.4, -6.6), rot=90, group="scan")
for k in range(4):
    R(f"R{k + 1}", "10k", f"ROW{k}", "+3V3", group="scan")

# --- module ------------------------------------------------------------------
# ESP32-S3-WROOM-1-N16R8: no radio used. GPIO33-37 are the PSRAM's.
mod = {"1": ("GND", "GND"), "2": ("+3V3", "3V3"), "3": ("EN", "EN"), "4": (None, "IO4"), "5": (None, "IO5"),
       "6": ("DAC_RST", "IO6"), "7": ("LINK_INT", "IO7"), "8": ("ROW0", "IO15"), "9": ("ROW1", "IO16"),
       "10": ("ROW2", "IO17"), "11": ("ROW3", "IO18"), "12": ("SCL", "IO8"), "13": ("USB_DN", "IO19"),
       "14": ("USB_DP", "IO20"), "15": (None, "IO3"), "16": (None, "IO46"), "17": ("SDA", "IO9"),
       "18": ("I2S_MCLK", "IO10"), "19": ("I2S_BCLK", "IO11"), "20": ("I2S_WCLK", "IO12"), "21": ("I2S_DOUT", "IO13"),
       "22": ("A3", "IO14"), "23": ("A2", "IO21"), "24": ("A0", "IO47"), "25": ("A1", "IO48"), "26": (None, "IO45"),
       "27": ("BOOT", "IO0"), "28": (None, "IO35"), "29": (None, "IO36"), "30": (None, "IO37"), "31": (None, "IO38"),
       "32": (None, "IO39"), "33": (None, "IO40"), "34": (None, "IO41"), "35": (None, "IO42"), "36": ("RXD0", "RXD0"),
       "37": ("TXD0", "TXD0"), "38": (None, "IO2"), "39": ("VBAT_SENSE", "IO1"), "40": ("GND", "GND"), "41": ("GND", "EPAD")}
part("U1", "ESP32-S3-WROOM-1-N16R8", "RF_Module:ESP32-S3-WROOM-1", {p: v[0] for p, v in mod.items()},
     (21.72, 1.2), "B", 270, pinfo={p: v[1] for p, v in mod.items()}, group="mcu")
Cc("C1", "10u", "+3V3", fp=C0603, group="mcu")
Cc("C2", "100n", "+3V3", group="mcu")
R("R5", "10k", "EN", "+3V3", group="mcu")
Cc("C3", "1u", "EN", group="mcu")
R("R6", "10k", "BOOT", "+3V3", group="mcu")

# --- power: battery or USB -> 3.3 V, 1.8 V ------------------------------------
part("D1", "SS14 class Schottky", "Diode_SMD:D_SOD-123", {"1": "VIN", "2": "VBUS"}, side="F", group="power")
part("Q1", "DMG2305UX", "Package_TO_SOT_SMD:SOT-23", {"1": "VBUS_G", "2": "VIN", "3": "VBAT"}, side="F", group="power",
     pinfo={"1": "G", "2": "S", "3": "D"})
R("R7", "100k", "VBUS_G", "GND", side="F", group="power")
R("R8", "0R", "VBUS", "VBUS_G", side="F", group="power")
part("U5", "TLV75533PDBV", "Package_TO_SOT_SMD:SOT-23-5", {"1": "VIN", "2": "GND", "3": "VIN", "4": None, "5": "+3V3"},
     side="F", group="power", pinfo={"1": "IN", "2": "GND", "3": "EN", "4": "NC", "5": "OUT"})
Cc("C4", "1u", "VIN", side="F", group="power")
Cc("C5", "10u", "+3V3", side="F", fp=C0603, group="power")
part("U6", "TLV75518PDBV", "Package_TO_SOT_SMD:SOT-23-5", {"1": "+3V3", "2": "GND", "3": "+3V3", "4": None, "5": "+1V8"},
     group="power", pinfo={"1": "IN", "2": "GND", "3": "EN", "4": "NC", "5": "OUT"})
Cc("C6", "1u", "+1V8", group="power")
R("R9", "1M", "VBAT", "VBAT_SENSE", group="power")
R("R10", "1M", "VBAT_SENSE", "GND", group="power")
Cc("C7", "100n", "VBAT_SENSE", group="power")

# --- USB ---------------------------------------------------------------------
usb = {"A4": "VBUS", "A9": "VBUS", "B4": "VBUS", "B9": "VBUS", "A1": "GND", "A12": "GND", "B1": "GND", "B12": "GND",
       "A5": "CC1", "B5": "CC2", "A6": "USB_CP", "B6": "USB_CP", "A7": "USB_CN", "B7": "USB_CN",
       "A8": None, "B8": None, "S1": "GND"}
part("J5", "USB4105-GF-A", "Connector_USB:USB_C_Receptacle_GCT_USB4105-xx-A_16P_TopMnt_Horizontal", usb,
     (40.7, 11.65), "F", 180, group="usb")
R("R11", "5k1", "CC1", "GND", side="F", group="usb")
R("R12", "5k1", "CC2", "GND", side="F", group="usb")
part("U4", "USBLC6-2SC6", "Package_TO_SOT_SMD:SOT-23-6",
     {"1": "USB_CP", "2": "GND", "3": "USB_CN", "4": "USB_DN", "5": "VBUS", "6": "USB_DP"}, side="F", group="usb",
     pinfo={"1": "I/O1", "2": "GND", "3": "I/O2", "4": "I/O2", "5": "VBUS", "6": "I/O1"})

# --- audio -------------------------------------------------------------------
dac = {"1": ("GND", "IOVSS"), "2": ("+3V3", "IOVDD"), "3": ("+1V8", "DVDD"), "4": (None, "NC"), "5": ("I2S_DOUT", "DIN"),
       "6": ("I2S_WCLK", "WCLK"), "7": ("I2S_BCLK", "BCLK"), "8": ("I2S_MCLK", "MCLK"), "9": ("SDA", "SDA"),
       "10": ("SCL", "SCL"), "11": (None, "VOL/MICDET"), "12": (None, "MICBIAS"), "13": (None, "AIN1"),
       "14": (None, "AIN2"), "15": (None, "NC"), "16": ("GND", "AVSS"), "17": ("+3V3A", "AVDD"), "18": ("GND", "DVSS"),
       "19": (None, "SPKM"), "20": ("GND", "SPKVSS"), "21": ("+3V3", "SPKVDD"), "22": (None, "SPKP"), "23": (None, "SPKM"),
       "24": ("+3V3", "SPKVDD"), "25": ("GND", "SPKVSS"), "26": (None, "SPKP"), "27": ("HPL", "HPL"), "28": ("+3V3A", "HPVDD"),
       "29": ("GND", "HPVSS"), "30": ("HPR", "HPR"), "31": ("DAC_RST", "RESET"), "32": (None, "GPIO1"), "33": ("GND", "EP")}
part("U3", "TLV320DAC3100IRHB", "Package_DFN_QFN:VQFN-32-1EP_5x5mm_P0.5mm_EP3.1x3.1mm",
     {p: v[0] for p, v in dac.items()}, (35.6, 4.4), "B", 90, pinfo={p: v[1] for p, v in dac.items()}, group="audio")
part("FB1", "600R @ 100 MHz", "Inductor_SMD:L_0402_1005Metric", {"1": "+3V3", "2": "+3V3A"}, group="audio")
Cc("C8", "100n", "+3V3", group="audio")
Cc("C9", "100n", "+1V8", group="audio")
Cc("C10", "100n", "+3V3A", group="audio")
Cc("C11", "10u", "+3V3A", fp=C0603, group="audio")
Cc("C12", "100n", "+3V3A", group="audio")
Cc("C13", "100n", "+3V3", group="audio")
R("R13", "100k", "DAC_RST", "GND", group="audio")
Cc("C14", "100u", "HPL", "EAR_L", fp=C1206, group="audio")
Cc("C15", "100u", "HPR", "EAR_R", fp=C1206, group="audio")

# --- wires: pads, no connectors -----------------------------------------------
PAD = "TestPoint:TestPoint_Pad_1.0x1.0mm"
for i, (net, name) in enumerate([("VBAT", "battery +"), ("GND", "ground"), ("+3V3", "3.3 V"), ("SDA", "SDA"),
                                 ("SCL", "SCL"), ("LINK_INT", "interrupt")]):
    part(f"P{i + 1}", name, PAD, {"1": net}, (48.8 + 1.5 * (i % 3), 13.1 - 1.5 * (i // 3)), "F", group="wires", title="To the link board")
for i, (net, name) in enumerate([("EAR_L", "jack tip"), ("EAR_R", "jack ring"), ("GND", "jack sleeve")]):
    part(f"P{i + 7}", name, PAD, {"1": net}, (30.0 + 1.5 * i, 12.6), "F", group="wires", title="To the jack")
R("R14", "2k2", "SDA", "+3V3", group="wires")
R("R15", "2k2", "SCL", "+3V3", group="wires")
for i, (net, name) in enumerate([("BOOT", "boot"), ("EN", "reset"), ("TXD0", "tx"), ("RXD0", "rx")]):
    part(f"TP{i + 1}", name, PAD, {"1": net}, None, "F", group="test")

# --- board -------------------------------------------------------------------
X0, X1, Y0, Y1 = 4.7, 56.7, -8.6, 13.9
OUTLINE = [(X0, Y1), (X1, Y1), (X1, -10.5), (49.6, -10.5), (48.6, -9.7), (48.6, Y0), (40.2, Y0), (40.2, -10.4), (30.3, -10.4),
           (30.3, Y0), (21.1, Y0), (21.1, -10.4), (19.6, -12.6), (12.6, -12.6), (11.1, -10.4), (11.1, Y0), (X0, Y0)]
PINS = [(7, 12.3), (54.5, 12.3), (16.6, -11.3), (37.6, -8.2)]   # locating pins; holes d2.2

# placement of the small parts: (X, Y, rot); side as in the table
PLACE = {
    "C20": (40.1, -7.2, 90),
    "R1": (24.0, 5.5, 0), "R2": (24.0, 4.0, 0), "R3": (24.0, 2.5, 0), "R4": (24.0, 1.0, 0),
    "C1": (6.4, 6.0, 90), "C2": (6.4, 3.5, 90), "R5": (6.4, 1.0, 90), "C3": (6.4, -1.5, 90), "R6": (6.4, -4.0, 90),
    "D1": (26.3, 12.7, 0), "Q1": (24.6, 9.6, 0), "R7": (22.8, 13.3, 0), "R8": (22.8, 12.3, 0),
    "U5": (20.3, 10.1, 0), "C4": (22.4, 7.9, 0), "C5": (20.3, 13.0, 0),
    "U6": (33.3, 10.5, 0), "C6": (33.3, 13.0, 0),
    "U4": (40.7, 11.6, 0), "R11": (42.0, 6.85, 0), "R12": (44.4, 6.85, 0),
    "C8": (42.0, 5.0, 0), "C9": (44.4, 5.0, 0), "FB1": (42.0, 2.5, 0), "C10": (44.4, 2.5, 0),
    "C13": (42.0, 0.0, 0), "C12": (44.4, 0.0, 0), "R13": (23.5, -4.0, 0),
    "R9": (26.5, -1.0, 0), "R10": (26.5, -2.5, 0), "C7": (26.5, -4.0, 0),
    "R14": (23.5, -1.0, 0), "R15": (23.5, -2.5, 0),
    "C11": (39.4, 7.9, 90), "C14": (42.6, 0.0, 90), "C15": (42.6, 5.0, 90),
    "TP1": (9.0, 12.8, 0), "TP2": (11.5, 12.8, 0), "TP3": (14.0, 12.8, 0), "TP4": (16.5, 12.8, 0),
}
SIDE = {"C8": "F", "C9": "F", "C10": "F", "C12": "F", "C13": "F", "FB1": "F", "R13": "F", "R9": "F", "R10": "F",
        "C7": "F", "R11": "F", "R12": "F", "R14": "F", "R15": "F", "R1": "F", "R2": "F", "R3": "F", "R4": "F", "C1": "F", "C2": "F", "R5": "F",
        "C3": "F", "R6": "F", "C20": "B", "U6": "B", "C6": "B", "U4": "B"}
