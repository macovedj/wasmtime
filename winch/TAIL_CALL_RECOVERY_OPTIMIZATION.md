# Winch caller-pop recovery optimization measurements

Native x86-64 Criterion measurements on an AMD Ryzen 9 9950X. Values are
medians of three runs. Runtime measurements were pinned to one CPU; compilation
measurements used normal machine affinity so parallel compilation remained
enabled. All versions used the benchmark fixtures from commit `6aa3d307b7`.

## Compilation time

Milliseconds per 256-function, 10-argument module.

| Version              | Ordinary | Tail call |
|----------------------|---------:|----------:|
| Before tail calls    |    0.836 |         — |
| Caller unoptimized   |    0.837 |     0.869 |
| Caller optimized     |    0.835 |     0.882 |

## Ordinary-call runtime

Microseconds at recursion depth 1,000.

| Test            | Before tail calls | Caller unoptimized | Change | Caller optimized | Change |
|-----------------|------------------:|-------------------:|-------:|-----------------:|-------:|
| Register args   |             1.884 |              2.769 | +47.0% |            1.872 |  -0.6% |
| Stack args      |             3.185 |              4.930 | +54.8% |            3.165 |  -0.6% |
| Resize direct   |             5.257 |              5.603 |  +6.6% |            5.220 |  -0.7% |
| Resize indirect |             6.290 |              6.840 |  +8.8% |            6.847 |  +8.9% |
