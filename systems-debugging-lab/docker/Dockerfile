FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gdb \
    valgrind \
    strace \
    binutils \
    linux-tools-generic \
    heaptrack \
    clang-tidy \
    clang-format \
    cppcheck \
    lcov \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu's /usr/bin/perf wrapper refuses to run when its embedded kernel version
# doesn't match `uname -r` (always true on Docker Desktop's linuxkit VM). The
# underlying binary works fine for software events, so link past the wrapper.
RUN ln -sf "$(ls /usr/lib/linux-tools/*/perf | head -1)" /usr/local/bin/perf

WORKDIR /workspace
