# Docker Dev Environment

Several tools in the [Tool Demonstration Matrix](../README.md#tool-demonstration-matrix) —
Valgrind, perf, gprof, gprofng, and heaptrack — either don't ship for macOS/Apple Silicon at all,
or (gprof/gprofng) aren't part of Apple's Clang toolchain. `docker/` provides an Ubuntu 24.04
container with all of them installed, so the full tool matrix can be exercised from any host that
runs Docker.

## Build and enter

```bash
docker compose -f docker/docker-compose.yml build
docker compose -f docker/docker-compose.yml run --rm devtools bash
```

The repo root is mounted at `/workspace` inside the container, so edits made on the host are
immediately visible there, and any artifacts the tools produce (e.g. `heaptrack.*.gz`,
`callgrind.out.*`) land back in the repo working tree.

## Sanity-checking each tool

```bash
gdb --version
valgrind --version
strace -V
gprof --version
gprofng --version
heaptrack --version
clang-tidy --version
clang-format --version
cppcheck --version
lcov --version
perf --version
```

## Known limitations

- **perf hardware counters are unavailable.** Docker Desktop's Linux VM doesn't expose real CPU
  performance-monitoring-unit (PMU) access, so `perf stat`/`perf record` work for software events
  (`task-clock`, `context-switches`, `page-faults`) but report `<not supported>` for `cycles`,
  `instructions`, `branches`, and `branch-misses`. Use Cachegrind/Callgrind (Valgrind-based, also
  in this image) for cache and call-path analysis instead — those don't need real hardware
  counters.
- **The stock `/usr/bin/perf` wrapper doesn't run at all** because it refuses to start when its
  embedded kernel version doesn't match `uname -r` — true by construction on Docker Desktop's
  linuxkit VM. The Dockerfile symlinks `/usr/local/bin/perf` directly to the underlying
  `linux-tools-*` binary to work around this; that's why `perf` resolves and the wrapper's
  "WARNING: perf not found for kernel ..." message is never seen.
- `gdb`, `strace`, and `valgrind` all rely on `ptrace`, and `perf` additionally wants
  `CAP_SYS_ADMIN`-equivalent access; `docker/docker-compose.yml` already grants
  `cap_add: [SYS_PTRACE, SYS_ADMIN]` and `security_opt: [seccomp:unconfined]` for this. If you run
  the image with plain `docker run` instead of `docker compose`, pass the same flags or these
  tools will fail with permission errors.
- All Linux packages installed are `aarch64`/arm64 builds (matching Apple Silicon's Docker Desktop
  VM) — Valgrind has supported arm64 Linux since 3.13+, so this works without emulation.
