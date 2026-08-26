# Winch tail-call register-spike measurements

AArch64: native. x86-64: Rosetta.

Both versions use the benchmark fixtures from this branch. For `before`, those
fixtures were overlaid on the compiler at `de5224e342`; these are not the
measurements produced by that revision's original, non-equivalent ordinary-call
controls. `After` is this branch.

## Tail-call improvement over ordinary calls

Percent faster than the equivalent ordinary-call implementation in the same
version. A negative value means the tail-call implementation was slower.

| Test            | AArch64 before | AArch64 after | x86-64 before | x86-64 after |
|-----------------|---------------:|--------------:|--------------:|-------------:|
| Register args   |          74.8% |         82.9% |         70.5% |        87.8% |
| Stack args      |          52.0% |         48.3% |         55.1% |        54.3% |
| Resize direct   |          58.6% |         58.8% |         50.3% |        49.1% |
| Resize indirect |          57.4% |         52.9% |         45.0% |        45.5% |
| State machine   |          -3.0% |         18.7% |          2.1% |        36.8% |

## Improvement caused by the spike

Percent faster for the tail-call implementation after the spike than before
it. The spike targets conflict-free direct calls with register-only arguments.

| Test            | AArch64 | x86-64 |
|-----------------|--------:|-------:|
| Register args   |   36.4% |  59.9% |
| Stack args      |    0.3% |   3.5% |
| Resize direct   |    2.6% |   2.1% |
| Resize indirect |    0.8% |   2.7% |
| State machine   |   31.7% |  38.6% |

## Recursive runtime

Microseconds at recursion depth 1,000. Each ordinary/tail pair is the same
recursive module with only `call` changed to `return_call`.

Tests from `benches/tail_calls.rs::bench_runtime`:
`ordinary/register-args` and `tail/fixed-register-args`;
`ordinary/stack-args` and `tail/fixed-stack-args`;
`ordinary/resize-direct` and `tail/resize-direct`;
`ordinary/resize-indirect` and `tail/resize-indirect`.

### Pre-spike

| Test            | AArch64 ordinary | AArch64 tail | x86-64 ordinary | x86-64 tail |
|-----------------|-----------------:|-------------:|----------------:|------------:|
| Register args   |            6.697 |        1.685 |           6.010 |       1.772 |
| Stack args      |            8.983 |        4.313 |           8.413 |       3.774 |
| Resize direct   |            7.164 |        2.966 |           6.699 |       3.331 |
| Resize indirect |            8.639 |        3.676 |           7.491 |       4.121 |

### Post-spike

| Test            | AArch64 ordinary | AArch64 tail | x86-64 ordinary | x86-64 tail |
|-----------------|-----------------:|-------------:|----------------:|------------:|
| Register args   |            6.261 |        1.072 |           5.798 |       0.710 |
| Stack args      |            8.320 |        4.301 |           7.959 |       3.641 |
| Resize direct   |            7.008 |        2.890 |           6.401 |       3.261 |
| Resize indirect |            7.746 |        3.648 |           7.354 |       4.008 |

## State-machine runtime

Microseconds per 100,000 transitions.

Tests: `ordinary/state-machine-dispatch` and `tail/state-machine` from
`benches/tail_calls.rs::bench_runtime`.

| Version | AArch64 ordinary | AArch64 tail | x86-64 ordinary | x86-64 tail |
|---------|-----------------:|-------------:|----------------:|------------:|
| before  |           246.49 |       253.98 |          274.66 |      268.98 |
| after   |           213.53 |       173.58 |          261.64 |      165.26 |

## Commands

```console
cargo bench --bench tail_calls -- runtime --noplot
cargo bench --target x86_64-apple-darwin --bench tail_calls -- runtime --noplot
```
