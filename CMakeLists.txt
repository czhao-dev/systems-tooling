cmake_minimum_required(VERSION 3.21)

project(buildlab VERSION 0.1.0
    DESCRIPTION "CMake systems build lab: target-based CMake demo with presets, sanitizers, coverage, and packaging"
    LANGUAGES C CXX
)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(ProjectOptions)
include(CompilerWarnings)
include(Sanitizers)
include(Coverage)
include(StaticAnalysis)
include(GNUInstallDirs)
include(CTest)

# C/C++ standards are set per-target via target_compile_features() in each
# src/*/CMakeLists.txt rather than globally here -- see "CMake Design" in
# README.md.
set(BUILD_SHARED_LIBS ${BUILDLAB_BUILD_SHARED_LIBS})

add_subdirectory(src/core)
add_subdirectory(src/net)
add_subdirectory(src/cli)

if(BUILDLAB_BUILD_TESTS AND BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()

if(BUILDLAB_BUILD_BENCHMARKS)
    add_subdirectory(benchmarks)
endif()

# ---- Install / Export ----
# Only the two libraries are part of the consumable package; the CLI is a
# standalone tool, not something downstream projects link against.
install(TARGETS buildlab_core buildlab_net
    EXPORT buildlabTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(TARGETS buildlab_cli
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(DIRECTORY include/buildlab DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(EXPORT buildlabTargets
    FILE buildlabTargets.cmake
    NAMESPACE buildlab::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/buildlab
)

include(CMakePackageConfigHelpers)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PackageConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/buildlabConfig.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/buildlab"
)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/buildlabConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/buildlabConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/buildlabConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/buildlab"
)

# ---- CPack ----
set(CPACK_PACKAGE_NAME "buildlab")
set(CPACK_PACKAGE_VENDOR "cmake-systems-build-lab")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_GENERATOR "TGZ;ZIP")
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    list(APPEND CPACK_GENERATOR "DEB")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "czhao-dev")
endif()
include(CPack)
