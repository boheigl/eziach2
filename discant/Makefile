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

OPENSCAD ?= openscad
PYTHON   ?= python3
B        := ../build/discant
KEY      := ../build/switch_hall

BODY_STL := $(addprefix $(B)/,housing.stl cover.stl gauge_link.stl)
KEY_STL  := $(addprefix $(KEY)/,cap.stl plunger.stl magnet.stl oring.stl stop.stl \
                                cap_down.stl plunger_down.stl magnet_down.stl oring_down.stl stop_down.stl)

all: $(BODY_STL) $(B)/board.stl $(B)/board_parts.stl $(B)/keys.stl $(B)/keys_down.stl $(B)/phone.html

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
               HOUSING_TRIS=$(B)/housing.stl COVER_TRIS=$(B)/cover.stl LINK_TRIS=$(B)/gauge_link.stl \
               CAP_TRIS=$(KEY)/cap.stl PLUNGER_TRIS=$(KEY)/plunger.stl MAGNET_TRIS=$(KEY)/magnet.stl \
               ORING_TRIS=$(KEY)/oring.stl STOP_TRIS=$(KEY)/stop.stl
$(B)/phone.html: phone.html embed_parts.py viewer_nav.js $(BODY_STL) $(B)/board.stl $(B)/board_parts.stl $(KEY_STL) ../hall_pcb/discant/board.scad
	@echo "  EMBED    $@"
	@$(PYTHON) embed_parts.py $< $@ --keys ../hall_pcb/discant/board.scad $(PHONE_PARTS)

# --- printing (print.scad, spec.md Printing): the holder's test piece as printed, on the plate
# (plate.py), and as a sliced Bambu Studio project for the X2D in PETG (../key_proto/bambu.py;
# needs Bambu Studio: the AppImage or the Flathub app; not part of all)
$(B)/print_holder_test.stl: print.scad $(B)/housing.stl
	$(call scad,$<,-D 'part="holder_test"')
$(B)/holder_test.3mf: plate.py ../key_proto/plate.py $(B)/print_holder_test.stl
	@echo "  PLATE    $@" && $(PYTHON) plate.py $(B)
# the AppImage if there is one, else the Flathub app (bambu.py)
BAMBU ?= $(if $(wildcard $(HOME)/Applications/BambuStudio.AppImage),$(HOME)/Applications/BambuStudio.AppImage,flatpak)
bambu: $(B)/holder_test_x2d.3mf
$(B)/holder_test_x2d.3mf: ../key_proto/bambu.py $(B)/holder_test.3mf
	@$(PYTHON) ../key_proto/bambu.py $(BAMBU) $(B) holder_test

clean:
	rm -rf $(B)

.PHONY: all clean key gauge bambu
.DELETE_ON_ERROR:

-include $(wildcard $(B)/.deps/*.d)
