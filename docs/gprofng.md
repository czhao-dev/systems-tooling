# gprofng

`gprofng` is the modern replacement for Sun/Oracle's `er_print`-based
profiling tools, bundled with recent `binutils`. Unlike `gprof`, it samples
an unmodified binary (no `-pg` recompilation) and supports both a function
profile and a call tree. Not part of Apple Clang's toolchain — use the Docker
dev environment.

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_gprofng.sh
```

Collects an experiment into `results/gprofng.er/` while running
`logforge --input logs/10k.log --threads 8 --top-paths 10`, then dumps the
function profile and call tree. Output is saved to `results/gprofng.log`.

## Run it by hand

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
gprofng collect app -o test.1.er ./build/logforge --input logs/1m.log --threads 8 --top-paths 10
gprofng display text -functions test.1.er
gprofng display text -calltree test.1.er
```

## What to look for

The function profile ranks by "Exclusive Total CPU Time" — for the
`--top-paths`/`--threads 8` workload, expect time split between
`logforge::parse_line` (parsing) and the `unordered_map`/sort machinery
inside `Aggregator`/`top_k`. The call tree shows the same data organized by
caller, which is more useful than the flat profile once `ThreadPool::enqueue`
lambdas show up as the caller of everything — it tells you which call *site*
(not just which function) is expensive.

## Lessons learned

* Because `gprofng` doesn't need `-pg`, you can profile the exact `Release`
  build you'd ship, rather than a specially-instrumented one — prefer it over
  `gprof` when the two tools would otherwise answer the same question.
* Experiment directories (`*.er/`) are real directories, not single files —
  clean them up between runs (the script does this via `rm -rf`) or
  `gprofng collect` will refuse to overwrite an existing one.
