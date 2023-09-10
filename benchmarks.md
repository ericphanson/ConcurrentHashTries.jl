# Benchmark Report for */Users/eph/ConcurrentHashTries.jl*

## Job Properties
* Time of benchmarks:
    - Target: 11 Sep 2023 - 00:45
    - Baseline: 11 Sep 2023 - 00:45
* Package commits:
    - Target: 347a0b
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
| `["insert", "integers"]`                | 1.14 (5%) :x: | 1.14 (1%) :x: |
| `["insert", "integers_hash_colliding"]` | 1.39 (5%) :x: | 2.40 (1%) :x: |
| `["insert", "integers_same_slot"]`      | 1.14 (5%) :x: | 1.25 (1%) :x: |

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
       #1  2400 MHz    8238156 s          0 s    7406577 s   44400688 s          0 s
       #2  2400 MHz    7818315 s          0 s    6958764 s   45267577 s          0 s
       #3  2400 MHz    7089168 s          0 s    5782723 s   47172778 s          0 s
       #4  2400 MHz    6664090 s          0 s    5035791 s   48344801 s          0 s
       #5  2400 MHz    8665498 s          0 s    5231703 s   46147486 s          0 s
       #6  2400 MHz    5422891 s          0 s    2212482 s   52409328 s          0 s
       #7  2400 MHz    3815177 s          0 s    1229711 s   54999820 s          0 s
       #8  2400 MHz    3148580 s          0 s     803685 s   56092430 s          0 s
  Memory: 16.0 GB (120.546875 MB free)
  Uptime: 1.5236719e7 sec
  Load Avg:  4.3017578125  3.1943359375  2.771484375
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
       #1  2400 MHz    8238174 s          0 s    7406600 s   44400701 s          0 s
       #2  2400 MHz    7818334 s          0 s    6958786 s   45267590 s          0 s
       #3  2400 MHz    7089186 s          0 s    5782745 s   47172792 s          0 s
       #4  2400 MHz    6664107 s          0 s    5035814 s   48344814 s          0 s
       #5  2400 MHz    8665515 s          0 s    5231705 s   46147520 s          0 s
       #6  2400 MHz    5422909 s          0 s    2212483 s   52409363 s          0 s
       #7  2400 MHz    3815188 s          0 s    1229711 s   54999862 s          0 s
       #8  2400 MHz    3148596 s          0 s     803686 s   56092466 s          0 s
  Memory: 16.0 GB (117.328125 MB free)
  Uptime: 1.5236724e7 sec
  Load Avg:  4.7578125  3.30712890625  2.8134765625
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-14.0.6 (ORCJIT, apple-m1)
  Threads: 4 on 4 virtual cores
```