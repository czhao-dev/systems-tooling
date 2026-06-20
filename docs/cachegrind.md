# Cachegrind

Cachegrind simulates the CPU's instruction and data caches and reports miss
rates per line/function — useful when `perf`'s hardware counters aren't
available (true by construction on Docker Desktop, see `docs/perf.md`) since
Cachegrind doesn't need real PMU access at all. Linux-only (part of
Valgrind); use the Docker dev environment.

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_cachegrind.sh
```

Runs `valgrind --tool=cachegrind ./build/logforge --input logs/10k.log --status-counts`
from inside `results/`, then pipes `cachegrind.out.*` through `cg_annotate`.
Output is saved to `results/cachegrind.log`.

## Run it by hand

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cd results
valgrind --tool=cachegrind ../build/logforge --input ../logs/1m.log --status-counts
cg_annotate cachegrind.out.* > cachegrind.txt
```

## What to look for

`cg_annotate`'s per-function breakdown of `D1mr`/`D1mw` (L1 data cache read
/ write misses) is what to check after a storage-layout change — e.g. if
`Aggregator`'s `status_counts_` (a `std::map`, pointer-chasing red-black
tree) were replaced with a flat array indexed by status code, expect data
cache misses in `Aggregator::add`/`merge` to drop, since the README's
"Aggregation Engine" design already favors simple hash/array lookups over
node-based containers where it matters.

## Lessons learned

* Cachegrind numbers are deterministic (it's a cache simulation, not a
  sampling profiler), which makes it the right tool for *comparing* two
  implementations precisely — run it before and after a storage-layout
  change and diff the miss counts directly, rather than averaging noisy
  wall-clock timings.
* Like Massif, it runs under full emulation and is slow — iterate on
  `logs/10k.log`, confirm the final comparison on `logs/1m.log`.
