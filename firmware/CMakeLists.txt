# eziach firmware for the ESP32-S3 on the main board (../main_pcb). Build with ESP-IDF v5.5:
#   . ~/esp/esp-idf-v5.5.6/export.sh && idf.py build
cmake_minimum_required(VERSION 3.16)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(eziach)

# idf.py flash writes the soundfont into its partition too (partitions.csv): sound/ZiachMini.sf2,
# a copy of the first eziach's (../../ctrl/ZiachMini.sf2)
set(SOUNDFONT "${CMAKE_SOURCE_DIR}/sound/ZiachMini.sf2")
esptool_py_flash_to_partition(flash "soundfont" "${SOUNDFONT}")
