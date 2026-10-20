cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "native_bridge.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

# The panel icon (AppIndicator) and sound (PulseAudio, or PipeWire's
# stand-in for it).
pkg_check_modules(APPINDICATOR REQUIRED IMPORTED_TARGET ayatana-appindicator3-0.1)
pkg_check_modules(PULSE REQUIRED IMPORTED_TARGET libpulse libpulse-simple)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::APPINDICATOR PkgConfig::PULSE)
# Newer libayatana-appindicator marks its GTK 3 API deprecated.
target_compile_options(${BINARY_NAME} PRIVATE -Wno-deprecated-declarations)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
