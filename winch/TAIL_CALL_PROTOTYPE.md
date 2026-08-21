# Winch tail-call prototype

This note records the evidence gathered for the caller-clean tail-call
prototype motivated by [wasmtime#9732]. It is a prototype report, not a final
ABI proposal.

[wasmtime#9732]: https://github.com/bytecodealliance/wasmtime/issues/9732

## Question

Can Winch support `return_call` and `return_call_indirect` without first
changing its caller-clean ABI, while keeping the effects on ordinary calls,
compilation time, and the AArch64 backend acceptable?

The comparison base is commit `bc06450a02`. Measurements were collected on
2026-08-21 on an Apple Silicon host. AArch64 results are native. x86-64 runtime
results run under Rosetta and are useful for smoke testing and rough direction
only; they need confirmation on a native x86-64 machine.

## Prototype design

Outgoing stack arguments are staged below the current frame. The tail-call
sequence then:

1. preserves the caller frame state;
2. copies the staged arguments high-to-low into the replacement incoming area;
3. keeps the end of the argument area anchored when caller and callee argument
   sizes differ;
4. restores the caller frame state; and
5. jumps to the callee without adding a return address.

On x86-64 the preserved state is RBP and the return address. On AArch64 it is
FP, LR, and x28, Winch's shadow stack pointer. Capturing x28 before the argument
copy is necessary because a growing argument area can overwrite its saved
frame slot.

A final tail callee can return with real SP at a different position from the
function originally called. Winch callers therefore recover their canonical
SP from FP on x86-64 and from x28 on AArch64. Cranelift-generated trampolines
carry explicit call metadata requesting the equivalent FP-based recovery.
Hand-emitted Winch calls perform their own recovery, avoiding the duplicate
restore previously visible in the indirect-call lazy-initialization path.

## Correctness coverage

Both x86-64 and AArch64 pass focused tests for:

- direct and indirect chains of 100,000 tail calls;
- growing and shrinking stack-argument areas;
- imported Wasm and host functions;
- indirect-call null and signature traps;
- stack-carried multi-value results; and
- backtraces through an aborting final callee.

The 14 `return_call` proposal WAST configurations also pass. `return_call_ref`
remains outside this prototype because Winch does not yet support the function
references proposal.

## Measurements

The benchmark compiles a generated chain of 256 ten-argument functions and
executes 100,000 calls per runtime sample.

### Compilation and artifact size

| Target | Compiler/fixture | Compile time | Precompiled bytes |
| --- | --- | ---: | ---: |
| AArch64 native | Winch ordinary | 0.973 ms | 151,264 |
| AArch64 native | Winch tail | 0.989 ms | 167,656 |
| AArch64 native | Cranelift ordinary | 1.472 ms | 101,776 |
| AArch64 native | Cranelift tail | 1.453 ms | 101,776 |
| x86-64 Rosetta | Winch ordinary | 1.287 ms | 110,280 |
| x86-64 Rosetta | Winch tail | 1.355 ms | 130,784 |
| x86-64 Rosetta | Cranelift ordinary | 2.234 ms | 77,200 |
| x86-64 Rosetta | Cranelift tail | 2.076 ms | 73,104 |

Relative to the current ordinary fixture, the Winch tail fixture costs about
1.6% compilation time and 10.8% artifact size on AArch64, and about 5.3% and
18.6%, respectively, in the provisional x86-64 run.

Against the exact base, the AArch64 ordinary artifact is byte-for-byte the same
size and ordinary compilation shows no statistically significant change. Its
ordinary stack-call runtime was also within Criterion's noise threshold. The
register-only microbenchmark varied substantially between otherwise identical
runs and should not be used as an ABI decision signal. Under Rosetta, the
x86-64 prototype did not show an ordinary-call regression and produced a 3.6%
smaller ordinary artifact, but native x86-64 data is still required.

### Runtime of tail-call chains

Times below are microseconds per 100,000 calls. They measure the current
correctness-first frame shuffle, not an optimized final implementation.

| Target | Shape | Winch | Cranelift | Winch / Cranelift |
| --- | --- | ---: | ---: | ---: |
| AArch64 native | fixed register arguments | 292.12 | 46.48 | 6.3x |
| AArch64 native | fixed stack arguments | 610.46 | 115.27 | 5.3x |
| AArch64 native | resize, direct | 425.07 | 86.72 | 4.9x |
| AArch64 native | resize, indirect | 491.92 | 208.83 | 2.4x |
| x86-64 Rosetta | fixed register arguments | 172.19 | 46.33 | 3.7x |
| x86-64 Rosetta | fixed stack arguments | 399.37 | 128.90 | 3.1x |
| x86-64 Rosetta | resize, direct | 332.86 | 99.09 | 3.4x |
| x86-64 Rosetta | resize, indirect | 398.16 | 227.13 | 1.8x |

## Current decision

The caller-clean design is a viable working hypothesis on both supported Winch
architectures. The data does not yet justify a callee-clean ABI prototype:

- the stable ordinary-call compilation and size signals show no AArch64
  regression;
- the provisional x86-64 signals do not show a regression either; and
- the largest measured gap is in the tail-transfer sequence itself, whose
  argument copies and frame-state shuffle would still need optimization under
  either cleanup convention.

Before reopening the ABI choice:

1. repeat the base/prototype comparison on native x86-64 hardware;
2. add paired or otherwise frequency-controlled runtime measurements;
3. specialize the zero-stack-argument and equal-sized-argument tail paths; and
4. remeasure tail runtime and ordinary-call overhead.

A callee-clean spike becomes worthwhile if native data shows a repeatable
ordinary-call regression or if simplifying the tail-transfer sequence requires
moving cleanup responsibility into the callee. Any such spike should include
both x86-64 and AArch64 from the start; AArch64 has no `ret imm` equivalent and
must express cleanup explicitly.

## Reproducing

```console
cargo test --test all winch_tail_call -- --nocapture
cargo test --test wast -- return_call --nocapture
cargo test --test disas -- /tail_call/
cargo bench --bench tail_calls -- --noplot
WASMTIME_TAIL_CALL_REPORT=1 cargo bench --bench tail_calls
```

For x86-64 cross-target smoke measurements on macOS, add
`--target x86_64-apple-darwin`. Set `WASMTIME_TAIL_CALL_ORDINARY_ONLY=1` to run
the control fixtures against a revision that predates Winch tail-call support.
