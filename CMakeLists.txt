cmake_minimum_required(VERSION 3.28)
project(NekoTuneLumen LANGUAGES NONE)
include(CTest)
file(GLOB_RECURSE theme_files CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/theme/*")
set(package "${CMAKE_BINARY_DIR}/packages/nekotune.theme-lumen.nktheme.zip")
add_custom_command(OUTPUT "${package}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_BINARY_DIR}/packages"
    COMMAND "${CMAKE_COMMAND}" "-DOUTPUT=${package}" -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Package.cmake"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/theme"
    DEPENDS ${theme_files} VERBATIM)
add_custom_target(extension_package ALL DEPENDS "${package}")
if(BUILD_TESTING)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    add_test(NAME theme_package COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_CURRENT_SOURCE_DIR}/tests/validate_package.py" "${package}")
endif()
option(LUMEN_QML_TESTS "Build standalone Qt Quick controller tests" OFF)
if(BUILD_TESTING AND LUMEN_QML_TESTS)
    enable_language(CXX)
    find_package(Qt6 6.6 REQUIRED COMPONENTS QuickTest)
    add_executable(lumen_qml_test tests/quick_test.cpp)
    target_link_libraries(lumen_qml_test PRIVATE Qt6::QuickTest)
    target_compile_definitions(lumen_qml_test PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/qml")
    add_test(NAME spectrum_controller COMMAND lumen_qml_test -import "${CMAKE_CURRENT_SOURCE_DIR}/tests/imports")
    set_tests_properties(spectrum_controller PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")
endif()
