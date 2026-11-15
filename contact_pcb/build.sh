#!/bin/sh
# Builds the contacts' panel (gen_pcb.py), checks it (KiCad's DRC) and writes the
# fabrication files to fab/: gerbers, drill, positions and a JLCPCB BOM for the pin board.
set -e
cd "$(dirname "$0")"
python3 gen_pcb.py contact.kicad_pcb
kicad-cli pcb drc --format json -o drc.json contact.kicad_pcb > /dev/null 2>&1 || true
python3 -c "
import json; d = json.load(open('drc.json'))
bad = [v['type'] for v in d['violations'] if v['severity'] == 'error']
print('DRC:', len(d['unconnected_items']), 'unconnected,', len(bad), 'errors', sorted(set(bad)))"
mkdir -p fab
kicad-cli pcb export gerbers -o fab/ contact.kicad_pcb > /dev/null
kicad-cli pcb export drill -o fab/ contact.kicad_pcb > /dev/null
kicad-cli pcb export pos --side front --units mm --format csv -o fab/contact-pos.csv contact.kicad_pcb > /dev/null
# BOM (JLCPCB's columns); the pad board and the wire pads carry no parts
cat > fab/contact-bom.csv << 'EOF'
"Comment","Designator","Footprint","LCSC","Quantity"
"PG2541-03-003P","J1,J2,J3","PG2541-03-003P (3 x pad D2.2, 2.54)","C49451741","3"
EOF
echo "fab/: gerbers, drill, contact-pos.csv, contact-bom.csv"
