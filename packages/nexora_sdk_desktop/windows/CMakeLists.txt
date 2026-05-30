# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(nexora_sdk_desktop_windows_plugin VERSION 3.4.0 LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "nexora_sdk_desktop_plugin")

add_library(${PLUGIN_NAME} SHARED
  "nexora_sdk_desktop_plugin.cpp"
  "nexora_sdk_desktop_plugin_c_api.cpp"
  "pigeon/hardware_api.g.cpp"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
