cmake_minimum_required(VERSION 3.16)
project(LogForge LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
option(ENABLE_TSAN "Enable ThreadSanitizer" OFF)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
option(ENABLE_GPROF "Enable gprof instrumentation" OFF)
option(ENABLE_COVERAGE "Enable coverage instrumentation" OFF)
option(BUILD_TESTS "Build unit tests" ON)
option(BUILD_BUGS "Build intentionally flawed bug demo executables" ON)

find_package(Threads REQUIRED)

if(ENABLE_ASAN)
    add_compile_options(-fsanitize=address -fno-omit-frame-pointer -g)
    add_link_options(-fsanitize=address)
endif()

if(ENABLE_TSAN)
    add_compile_options(-fsanitize=thread -fno-omit-frame-pointer -g)
    add_link_options(-fsanitize=thread)
endif()

if(ENABLE_UBSAN)
    add_compile_options(-fsanitize=undefined -fno-omit-frame-pointer -g)
    add_link_options(-fsanitize=undefined)
endif()

if(ENABLE_GPROF)
    add_compile_options(-pg -g)
    add_link_options(-pg)
endif()

if(ENABLE_COVERAGE)
    add_compile_options(--coverage -O0 -g)
    add_link_options(--coverage)
endif()

add_library(logforge_core STATIC
    src/LogParser.cpp
    src/Aggregator.cpp
    src/ThreadPool.cpp
    src/LogIndex.cpp
    src/QueryEngine.cpp
    src/ReportWriter.cpp
)
target_include_directories(logforge_core PUBLIC include)
target_link_libraries(logforge_core PUBLIC Threads::Threads)

add_executable(logforge src/main.cpp)
target_link_libraries(logforge PRIVATE logforge_core)

if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

if(BUILD_BUGS)
    add_subdirectory(bugs)
endif()
