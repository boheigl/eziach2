# Builds every file generated from the discant's sources into ../build/discant/:
# the housing, cover, main PCB and cable STLs, the assembly array.stl, the .js geometry
# for array.html and the phone page phone.html. Only what changed is rebuilt.
#   make                             everything (and the key's parts it needs)
#   make ../build/discant/housing.js one file (and what it needs)
#   make -j                          in parallel
#   make clean                       deletes ../build/discant/
#
# The key's parts (boards, connector, button) come from ../switch/ and are
# built there, into ../build/switch/. OpenSCAD writes the files each output
# reads (use <...>, import()) to ../build/discant/.deps/, so those dependencies
# are tracked without listing them here.

OPENSCAD ?= openscad
PYTHON   ?= python3
B        := ../build/discant
KEY      := ../build/switch

BODY_STL := $(addprefix $(B)/,main_pcb.stl gauge_link.stl housing.stl cover.stl)
JS       := $(addprefix $(B)/,housing.js cover.js pcb_cable.js main_pcb.js gauge_link.js)
KEY_STL  := $(addprefix $(KEY)/,pcb.stl pcb_12.stl pcb_11.stl pcb_10.stl pcb_connector.stl \
                                button.stl felt.stl washer.stl sleeve.stl screw.stl guide.stl spring.stl)
PHONE_KEY := $(addprefix $(KEY)/,pcb_board.stl pcb_copper.stl pcb_board_12.stl pcb_copper_12.stl \
                                 pcb_board_11.stl pcb_copper_11.stl pcb_board_10.stl pcb_copper_10.stl)

all: $(BODY_STL) $(B)/pcb_cable.stl $(B)/array.stl $(JS) $(B)/phone.html

# $(call scad,source,extra options)
scad = @mkdir -p $(B)/.deps && echo "  OPENSCAD $@" && \
       $(OPENSCAD) -q -o $@ -d $(B)/.deps/$(notdir $@).d $(2) $(1)

# --- one part per file
$(BODY_STL): $(B)/%.stl: %.scad
	$(call scad,$<)

# gauge_link.scad imports the gauge's STLs, built in ../strain_gauge/; the outer
# holders become part of the housing
GAUGE_STL := $(addprefix ../build/strain_gauge/,outer_holder.stl inner_holder.stl strain_gauge_plate.stl)
$(B)/gauge_link.stl $(B)/housing.stl: $(GAUGE_STL)
$(GAUGE_STL): gauge ;
gauge:
	@$(MAKE) --no-print-directory -C ../strain_gauge

# the cables come from the same source as the board
$(B)/pcb_cable.stl: main_pcb.scad
	$(call scad,$<,-D 'show="cables"')

# the routed main PCB (main_pcb/, KiCad) in 3D, and its pieces for the phone page
KICAD3D := $(addprefix $(B)/main_pcb/,kicad_board.stl kicad_copper.stl kicad_parts.stl)
$(KICAD3D) &: main_pcb/main_pcb.kicad_pcb main_pcb/export_3d.py main_pcb/design.py
	@echo "  KICAD    $(B)/main_pcb/"
	@cd main_pcb && $(PYTHON) export_3d.py ../$(B)/main_pcb > /dev/null
$(B)/main_pcb.stl: $(KICAD3D)
MAIN_PIECES := $(addprefix $(B)/,main_pcb_laminate.stl main_pcb_parts.stl main_pcb_copper.stl)
$(MAIN_PIECES): $(B)/main_pcb_%.stl: main_pcb.scad $(KICAD3D)
	$(call scad,$<,-D 'show="$*"')

# array.scad imports the key's STLs from ../build/switch/. The key's own
# Makefile brings them up to date first (once per run); the assembly is rebuilt
# only if one of them changed.
$(B)/array.stl: array.scad $(KEY_STL)
	$(call scad,$<)
$(KEY_STL) $(PHONE_KEY): key ;
key:
	@$(MAKE) --no-print-directory -C ../switch

# --- geometry for array.html
$(B)/housing.js:    VAR = HOUSING_TRIS
$(B)/cover.js:      VAR = COVER_TRIS
$(B)/pcb_cable.js:  VAR = CABLE_TRIS
$(B)/main_pcb.js:   VAR = MAIN_PCB_TRIS
$(B)/gauge_link.js: VAR = LINK_TRIS
$(JS): $(B)/%.js: $(B)/%.stl stl2js.py
	@echo "  STL2JS   $@"
	@$(PYTHON) stl2js.py $< $@ $(VAR)

# --- phone page: phone.html with every part embedded (embed_parts.py), one
# file that loads nothing else; NAME=stl as the page reads them
PHONE_PARTS := BOARD13_TRIS=$(KEY)/pcb_board.stl COPPER13_TRIS=$(KEY)/pcb_copper.stl \
               BOARD12_TRIS=$(KEY)/pcb_board_12.stl COPPER12_TRIS=$(KEY)/pcb_copper_12.stl \
               BOARD11_TRIS=$(KEY)/pcb_board_11.stl COPPER11_TRIS=$(KEY)/pcb_copper_11.stl \
               BOARD10_TRIS=$(KEY)/pcb_board_10.stl COPPER10_TRIS=$(KEY)/pcb_copper_10.stl \
               CONN_TRIS=$(KEY)/pcb_connector.stl \
               HOUSING_TRIS=$(B)/housing.stl COVER_TRIS=$(B)/cover.stl CABLE_TRIS=$(B)/pcb_cable.stl MAIN_PCB_TRIS=$(B)/main_pcb_laminate.stl MAIN_PARTS_TRIS=$(B)/main_pcb_parts.stl MAIN_CU_TRIS=$(B)/main_pcb_copper.stl LINK_TRIS=$(B)/gauge_link.stl \
               BUTTON_TRIS=$(KEY)/button.stl FELT_TRIS=$(KEY)/felt.stl WASHER_TRIS=$(KEY)/washer.stl \
               SLEEVE_TRIS=$(KEY)/sleeve.stl SCREW_TRIS=$(KEY)/screw.stl SPRING_TRIS=$(KEY)/spring.stl
$(B)/phone.html: phone.html embed_parts.py $(BODY_STL) $(B)/pcb_cable.stl $(MAIN_PIECES) $(KEY_STL) $(PHONE_KEY)
	@echo "  EMBED    $@"
	@$(PYTHON) embed_parts.py $< $@ $(PHONE_PARTS)

clean:
	rm -rf $(B)

.PHONY: all clean key gauge
.DELETE_ON_ERROR:

-include $(wildcard $(B)/.deps/*.d)
