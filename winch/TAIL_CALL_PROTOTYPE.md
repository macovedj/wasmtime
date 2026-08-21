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

The follow-up fast paths avoid that general shuffle when it is unnecessary:

- equal-sized argument areas copy directly and restore the frame normally;
- zero-sized outgoing argument areas do not reserve scratch stack slots; and
- the full state-preserving shuffle remains only for a resize to a non-empty
  argument area.

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

Cranelift is a useful reference point, not a pass/fail threshold. Winch is not
expected to match an optimizing compiler. The more relevant acceptance signals
are whether ordinary Winch code regresses, whether tail calls preserve bounded
stack use, whether Winch retains its compilation-speed advantage, and how a
tail transfer compares with an ordinary Winch call. The microbenchmarks do not
establish a universal acceptable slowdown.

### Compilation and artifact size

| Target | Compiler/fixture | Compile time | Precompiled bytes |
| --- | --- | ---: | ---: |
| AArch64 native | Winch ordinary | 0.993 ms | 151,264 |
| AArch64 native | Winch tail | 0.999 ms | 167,648 |
| AArch64 native | Cranelift ordinary | 1.472 ms | 101,776 |
| AArch64 native | Cranelift tail | 1.469 ms | 101,776 |
| x86-64 Rosetta | Winch ordinary | 1.400 ms | 110,280 |
| x86-64 Rosetta | Winch tail | 1.319 ms | 118,488 |
| x86-64 Rosetta | Cranelift ordinary | 2.245 ms | 77,200 |
| x86-64 Rosetta | Cranelift tail | 2.062 ms | 73,104 |

In the current native run, the Winch tail fixture compiles within about 1% of
the ordinary fixture and about 32% faster than the Cranelift tail fixture. The
AArch64 artifact remains 10.8% larger than the ordinary Winch artifact. On
x86-64, the fast paths reduce the tail artifact from 130,784 to 118,488 bytes;
its overhead relative to the ordinary artifact falls from 18.6% to 7.4%.

Against the exact base, the AArch64 ordinary artifact is byte-for-byte the same
size and ordinary compilation shows no statistically significant change. Its
ordinary stack-call runtime was also within Criterion's noise threshold. The
register-only microbenchmark varied substantially between otherwise identical
runs and should not be used as an ABI decision signal. Under Rosetta, the
x86-64 prototype did not show an ordinary-call regression and produced a 3.6%
smaller ordinary artifact, but native x86-64 data is still required.

### Runtime of tail-call chains

Times below are microseconds per 100,000 calls. They measure the current
prototype, including the zero-sized and equal-sized fast paths.

| Target | Shape | Winch | Cranelift | Winch / Cranelift |
| --- | --- | ---: | ---: | ---: |
| AArch64 native | fixed register arguments | 165.20 | 47.60 | 3.5x |
| AArch64 native | fixed stack arguments | 415.69 | 115.55 | 3.6x |
| AArch64 native | resize, direct | 293.27 | 85.02 | 3.4x |
| AArch64 native | resize, indirect | 371.22 | 208.01 | 1.8x |
| x86-64 Rosetta | fixed register arguments | 167.78 | 46.50 | 3.6x |
| x86-64 Rosetta | fixed stack arguments | 374.92 | 122.91 | 3.1x |
| x86-64 Rosetta | resize, direct | 341.90 | 98.62 | 3.5x |
| x86-64 Rosetta | resize, indirect | 397.32 | 212.59 | 1.9x |

The within-Winch controls are more relevant to an initial acceptance judgment:

| Target | Shape | Tail chain | Ordinary-call control | Tail / ordinary |
| --- | --- | ---: | ---: | ---: |
| AArch64 native | register arguments | 165.20 | 92.95 | 1.8x |
| AArch64 native | stack arguments | 415.69 | 236.07 | 1.8x |
| x86-64 Rosetta | register arguments | 167.78 | 118.65 | 1.4x |
| x86-64 Rosetta | stack arguments | 374.92 | 251.59 | 1.5x |

These controls are intentionally simple and are not semantically identical to
the recursive chains, so their ratios are diagnostic rather than release
criteria. They do show that the Winch cost is closer to 1.4--1.8 times its own
ordinary-call controls than the Cranelift comparison alone suggests.

### Fast-path comparison

A back-to-back AArch64 comparison against commit `b24a9b7793` used
architecture-specific Criterion baselines. Ordinary Winch register-call
runtime showed no statistically significant change, and the ordinary
stack-call result remained within Criterion's noise threshold. Resize-direct
improved by 6.6% and resize-indirect by 2.5%, with their corresponding
Cranelift controls unchanged.

The fixed-size measurements were not conclusive: their unchanged Cranelift
controls moved by similar amounts between runs. The generated disassembly does
confirm fewer instructions and no scratch-stack reservation on the common
paths, but a paired or frequency-controlled experiment is still needed to
assign a reliable runtime percentage to those reductions. Benchmark groups are
now target-qualified so native AArch64 and Rosetta x86-64 runs cannot overwrite
each other's Criterion baselines.

## Current decision

The caller-clean design is a viable working hypothesis on both supported Winch
architectures. The data does not yet justify a callee-clean ABI prototype:

- the controlled ordinary-call runtime signals show no AArch64 regression;
- Winch retains a substantial compilation-time advantage on the tail fixture;
- the fast paths improve resizing calls without changing the ABI; and
- the remaining cost is local to tail transfer and should be evaluated against
  Winch's goals and real workloads, not Cranelift parity alone.

Before reopening the ABI choice:

1. repeat the base/prototype comparison on native x86-64 hardware;
2. add paired or otherwise frequency-controlled runtime measurements;
3. measure at least one representative tail-call-heavy workload in addition to
   microbenchmarks; and
4. decide an acceptable Winch-relative tail-transfer overhead with the Winch
   maintainers rather than deriving one from Cranelift's runtime.

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
