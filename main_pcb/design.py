"""Main board in the bass: the one source of parts, nets and placement.

gen_pcb.py writes the board from it, gen_sch.py the schematic. The board lies flat on
the front wall's inside at the bottom of the bass box, against the +x side wall
(../bass/elec.scad), its parts facing the back cover.

Board frame, millimetres, seen from the parts' side (from the back cover): X from the
+x side wall's edge of the board towards -x of the bass, Y up (the bass's z), origin
at the board's lower corner by the side wall:
    X = pwr_x[1] - x,  Y = z - pwr_z[0]       (elec.scad)
so the USB socket, the LED and the earphone jack's hole are at X = 0, the module's antenna at the
bottom. pos is (X, Y, rot): rot is KiCad's orientation in degrees. Every part is on
the top; the underside lies 0.47 mm over the front wall.
"""

W, H = 45.5, 33.0                 # board outline [given: elec.scad]
PCB_T = 1.0                       # [given: elec.scad pcb_tk]
# a tab under the USB socket, into a pocket of the side wall [given 2026-11-18: way B]: the
# socket stands 1.95 beyond the board's edge, so its front shell legs (slots to X -0.05,
# copper to X -0.25) lay on the edge, cut by the router. With the tab to X -0.8 their copper
# keeps 0.55 from the edge, the slots 0.75. The board's edge lies 0.45 inside the wall, so
# the tab stands 0.35 into it (the pocket: ../bass/elec.scad elec_cuts()).
USB_TAB = (-0.8, 15.8, 26.8)      # X of its end, Y from .. to (the socket's legs: Y 16.48 .. 26.12)
OUTLINE = [(0, 0), (W, 0), (W, H), (0, H),
           (0, USB_TAB[2]), (USB_TAB[0], USB_TAB[2]), (USB_TAB[0], USB_TAB[1]), (0, USB_TAB[1])]
# M2 screws from the parts' side into pilots in the front wall; head clearance d 4.4
# placed clear of the hand plate's former 1 mm recess (gone since 2026-11-15)
HOLES = [(4.4, 30.6), (25.0, 30.6), (22.4, 2.6)]
HOLE_D = 2.2
HEAD_D = 4.4
# no copper on any layer under and beside the module's antenna
ANTENNA_KEEPOUT = (24.6, W, 0, 6.6)          # X0, X1, Y0, Y1

C = []

def part(ref, value, fp, pins, pos, pinfo=None, group=None, title=None):
    C.append(dict(ref=ref, value=value, fp=fp, pins=pins, pos=pos, pinfo=pinfo or {},
                  group=group, title=title))

R0402 = "Resistor_SMD:R_0402_1005Metric"
C0402 = "Capacitor_SMD:C_0402_1005Metric"
C0603 = "Capacitor_SMD:C_0603_1608Metric"
C0805 = "Capacitor_SMD:C_0805_2012Metric"
C1206 = "Capacitor_SMD:C_1206_3216Metric"
SOT23 = "Package_TO_SOT_SMD:SOT-23"
SOT236 = "Package_TO_SOT_SMD:SOT-23-6"
PAD = "TestPoint:TestPoint_Pad_1.5x1.5mm"
TP = "TestPoint:TestPoint_Pad_1.0x1.0mm"

def R(ref, val, a, b, pos, group):
    part(ref, val, R0402, {"1": a, "2": b}, pos, group=group)
def Cc(ref, val, a, b, pos, group, fp=C0402):
    part(ref, val, fp, {"1": a, "2": b}, pos, group=group)

# --- module ------------------------------------------------------------------------
# ESP32-S3-WROOM-1-N16R8 (GPIO35-37 belong to the octal PSRAM). Pins 1-14 face the side
# wall's opposite edge (X 44), 15-26 the top, 27-40 the parts (X 26.6).
mod = {"1": ("GND", "GND"), "2": ("+3V3", "3V3"), "3": ("EN", "EN"), "4": (None, "IO4"), "5": (None, "IO5"),
       "6": (None, "IO6"), "7": (None, "IO7"), "8": (None, "IO15"), "9": (None, "IO16"), "10": (None, "IO17"),
       "11": (None, "IO18"), "12": (None, "IO8"), "13": ("USB_DN", "USB_D-"), "14": ("USB_DP", "USB_D+"),
       "15": (None, "IO3"), "16": (None, "IO46"), "17": ("SDA1", "IO9"), "18": ("I2S_MCLK", "IO10"),
       "19": ("I2S_BCLK", "IO11"), "20": ("I2S_WCLK", "IO12"), "21": ("I2S_DOUT", "IO13"), "22": ("SCL1", "IO14"),
       "23": ("INT1", "IO21"), "24": ("SDA2", "IO47"), "25": ("SCL2", "IO48"), "26": (None, "IO45"),
       "27": ("BOOT", "IO0"), "28": (None, "IO35"), "29": (None, "IO36"), "30": (None, "IO37"), "31": ("INT2", "IO38"),
       "32": ("DAC_RST", "IO39"), "33": ("DISC_ON", "IO40"), "34": ("VBUS_SENSE", "IO41"), "35": ("LOW_BAT", "IO42"),
       "36": ("RXD0", "RXD0"), "37": ("TXD0", "TXD0"), "38": (None, "IO2"), "39": ("VBAT_SENSE", "IO1"),
       "40": ("GND", "GND"), "41": ("GND", "GND")}
part("U1", "ESP32-S3-WROOM-1-N16R8", "RF_Module:ESP32-S3-WROOM-1", {p: v[0] for p, v in mod.items()},
     (35.3, 13.25, 180), pinfo={p: v[1] for p, v in mod.items()}, group="mcu", title="ESP32-S3")
Cc("C1", "22u", "+3V3", "GND", (24.0, 8.4, 90), "mcu", C0805)
Cc("C2", "100n", "+3V3", "GND", (25.1, 12.4, 90), "mcu")
R("R1", "10k", "EN", "+3V3", (25.1, 22.4, 90), "mcu")
Cc("C3", "1u", "EN", "GND", (25.1, 20.3, 90), "mcu")
R("R2", "10k", "BOOT", "+3V3", (25.1, 24.5, 90), "mcu")
# boot, reset and ground at the top edge; tx and rx nearer the module's pins 36/37 (the
# board has no room beside them), so their tracks stay short
for i, (net, name, pos) in enumerate([("BOOT", "boot", (7.8, 31.9)), ("EN", "reset", (9.9, 31.9)),
                                      ("TXD0", "tx", (10.4, 11.35)), ("RXD0", "rx", (10.4, 13.45)),
                                      ("GND", "ground", (16.2, 31.9))]):
    part(f"TP{i + 1}", name, TP, {"1": net}, (*pos, 0), group="mcu", title="Test pads")

# --- USB-C: charging, firmware, MIDI ---------------------------------------------
usb = {"A4": "VBUS", "A9": "VBUS", "B4": "VBUS", "B9": "VBUS", "A1": "GND", "A12": "GND", "B1": "GND", "B12": "GND",
       "A5": "CC1", "B5": "CC2", "A6": "USB_CP", "B6": "USB_CP", "A7": "USB_CN", "B7": "USB_CN",
       "A8": None, "B8": None, "S1": "GND"}
# its mouth 0.2 inside the wall's face: 2.25 beyond the board's edge (elec.scad usb_x1)
part("J1", "USB4105-GF-A", "Connector_USB:USB_C_Receptacle_GCT_USB4105-xx-A_16P_TopMnt_Horizontal", usb,
     (None, 21.3, None), group="usb", title="USB-C")
R("R3", "5k1", "CC1", "GND", (8.0, 24.1, 0), "usb")
R("R4", "5k1", "CC2", "GND", (8.4, 17.9, 0), "usb")
part("U2", "USBLC6-2SC6", SOT236,
     {"1": "USB_CP", "2": "GND", "3": "USB_CN", "4": "USB_DN", "5": "VBUS", "6": "USB_DP"}, (8.6, 21.3, 90),
     pinfo={"1": "I/O1", "2": "GND", "3": "I/O2", "4": "I/O2", "5": "VBUS", "6": "I/O1"}, group="usb")

# --- charger with power path ------------------------------------------------------
# BQ24074: OUT carries the system from USB or battery; EN2 high, EN1 low: input
# current set by ILIM (1.5k: about 1.0 A); ISET 1k: about 0.9 A charge; TS to the cell's
# own 10k NTC (a 3-wire cell, third wire on pad P17): charging only within 0 ... 50 C;
# TMR 68k: fast-charge timer 10 x 68k x K_TMR 48 s/kOhm = 9.1 h (6.8 ... 11.3 h; TMR is
# specified for 18 ... 72k only) against about 5 ... 6 h for a full charge; ITERM open:
# 10 % termination.
chg = {"1": "TS", "2": "VBAT", "3": "VBAT", "4": "GND", "5": "VBUS", "6": "GND", "7": "PGOOD", "8": "GND",
       "9": "CHG", "10": "VSYS", "11": "VSYS", "12": "ILIM", "13": "VBUS", "14": "TMR", "15": None,
       "16": "ISET", "17": "GND"}
part("U3", "BQ24074RGTR", "Package_DFN_QFN:VQFN-16-1EP_3x3mm_P0.5mm_EP1.6x1.6mm", chg, (12.9, 21.3, 0),
     pinfo={"1": "TS", "2": "BAT", "3": "BAT", "4": "~CE", "5": "EN2", "6": "EN1", "7": "~PGOOD", "8": "VSS",
            "9": "~CHG", "10": "OUT", "11": "OUT", "12": "ILIM", "13": "IN", "14": "TMR", "15": "ITERM",
            "16": "ISET", "17": "VSS"}, group="charger", title="Charger")
Cc("C4", "4u7", "VBUS", "GND", (12.9, 24.9, 0), "charger", C0603)
Cc("C5", "10u", "VSYS", "GND", (15.9, 21.3, 90), "charger", C0603)
Cc("C6", "10u", "VBAT", "GND", (12.9, 17.7, 0), "charger", C0603)
R("R6", "1k5", "ILIM", "GND", (12.9, 26.2, 0), "charger")
R("R7", "1k", "ISET", "GND", (11.6, 16.1, 0), "charger")
R("R8", "68k", "TMR", "GND", (13.6, 16.1, 0), "charger")
# charge light [given 2026-11-15: red while charging, green when full; red too when the
# battery runs low]: a side-emitting red/green LED with a common anode on VSYS (USB or
# battery), LiteOn LTST-S326KGJRKT [unverified: which pad is which colour, datasheet
# DS22-2000-287], through a hole in the side wall (elec.scad led_z).
#   red: through R9 into ~CHG, which the charger pulls low while charging, and Q5, which
#        the ESP32 turns on (IO42) when the battery runs low;
#   green: through R27 and Q4 into ~PGOOD (low only with USB); Q4's gate is ~CHG, pulled
#        up through the red LED and R9 once ~CHG lets go, so green comes on when the
#        charge is done and red goes off. Without USB ~PGOOD is open: no green.
part("D1", "LTST-S326KGJRKT", "LED_SMD:LED_LiteOn_LTST-S326",
     {"2": "VSYS", "1": "LED_G", "3": "LED_R"}, (None, 29.0, None), pinfo={"2": "A", "1": "K green", "3": "K red"},
     group="charger")
R("R9", "1k5", "LED_R", "CHG", (3.4, 27.4, 0), "charger")
part("Q4", "DMG1012T", "Package_TO_SOT_SMD:SOT-523", {"1": "CHG", "2": "PGOOD", "3": "LED_GQ"}, (8.4, 25.85, 90),
     pinfo={"1": "G", "2": "S", "3": "D"}, group="charger")
R("R27", "1k5", "LED_G", "LED_GQ", (10.6, 25.9, 90), "charger")
part("Q5", "DMG1012T", "Package_TO_SOT_SMD:SOT-523", {"1": "LOW_BAT", "2": "GND", "3": "CHG"}, (24.1, 15.6, 90),
     pinfo={"1": "G", "2": "S", "3": "D"}, group="charger")
R("R28", "100k", "LOW_BAT", "GND", (24.1, 13.9, 0), "charger")

# --- battery: the cell carries its own protection board (PCM) [chosen]; a fuse here ---
part("F1", "PTC 1.5 A hold", "Fuse:Fuse_1206_3216Metric", {"1": "BATP", "2": "VBAT"}, (19.6, 6.0, 0),
     group="battery", title="Battery")
R("R12", "1M", "VBAT", "VBAT_SENSE", (22.4, 9.0, 90), "battery")
R("R13", "1M", "VBAT_SENSE", "GND", (22.4, 11.3, 90), "battery")
Cc("C8", "100n", "VBAT_SENSE", "GND", (23.6, 12.4, 90), "battery")

# --- system switch and 3.3 V --------------------------------------------------------
# DET: the discant's contact board ties it to ground when the halves are plugged for
# playing. Pulled low it turns on Q2 (system on) and Q3 (3.3 V to the discant through the
# contacts). USB's VBUS also turns the system on (firmware, MIDI, charging with the ESP32
# awake), never the discant's 3.3 V: apart, the contacts carry nothing.
# R14 100k with C9 100n: the gate falls with about 9 ms, so Q3 turns on 3 ... 7 ms after DET
# closes and is fully on after about 12: the pins' spread as the bass slides on is
# covered before the discant's capacitors charge through them
R("R14", "100k", "DET", "DET_G", (19.9, 28.8, 90), "power")
R("R15", "1M", "DET_G", "VSYS", (21.0, 28.8, 90), "power")
Cc("C9", "100n", "DET_G", "GND", (22.1, 28.8, 90), "power")
part("Q2", "AO3401A", SOT23, {"1": "DET_G", "2": "VSYS", "3": "EN_DET"}, (12.9, 28.8, 0),
     pinfo={"1": "G", "2": "S", "3": "D"}, group="power")
part("D2", "BAT54C", SOT23, {"1": "EN_DET", "2": "VBUS", "3": "EN_SYS"}, (8.7, 28.8, 0),
     pinfo={"1": "A1", "2": "A2", "3": "K"}, group="power")
R("R16", "1M", "EN_SYS", "GND", (12.0, 31.9, 90), "power")   # beside D2: EN_SYS needs one track, D2 to U5
# TPS63001: buck-boost, fixed 3.3 V, from the system rail (3.0 .. 4.4 V); PS/SYNC high:
# fixed frequency, no power-save bursts near the audio
part("U5", "TPS63001DRCR", "Package_SON:Texas_DRC0010J", {"1": "+3V3", "2": "L2", "3": "GND", "4": "L1",
     "5": "VSYS", "6": "EN_SYS", "7": "VSYS", "8": "VINA", "9": "GND", "10": "+3V3", "11": "GND"}, (19.8, 21.3, 0),
     pinfo={"1": "VOUT", "2": "L2", "3": "PGND", "4": "L1", "5": "VIN", "6": "EN", "7": "PS/SYNC", "8": "VINA",
            "9": "GND", "10": "FB", "11": "PGND"}, group="power", title="3.3 V")
part("L1", "2.2u, Isat 2 A", "Inductor_SMD:L_1008_2520Metric", {"1": "L1", "2": "L2"}, (19.8, 17.4, 0), group="power")
Cc("C10", "10u", "VSYS", "GND", (17.6, 25.0, 0), "power", C0805)
R("R17", "100R", "VSYS", "VINA", (21.0, 25.6, 0), "power")
Cc("C11", "100n", "VINA", "GND", (21.0, 24.5, 0), "power")
Cc("C12", "22u", "+3V3", "GND", (23.4, 18.6, 90), "power", C0805)
Cc("C13", "22u", "+3V3", "GND", (23.4, 22.4, 90), "power", C0805)
part("Q3", "AO3401A", SOT23, {"1": "DET_G", "2": "+3V3", "3": "+3V3_D"}, (17.0, 28.8, 0),
     pinfo={"1": "G", "2": "S", "3": "D"}, group="power")
Cc("C14", "1u", "+3V3_D", "GND", (20.1, 31.9, 90), "power")
R("R18", "10k", "+3V3_D", "DISC_ON", (17.9, 31.9, 90), "power")
R("R19", "100k", "DISC_ON", "GND", (19.0, 31.9, 90), "power")
R("R20", "100k", "VBUS", "VBUS_SENSE", (7.6, 16.1, 0), "power")
R("R21", "100k", "VBUS_SENSE", "GND", (15.6, 16.1, 0), "power")

# --- audio ---------------------------------------------------------------------------
dac = {"1": ("GND", "IOVSS"), "2": ("+3V3", "IOVDD"), "3": ("+1V8", "DVDD"), "4": (None, "NC"), "5": ("I2S_DOUT", "DIN"),
       "6": ("I2S_WCLK", "WCLK"), "7": ("I2S_BCLK", "BCLK"), "8": ("I2S_MCLK", "MCLK"), "9": ("SDA2", "SDA"),
       "10": ("SCL2", "SCL"), "11": (None, "VOL/MICDET"), "12": (None, "MICBIAS"), "13": (None, "AIN1"),
       "14": (None, "AIN2"), "15": (None, "NC"), "16": ("GND", "AVSS"), "17": ("+3V3A", "AVDD"), "18": ("GND", "DVSS"),
       "19": (None, "SPKM"), "20": ("GND", "SPKVSS"), "21": ("+3V3", "SPKVDD"), "22": (None, "SPKP"), "23": (None, "SPKM"),
       "24": ("+3V3", "SPKVDD"), "25": ("GND", "SPKVSS"), "26": (None, "SPKP"), "27": ("HPL", "HPL"), "28": ("+3V3A", "HPVDD"),
       "29": ("GND", "HPVSS"), "30": ("HPR", "HPR"), "31": ("DAC_RST", "RESET"), "32": (None, "GPIO1"), "33": ("GND", "EP")}
part("U7", "TLV320DAC3100IRHBR", "Package_DFN_QFN:VQFN-32-1EP_5x5mm_P0.5mm_EP3.1x3.1mm",
     {p: v[0] for p, v in dac.items()}, (36.4, 29.8, 90), pinfo={p: v[1] for p, v in dac.items()}, group="audio",
     title="Audio")
part("U6", "TLV75518PDBVR", "Package_TO_SOT_SMD:SOT-23-5", {"1": "+3V3", "2": "GND", "3": "+3V3", "4": None, "5": "+1V8"},
     (30.1, 31.0, 0), pinfo={"1": "IN", "2": "GND", "3": "EN", "4": "NC", "5": "OUT"}, group="audio")
Cc("C15", "1u", "+3V3", "GND", (28.6, 27.6, 90), "audio")
Cc("C16", "1u", "+1V8", "GND", (30.8, 27.6, 90), "audio")
part("FB1", "600R @ 100 MHz", "Inductor_SMD:L_0402_1005Metric", {"1": "+3V3", "2": "+3V3A"}, (40.3, 27.6, 90), group="audio")
Cc("C17", "100n", "+3V3", "GND", (27.5, 27.6, 90), "audio")
Cc("C18", "100n", "+1V8", "GND", (31.9, 27.6, 90), "audio")
Cc("C19", "100n", "+3V3A", "GND", (40.3, 29.8, 90), "audio")
Cc("C20", "10u", "+3V3A", "GND", (42.4, 27.4, 0), "audio")
Cc("C21", "100n", "+3V3", "GND", (40.3, 31.75, 90), "audio")
Cc("C24", "100n", "+3V3A", "GND", (32.7, 31.0, 90), "audio")
R("R22", "100k", "DAC_RST", "GND", (29.7, 27.6, 90), "audio")
Cc("C22", "100u", "HPL", "EAR_L", (11.9, 6.0, 0), "audio", C0805)
Cc("C23", "100u", "HPR", "EAR_R", (15.4, 6.0, 0), "audio", C0805)
# the earphone jack is not on the board: a panel jack (Switchcraft 35PRM3, M6 nut) in the
# side wall, its body over the board (../bass/elec.scad), three wires to these pads. Under
# its body (JACK_ZONE: X from the edge to its lugs' end, Y round its axis) the parts stay
# low: 1.0 mm under the flange at the edge, about 1.9 under the body on its axis.
JACK_Y = 9.8                                   # its axis [given: elec.scad jack_z]
JACK_ZONE = (0.0, 21.0, JACK_Y - 4.75, JACK_Y + 4.75)   # X0, X1, Y0, Y1
for i, (net, name) in enumerate((("EAR_L", "jack tip (left)"), ("EAR_R", "jack ring (right)"), ("GND", "jack sleeve"))):
    part(f"P{19 + i}", name, PAD, {"1": net}, (15.6 + 2.1 * i, JACK_Y, 0), group="audio",
         title="Earphones" if i == 0 else None)

# --- I2C: bus 1 to the discant through the contacts, bus 2 in the bass ----------------
R("R23", "2k2", "SDA1", "+3V3_D", (21.0, 14.6, 0), "i2c")
R("R24", "2k2", "SCL1", "+3V3_D", (21.0, 13.4, 0), "i2c")
R("R25", "2k2", "SDA2", "+3V3", (24.6, 27.0, 0), "i2c")
R("R26", "2k2", "SCL2", "+3V3", (22.0, 26.9, 0), "i2c")
# the contacts' lines are touched when the bass is apart
part("U8", "SRV05-4", SOT236, {"1": "SDA1", "2": "GND", "3": "SCL1", "4": "INT1", "5": "+3V3", "6": None},
     (17.8, 13.4, 0), pinfo={"1": "IO1", "2": "VN", "3": "IO2", "4": "IO3", "5": "VP", "6": "IO4"}, group="i2c")

# --- wires: solder pads at the bottom edge --------------------------------------------
WIRES = [("+3V3_D", "contacts 3.3 V"), ("+3V3_D", "contacts 3.3 V"), ("GND", "contacts GND"), ("GND", "contacts GND"),
         ("GND", "contacts GND"), ("SDA1", "contacts SDA"), ("SCL1", "contacts SCL"), ("INT1", "contacts INT"),
         ("GND", "battery -"),
         ("DET", "contacts DET"), ("+3V3", "bass keys 3.3 V"), ("GND", "bass keys GND"), ("SDA2", "bass keys SDA"),
         ("SCL2", "bass keys SCL"), ("INT2", "bass keys INT"), ("GND", "spare GND / NTC return"), ("TS", "battery NTC"),
         ("BATP", "battery +")]
for i, (net, name) in enumerate(WIRES):
    part(f"P{i + 1}", name, PAD, {"1": net}, (1.2 + 2.0 * (i % 9), 1.0 + 1.85 * (i // 9), 0), group="wires",
         title="Wires")

# JLCPCB / LCSC part numbers for the BOM, by (value, footprint) [checked 2026-11-15 at jlcpcb.com:
# all in stock; "basic" parts need no extended-part fee]. The test and wire pads have none.
LCSC = {
    ("ESP32-S3-WROOM-1-N16R8", "RF_Module:ESP32-S3-WROOM-1"): "C2913202",
    ("USB4105-GF-A", "Connector_USB:USB_C_Receptacle_GCT_USB4105-xx-A_16P_TopMnt_Horizontal"): "C3020560",
    ("USBLC6-2SC6", SOT236): "C7519",
    ("BQ24074RGTR", "Package_DFN_QFN:VQFN-16-1EP_3x3mm_P0.5mm_EP1.6x1.6mm"): "C54313",
    ("TPS63001DRCR", "Package_SON:Texas_DRC0010J"): "C28060",
    ("TLV320DAC3100IRHBR", "Package_DFN_QFN:VQFN-32-1EP_5x5mm_P0.5mm_EP3.1x3.1mm"): "C179677",
    ("TLV75518PDBVR", "Package_TO_SOT_SMD:SOT-23-5"): "C2877863",
    ("SRV05-4", SOT236): "C85364",                     # ProTek SRV05-4-P-T7
    ("AO3401A", SOT23): "C15127",                      # basic
    ("BAT54C", SOT23): "C37704",                       # Nexperia BAT54C,215
    ("DMG1012T", "Package_TO_SOT_SMD:SOT-523"): "C20512",   # DMG1012T-7
    ("LTST-S326KGJRKT", "LED_SMD:LED_LiteOn_LTST-S326"): "C125116",
    ("2.2u, Isat 2 A", "Inductor_SMD:L_1008_2520Metric"): "C23894",   # Sunlord SWPA252012S2R2MT, Isat 2.07 A
    ("PTC 1.5 A hold", "Fuse:Fuse_1206_3216Metric"): "C20802",        # SMD1206P150TF, 6 V
    ("600R @ 100 MHz", "Inductor_SMD:L_0402_1005Metric"): "C76884",   # Murata BLM15AG601SN1D, 300 mA
    ("100u", C0805): "C141660",                        # Murata GRM21BR60J107ME15L, 6.3 V
    ("22u", C0805): "C45783",                          # basic, 25 V
    ("10u", C0805): "C15850",                          # basic, 25 V
    ("10u", C0603): "C19702",                          # basic, 10 V
    ("10u", C0402): "C15525",                          # basic, 6.3 V
    ("4u7", C0603): "C19666",                          # basic, 16 V
    ("1u", C0402): "C52923",                           # basic, 25 V
    ("100n", C0402): "C1525",                          # basic, 16 V
    ("100R", R0402): "C25076", ("1k", R0402): "C11702", ("1k5", R0402): "C25867", ("2k2", R0402): "C25879",
    ("5k1", R0402): "C25905", ("10k", R0402): "C25744", ("100k", R0402): "C25741", ("1M", R0402): "C26083",
    ("68k", R0402): "C36871",                          # UNI-ROYAL 0402WGF6802TCE, extended; the rest basic
}
