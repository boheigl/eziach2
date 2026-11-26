# The main board's generated pages (the board itself: ./build.sh, which needs KiCad and routes).
#   make pads   ../build/main_pcb/pads.html, the wire pads' page, from main_pcb.kicad_pcb (kicad-cli)
PYTHON ?= python3
B := ../build/main_pcb

all: pads
pads: $(B)/pads.html
$(B)/pads.html: pads_page.py main_pcb.kicad_pcb $(wildcard drc.json)
	@echo "  PADS     $@"
	@$(PYTHON) pads_page.py $@ > /dev/null
.PHONY: all pads
