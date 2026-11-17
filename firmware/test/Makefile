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

# the soundfont through TinySoundFont, as the synthesizer plays it
SF2 ?= ../sound/ZiachMini.sf2
sf2: $(B)/test_sf2
	./$(B)/test_sf2 $(SF2)

$(B)/test_sf2: test_sf2.c ../components/tinysoundfont/tsf.h $(GEN)/keymap.c $(GEN)/config.h
	@mkdir -p $(B)
	$(CC) -std=c11 -O2 -Wall -I../components/tinysoundfont -I$(GEN) -o $@ test_sf2.c $(GEN)/keymap.c -lm

.PHONY: sf2

# chords to listen to: each tempered, then with the thirds low -> build/chords.wav
chords: $(B)/chords_wav
	./$(B)/chords_wav $(SF2) $(B)/chords.wav

$(B)/chords_wav: chords_wav.c ../components/tinysoundfont/tsf.h $(GEN)/keymap.c $(GEN)/config.h
	@mkdir -p $(B)
	$(CC) -std=c11 -O2 -Wall -I../components/tinysoundfont -I$(GEN) -o $@ chords_wav.c $(GEN)/keymap.c -lm

.PHONY: chords
