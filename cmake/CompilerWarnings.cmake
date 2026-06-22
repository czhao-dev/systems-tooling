# Attaches a curated compiler warning profile to `target_name`. Split out as
# its own function (rather than inlined in ProjectOptions.cmake) so the
# warning policy can be unit-reasoned-about and reused independently of
# option declarations.
function(buildlab_set_project_warnings target_name)
    if(NOT BUILDLAB_ENABLE_WARNINGS)
        return()
    endif()

    set(MSVC_WARNINGS /W4)
    if(BUILDLAB_WARNINGS_AS_ERRORS)
        list(APPEND MSVC_WARNINGS /WX)
    endif()

    # Warnings shared by C and C++ translation units.
    set(COMMON_WARNINGS
        -Wall -Wextra -Wpedantic -Wconversion -Wshadow
        -Wunused -Wnull-dereference -Wdouble-promotion
    )
    # C++-only warnings: gated with a COMPILE_LANGUAGE generator expression
    # so C sources never see flags clang/gcc would otherwise silently accept
    # but that are meaningless (or noisy) for C, such as -Wold-style-cast.
    set(CXX_ONLY_WARNINGS
        -Wnon-virtual-dtor -Wold-style-cast -Wcast-align -Woverloaded-virtual
    )
    if(BUILDLAB_WARNINGS_AS_ERRORS)
        list(APPEND COMMON_WARNINGS -Werror)
    endif()

    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|AppleClang|GNU")
        target_compile_options(${target_name} INTERFACE
            $<$<COMPILE_LANGUAGE:C,CXX>:${COMMON_WARNINGS}>
            $<$<COMPILE_LANGUAGE:CXX>:${CXX_ONLY_WARNINGS}>
        )
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${target_name} INTERFACE ${MSVC_WARNINGS})
    endif()
endfunction()

buildlab_set_project_warnings(buildlab_project_warnings)
