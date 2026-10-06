# Builds every file generated from the sources into ../build/switch/: the part
# STLs, the PCB DXFs and the .js geometry for array.html. Only what changed is
# rebuilt.
# ../build/ (one folder per project) is not under version control; delete it
# at any time.
#   make                             everything
#   make ../build/switch/housing.js  one file (and what it needs)
#   make -j                          in parallel
#   make clean                       deletes ../build/switch/
#
# OpenSCAD writes the files each output reads (use <...>, import()) to
# ../build/switch/.deps/, so those dependencies are tracked without listing
# them here.
# ffc_channel.scad (cabling/channel.js, route back_channel) is not rebuilt: no
# part uses it at present.

OPENSCAD ?= openscad
PYTHON   ?= python3
B        := ../build/switch

PCB_STL    := $(addprefix $(B)/,pcb.stl pcb_12.stl pcb_11.stl pcb_10.stl \
                                pcb_board.stl pcb_copper.stl pcb_connector.stl)
PCB_DXF    := $(addprefix $(B)/,pcb.dxf pcb_copper.dxf pcb_copper_top.dxf pcb_drill.dxf pcb_mask.dxf)
BUTTON_STL := $(addprefix $(B)/,button.stl washer.stl sleeve.stl screw.stl guide.stl spring.stl)
BODY_STL   := $(addprefix $(B)/,back_cable.stl housing.stl cover.stl)
JS         := $(addprefix $(B)/,housing.js cover.js back_cable.js)

all: $(PCB_STL) $(PCB_DXF) $(BUTTON_STL) $(BODY_STL) $(B)/array.stl $(JS)

# $(call scad,source,extra options)
scad = @mkdir -p $(B)/.deps && echo "  OPENSCAD $@" && \
       $(OPENSCAD) -q -o $@ -d $(B)/.deps/$(notdir $@).d $(2) $(1)

# --- pcb.scad
$(B)/pcb.stl: pcb.scad
	$(call scad,$<)
$(B)/pcb_12.stl: pcb.scad
	$(call scad,$<,-D cut_holes=1)
$(B)/pcb_11.stl: pcb.scad
	$(call scad,$<,-D cut_holes=2)
$(B)/pcb_10.stl: pcb.scad
	$(call scad,$<,-D cut_holes=3)
$(B)/pcb_board.stl $(B)/pcb_copper.stl $(B)/pcb_connector.stl: $(B)/pcb_%.stl: pcb.scad
	$(call scad,$<,-D 'part="$*"')
$(B)/pcb.dxf: pcb.scad
	$(call scad,$<,-D flat=true -D 'part="board"')
$(B)/pcb_copper.dxf $(B)/pcb_copper_top.dxf $(B)/pcb_drill.dxf $(B)/pcb_mask.dxf: $(B)/pcb_%.dxf: pcb.scad
	$(call scad,$<,-D flat=true -D 'part="$*"')

# --- button.scad: moving parts at the upper stop
$(BUTTON_STL): $(B)/%.stl: button.scad
	$(call scad,$<,-D 'part="$*"')

# --- one part per file
$(BODY_STL): $(B)/%.stl: %.scad
	$(call scad,$<)

# array.scad imports the part STLs from ../build/switch/, so they must exist
# before its first build
$(B)/array.stl: array.scad $(filter-out $(B)/pcb_board.stl $(B)/pcb_copper.stl,$(PCB_STL)) $(BUTTON_STL)
	$(call scad,$<)

# --- geometry for array.html
$(B)/housing.js:    VAR = HOUSING_TRIS
$(B)/cover.js:      VAR = COVER_TRIS
$(B)/back_cable.js: VAR = CABLE_TRIS
$(JS): $(B)/%.js: $(B)/%.stl stl2js.py
	@echo "  STL2JS   $@"
	@$(PYTHON) stl2js.py $< $@ $(VAR)

clean:
	rm -rf $(B)

.PHONY: all clean
.DELETE_ON_ERROR:

-include $(wildcard $(B)/.deps/*.d)
