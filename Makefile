# Builds the generated files of every project into build/<project>/.
#   make                  switch, discant and strain_gauge (seconds)
#   make cabling          the cable routes (minutes per route, not part of make)
#   make <project>        one project
#   make -j               in parallel
#   make clean            deletes build/

FAST := switch switch_hall discant strain_gauge

all: $(FAST)

$(FAST) cabling:
	@$(MAKE) --no-print-directory -C $@

# the discant uses the key's parts: never build switch/ twice at once
discant: switch

clean:
	rm -rf build

.PHONY: all clean $(FAST) cabling
