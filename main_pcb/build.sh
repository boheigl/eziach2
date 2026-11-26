#!/bin/sh
# Builds the bass's main board: gen_pcb, then route; nets that fail go first in the next
# try. Keeps the best board (scored by KiCad's DRC), then draws the schematic and writes
# the fabrication files to fab/. MAIN_TRIES: how many tries; MAIN_PRI: the nets routed first.
set -e
cd "$(dirname "$0")"
PRI=${MAIN_PRI:-USB_DP,USB_DN,USB_CP,USB_CN,I2S_MCLK,I2S_BCLK,I2S_WCLK,I2S_DOUT,L1,L2}
best=9999
for try in $(seq 1 ${MAIN_TRIES:-3}); do
    python3 gen_pcb.py > gen.log 2>&1
    timeout 3000 python3 route.py "$PRI" > route.log 2>&1 || { echo "try $try: router stopped"; continue; }
    kicad-cli pcb drc --format json -o drc_try.json main_pcb.kicad_pcb > /dev/null 2>&1 || true
    n=$(python3 -c "
import json; d=json.load(open('drc_try.json'))
bad=sum(v['type'] in ('shorting_items','tracks_crossing','clearance','hole_to_hole','copper_edge_clearance') for v in d['violations'])
print(len(d['unconnected_items']) + 10 * bad)")
    echo "try $try: score $n"
    if [ "$n" -lt "$best" ]; then best=$n; cp main_pcb.kicad_pcb best.kicad_pcb; fi
    [ "$n" -eq 0 ] && break
    PRI=$(python3 -c "
import json
f=[x[0] for x in json.load(open('route_failed.json'))]
old='$PRI'.split(',')
seen=[]
for n in f+old:
    if n not in seen: seen.append(n)
print(','.join(seen))")
done
mv best.kicad_pcb main_pcb.kicad_pcb
rm -f drc_try.json
python3 gen_sch.py
echo "best: $best"
mkdir -p fab
kicad-cli pcb export gerbers -o fab/ main_pcb.kicad_pcb > /dev/null
kicad-cli pcb export drill -o fab/ main_pcb.kicad_pcb > /dev/null
kicad-cli pcb export pos --side front --units mm --format csv -o fab/main_pcb-pos.csv main_pcb.kicad_pcb > /dev/null
kicad-cli sch export bom -o fab/main_pcb-bom.csv --group-by Value,Footprint --fields 'Value,Reference,Footprint,LCSC,${QUANTITY}' --labels 'Comment,Designator,Footprint,LCSC,Quantity' --exclude-dnp main_pcb.kicad_sch > /dev/null
kicad-cli pcb drc --format json -o drc.json main_pcb.kicad_pcb > /dev/null 2>&1 || true
python3 pads_page.py > /dev/null   # the page of the wire pads, ../build/main_pcb/pads.html
