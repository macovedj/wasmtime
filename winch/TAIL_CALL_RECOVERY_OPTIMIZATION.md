# Winch caller-pop recovery optimization measurements

Native x86-64 measurements on an AMD Ryzen 9 9950X. Criterion values are
medians of three runs. Runtime measurements were pinned to one CPU; compilation
measurements used normal machine affinity so parallel compilation remained
enabled. All versions used the benchmark fixtures from commit `6aa3d307b7`.

## Compilation time

Milliseconds per 256-function, 10-argument module.

| Version              | Ordinary | Tail call |
|----------------------|---------:|----------:|
| Before tail calls    |    0.836 |         — |
| Caller unoptimized   |    0.837 |     0.869 |
| Caller `memchr3`     |    0.840 |     0.840 |

## Ordinary-call runtime

Microseconds at recursion depth 1,000.

| Test            | Before tail calls | Caller unoptimized | Change | Caller `memchr3` | Change |
|-----------------|------------------:|-------------------:|-------:|-----------------:|-------:|
| Register args   |             1.884 |              2.769 | +47.0% |            1.858 |  -1.4% |
| Stack args      |             3.185 |              4.930 | +54.8% |            3.138 |  -1.5% |
| Resize direct   |             5.257 |              5.603 |  +6.6% |            5.182 |  -1.4% |
| Resize indirect |             6.290 |              6.840 |  +8.8% |            6.807 |  +8.2% |

## Sightglass

Percent change from the pre-tail-call baseline. Each column is a separate
engine-order run with 5 processes and 5 iterations per process.

| Workload       | Compile run 1 | Compile run 2 | Execute run 1 | Execute run 2 |
|----------------|--------------:|--------------:|--------------:|--------------:|
| bz2            |         +2.31% |         -4.60% |         +3.12% |         -3.89% |
| pulldown-cmark |         -3.37% |         +0.65% |         -2.39% |         +1.31% |
| SpiderMonkey   |         -0.08% |         -0.31% |         +0.22% |         -0.13% |
| Geometric mean |         -0.41% |         -1.45% |         +0.29% |         -0.93% |
