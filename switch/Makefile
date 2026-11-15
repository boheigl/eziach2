# Builds every file generated from the key's sources into ../build/switch/: the
# board STLs and DXFs and the button parts. Only what changed is rebuilt.
# ../build/ (one folder per project) is not under version control; delete it
# at any time.
#   make                             everything
#   make ../build/switch/pcb.stl     one file (and what it needs)
#   make -j                          in parallel
#   make clean                       deletes ../build/switch/
#
# OpenSCAD writes the files each output reads (use <...>, import()) to
# ../build/switch/.deps/, so those dependencies are tracked without listing
# them here. ../discant/ uses these parts.

OPENSCAD ?= openscad
B        := ../build/switch

PCB_STL    := $(addprefix $(B)/,pcb.stl pcb_12.stl pcb_11.stl pcb_10.stl \
                                pcb_board.stl pcb_copper.stl pcb_connector.stl \
                                pcb_board_12.stl pcb_board_11.stl pcb_board_10.stl \
                                pcb_copper_12.stl pcb_copper_11.stl pcb_copper_10.stl)
PCB_DXF    := $(addprefix $(B)/,pcb.dxf pcb_copper.dxf pcb_copper_top.dxf pcb_drill.dxf pcb_mask.dxf)
BUTTON_STL := $(addprefix $(B)/,button.stl felt.stl washer.stl sleeve.stl screw.stl guide.stl spring.stl)

all: ioexp.scad $(PCB_STL) $(PCB_DXF) $(BUTTON_STL)
$(PCB_STL) $(PCB_DXF): ioexp.scad

# $(call scad,source,extra options)
scad = @mkdir -p $(B)/.deps && echo "  OPENSCAD $@" && \
       $(OPENSCAD) -q -o $@ -d $(B)/.deps/$(notdir $@).d $(2) $(1)

# --- the -x end's expander layout, checked (fails on a clearance violation)
ioexp.scad: ioexp_layout.py
	@echo "  LAYOUT   $@" && python3 ioexp_layout.py

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
# laminate and copper of the sawn-off boards apart (for the discant's phone page)
cut_of = $(if $(findstring 12,$1),1,$(if $(findstring 11,$1),2,3))
$(B)/pcb_board_12.stl $(B)/pcb_board_11.stl $(B)/pcb_board_10.stl: $(B)/pcb_board_%.stl: pcb.scad
	$(call scad,$<,-D cut_holes=$(call cut_of,$*) -D 'part="board"')
$(B)/pcb_copper_12.stl $(B)/pcb_copper_11.stl $(B)/pcb_copper_10.stl: $(B)/pcb_copper_%.stl: pcb.scad
	$(call scad,$<,-D cut_holes=$(call cut_of,$*) -D 'part="copper"')
$(B)/pcb.dxf: pcb.scad
	$(call scad,$<,-D flat=true -D 'part="board"')
$(B)/pcb_copper.dxf $(B)/pcb_copper_top.dxf $(B)/pcb_drill.dxf $(B)/pcb_mask.dxf: $(B)/pcb_%.dxf: pcb.scad
	$(call scad,$<,-D flat=true -D 'part="$*"')

# --- button.scad: moving parts at the upper stop
$(BUTTON_STL): $(B)/%.stl: button.scad
	$(call scad,$<,-D 'part="$*"')

clean:
	rm -rf $(B)

.PHONY: all clean
.DELETE_ON_ERROR:

-include $(wildcard $(B)/.deps/*.d)
