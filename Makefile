# Builds the generated files of every project into build/<project>/.
#   make                  switch_hall, discant, strain_gauge and key_proto (seconds)
#   make <project>        one project
#   make -j               in parallel
#   make clean            deletes build/

FAST := switch_hall discant strain_gauge key_proto

all: $(FAST)

$(FAST):
	@$(MAKE) --no-print-directory -C $@

# the discant uses the key's parts: never build switch_hall/ twice at once
discant key_proto: switch_hall

clean:
	rm -rf build

.PHONY: all clean $(FAST)
