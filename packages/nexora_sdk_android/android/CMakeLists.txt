cmake_minimum_required(VERSION 3.4.1)

add_library(nexora_core SHARED
    ../../../src/nexora_core.cpp
)

target_link_libraries(nexora_core log)
