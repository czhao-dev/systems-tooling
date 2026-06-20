# ThreadSanitizer

ThreadSanitizer (TSan) instruments memory accesses and synchronization
primitives to detect data races between threads at runtime. It works on both
macOS and Linux.

## Run it

```bash
./scripts/run_tsan.sh
```

Builds `build-tsan/` (`-DENABLE_TSAN=ON`) and runs
`logforge --input logs/10k.log --threads 8 --status-counts`. Output is saved
to `results/tsan.log`. This comes back **clean** — confirming that
`main.cpp`'s thread-local-`Aggregator`-then-`merge()` design (each worker
writes only to its own `local_aggregators[t]` slot; nothing is shared until
`ThreadPool::wait_idle()` returns) really does avoid the shared-map race
described in the README, even at 8 threads.

## Run it by hand

```bash
cmake -B build-tsan -DCMAKE_BUILD_TYPE=Debug -DENABLE_TSAN=ON
cmake --build build-tsan
./build-tsan/logforge --input logs/1m.log --threads 8 --status-counts
./build-tsan/bugs/bug_data_race
```

## Worked example: `bugs/data_race.cpp`

```cpp
std::unordered_map<int, int> status_counts;
auto worker = [&status_counts]() {
    for (int i = 0; i < 100000; ++i) {
        status_counts[200]++;  // Unsynchronized concurrent writes.
    }
};
```

Real captured output (truncated):

```text
WARNING: ThreadSanitizer: data race (pid=48055)
  Write of size 8 at 0x00016d32a8f8 by thread T3:
    #0 ... std::__1::unordered_map<...>::operator[](int&&) ...
    #1 ... main::$_0::operator()() const data_race.cpp:12

  Previous read of size 8 at 0x00016d32a8f8 by thread T1:
    #0 ... std::__1::unordered_map<...>::operator[](int&&) ...
    #1 ... main::$_0::operator()() const data_race.cpp:12

  Location is stack of main thread.

  Thread T3 (tid=..., running) created by main thread at:
    #0 pthread_create ...
    ...
    #8 main data_race.cpp:18
```

Both the racing write and the prior read point at the same line
(`data_race.cpp:12`, the `status_counts[200]++`), confirming every thread is
mutating the same `unordered_map` with no synchronization.

Fix: give each thread its own counter and merge at the end —
`logforge`'s actual `Aggregator`/`ThreadPool` design is the fixed version of
this exact bug.

## Lessons learned

* TSan reports both sides of the race (the write *and* the conflicting prior
  access) with separate stacks — read the "created by" stack too; it tells
  you which thread is involved, which matters once you have more than two.
* A clean TSan run at high thread counts is meaningful evidence for a
  concurrency design, not just an absence of crashes — it's part of why
  `scripts/run_tsan.sh` uses `--threads 8` rather than the default of 1.
