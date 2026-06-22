# Project-wide options. Keeping every toggle in one place means a contributor
# can discover the full set of build knobs by reading a single file instead
# of grepping the whole tree for option().
option(BUILDLAB_BUILD_TESTS "Build tests" ON)
option(BUILDLAB_BUILD_BENCHMARKS "Build benchmarks" OFF)
option(BUILDLAB_ENABLE_WARNINGS "Enable compiler warnings" ON)
option(BUILDLAB_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)
option(BUILDLAB_ENABLE_SANITIZERS "Enable sanitizers" OFF)
option(BUILDLAB_ENABLE_COVERAGE "Enable coverage instrumentation" OFF)
option(BUILDLAB_BUILD_SHARED_LIBS "Build shared libraries" OFF)

# Comma-separated sanitizer list passed straight through to -fsanitize=,
# e.g. "address" or "undefined" or "thread". Only consulted when
# BUILDLAB_ENABLE_SANITIZERS is ON. Kept as a free-form string (rather than
# one option() per sanitizer) so new sanitizers don't require touching this
# file again.
set(BUILDLAB_SANITIZERS "" CACHE STRING "Comma list of sanitizers, e.g. address / undefined / thread")

# Every first-party target links against these two INTERFACE libraries
# (never against global compiler flags) so that fetched third-party
# dependencies such as GoogleTest are never affected by this project's
# warning/sanitizer/coverage settings.
add_library(buildlab_project_options INTERFACE)
add_library(buildlab_project_warnings INTERFACE)
