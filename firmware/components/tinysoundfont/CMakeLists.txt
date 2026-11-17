# TinySoundFont (https://github.com/schellingb/TinySoundFont, tsf.h at 790a219, MIT, LICENSE)
idf_component_register(SRCS "tsf_impl.c" INCLUDE_DIRS ".")
target_compile_options(${COMPONENT_LIB} PRIVATE -Wno-unused-variable -Wno-unused-but-set-variable)
