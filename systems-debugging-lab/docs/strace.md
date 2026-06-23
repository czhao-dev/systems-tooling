# strace / dtruss

`strace` traces the system calls a process makes — invaluable for spotting
I/O patterns like "one `read()` per byte" that are invisible in a CPU
profile (the time is real, it's just spent in the kernel, not user code).
`dtruss` is macOS's DTrace-based equivalent; it requires `sudo` and System
Integrity Protection to permit it, which is unreliable on modern macOS, so
prefer the Docker dev environment for this one too.

## Run it

```bash
./scripts/run_strace.sh
```

Uses `strace -f -c` if available, falls back to `sudo dtruss -c` on macOS,
and exits with an error if neither is present. It traces the main
`logforge --input logs/10k.log --status-counts`, which reads via
`std::ifstream::getline` (already buffered) — expect a modest, unremarkable
syscall count. Output is saved to `results/strace.log`.

## Run it by hand (Linux)

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
strace -f -c ./build/logforge --input logs/10k.log --status-counts
strace -f -c ./build/bugs/bug_syscall_storm logs/10k.log
```

## Worked example: `bugs/syscall_storm.cpp`

```cpp
std::setvbuf(file, nullptr, _IONBF, 0);  // Disable buffering.
while ((ch = std::fgetc(file)) != EOF) { ... }  // One read() syscall per byte.
```

Expected `strace -c` summary (illustrative — capture this for real inside
Docker):

```text
% time     seconds  usecs/call     calls    syscall
------ ----------- ----------- --------- ----------------
 98.40    0.842113           1    600685  read
  1.10    0.009421         941        10  mmap
  ...
------ ----------- ----------- --------- ----------------
100.00    0.855...           -    600706  total
```

One `read()` per byte (600,685 calls for a 600KB file) versus a handful of
large reads with buffering — this is the same before/after the README's
`--reader slow` vs `--reader buffered` comparison describes for the main
parser.

Fix: never disable buffering on a `FILE*`/`ifstream` you're reading
sequentially; let the C library batch reads (the default), or read large
chunks explicitly.

## Lessons learned

* A flat CPU profile (gprof/perf) can look unremarkable for syscall-bound
  code, because the time is spent in the kernel, charged to `read`, not to
  your functions. If wall-clock time and CPU-profile time disagree, reach for
  `strace -c` before assuming the profiler is lying.
* `-f` (follow forks/threads) matters as soon as `--threads` is greater than
  1 — without it you only see the main thread's syscalls.
