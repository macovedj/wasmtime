# Winch tail-call prototype measurements

AArch64: native. x86-64: Rosetta.

## Compilation-time measurements

Milliseconds per 256-function, 10-argument module.

Tests: `tail-calls/{arch}/compile/{ordinary,tail}/winch` from
`benches/tail_calls.rs::compile_fixture`.

The AArch64 pre/post values are from back-to-back runs. The x86-64 pre/post
values are the observed ranges across repeated Rosetta runs.

| Version               | AArch64 ordinary (ms) | AArch64 tail (ms) | x86-64 ordinary (ms) | x86-64 tail (ms) |
|-----------------------|----------------------:|------------------:|---------------------:|-----------------:|
| Before tail-call work |                 0.963 |                 — |                1.362 |                — |
| Tail-call prototype   |                 0.962 |             0.991 |          1.357–1.405 |      1.316–1.317 |

## Runtime measurements

### Recursive calls

Microseconds at recursion depth 1,000. Each ordinary/tail pair is the same
recursive module with only `call` changed to `return_call`.

Tests from `benches/tail_calls.rs::bench_runtime`:
`ordinary/register-args` and `tail/fixed-register-args`;
`ordinary/stack-args` and `tail/fixed-stack-args`;
`ordinary/resize-direct` and `tail/resize-direct`;
`ordinary/resize-indirect` and `tail/resize-indirect`.

#### Before tail-call work

The corrected ordinary fixtures were overlaid on the comparison base.

| Test            | AArch64 ordinary (µs) | x86-64 ordinary (µs) |
|-----------------|----------------------:|---------------------:|
| Register args   |                 6.532 |                6.142 |
| Stack args      |                 8.645 |                8.806 |
| Resize direct   |                 6.937 |                6.948 |
| Resize indirect |                 7.647 |                7.867 |

#### Tail-call prototype

| Test            | Compiler  | AArch64 ordinary (µs) | AArch64 tail (µs) | x86-64 ordinary (µs) | x86-64 tail (µs) |
|-----------------|-----------|----------------------:|------------------:|---------------------:|-----------------:|
| Register args   | Winch     |                 6.697 |             1.685 |                6.010 |            1.772 |
| Register args   | Cranelift |                 4.795 |             0.473 |                4.933 |            0.480 |
| Stack args      | Winch     |                 8.983 |             4.313 |                8.413 |            3.774 |
| Stack args      | Cranelift |                 5.442 |             1.152 |                5.826 |            1.201 |
| Resize direct   | Winch     |                 7.164 |             2.966 |                6.699 |            3.331 |
| Resize direct   | Cranelift |                 5.145 |             0.857 |                5.232 |            0.941 |
| Resize indirect | Winch     |                 8.639 |             3.676 |                7.491 |            4.121 |
| Resize indirect | Cranelift |                 6.764 |             2.094 |                8.074 |            2.171 |

### State machine

Microseconds per 100,000 transitions.

Tests: `ordinary/state-machine-dispatch` and `tail/state-machine` from
`benches/tail_calls.rs::bench_runtime`.

#### Before tail-call work

| Compiler | AArch64 ordinary (µs) | x86-64 ordinary (µs) |
|----------|----------------------:|---------------------:|
| Winch    |                246.19 |               274.35 |

#### Tail-call prototype

| Compiler  | AArch64 ordinary (µs) | AArch64 tail (µs) | x86-64 ordinary (µs) | x86-64 tail (µs) |
|-----------|----------------------:|------------------:|---------------------:|-----------------:|
| Winch     |                246.49 |            253.98 |               274.66 |           268.98 |
| Cranelift |                109.84 |             48.87 |               117.20 |            46.09 |

## Commands

```console
WASMTIME_TAIL_CALL_ORDINARY_ONLY=1 cargo bench --bench tail_calls -- --noplot
cargo bench --bench tail_calls -- --noplot
cargo bench --target x86_64-apple-darwin --bench tail_calls -- --noplot
```
