# Valgrind Memcheck

Valgrind Memcheck detects memory leaks, invalid reads/writes, and use of
uninitialized values by running the binary under a full instruction-level
emulator. It's slower than the sanitizers but catches some classes of bugs
(e.g. reads of uninitialized stack memory) that AddressSanitizer doesn't
always flag, and works without recompiling.

Valgrind is **Linux-only** — there's no Apple Silicon build. Use the Docker
dev environment (`docs/docker_dev_environment.md`) for everything in this
doc.

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_valgrind.sh
```

Builds `build-debug/` and runs Memcheck against
`logforge --input logs/10k.log --status-counts`. Output is saved to
`results/valgrind.log`.

## Run it by hand

```bash
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug
valgrind --leak-check=full --track-origins=yes \
    ./build-debug/logforge --input logs/10k.log --status-counts
```

## Worked example: `bugs/memory_leak.cpp`

```bash
g++ -g -Iinclude -o bug_memory_leak bugs/memory_leak.cpp
valgrind --leak-check=full --track-origins=yes ./bug_memory_leak
```

`build_chain()` allocates a `Node` per call and returns the head pointer,
which the caller in `main()` never frees. Expected Memcheck output:

```text
==NNNN== HEAP SUMMARY:
==NNNN==     in use at exit: ... bytes in ... blocks
==NNNN==   total heap usage: ... allocs, 0 frees, ... bytes allocated
==NNNN==
==NNNN== ... bytes in ... blocks are definitely lost in loss record ... of ...
==NNNN==    at 0x...: operator new(unsigned long)
==NNNN==    by 0x...: build_chain(int) (memory_leak.cpp:13)
==NNNN==    by 0x...: main (memory_leak.cpp:20)
```

Fix: store nodes in an owning container (`std::vector<std::unique_ptr<Node>>`)
or free the chain explicitly before the next iteration overwrites `chain`.
After the fix, Memcheck reports `0 bytes in 0 blocks are definitely lost`.

## Lessons learned

* `--track-origins=yes` adds real overhead but is worth it the first time you
  see an "uninitialised value" report — it tells you *where* the
  uninitialized value originated, not just where it was used.
* Memcheck and AddressSanitizer overlap heavily but aren't redundant: Memcheck
  needs no recompilation and catches some uninitialized-read cases ASan
  misses; ASan is far faster and catches the same heap/stack corruption with
  precise instrumentation. Use both during development if you can.
