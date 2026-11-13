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

all: $(STL) $(DOWN)

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
