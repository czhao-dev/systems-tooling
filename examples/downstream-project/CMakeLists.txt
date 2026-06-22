# A standalone CMake project on purpose: it is not add_subdirectory()'d
# from the root CMakeLists.txt and has no entry in the root
# CMakePresets.json. It exists to prove that an installed copy of
# buildlab is consumable from completely outside this repository's own
# build tree -- see "Downstream Usage" in README.md for the exact
# install-then-configure flow.
cmake_minimum_required(VERSION 3.21)
project(buildlab_downstream_example LANGUAGES CXX)

find_package(buildlab CONFIG REQUIRED)

add_executable(downstream_app main.cpp)
target_compile_features(downstream_app PRIVATE cxx_std_17)

target_link_libraries(downstream_app
    PRIVATE
        buildlab::core
        buildlab::net
)
