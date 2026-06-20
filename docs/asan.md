# AddressSanitizer

AddressSanitizer (ASan) instruments memory accesses at compile time to catch
stack/heap buffer overflows, use-after-free, and use-after-scope bugs, with
much lower overhead than Valgrind. It works on both macOS (Apple Clang) and
Linux.

## Run it

```bash
./scripts/run_asan.sh
```

Builds `build-asan/` (`-DENABLE_ASAN=ON`) and runs
`logforge --input logs/10k.log --status-counts`. Output is saved to
`results/asan.log`. The main `logforge` binary is clean — ASan only fires
against the demos in `bugs/`, shown below.

## Run it by hand

```bash
cmake -B build-asan -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON
cmake --build build-asan
./build-asan/bugs/bug_buffer_overflow
./build-asan/bugs/bug_use_after_free
```

## Worked example 1: stack buffer overflow (`bugs/buffer_overflow.cpp`)

```cpp
char method[4];  // Too small for "POST" + the null terminator.
std::strcpy(method, token.c_str());
```

Real captured output:

```text
==47784==ERROR: AddressSanitizer: stack-buffer-overflow on address 0x00016f1da824 ...
WRITE of size 5 at 0x00016f1da824 thread T0
    #0 ... in strcpy+0x458
    #1 ... in copy_method(char const*) buffer_overflow.cpp:7
    #2 ... in main buffer_overflow.cpp:12

Address ... is located in stack of thread T0 at offset 36 in frame
    #0 ... in copy_method(char const*) buffer_overflow.cpp:5

  This frame has 1 object(s):
    [32, 36) 'method' (line 6) <== Memory access at offset 36 overflows this variable
SUMMARY: AddressSanitizer: stack-buffer-overflow buffer_overflow.cpp:7 in copy_method(char const*)
```

Fix: use `std::string` (or a buffer sized for the worst case) instead of a
fixed 4-byte `char[]`.

## Worked example 2: use-after-free (`bugs/use_after_free.cpp`)

```cpp
Record* record = new Record{200};
delete record;
std::cout << record->status;  // Reads freed memory.
```

Real captured output:

```text
==47788==ERROR: AddressSanitizer: heap-use-after-free on address 0x6020000000d0 ...
READ of size 4 at 0x6020000000d0 thread T0
    #0 ... in main use_after_free.cpp:11

freed by thread T0 here:
    #0 ... in operator delete(void*)
    #1 ... in main use_after_free.cpp:10

previously allocated by thread T0 here:
    #0 ... in operator new(unsigned long)
    #1 ... in main use_after_free.cpp:9
SUMMARY: AddressSanitizer: heap-use-after-free use_after_free.cpp:11 in main
```

ASan's three-part report — the bad access, the `free` site, and the original
`alloc` site — is exactly the information you need and is harder to get from
a plain crash backtrace alone.

## Platform note

`ASAN_OPTIONS=detect_leaks=1` is **Linux-only**; setting it on macOS aborts
immediately with `detect_leaks is not supported on this platform`.
`scripts/run_asan.sh` only sets it when `uname -s` is `Linux`. For leak
detection on macOS, see `docs/lsan.md`.

## Lessons learned

* ASan's overhead (~2x) is low enough to run on every debug build, unlike
  Valgrind. Treat a clean ASan run as a normal part of the dev loop, not a
  special occasion.
* The "freed by / previously allocated by" pair in the use-after-free report
  is the single most useful piece of sanitizer output in this whole project —
  it turns "crash somewhere" into "these two call sites, in this order."
