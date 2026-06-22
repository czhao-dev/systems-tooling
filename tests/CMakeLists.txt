include(FetchContent)

set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.15.2
)
FetchContent_MakeAvailable(googletest)

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
