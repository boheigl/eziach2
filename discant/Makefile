# Builds every file generated from the discant's sources into ../build/discant/:
# housing, cover, the gauges with their wires, the Hall-sensor board with its part
# bodies, the 46 keys, and the phone page phone.html. Only what changed is rebuilt.
#   make                             everything (and the key's parts it needs)
#   make ../build/discant/cover.stl  one file (and what it needs)
#   make -j                          in parallel
#   make clean                       deletes ../build/discant/
#
# The key's parts come from ../switch_hall/, built there into ../build/switch_hall/;
# the board's data from ../hall_pcb/discant/board.scad (written by its build.sh).
# OpenSCAD writes the files each output reads (use <...>, import()) to
# ../build/discant/.deps/, so those dependencies are tracked without listing them here.
#
# Still in this folder from the four-board staircase, not built any more and kept for
# the bass and the assembly until they are moved over: array.scad, array.html,
# main_pcb.scad, stl2js.py.

OPENSCAD ?= openscad
PYTHON   ?= python3
B        := ../build/discant
KEY      := ../build/switch_hall

BODY_STL := $(addprefix $(B)/,housing.stl cover.stl gauge_link.stl)
KEY_STL  := $(addprefix $(KEY)/,cap.stl plunger.stl magnet.stl oring.stl stop.stl \
                                cap_down.stl plunger_down.stl magnet_down.stl oring_down.stl stop_down.stl)

all: $(BODY_STL) $(B)/gauge_lid.stl $(B)/board.stl $(B)/board_parts.stl $(B)/keys.stl $(B)/keys_down.stl $(B)/phone.html

# $(call scad,source,extra options)
scad = @mkdir -p $(B)/.deps && echo "  OPENSCAD $@" && \
       $(OPENSCAD) -q --export-format binstl -o $@ -d $(B)/.deps/$(notdir $@).d $(2) $(1)

$(BODY_STL): $(B)/%.stl: %.scad
	$(call scad,$<)

# gauge_link.scad imports the gauge's STLs, built in ../strain_gauge/; the outer
# holders are part of the housing
GAUGE_STL := $(addprefix ../build/strain_gauge/,outer_holder.stl inner_holder.stl strain_gauge_plate.stl)
$(B)/gauge_link.stl $(B)/housing.stl: $(GAUGE_STL)
$(GAUGE_STL): gauge ;
gauge:
	@$(MAKE) --no-print-directory -C ../strain_gauge

# the link pocket's lid, a printed part of its own
$(B)/gauge_lid.stl: gauge_link.scad
	$(call scad,$<,-D 'part="lid"')

# the board: laminate, and the parts' bodies on its underside
$(B)/board.stl: board.scad
	$(call scad,$<,-D 'part="board"')
$(B)/board_parts.stl: board.scad
	$(call scad,$<,-D 'part="parts"')

# the keys, at rest and pressed (springs left out, see keys.scad)
$(B)/keys.stl: keys.scad $(KEY_STL)
	$(call scad,$<)
$(B)/keys_down.stl: keys.scad $(KEY_STL)
	$(call scad,$<,-D down=true)
$(KEY_STL): key ;
key:
	@$(MAKE) --no-print-directory -C ../switch_hall

# --- phone page: phone.html with every part embedded (embed_parts.py), one
# file that loads nothing else; NAME=stl as the page reads them
PHONE_PARTS := BOARD_TRIS=$(B)/board.stl PARTS_TRIS=$(B)/board_parts.stl \
               HOUSING_TRIS=$(B)/housing.stl COVER_TRIS=$(B)/cover.stl LINK_TRIS=$(B)/gauge_link.stl LID_TRIS=$(B)/gauge_lid.stl \
               CAP_TRIS=$(KEY)/cap.stl PLUNGER_TRIS=$(KEY)/plunger.stl MAGNET_TRIS=$(KEY)/magnet.stl \
               ORING_TRIS=$(KEY)/oring.stl STOP_TRIS=$(KEY)/stop.stl
$(B)/phone.html: phone.html embed_parts.py $(BODY_STL) $(B)/gauge_lid.stl $(B)/board.stl $(B)/board_parts.stl $(KEY_STL) ../hall_pcb/discant/board.scad
	@echo "  EMBED    $@"
	@$(PYTHON) embed_parts.py $< $@ --keys ../hall_pcb/discant/board.scad $(PHONE_PARTS)

clean:
	rm -rf $(B)

.PHONY: all clean key gauge
.DELETE_ON_ERROR:

-include $(wildcard $(B)/.deps/*.d)
