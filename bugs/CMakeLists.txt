add_executable(bug_memory_leak memory_leak.cpp)
add_executable(bug_buffer_overflow buffer_overflow.cpp)
add_executable(bug_use_after_free use_after_free.cpp)
add_executable(bug_undefined_behavior undefined_behavior.cpp)
add_executable(bug_syscall_storm syscall_storm.cpp)

add_executable(bug_data_race data_race.cpp)
target_link_libraries(bug_data_race PRIVATE Threads::Threads)

add_executable(bug_parser_crash parser_crash.cpp)
