# Discant and bass together: the discant's parts moved into the bass's frame
# (assembly.scad), the phone page phone.html. Builds discant/ and bass/ first.
#   make        everything
#   make clean  deletes ../build/assembly/

OPENSCAD ?= openscad
PYTHON   ?= python3
B  := ../build/assembly
BB := ../build/bass

PIECES := $(addprefix $(B)/,d_housing.stl d_cover.stl d_boards.stl d_copper.stl d_conn.stl d_main.stl d_main_cu.stl d_cables.stl \
                           keys_bass.stl keys_discant.stl)

all: $(B)/phone.html

# the discant's pieces come in as its built STLs (and the routed board's 3D export)
D_STL := $(wildcard ../build/discant/*.stl ../build/discant/main_pcb/*.stl)
$(PIECES): $(B)/%.stl: assembly.scad ../bass/link.scad ../bass/layout.scad $(D_STL) | parts
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ -D 'part="$*"' $<

parts:
	@$(MAKE) --no-print-directory -C ../discant
	@$(MAKE) --no-print-directory -C ../bass

PHONE_PARTS := B_CASE=$(BB)/case.stl B_LID=$(BB)/lid.stl B_BAT=$(BB)/battery.stl B_COVER=$(BB)/cover.stl B_LAM=$(BB)/laminate.stl B_CU=$(BB)/copper.stl B_CONN=$(BB)/connectors.stl \
               D_HOUSING=$(B)/d_housing.stl D_COVER=$(B)/d_cover.stl D_BOARDS=$(B)/d_boards.stl D_CU=$(B)/d_copper.stl \
               D_CONN=$(B)/d_conn.stl D_MAIN=$(B)/d_main.stl D_MAIN_CU=$(B)/d_main_cu.stl D_CABLES=$(B)/d_cables.stl \
               KEYS_B=$(B)/keys_bass.stl KEYS_D=$(B)/keys_discant.stl
BASS_STL := $(addprefix $(BB)/,case.stl lid.stl battery.stl cover.stl laminate.stl copper.stl connectors.stl)
$(BASS_STL): parts ;
$(B)/phone.html: phone.html ../discant/embed_parts.py $(PIECES) $(BASS_STL)
	@echo "  EMBED    $@"
	@$(PYTHON) ../discant/embed_parts.py $< $@ $(PHONE_PARTS)

clean:
	rm -rf $(B)
.PHONY: all clean parts
