# Builds the STLs of the .scad sources into ../build/strain_gauge/. Only what
# changed is rebuilt.
#   make                  everything
#   make -j               in parallel
#   make clean            deletes ../build/strain_gauge/
#
# OpenSCAD writes the files each output reads (use <...>) to
# ../build/strain_gauge/.deps/, so those dependencies are tracked without
# listing them here.

OPENSCAD ?= openscad
B        := ../build/strain_gauge

STL := $(addprefix $(B)/,strain_gauge_plate.stl inner_holder.stl outer_holder.stl)

all: $(STL) $(B)/inner_holder_detent.stl

# the stored position's socket (../bass/link.scad): the latch as a detent
$(B)/inner_holder_detent.stl: inner_holder.scad
	@mkdir -p $(B)/.deps && echo "  OPENSCAD $@"
	@$(OPENSCAD) -q -o $@ -d $(B)/.deps/$(notdir $@).d -D 'latch="detent"' $<

$(STL): $(B)/%.stl: %.scad
	@mkdir -p $(B)/.deps && echo "  OPENSCAD $@"
	@$(OPENSCAD) -q -o $@ -d $(B)/.deps/$(notdir $@).d $<

clean:
	rm -rf $(B)

.PHONY: all clean
.DELETE_ON_ERROR:

-include $(wildcard $(B)/.deps/*.d)
