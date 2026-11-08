# Builds the bass from its sources into ../build/bass/: case (hand plate and
# housing), covers, the keys and the boards, and the phone page phone.html. Only
# what changed is rebuilt.
#   make        everything (and the key's parts it needs)
#   make clean  deletes ../build/bass/
# The key's parts come from ../switch/ (built there into ../build/switch/).

OPENSCAD ?= openscad
PYTHON   ?= python3
B        := ../build/bass
KEY      := ../build/switch

scad = @mkdir -p $(B)/.deps && echo "  OPENSCAD $@" && \
       $(OPENSCAD) -q -o $@ -d $(B)/.deps/$(notdir $@).d $(2) $(1)

KEY_STL   := $(addprefix $(KEY)/,button.stl felt.stl washer.stl sleeve.stl screw.stl spring.stl pcb_connector.stl)

all: $(B)/elec.stl $(B)/wires.stl $(B)/case.stl $(B)/cover.stl $(B)/back_cover.stl $(B)/battery.stl $(B)/keys.stl $(B)/boards.stl $(B)/discant_link.stl $(B)/phone.html

$(B)/back_cover.stl: case.scad layout.scad elec.scad
	$(call scad,$<,-D 'part="back_cover"')
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
$(B)/wires.stl: elec.scad layout.scad
	$(call scad,$<,-D 'part="wires"')
$(B)/case.stl $(B)/battery.stl $(B)/elec.stl: elec.scad
GAUGE_DEPS := link.scad ../discant/gauge_link.scad $(addprefix ../build/strain_gauge/,inner_holder.stl inner_holder_detent.stl outer_holder.stl strain_gauge_plate.stl)
$(B)/case.stl $(B)/battery.stl $(B)/elec.stl $(B)/wires.stl $(B)/back_cover.stl: $(GAUGE_DEPS)
$(B)/discant_link.stl: $(GAUGE_DEPS)

$(B)/pcb_board_9.stl: ../switch/pcb.scad
	$(call scad,$<,-D cut_holes=4 -D 'part="board"')
$(B)/pcb_copper_9.stl: ../switch/pcb.scad
	$(call scad,$<,-D cut_holes=4 -D 'part="copper"')

$(B)/keys.stl: keys.scad layout.scad $(KEY_STL)
	$(call scad,$<)
$(B)/keys_static.stl: keys.scad layout.scad $(KEY_STL)
	$(call scad,$<,-D 'part="static"')
$(B)/boards.stl: array.scad layout.scad $(B)/pcb_board_9.stl $(KEY_STL)
	$(call scad,$<)
$(B)/connectors.stl: array.scad layout.scad $(KEY_STL)
	$(call scad,$<,-D 'part="connectors"')
$(B)/copper.stl: array.scad layout.scad $(B)/pcb_copper_9.stl
	$(call scad,$<,-D 'part="copper"')
$(B)/laminate.stl: array.scad layout.scad $(B)/pcb_board_9.stl
	@mkdir -p $(B)/.deps && echo "  OPENSCAD $@" && \
	$(OPENSCAD) -q -o $@ lam.scad
$(KEY_STL): key ;
key:
	@$(MAKE) --no-print-directory -C ../switch

PHONE_PARTS := CASE_TRIS=$(B)/case.stl COVER_TRIS=$(B)/cover.stl BOARDS_TRIS=$(B)/laminate.stl \
               COPPER_TRIS=$(B)/copper.stl CONN_TRIS=$(B)/connectors.stl ELEC_TRIS=$(B)/elec.stl WIRES_TRIS=$(B)/wires.stl KEYS_TRIS=$(B)/keys_static.stl \
               BUTTON_TRIS=$(KEY)/button.stl FELT_TRIS=$(KEY)/felt.stl WASHER_TRIS=$(KEY)/washer.stl \
               SLEEVE_TRIS=$(KEY)/sleeve.stl SCREW_TRIS=$(KEY)/screw.stl SPRING_TRIS=$(KEY)/spring.stl \
               LINK_TRIS=$(B)/discant_link.stl LID_TRIS=$(B)/back_cover.stl BATTERY_TRIS=$(B)/battery.stl
$(B)/phone.html: phone.html ../discant/embed_parts.py $(B)/case.stl $(B)/cover.stl $(B)/laminate.stl $(B)/copper.stl \
                 $(B)/connectors.stl $(B)/elec.stl $(B)/wires.stl $(B)/keys_static.stl $(B)/discant_link.stl $(B)/back_cover.stl $(B)/battery.stl $(KEY_STL)
	@echo "  EMBED    $@"
	@$(PYTHON) ../discant/embed_parts.py $< $@ $(PHONE_PARTS)

clean:
	rm -rf $(B)

-include $(wildcard $(B)/.deps/*.d)
.PHONY: all clean key
