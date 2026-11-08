#!/bin/sh
# gen_pcb, then route; nets that fail go first in the next try. Keeps the best board.
PRI="I2S_BCLK,I2S_WCLK,I2S_DOUT,I2S_MCLK,SDA,SCL,DAC_RST,HPL,HPR,+1V8,+3V3A,+3V3,VIN"
best=9999
for try in 1 2 3; do
    python3 gen_pcb.py > gen.log 2>&1
    timeout 3000 python3 route.py "$PRI" > route.log 2>&1 || { echo "try $try: router stopped"; continue; }
    # scored by KiCad's DRC, not by the router: unconnected items, shorts ten times
    kicad-cli pcb drc --format json -o drc_try.json main_pcb.kicad_pcb > /dev/null 2>&1
    n=$(python3 -c "
import json; d=json.load(open('drc_try.json'))
bad=sum(v['type'] in ('shorting_items','tracks_crossing','clearance','hole_to_hole') for v in d['violations'])
print(len(d['unconnected_items']) + 10 * bad)")
    echo "try $try: score $n (router: $(python3 -c "import json;print(len(json.load(open('route_failed.json'))))") open)"
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
cp best.kicad_pcb main_pcb.kicad_pcb
echo "best: $best open"
