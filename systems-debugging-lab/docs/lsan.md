# LeakSanitizer

LeakSanitizer (LSan) detects leaked heap allocations at process exit. On
Linux it runs automatically inside an ASan build when
`ASAN_OPTIONS=detect_leaks=1` is set; it has no standalone macOS build (Apple
Clang's runtime doesn't ship the leak-detection component at all, and setting
`detect_leaks=1` there just aborts — see `docs/asan.md`).

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_lsan.sh
```

`scripts/run_lsan.sh` checks `uname -s` and exits early with a pointer to
Docker if run on a non-Linux host — there is no working local fallback on
macOS. On Linux it builds `build-lsan/` (`-DENABLE_ASAN=ON`), sets
`ASAN_OPTIONS=detect_leaks=1`, and runs
`logforge --input logs/10k.log --build-index`. Output is saved to
`results/lsan.log`.

## Run it by hand (Linux)

```bash
cmake -B build-lsan -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON
cmake --build build-lsan
ASAN_OPTIONS=detect_leaks=1 ./build-lsan/bugs/bug_memory_leak
```

## Worked example: `bugs/memory_leak.cpp`

Same leak as in `docs/valgrind.md` — a singly-linked chain of `Node`s that's
never freed. Expected LSan output (Linux):

```text
=================================================================
==NNNN==ERROR: LeakSanitizer: detected memory leaks

Direct leak of NNN byte(s) in N object(s) allocated from:
    #0 ... in operator new(unsigned long)
    #1 ... in build_chain(int) memory_leak.cpp:13
    #2 ... in main memory_leak.cpp:20

SUMMARY: LeakSanitizer: NNN byte(s) leaked in N allocation(s).
```

Fix: same as the Valgrind writeup — give the chain an owner that actually
frees it (`std::unique_ptr` chain, or explicit cleanup before reassigning
`chain`).

## Lessons learned

* LSan and Valgrind's `--leak-check=full` answer the same question; LSan is
  dramatically faster since it reuses ASan's existing instrumentation instead
  of emulating every instruction, so prefer it for routine leak checks and
  fall back to Valgrind when you need its other Memcheck diagnostics
  (uninitialized reads, invalid frees) too.
* Don't assume "no leak reported on macOS" means "no leak" — it means LSan
  didn't run at all there. The Linux/Docker leg of the workflow is load
  bearing for this check, not optional.
