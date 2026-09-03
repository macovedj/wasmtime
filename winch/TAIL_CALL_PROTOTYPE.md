# Winch caller-pop tail-call prototype measurements

AArch64 values retain the prior native measurements. x86-64 values are medians
of three native Criterion runs on an AMD Ryzen 9 9950X.

## Compilation-time measurements

Milliseconds per 256-function, 10-argument module.

Tests: `tail-calls/{arch}/compile/{ordinary,tail}/winch` from
`benches/tail_calls.rs::compile_fixture`.

| Version               | AArch64 ordinary (ms) | AArch64 tail (ms) | x86-64 ordinary (ms) | x86-64 tail (ms) |
|-----------------------|----------------------:|------------------:|---------------------:|-----------------:|
| Before tail-call work |                 0.963 |                 — |                0.858 |                — |
| Caller-pop prototype  |                 0.962 |             0.991 |                0.861 |            0.842 |

## Runtime measurements

Microseconds at recursion depth 1,000. Each ordinary/tail pair is the same
recursive module with only `call` changed to `return_call`.

Tests from `benches/tail_calls.rs::bench_runtime`:
`ordinary/register-args` and `tail/fixed-register-args`;
`ordinary/stack-args` and `tail/fixed-stack-args`;
`ordinary/resize-direct` and `tail/resize-direct`;
`ordinary/resize-indirect` and `tail/resize-indirect`.

### Caller-pop prototype

Percentages on Winch ordinary results are changes from the corresponding
pre-tail-call baseline.

| Test            | Version/compiler      | AArch64 ordinary (µs) | AArch64 tail (µs) | x86-64 ordinary (µs) | x86-64 tail (µs) |
|-----------------|-----------------------|----------------------:|------------------:|---------------------:|-----------------:|
| Register args   | Before tail-call work |                 6.532 |                 — |                1.884 |                — |
| Register args   | Caller-pop Winch      |          6.697 (+2.5%) |             1.685 |       2.781 (+47.6%) |            1.008 |
| Register args   | Cranelift             |                 4.795 |             0.473 |                1.330 |            1.189 |
| Stack args      | Before tail-call work |                 8.645 |                 — |                3.185 |                — |
| Stack args      | Caller-pop Winch      |          8.983 (+3.9%) |             4.313 |       4.847 (+52.2%) |            3.023 |
| Stack args      | Cranelift             |                 5.442 |             1.152 |                1.747 |            1.381 |
| Resize direct   | Before tail-call work |                 6.937 |                 — |                5.257 |                — |
| Resize direct   | Caller-pop Winch      |          7.164 (+3.3%) |             2.966 |        5.617 (+6.8%) |            2.238 |
| Resize direct   | Cranelift             |                 5.145 |             0.857 |                4.352 |            1.317 |
| Resize indirect | Before tail-call work |                 7.647 |                 — |                6.290 |                — |
| Resize indirect | Caller-pop Winch      |         8.639 (+13.0%) |             3.676 |        6.860 (+9.1%) |            3.175 |
| Resize indirect | Cranelift             |                 6.764 |             2.094 |                6.029 |            2.459 |

The x86-64 fixed-register tail measurements had wider confidence intervals
than the other runtime cases.

## Commands

```console
WASMTIME_TAIL_CALL_ORDINARY_ONLY=1 cargo bench --bench tail_calls -- --noplot
cargo bench --bench tail_calls -- --noplot
```
