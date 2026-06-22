add_executable(buildlab_cli main.cpp)
set_target_properties(buildlab_cli PROPERTIES OUTPUT_NAME "buildlab-cli")

target_link_libraries(buildlab_cli
    PRIVATE
        buildlab::core
        buildlab::net
        buildlab_project_options
        buildlab_project_warnings
)
