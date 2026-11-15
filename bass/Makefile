# Builds the bass from its sources into ../build/bass/: case (hand plate and
# housing), covers, the keys and the boards, and the phone page phone.html. Only
# what changed is rebuilt.
#   make        everything (and the key's parts it needs)
#   make clean  deletes ../build/bass/
# The key's parts come from ../switch_hall/ (built there into ../build/switch_hall/), the
# board's data from ../hall_pcb/bass/board.scad.

OPENSCAD ?= openscad
PYTHON   ?= python3
B        := ../build/bass
KEY      := ../build/switch_hall

scad = @mkdir -p $(B)/.deps && echo "  OPENSCAD $@" && \
       $(OPENSCAD) -q -o $@ -d $(B)/.deps/$(notdir $@).d $(2) $(1)

KEY_STL   := $(addprefix $(KEY)/,$(foreach r,0 1,$(foreach p,cap plunger magnet oring stop,bass$(r)_$(p).stl bass$(r)_$(p)_down.stl) bass$(r)_tube_body.stl bass$(r)_tube_cut.stl))

all: $(B)/strap.stl $(B)/elec.stl $(B)/wires.stl $(B)/case.stl $(B)/cover.stl $(B)/back_cover.stl $(B)/cover_screws.stl $(B)/battery.stl $(B)/keys.stl $(B)/boards.stl $(B)/discant_link.stl $(B)/phone.html

$(B)/back_cover.stl: case.scad layout.scad elec.scad
	$(call scad,$<,-D 'part="back_cover"')
$(B)/cover_screws.stl: case.scad layout.scad
	$(call scad,$<,-D 'part="cover_screws"')
$(B)/battery.stl: case.scad layout.scad
	$(call scad,$<,-D 'part="battery"')

# the discant's side of the gauges (plates, pins, outer holders), for checks and the page
$(B)/discant_link.stl: link.scad layout.scad ../discant/gauge_link.scad
	$(call scad,$<,-D 'part="discant"')

$(B)/case.stl $(B)/cover.stl: $(B)/%.stl: %.scad layout.scad
	$(call scad,$<)
# the case carries the gauges' mount and the stored discant's socket (link.scad)
$(B)/elec.stl: elec.scad layout.scad
	$(call scad,$<)
$(B)/strap.stl: case.scad layout.scad
	$(call scad,$<,-D 'part="strap"')
$(B)/wires.stl: elec.scad layout.scad
	$(call scad,$<,-D 'part="wires"')
$(B)/case.stl $(B)/battery.stl $(B)/elec.stl: elec.scad
GAUGE_DEPS := link.scad ../discant/gauge_link.scad $(addprefix ../build/strain_gauge/,inner_holder.stl inner_holder_detent.stl outer_holder.stl strain_gauge_plate.stl)
$(B)/case.stl $(B)/battery.stl $(B)/elec.stl $(B)/wires.stl $(B)/back_cover.stl: $(GAUGE_DEPS)
$(B)/discant_link.stl: $(GAUGE_DEPS)


$(B)/keys.stl: keys.scad layout.scad $(KEY_STL)
	$(call scad,$<)
$(B)/keys_static.stl: keys.scad layout.scad $(KEY_STL)
	$(call scad,$<,-D 'part="static"')
$(B)/boards.stl: array.scad layout.scad
	$(call scad,$<)
$(B)/connectors.stl: array.scad layout.scad
	$(call scad,$<,-D 'part="connectors"')
$(B)/case.stl $(B)/cover.stl $(B)/keys.stl: $(KEY_STL)
$(KEY_STL): key ;
key:
	@$(MAKE) --no-print-directory -C ../switch_hall

PHONE_PARTS := CASE_TRIS=$(B)/case.stl COVER_TRIS=$(B)/cover.stl BOARDS_TRIS=$(B)/boards.stl \
               CONN_TRIS=$(B)/connectors.stl ELEC_TRIS=$(B)/elec.stl WIRES_TRIS=$(B)/wires.stl STRAP_TRIS=$(B)/strap.stl \
               $(foreach r,0 1,$(foreach p,CAP PLUNGER MAGNET ORING STOP,$(p)$(r)_TRIS=$(KEY)/bass$(r)_$(shell echo $(p) | tr A-Z a-z).stl)) \
               LINK_TRIS=$(B)/discant_link.stl LID_TRIS=$(B)/back_cover.stl CSCREW_TRIS=$(B)/cover_screws.stl BATTERY_TRIS=$(B)/battery.stl
$(B)/phone.html: phone.html ../discant/embed_parts.py ../discant/viewer_nav.js $(B)/case.stl $(B)/cover.stl $(B)/boards.stl \
                 $(B)/connectors.stl $(B)/elec.stl $(B)/wires.stl $(B)/strap.stl $(B)/discant_link.stl $(B)/back_cover.stl $(B)/cover_screws.stl $(B)/battery.stl $(KEY_STL)
	@echo "  EMBED    $@"
	@$(PYTHON) ../discant/embed_parts.py $< $@ $(PHONE_PARTS)

clean:
	rm -rf $(B)

-include $(wildcard $(B)/.deps/*.d)
.PHONY: all clean key
