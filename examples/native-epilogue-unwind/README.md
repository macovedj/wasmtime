# Native x86-64 epilogue unwind reproducer

This standalone diagnostic demonstrates a missing-caller-frame limitation in
native DWARF unwinding through ordinary Winch **and** Cranelift epilogues.
It does not change the compiler, implement a fix, or require tail calls.

The branch is based on upstream commit
`0675528cca48cc8dd90cefe91eb7f1a279a7415b`. Its only additions are this directory.
This branch includes no tail-call changes; the diagnostic disables the Wasm
tail-call feature.

## Run

Use native x86-64 GNU/Linux with `libgcc_s`, a C compiler/linker, and Rust
1.97.1. Run outside a debugger, or configure it to deliver `SIGTRAP` to the
program. The process must be allowed to temporarily make its own JIT pages
writable and executable; do not weaken system protections to run this probe.

```console
git clone --branch native-epilogue-unwind-repro --single-branch https://github.com/macovedj/wasmtime.git
cd wasmtime
cargo +1.97.1 run --release --locked --manifest-path examples/native-epilogue-unwind/Cargo.toml
```

The default command reports results and exits successfully if the diagnostic's
controls passed, even when a caller frame is missing. To require both Wasm
frames at every sampled instruction boundary:

```console
cargo +1.97.1 run --release --locked --manifest-path examples/native-epilogue-unwind/Cargo.toml -- --check
```

`--check` exits with status 1 when it reproduces the unwind gap, and status 0 if
every sample recovers both Wasm frames. Unsupported platforms exit with status
2. No submodules or changes to the workspace's default build are needed.

## What is being tested?

For each compiler, two modules exercise register arguments (one `i64`) and
stack arguments (ten `i64`s). Both perform this ordinary, non-tail call:

```text
host -> run -> leaf
              returns 42
        adds 1 and returns 43
```

The probe explicitly disables Wasm tail calls and Cranelift inlining. It locates
`leaf`'s `pop rbp` and `ret` using a disassembler, then captures a native stack
before each instruction from the `pop` through the `ret`.

Each capture replaces the instruction's first byte with `INT3`. The `SIGTRAP`
handler corrects the saved RIP from `site + 1` back to `site` **before** calling
libgcc's `_Unwind_Backtrace`, so the unwind lookup uses the original instruction
boundary. It restores the original byte and resumes the original instruction.
Instruction bytes, returned value, and exactly one signal are checked each time.

The expected Wasm frames are `["leaf", "run"]` at both boundaries:

- Before `pop rbp`, both frames must be present. This is a positive control for
  registration, signal-frame traversal, and function-address mapping.
- Before `ret`, RBP has already been restored to the caller's value. The missing
  epilogue CFI leaves the active rule as `CFA = RBP + 16`, using the wrong frame
  pointer and skipping `run`.

The code checks that the native unwinder actually sees the normalized interrupted
PC. It uses `_Unwind_GetIPInfo` to distinguish that PC from ordinary return
addresses when mapping native frames to Wasm functions. Captures that overflow
the preallocated buffer are rejected.

`complete` refers only to recovering these two defined Wasm frames, not every
native frame in the process. All ordinary Wasm executions still return 43.

## Observed result

Reproduced on native x86-64 GNU/Linux with Rust 1.97.1:

| Compiler | Arguments | Before `pop rbp` | Before `ret` |
|----------|-----------|------------------|--------------|
| Winch | Register | `leaf, run` | `leaf` |
| Winch | Stack | `leaf, run` | `leaf` |
| Cranelift | Register | `leaf, run` | `leaf` |
| Cranelift | Stack | `leaf, run` | `leaf` |

The default run reports `4/8` instruction boundaries with both Wasm frames and
exits 0; `--check` reports the same captures and exits 1. These counts describe
this deliberately selected set of boundaries, **not** a failure rate under
real-world sampling. Cranelift's stack-argument return is `ret 0x30`; the others
are plain `ret`.

## Scope

This is a Linux x86-64/libgcc diagnostic, not a test of Windows unwind tables,
AArch64, Rust async, or Wasmtime's own `WasmBacktrace`. It samples specific
instruction boundaries; it does not measure how often a profiler would hit them.

This limitation is already documented in
[`UnwindInst`](../../cranelift/codegen/src/isa/unwind.rs), which currently describes
prologues but omits epilogues. The reproducer makes the effect observable using
the native unwinder; it does not establish that every native unwind consumer or
every frame transition behaves identically.

The signal handler is deliberately constrained diagnostic code, not a general
async-signal-safe profiler. Execution is synchronous on one thread, parallel
compilation is disabled by the dependency features, and libgcc is warmed up
before installing the handler. Those precautions do not make arbitrary use of
native unwinding from signal handlers safe. Only this disposable process's own
JIT pages are patched; page permissions and the prior signal handler are
restored on normal completion.
