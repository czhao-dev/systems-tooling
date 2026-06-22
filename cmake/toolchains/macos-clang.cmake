# Forces Apple Clang explicitly, useful when Homebrew LLVM is also on PATH
# and could otherwise be picked up by find_program-based compiler detection.
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_C_COMPILER /usr/bin/clang)
set(CMAKE_CXX_COMPILER /usr/bin/clang++)
