add_executable(buildlab_bench bench_main.cpp)
set_target_properties(buildlab_bench PROPERTIES OUTPUT_NAME "buildlab-bench")

target_link_libraries(buildlab_bench
    PRIVATE
        buildlab::core
        buildlab::net
        buildlab_project_options
        buildlab_project_warnings
)
