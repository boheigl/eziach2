# Discant and bass together: the discant's parts moved into the bass's frame
# (assembly.scad), the 3D view view3d.html. Builds discant/ and bass/ first.
#   make        everything
#   make clean  deletes ../build/assembly/
#   make promo  the promo video, ../build/assembly/eziach_promo.webm and .mp4 (video/promo.py;
#               about an hour, not part of all; needs the parts built)

OPENSCAD ?= openscad
PYTHON   ?= python3
B  := ../build/assembly
BB := ../build/bass

D_COLS := red black blue yellow green
B_COLS := red black blue yellow green white orange brown
PIECES := $(addprefix $(B)/,d_housing.stl d_cover.stl d_boards.stl d_parts.stl d_cables.stl \
                           keys_bass.stl keys_discant.stl $(foreach c,$(D_COLS),d_wires_$(c).stl))

all: $(B)/view3d.html

# the discant's pieces come in as its built STLs
D_STL := $(wildcard ../build/discant/*.stl)
$(PIECES): $(B)/%.stl: assembly.scad ../bass/link.scad ../bass/layout.scad $(D_STL) | parts
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ -D 'part="$*"' $<

parts:
	@$(MAKE) --no-print-directory -C ../discant
	@$(MAKE) --no-print-directory -C ../bass

VIEW_PARTS := B_CASE=$(BB)/case.stl B_LID=$(BB)/back_cover.stl B_CSCREW=$(BB)/cover_screws.stl B_BAT=$(BB)/battery.stl B_COVER=$(BB)/cover.stl B_BOARD=$(BB)/boards.stl B_CONN=$(BB)/connectors.stl B_ELEC=$(BB)/elec.stl $(foreach c,$(B_COLS),B_W_$(c)=$(BB)/wires_$(c).stl) B_STRAP=$(BB)/strap.stl B_ROD=$(BB)/latch_rod.stl B_LEVER=$(BB)/lever.stl B_PINS=$(BB)/contact_pins.stl \
               D_HOUSING=$(B)/d_housing.stl D_COVER=$(B)/d_cover.stl D_BOARDS=$(B)/d_boards.stl D_PARTS=$(B)/d_parts.stl \
               D_CABLES=$(B)/d_cables.stl $(foreach c,$(D_COLS),D_W_$(c)=$(B)/d_wires_$(c).stl) \
               KEYS_B=$(B)/keys_bass.stl KEYS_D=$(B)/keys_discant.stl
BASS_STL := $(addprefix $(BB)/,case.stl back_cover.stl cover_screws.stl battery.stl cover.stl boards.stl connectors.stl elec.stl wires.stl $(foreach c,$(B_COLS),wires_$(c).stl) strap.stl latch_rod.stl lever.stl contact_pins.stl)
$(BASS_STL): parts ;
$(B)/view3d.html: view3d.html ../discant/embed_parts.py ../discant/viewer_nav.js $(PIECES) $(BASS_STL)
	@echo "  EMBED    $@"
	@$(PYTHON) ../discant/embed_parts.py $< $@ $(VIEW_PARTS)

promo: $(PIECES) $(BASS_STL) $(BB)/discant_link.stl video/promo.py video/promo.scad video/frames.scad
	$(PYTHON) video/promo.py $(B)/eziach_promo.webm

clean:
	rm -rf $(B)
.PHONY: all clean parts promo
