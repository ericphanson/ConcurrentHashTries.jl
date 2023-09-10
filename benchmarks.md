# Benchmark Report for */Users/eph/ConcurrentHashTries.jl*

## Job Properties
* Time of benchmarks:
    - Target: 11 Sep 2023 - 01:21
    - Baseline: 11 Sep 2023 - 01:21
* Package commits:
    - Target: b1c48c
    - Baseline: 2b7e44
* Julia commits:
    - Target: bed2cd
    - Baseline: bed2cd
* Julia command flags:
    - Target: None
    - Baseline: None
* Environment variables:
    - Target: None
    - Baseline: None

## Results
A ratio greater than `1.0` denotes a possible regression (marked with :x:), while a ratio less
than `1.0` denotes a possible improvement (marked with :white_check_mark:). Only significant results - results
that indicate possible regressions or improvements - are shown below (thus, an empty table means that all
benchmark results remained invariant between builds).

| ID                                      | time ratio    | memory ratio  |
|-----------------------------------------|---------------|---------------|
| `["insert", "integers"]`                | 1.21 (5%) :x: | 1.09 (1%) :x: |
| `["insert", "integers_hash_colliding"]` | 1.08 (5%) :x: | 1.38 (1%) :x: |
| `["insert", "integers_same_slot"]`      |    1.03 (5%)  | 1.13 (1%) :x: |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["insert"]`

## Julia versioninfo

### Target
```
Julia Version 1.9.3
Commit bed2cd540a1 (2023-08-24 14:43 UTC)
Build Info:
  Official https://julialang.org/ release
Platform Info:
  OS: macOS (arm64-apple-darwin22.4.0)
  uname: Darwin 21.6.0 Darwin Kernel Version 21.6.0: Sun Nov  6 23:29:57 PST 2022; root:xnu-8020.240.14~1/RELEASE_ARM64_T8101 arm64 arm
  CPU: Apple M1: 
              speed         user         nice          sys         idle          irq
       #1  2400 MHz    8243986 s          0 s    7411755 s   44411359 s          0 s
       #2  2400 MHz    7824052 s          0 s    6963738 s   45278545 s          0 s
       #3  2400 MHz    7094710 s          0 s    5787465 s   47184172 s          0 s
       #4  2400 MHz    6669516 s          0 s    5040325 s   48356519 s          0 s
       #5  2400 MHz    8668254 s          0 s    5232965 s   46165147 s          0 s
       #6  2400 MHz    5424928 s          0 s    2213226 s   52428227 s          0 s
       #7  2400 MHz    3816591 s          0 s    1230162 s   55019632 s          0 s
       #8  2400 MHz    3149687 s          0 s     803986 s   56112700 s          0 s
  Memory: 16.0 GB (86.765625 MB free)
  Uptime: 1.5238887e7 sec
  Load Avg:  1.46240234375  2.63720703125  3.26025390625
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-14.0.6 (ORCJIT, apple-m1)
  Threads: 4 on 4 virtual cores
```

### Baseline
```
Julia Version 1.9.3
Commit bed2cd540a1 (2023-08-24 14:43 UTC)
Build Info:
  Official https://julialang.org/ release
Platform Info:
  OS: macOS (arm64-apple-darwin22.4.0)
  uname: Darwin 21.6.0 Darwin Kernel Version 21.6.0: Sun Nov  6 23:29:57 PST 2022; root:xnu-8020.240.14~1/RELEASE_ARM64_T8101 arm64 arm
  CPU: Apple M1: 
              speed         user         nice          sys         idle          irq
       #1  2400 MHz    8243990 s          0 s    7411762 s   44411404 s          0 s
       #2  2400 MHz    7824056 s          0 s    6963744 s   45278590 s          0 s
       #3  2400 MHz    7094715 s          0 s    5787470 s   47184218 s          0 s
       #4  2400 MHz    6669520 s          0 s    5040329 s   48356568 s          0 s
       #5  2400 MHz    8668272 s          0 s    5232968 s   46165182 s          0 s
       #6  2400 MHz    5424950 s          0 s    2213228 s   52428257 s          0 s
       #7  2400 MHz    3816604 s          0 s    1230164 s   55019674 s          0 s
       #8  2400 MHz    3149704 s          0 s     803987 s   56112738 s          0 s
  Memory: 16.0 GB (69.125 MB free)
  Uptime: 1.5238893e7 sec
  Load Avg:  1.42529296875  2.60986328125  3.24658203125
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-14.0.6 (ORCJIT, apple-m1)
  Threads: 4 on 4 virtual cores
```