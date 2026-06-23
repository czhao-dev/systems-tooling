# Only built when BUILDLAB_BUILD_BENCHMARKS is ON (see the "benchmark"
# preset in CMakePresets.json) so a normal debug/release build doesn't pay
# for compiling it.
add_executable(buildlab_bench bench_main.cpp)
set_target_properties(buildlab_bench PROPERTIES OUTPUT_NAME "buildlab-bench")

target_link_libraries(buildlab_bench
    PRIVATE
        buildlab::core
        buildlab::net
        buildlab_project_options
        buildlab_project_warnings
)
