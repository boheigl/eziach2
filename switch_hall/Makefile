# Builds the Hall-sensor key's parts into ../build/switch_hall/.
#   make          everything
#   make clean    deletes ../build/switch_hall/
# key.scad asserts its clearances, stresses and the staircase lanes; a failed
# assert stops the build.

OPENSCAD ?= openscad
B        := ../build/switch_hall

PARTS := cap plunger magnet oring stop spring tube sensor board
MOVING := cap plunger magnet oring stop spring
STL   := $(addprefix $(B)/,$(addsuffix .stl,$(PARTS)) key.stl)
# the moving parts at the lower stop, for the cases' assemblies and clash checks
DOWN  := $(addprefix $(B)/,$(addsuffix _down.stl,$(MOVING)))

# the bass (../bass/): its board lies flat (board_tilt = 0), the back row stands 10 higher
# (riser = 10): the moving parts at rest and down, and the tube's body and bores for its cover
BASS_PARTS := $(MOVING) tube_body tube_cut
BASS0 := $(addprefix $(B)/bass0_,$(addsuffix .stl,$(BASS_PARTS))) $(addprefix $(B)/bass0_,$(addsuffix _down.stl,$(MOVING)))
BASS1 := $(addprefix $(B)/bass1_,$(addsuffix .stl,$(BASS_PARTS))) $(addprefix $(B)/bass1_,$(addsuffix _down.stl,$(MOVING)))

all: $(STL) $(DOWN) $(BASS0) $(BASS1)

$(B)/bass0_%_down.stl: key.scad
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ -D 'part="$*"' -D travel=3 -D board_tilt=0 $<
$(B)/bass1_%_down.stl: key.scad
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ -D 'part="$*"' -D travel=3 -D board_tilt=0 -D riser=10 $<
$(B)/bass0_%.stl: key.scad
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ -D 'part="$*"' -D board_tilt=0 $<
$(B)/bass1_%.stl: key.scad
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ -D 'part="$*"' -D board_tilt=0 -D riser=10 $<

$(B)/key.stl: key.scad
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ $<
$(DOWN): $(B)/%_down.stl: key.scad
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ -D 'part="$*"' -D travel=3 $<
$(B)/%.stl: key.scad
	@mkdir -p $(B) && echo "  OPENSCAD $@" && $(OPENSCAD) -q -o $@ -D 'part="$*"' $<

clean:
	rm -rf $(B)

.PHONY: all clean
.DELETE_ON_ERROR:
