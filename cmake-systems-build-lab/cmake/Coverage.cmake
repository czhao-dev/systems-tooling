# Attaches coverage instrumentation flags to `target_name`. This module is
# deliberately compile/link flags only -- it does not invoke llvm-cov, lcov,
# or gcov itself. Report generation lives in scripts/coverage.sh, which can
# be iterated on (and re-run against an existing build) without forcing a
# reconfigure.
function(buildlab_enable_coverage target_name)
    if(NOT BUILDLAB_ENABLE_COVERAGE)
        return()
    endif()

    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|AppleClang")
        # Clang's source-based coverage: instrumentation lives in the binary
        # itself and is decoded later with llvm-profdata/llvm-cov.
        target_compile_options(${target_name} INTERFACE -fprofile-instr-generate -fcoverage-mapping)
        target_link_options(${target_name} INTERFACE -fprofile-instr-generate -fcoverage-mapping)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        # GCC's gcov-style coverage: .gcno/.gcda side files decoded with
        # lcov/gcov. -fprofile-abs-path keeps file paths in the .gcno files
        # absolute so genhtml can locate sources regardless of cwd.
        target_compile_options(${target_name} INTERFACE --coverage -fprofile-abs-path)
        target_link_options(${target_name} INTERFACE --coverage)
    else()
        message(WARNING "buildlab: coverage is not supported for compiler '${CMAKE_CXX_COMPILER_ID}'")
    endif()
endfunction()

buildlab_enable_coverage(buildlab_project_options)
