# The generated tables (tools/gen_config.py): written at configure time, and CMake runs again
# when the configuration, the tuning table or a board's channels.json changes.
set(gen ${CMAKE_CURRENT_BINARY_DIR}/gen)
set(fw ${CMAKE_CURRENT_SOURCE_DIR}/..)
file(GLOB conf_files ${fw}/config/*.toml)
set(gen_inputs ${fw}/tools/gen_config.py ${conf_files}
               ${fw}/../hall_pcb/discant/channels.json ${fw}/../hall_pcb/bass/channels.json)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${gen_inputs})
execute_process(COMMAND ${PYTHON} ${fw}/tools/gen_config.py ${gen}
                RESULT_VARIABLE gen_result)
if(NOT gen_result EQUAL 0)
    message(FATAL_ERROR "tools/gen_config.py failed")
endif()

idf_component_register(
    SRCS "app_main.c" "mapping.c" "keys.c" "force.c" "instrument.c" "bus.c" "keyio.c" "nau7802.c" "dac.c" "synthesizer.c" "midi.c" "usb_console.c" "history.c" "power.c" "settings.c" "${gen}/keymap.c"
    INCLUDE_DIRS "." "${gen}")
