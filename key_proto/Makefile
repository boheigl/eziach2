# Builds the key prototype (2 rows of 4 keys on a board stand-in) into ../build/key_proto/:
# to print base.stl, board.stl (or a blank PCB), cover.stl, cap.stl (8) and collar.stl (8); keys.stl and keys_down.stl
# show the key parts in place; print_*.stl lie as printed, and plate.3mf / fit_test.3mf
# hold them arranged on the Bambu Lab X2D's plate (plate.py, print.scad).
#   make        everything (and the key's parts it shows, in ../switch_hall/)
#   make clean  deletes ../build/key_proto/

OPENSCAD ?= openscad
B        := ../build/key_proto
KEY_STL  := $(addprefix ../build/switch_hall/,$(foreach p,cap plunger magnet oring stop spring,$(p).stl $(p)_down.stl))

PRINT := $(addprefix $(B)/print_,$(addsuffix .stl,tray board cover cap collar tube))

all: $(B)/base.stl $(B)/board.stl $(B)/cover.stl $(B)/cap.stl $(B)/collar.stl $(B)/keys.stl $(B)/keys_down.stl \
     $(B)/plate.3mf

scad = @mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ $(2) $(1)

$(B)/base.stl: proto.scad ../switch_hall/key.scad
	$(call scad,$<,-D 'part="base"')
$(B)/board.stl: proto.scad
	$(call scad,$<,-D 'part="board"')
$(B)/cover.stl: proto.scad ../switch_hall/key.scad
	$(call scad,$<,-D 'part="cover"')
# the printed key parts, single, as the discant's
$(B)/cap.stl $(B)/collar.stl $(B)/tube.stl: $(B)/%.stl: ../switch_hall/key.scad
	$(call scad,$<,-D 'part="$*"')

# the parts as printed, and the plate
$(B)/print_tray.stl $(B)/print_board.stl $(B)/print_cover.stl: $(B)/print_%.stl: print.scad proto.scad ../switch_hall/key.scad
	$(call scad,$<,-D 'part="$*"')
$(B)/print_cap.stl $(B)/print_collar.stl $(B)/print_tube.stl: $(B)/print_%.stl: print.scad $(B)/%.stl
	$(call scad,$<,-D 'part="$*"')
$(B)/plate.3mf: plate.py $(PRINT)
	@echo "  PLATE    $@" && python3 plate.py $(B)
$(B)/keys.stl: proto.scad $(KEY_STL)
	$(call scad,$<,-D 'part="keys"')
$(B)/keys_down.stl: proto.scad $(KEY_STL)
	$(call scad,$<,-D 'part="keys"' -D down=true)
$(KEY_STL): key ;
key:
	@$(MAKE) --no-print-directory -C ../switch_hall

clean:
	rm -rf $(B)

# Bambu Studio projects for the X2D in PETG, sliced (bambu.py; needs Bambu Studio: the AppImage or the Flathub app; not part of all)
# the AppImage if there is one (or the extracted one linked as ~/.local/bin/bambu-studio), else the Flathub app (bambu.py)
BAMBU ?= $(firstword $(wildcard $(HOME)/Applications/BambuStudio.AppImage $(HOME)/.local/bin/bambu-studio) flatpak)
bambu: $(B)/plate_x2d.3mf
$(B)/plate_x2d.3mf: bambu.py $(B)/plate.3mf
	@python3 bambu.py $(BAMBU) $(B)

# the plate's project and PRINTING.txt in one zip, for someone printing on an X2D
zip: $(B)/key_proto_x2d.zip
$(B)/key_proto_x2d.zip: PRINTING.txt $(B)/plate_x2d.3mf
	@echo "  ZIP      $@" && zip -j -q -FS $@ PRINTING.txt $(B)/plate_x2d.3mf

.PHONY: all clean key bambu zip
.DELETE_ON_ERROR:
