cmake_minimum_required(VERSION 3.10)
project(nexora_sdk_desktop_linux_plugin LANGUAGES CXX)

set(PLUGIN_NAME "nexora_sdk_desktop_plugin")

add_library(${PLUGIN_NAME} SHARED
  "nexora_sdk_desktop_plugin.cc"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# Include glib and gio for D-Bus
find_package(PkgConfig REQUIRED)
pkg_check_modules(GIO REQUIRED gio-2.0)
target_link_libraries(${PLUGIN_NAME} PRIVATE ${GIO_LIBRARIES})
target_include_directories(${PLUGIN_NAME} PRIVATE ${GIO_INCLUDE_DIRS})
target_compile_options(${PLUGIN_NAME} PRIVATE ${GIO_CFLAGS_OTHER})
