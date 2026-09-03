# Winch callee-pop tail-call prototype measurements

AArch64 values retain the prior native measurements. x86-64 values are medians
of three native Criterion runs on an AMD Ryzen 9 9950X.

## Compilation-time measurements

Milliseconds per 256-function, 10-argument module.

Tests: `tail-calls/{arch}/compile/{ordinary,tail}/winch` from
`benches/tail_calls.rs::compile_fixture`.

| Version               | AArch64 ordinary (ms) | AArch64 tail (ms) | x86-64 ordinary (ms) | x86-64 tail (ms) |
|-----------------------|----------------------:|------------------:|---------------------:|-----------------:|
| Before tail-call work |                 0.963 |                 — |                0.858 |                — |
| Callee-pop prototype  |                 0.991 |             0.996 |                0.842 |            0.845 |

## Runtime measurements

Microseconds at recursion depth 1,000. Each ordinary/tail pair is the same
recursive module with only `call` changed to `return_call`.

Tests from `benches/tail_calls.rs::bench_runtime`:
`ordinary/register-args` and `tail/fixed-register-args`;
`ordinary/stack-args` and `tail/fixed-stack-args`;
`ordinary/resize-direct` and `tail/resize-direct`;
`ordinary/resize-indirect` and `tail/resize-indirect`.

### Callee-pop prototype

Percentages on Winch ordinary results are changes from the corresponding
pre-tail-call baseline.

| Test            | Version/compiler      | AArch64 ordinary (µs) | AArch64 tail (µs) | x86-64 ordinary (µs) | x86-64 tail (µs) |
|-----------------|-----------------------|----------------------:|------------------:|---------------------:|-----------------:|
| Register args   | Before tail-call work |                 6.532 |                 — |                1.884 |                — |
| Register args   | Callee-pop Winch      |          6.630 (+1.5%) |             1.701 |        1.877 (−0.4%) |            1.046 |
| Register args   | Cranelift             |                 4.768 |             0.489 |                1.329 |            1.230 |
| Stack args      | Before tail-call work |                 8.645 |                 — |                3.185 |                — |
| Stack args      | Callee-pop Winch      |          9.086 (+5.1%) |             4.192 |       3.513 (+10.3%) |            3.019 |
| Stack args      | Cranelift             |                 5.444 |             1.159 |                1.745 |            1.378 |
| Resize direct   | Before tail-call work |                 6.937 |                 — |                5.257 |                — |
| Resize direct   | Callee-pop Winch      |          7.331 (+5.7%) |             2.957 |        5.751 (+9.4%) |            2.238 |
| Resize direct   | Cranelift             |                 5.372 |             0.888 |                4.353 |            1.323 |
| Resize indirect | Before tail-call work |                 7.647 |                 — |                6.290 |                — |
| Resize indirect | Callee-pop Winch      |          8.216 (+7.4%) |             3.680 |       6.929 (+10.2%) |            3.173 |
| Resize indirect | Cranelift             |                 6.990 |             2.146 |                6.020 |            2.462 |

The x86-64 fixed-register tail measurements had wider confidence intervals
than the other runtime cases.

## Commands

```console
WASMTIME_TAIL_CALL_ORDINARY_ONLY=1 cargo bench --bench tail_calls -- --noplot
cargo bench --bench tail_calls -- --noplot
```
