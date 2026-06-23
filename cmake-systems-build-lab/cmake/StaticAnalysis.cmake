# Optional, opt-in static analysis hooks. Both are OFF by default so a
# normal build stays fast; turning either ON wires the tool directly into
# the compiler invocation via CMake's native CMAKE_<LANG>_CLANG_TIDY /
# CMAKE_<LANG>_CPPCHECK target properties.
#
# scripts/run-clang-tidy.sh is the faster day-to-day path: it runs
# clang-tidy directly against compile_commands.json without making a single
# warning fail the whole build, and gives better one-shot diagnostics.
option(BUILDLAB_ENABLE_CLANG_TIDY "Enable clang-tidy via CMAKE_CXX_CLANG_TIDY" OFF)
option(BUILDLAB_ENABLE_CPPCHECK "Enable cppcheck via CMAKE_CXX_CPPCHECK" OFF)

if(BUILDLAB_ENABLE_CLANG_TIDY)
    find_program(CLANG_TIDY_EXE NAMES clang-tidy)
    if(CLANG_TIDY_EXE)
        set(CMAKE_C_CLANG_TIDY "${CLANG_TIDY_EXE}" CACHE STRING "" FORCE)
        set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE}" CACHE STRING "" FORCE)
    else()
        message(WARNING "BUILDLAB_ENABLE_CLANG_TIDY is ON but clang-tidy was not found")
    endif()
endif()

if(BUILDLAB_ENABLE_CPPCHECK)
    find_program(CPPCHECK_EXE NAMES cppcheck)
    if(CPPCHECK_EXE)
        set(CMAKE_CXX_CPPCHECK
            "${CPPCHECK_EXE};--enable=all;--inconclusive;--std=c++17;--suppress=missingIncludeSystem"
            CACHE STRING "" FORCE)
    else()
        message(WARNING "BUILDLAB_ENABLE_CPPCHECK is ON but cppcheck was not found")
    endif()
endif()

# include-what-you-use is intentionally not wired up: it is not part of this
# project's required tooling and the README lists it as optional. Add a
# CMAKE_CXX_INCLUDE_WHAT_YOU_USE stanza here, mirroring the clang-tidy block
# above, if a future contributor wants it.
