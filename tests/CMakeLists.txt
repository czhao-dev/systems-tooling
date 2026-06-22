# This is the project's concrete demonstration of CMake-native dependency
# management: GoogleTest is fetched, configured, and built as part of this
# tree via FetchContent rather than assumed to be preinstalled. Disabling
# its own install step keeps `cmake --install` from trying to install
# GoogleTest's headers/libraries alongside this project's own.
include(FetchContent)

set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)

# Pinned to a tag (not a branch) so every contributor and CI run fetches
# byte-for-byte the same GoogleTest sources.
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.15.2
)
FetchContent_MakeAvailable(googletest)

# Provides gtest_discover_tests(), which registers each individual
# TEST()/TEST_F() as its own CTest test instead of one opaque "run the
# whole binary" test -- this is what gives the granular pass/fail output
# seen in `ctest --preset debug --output-on-failure`.
include(GoogleTest)

add_executable(buildlab_tests
    test_core.cpp
    test_net.cpp
)

target_link_libraries(buildlab_tests
    PRIVATE
        buildlab::core
        buildlab::net
        GTest::gtest_main
        buildlab_project_options
        buildlab_project_warnings
)

gtest_discover_tests(buildlab_tests)
