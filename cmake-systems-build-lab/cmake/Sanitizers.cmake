# Attaches sanitizer compile/link flags to `target_name`, driven entirely by
# the BUILDLAB_ENABLE_SANITIZERS / BUILDLAB_SANITIZERS cache variables so
# each preset (asan/ubsan/tsan) can select a sanitizer set without this file
# needing to know about presets at all.
#
# Note: LeakSanitizer is not supported standalone on macOS (only ships on
# Linux), so a `leak` entry in BUILDLAB_SANITIZERS only takes effect in CI.
function(buildlab_enable_sanitizers target_name)
    if(NOT BUILDLAB_ENABLE_SANITIZERS OR BUILDLAB_SANITIZERS STREQUAL "")
        return()
    endif()

    separate_arguments(SANITIZER_FLAGS UNIX_COMMAND
        "-fsanitize=${BUILDLAB_SANITIZERS} -fno-omit-frame-pointer")

    target_compile_options(${target_name} INTERFACE ${SANITIZER_FLAGS})
    target_link_options(${target_name} INTERFACE ${SANITIZER_FLAGS})
endfunction()

buildlab_enable_sanitizers(buildlab_project_options)
