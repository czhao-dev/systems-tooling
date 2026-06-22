# buildlab-cli is a thin, manual-arg-dispatch demo executable whose only
# job is to exercise both first-party libraries from outside their own
# test suites. It is intentionally not part of the buildlabTargets export
# set in the root CMakeLists.txt -- downstream consumers depend on the
# libraries, not on this tool.
add_executable(buildlab_cli main.cpp)

# The CMake target name stays underscore-separated for consistency with
# buildlab_core/buildlab_net, but the on-disk binary name matches the
# hyphenated convention documented in the README's Quick Start.
set_target_properties(buildlab_cli PROPERTIES OUTPUT_NAME "buildlab-cli")

target_link_libraries(buildlab_cli
    PRIVATE
        buildlab::core
        buildlab::net
        buildlab_project_options
        buildlab_project_warnings
)
