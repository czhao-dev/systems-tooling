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
