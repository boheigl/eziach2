# TinySoundFont (https://github.com/schellingb/TinySoundFont, tsf.h at 790a219, MIT, LICENSE),
# changed here: tsf_channel_note_on_tuned() detunes a single note (marked "eziach:" in tsf.h)
idf_component_register(SRCS "tsf_impl.c" INCLUDE_DIRS ".")
target_compile_options(${COMPONENT_LIB} PRIVATE -Wno-unused-variable -Wno-unused-but-set-variable)
