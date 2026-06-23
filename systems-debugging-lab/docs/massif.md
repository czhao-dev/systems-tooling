# Valgrind Massif

Massif samples heap allocations over time and produces a peak-usage
snapshot, broken down by allocation call stack — the right tool for "why
does this use so much memory," as opposed to Memcheck's "why does this leak"
or "why is this read invalid." Linux-only (part of Valgrind); use the Docker
dev environment.

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_massif.sh
```

Runs `valgrind --tool=massif ./build/logforge --input logs/10k.log --build-index`
from inside `results/`, then pipes `massif.out.*` through `ms_print`. Output
is saved to `results/massif.log`.

## Run it by hand

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cd results
valgrind --tool=massif ../build/logforge --input ../logs/1m.log --build-index
ms_print massif.out.* > massif.txt
```

## What to look for

`--build-index` is the interesting workload here: `LogIndex::build()` stores
a `vector<size_t>` of record IDs per distinct status/ip/path value, on top of
the `vector<LogRecord>` already held for indexing/querying. `ms_print`'s
snapshot graph shows peak heap usage and which call stack (`LogIndex::build`
vs the `vector<LogRecord>` compaction in `main.cpp`) owns the largest share
at the peak — exactly the kind of indexed-storage memory cost the README's
"Optional Query Index" section calls out as worth measuring.

## Lessons learned

* Massif's peak-usage number is the one to track across changes (e.g. if you
  later switch the index to store `string_view`s into a single buffer
  instead of per-record `std::string`s) — the detailed snapshot graph is
  mainly useful for finding *which* allocation site to target first.
* Massif runs under the same full-program emulation as Memcheck, so it's slow
  on large inputs — use `logs/10k.log` or `logs/1m.log` for iteration, and
  save `logs/10m.log` runs for a final measurement.
