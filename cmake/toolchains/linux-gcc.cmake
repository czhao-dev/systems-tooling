# Selects GCC on Linux. CI-only: exercised by the ubuntu-latest GitHub
# Actions runners, not locally testable on macOS.
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
