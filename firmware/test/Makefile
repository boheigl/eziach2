# Host tests of the firmware's core: the generated key map, keys, force and the instrument
# logic, compiled with the host's gcc (no ESP-IDF, no hardware).
#   make        build and run
#   make clean  deletes build/

CC     ?= gcc
CFLAGS := -std=c11 -O1 -g -Wall -Wextra -Werror -fsanitize=address,undefined
B      := build
GEN    := $(B)/gen
CORE   := ../main/mapping.c ../main/keys.c ../main/force.c ../main/instrument.c

run: $(B)/test_core
	./$(B)/test_core

$(GEN)/keymap.c $(GEN)/keymap.h $(GEN)/config.h: ../tools/gen_config.py ../config/eziach.toml ../config/*.toml \
                                                  ../../hall_pcb/discant/channels.json ../../hall_pcb/bass/channels.json
	@python3 ../tools/gen_config.py $(GEN)

$(B)/test_core: test_core.c $(CORE) $(GEN)/keymap.c $(GEN)/config.h
	$(CC) $(CFLAGS) -I../main -I$(GEN) -o $@ test_core.c $(CORE) $(GEN)/keymap.c -lm

clean:
	rm -rf $(B)

.PHONY: run clean
