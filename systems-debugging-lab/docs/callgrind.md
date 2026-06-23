# Callgrind

Callgrind extends Cachegrind with full call-graph recording — instruction
counts per call edge, not just per function — and can be visualized with
KCachegrind. It's the tool for "which call *path*, not just which function,
is expensive," which matters once a function like
`Aggregator::merge` is called from several places. Linux-only (part of
Valgrind); use the Docker dev environment.

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_callgrind.sh
```

Runs `valgrind --tool=callgrind ./build/logforge --input logs/10k.log --top-paths 10`
from inside `results/`, then pipes `callgrind.out.*` through
`callgrind_annotate`. Output is saved to `results/callgrind.log`.

## Run it by hand

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cd results
valgrind --tool=callgrind ../build/logforge --input ../logs/1m.log --top-paths 10
callgrind_annotate callgrind.out.* > callgrind.txt
# Optional GUI (not installed in the Docker image):
kcachegrind callgrind.out.*
```

## What to look for

For `--top-paths`, `callgrind_annotate` should show `top_k()`'s
`std::sort` call as a meaningful fraction of total instructions once the
number of distinct paths gets large — sorting the *entire* map just to take
the top K is wasted work. The README's benchmark matrix calls this out
directly ("full sort vs min-heap" under Top-K query); Callgrind's call-graph
view is what would tell you to replace `std::sort` + `resize` in
`Aggregator::top_k` with a bounded `std::partial_sort` or a min-heap, and
then let you confirm the instruction count for that call edge actually drops
afterward.

## Lessons learned

* Callgrind's overhead is the highest of the Valgrind tools used in this
  project (it's recording every call edge, not just sampling) — reserve it
  for the specific function/path you already suspect from a cheaper tool
  (perf, gprof, gprofng), rather than as a first profiling pass.
* `callgrind_annotate`'s default output is sorted by *inclusive* cost; for
  "which call site specifically is slow" rather than "which function and
  everything it calls is slow," cross-reference against the (exclusive-cost)
  Cachegrind/gprof flat profile too.
