# perf

`perf` is the Linux kernel's CPU profiler — used here for both quick
aggregate stats (`perf stat`) and call-graph sampling (`perf record`/
`perf report`) to find hot functions without recompiling. Linux-only; use the
Docker dev environment.

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_perf.sh
```

Runs `perf stat ./build/logforge --input logs/10k.log --threads 8 --status-counts`.
Output is saved to `results/perf.log`.

## Run it by hand

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
perf stat ./build/logforge --input logs/1m.log --threads 8 --status-counts
perf record -g ./build/logforge --input logs/1m.log --threads 8 --top-paths 10
perf report
```

## What to look for

* `perf stat` — task-clock, context-switches, page-faults are always
  available; cycles/instructions/branches require real hardware PMU access.
* `perf record -g` + `perf report` — shows where CPU time actually goes.
  Before optimizing the parser, this is what would have pointed at
  `std::stringstream` extraction dominating `LogParser`'s time, the
  motivation for the manual/`string_view`-based parser described in the
  README.

## Platform note (Docker Desktop)

Inside the Docker dev environment, **hardware performance counters are
unavailable** — Docker Desktop's Linux VM doesn't expose real PMU access, so
`cycles`/`instructions`/`branches`/`branch-misses` report `<not supported>`.
Software events (`task-clock`, `context-switches`, `page-faults`) still work.
For cache/call-path analysis on Docker Desktop, use Cachegrind/Callgrind
instead (`docs/cachegrind.md`, `docs/callgrind.md`) — they don't need real
hardware counters. See `docs/docker_dev_environment.md` for the full list of
container caveats, including why `/usr/local/bin/perf` is symlinked past the
stock wrapper.

## Lessons learned

* `perf stat` is cheap enough to run as a sanity check before reaching for
  `perf record` — if task-clock and context-switches already look wrong
  (e.g. way more context switches than thread count would suggest), that's
  often enough to point at the problem without a full sampling profile.
* On a real Linux host (not Docker Desktop), capture `cycles` and
  `branch-misses` too — they distinguish "slow because of cache/branch
  behavior" from "slow because of more instructions," which Cachegrind
  alone won't tell you as directly.
