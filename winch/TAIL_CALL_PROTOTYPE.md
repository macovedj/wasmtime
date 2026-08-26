# Winch tail-call prototype measurements

AArch64: native. x86-64: Rosetta.

## Compilation time

Milliseconds per 256-function, 10-argument module.

Tests: `tail-calls/{arch}/compile/{ordinary,tail}/{compiler}` from
`benches/tail_calls.rs::compile_fixture`.

| Compiler  | AArch64 ordinary | AArch64 tail | x86-64 ordinary | x86-64 tail |
|-----------|-----------------:|-------------:|----------------:|------------:|
| Winch     |            0.957 |        0.982 |           1.340 |       1.359 |
| Cranelift |            1.444 |        1.433 |           2.487 |       2.084 |

## Recursive runtime

Microseconds at recursion depth 1,000. Each ordinary/tail pair is the same
recursive module with only `call` changed to `return_call`.

Tests from `benches/tail_calls.rs::bench_runtime`:
`ordinary/register-args` and `tail/fixed-register-args`;
`ordinary/stack-args` and `tail/fixed-stack-args`;
`ordinary/resize-direct` and `tail/resize-direct`;
`ordinary/resize-indirect` and `tail/resize-indirect`.

| Test            | Compiler  | AArch64 ordinary | AArch64 tail | x86-64 ordinary | x86-64 tail |
|-----------------|-----------|-----------------:|-------------:|----------------:|------------:|
| Register args   | Winch     |            6.261 |        1.072 |           5.798 |       0.710 |
| Register args   | Cranelift |            5.002 |        0.475 |           4.574 |       0.481 |
| Stack args      | Winch     |            8.320 |        4.301 |           7.959 |       3.641 |
| Stack args      | Cranelift |            5.598 |        1.153 |           5.832 |       1.206 |
| Resize direct   | Winch     |            7.008 |        2.890 |           6.401 |       3.261 |
| Resize direct   | Cranelift |            5.250 |        0.839 |           5.316 |       0.939 |
| Resize indirect | Winch     |            7.746 |        3.648 |           7.354 |       4.008 |
| Resize indirect | Cranelift |            6.984 |        2.067 |           6.978 |       2.242 |

## State-machine runtime

Microseconds per 100,000 transitions.

Tests: `ordinary/state-machine-dispatch` and `tail/state-machine` from
`benches/tail_calls.rs::bench_runtime`.

| Compiler  | AArch64 ordinary | AArch64 tail | x86-64 ordinary | x86-64 tail |
|-----------|-----------------:|-------------:|----------------:|------------:|
| Winch     |           213.53 |       173.58 |          261.64 |      165.26 |
| Cranelift |           115.13 |        49.77 |          120.22 |       46.76 |

## Bounded stack

Test: `tests/all/winch_engine_features.rs::tail_calls_remain_bounded_when_ordinary_recursion_overflows`.
Each cell is the result at depth 1,000,000 with a 64 KiB maximum Wasm stack.

| Compiler | AArch64 ordinary | AArch64 tail | x86-64 ordinary | x86-64 tail |
|----------|------------------|--------------|-----------------|-------------|
| Winch    | `StackOverflow`  | `42`         | `StackOverflow` | `42`        |

## Winch state-machine disassembly

Instructions executed per nonzero transition, including the ordinary step
callee. The ordinary range covers the two alternating dispatch paths.

Tests: `tests/disas/winch/aarch64/tail_call/state_machine.wat` and
`tests/disas/winch/x64/tail_call/state_machine.wat`.

| Metric              | AArch64 ordinary | AArch64 tail | x86-64 ordinary | x86-64 tail |
|---------------------|-----------------:|-------------:|----------------:|------------:|
| Instructions        |            61–62 |           35 |           49–50 |          29 |
| Memory instructions |               21 |           13 |              21 |          11 |

## Commands

```console
cargo test --test all winch_tail_call -- --nocapture
cargo test --target x86_64-apple-darwin --test all winch_tail_call -- --nocapture
cargo test --test wast -- return_call --nocapture
cargo test --test disas -- tail_call/state_machine
cargo bench --bench tail_calls -- --noplot
cargo bench --target x86_64-apple-darwin --bench tail_calls -- --noplot
```
