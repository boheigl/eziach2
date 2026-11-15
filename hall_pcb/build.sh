#!/bin/sh
# Builds a Hall-sensor board (discant or bass, first argument; default discant): gen_pcb, then route; nets that fail go first
# in the next try. Keeps the best board (scored by KiCad's DRC), then draws the
# schematic, the viewer, and the fabrication files to <board>/fab/.
set -e
cd "$(dirname "$0")"
B=${1:-discant}
export HALL_BOARD=$B
mkdir -p $B
# HALL_PRI: the nets routed first in the first try; HALL_TRIES: how many tries
PRI=${HALL_PRI:-SDA,SCL,INT,+3V3}
best=9999
for try in $(seq 1 ${HALL_TRIES:-3}); do
    python3 gen_pcb.py $B/$B.kicad_pcb > $B/gen.log 2>&1
    timeout 3000 python3 route.py $B/$B.kicad_pcb "$PRI" > $B/route.log 2>&1 || { echo "try $try: router stopped"; continue; }
    kicad-cli pcb drc --format json -o $B/drc_try.json $B/$B.kicad_pcb > /dev/null 2>&1 || true
    n=$(python3 -c "
import json; d=json.load(open('$B/drc_try.json'))
bad=sum(v['type'] in ('shorting_items','tracks_crossing','clearance','hole_to_hole','copper_edge_clearance') for v in d['violations'])
print(len(d['unconnected_items']) + 10 * bad)")
    echo "try $try: score $n"
    if [ "$n" -lt "$best" ]; then best=$n; cp $B/$B.kicad_pcb $B/best.kicad_pcb; cp $B/pins.json $B/best_pins.json; cp $B/channels.json $B/best_channels.json; fi
    [ "$n" -eq 0 ] && break
    PRI=$(python3 -c "
import json
f=[x[0] for x in json.load(open('$B/route_failed.json'))]
old='$PRI'.split(',')
seen=[]
for n in f+old:
    if n not in seen: seen.append(n)
print(','.join(seen))")
done
mv $B/best.kicad_pcb $B/$B.kicad_pcb; mv $B/best_pins.json $B/pins.json; mv $B/best_channels.json $B/channels.json
rm -f $B/drc_try.json
python3 gen_sch.py $B
echo "best: $best"
# fabrication: gerbers, drill, positions, BOM
mkdir -p $B/fab
kicad-cli pcb export gerbers -o $B/fab/ $B/$B.kicad_pcb > /dev/null
kicad-cli pcb export drill -o $B/fab/ $B/$B.kicad_pcb > /dev/null
kicad-cli pcb export pos --side back --units mm --format csv -o $B/fab/$B-pos.csv $B/$B.kicad_pcb > /dev/null
kicad-cli sch export bom -o $B/fab/$B-bom.csv --group-by Value,Footprint --fields 'Reference,Value,Footprint,${QUANTITY}' $B/$B.kicad_sch > /dev/null
kicad-cli pcb drc --format json -o $B/drc.json $B/$B.kicad_pcb > /dev/null 2>&1 || true
python3 export_view.py $B/$B.kicad_pcb $B/drc.json
python3 export_scad.py $B/$B.kicad_pcb
