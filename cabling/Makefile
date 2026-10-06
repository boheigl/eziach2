# Solves the cable routes of routes.json into ../build/cabling/: per route
# <name>.stl, <name>_opt<k>.stl, <name>_obstacles.stl and the solver's report
# <name>.log. Solving can take minutes per route, and a route is solved again
# whenever routes.json, ffc.js or route.js change.
#   make                  every route
#   make bend             one route
#   make -j               routes in parallel
#   make clean            deletes ../build/cabling/
#
# channel.js (route back_channel -> ../switch/ffc_channel.scad) is run by hand.

NODE   ?= node
B      := ../build/cabling
ROUTES := $(shell $(NODE) -e 'require("./routes.json").routes.forEach(r => console.log(r.name))')

all: $(ROUTES)

$(ROUTES): %: $(B)/%.log

$(B)/%.log: routes.json ffc.js route.js
	@mkdir -p $(B) && echo "  ROUTE    $*"
	@$(NODE) route.js --out $(B) routes.json $* > $@ || { cat $@; exit 1; }

clean:
	rm -rf $(B)

.PHONY: all clean $(ROUTES)
.DELETE_ON_ERROR:
