//! Measure the caller-clean Winch tail-call prototype.
//!
//! Runtime benchmarks cover both the ordinary-call cost of recovering SP from
//! FP and tail-call chains with fixed, growing, and shrinking stack-argument
//! areas. Compilation benchmarks use generated high-arity call chains. Set
//! `WASMTIME_TAIL_CALL_REPORT=1` to print precompiled artifact sizes instead.

use criterion::{BenchmarkId, Criterion, Throughput};
use std::fmt::Write as _;
use std::hint::black_box;
use std::time::Duration;
use wasmtime::{Config, Engine, Module, Store, Strategy};

const RUNTIME_CALLS: u64 = 100_000;
const COMPILE_FUNCTIONS: usize = 256;

fn main() {
    let ordinary_only = std::env::var_os("WASMTIME_TAIL_CALL_ORDINARY_ONLY").is_some();
    if std::env::var_os("WASMTIME_TAIL_CALL_REPORT").is_some() {
        report_artifact_sizes(ordinary_only);
        return;
    }

    let mut criterion = Criterion::default().configure_from_args();
    bench_runtime(&mut criterion, ordinary_only);
    bench_compile(&mut criterion, ordinary_only);
    criterion.final_summary();
}

fn compiler_name(strategy: Strategy) -> &'static str {
    match strategy {
        Strategy::Cranelift => "cranelift",
        Strategy::Winch => "winch",
        _ => unreachable!(),
    }
}

fn engine(strategy: Strategy, tail_calls: bool) -> Engine {
    let mut config = Config::new();
    config.strategy(strategy).wasm_tail_call(tail_calls);
    Engine::new(&config).unwrap()
}

fn bench_runtime(c: &mut Criterion, ordinary_only: bool) {
    // Keep Criterion baselines architecture-specific. In particular, running
    // an x86-64 binary under Rosetta from an AArch64 host must not overwrite
    // the native AArch64 comparison data.
    let mut group = c.benchmark_group(format!("tail-calls/{}/runtime", std::env::consts::ARCH));
    group.throughput(Throughput::Elements(RUNTIME_CALLS));
    group.warm_up_time(Duration::from_secs(1));
    group.measurement_time(Duration::from_secs(3));
    group.sample_size(20);

    for strategy in [Strategy::Winch, Strategy::Cranelift] {
        let compiler = compiler_name(strategy);

        let benchmarks = [
            ("ordinary/register-args", ordinary_register_args(), false),
            ("ordinary/stack-args", ordinary_stack_args(), false),
            ("tail/fixed-register-args", tail_fixed_register_args(), true),
            ("tail/fixed-stack-args", tail_fixed_stack_args(), true),
            ("tail/resize-direct", tail_resize_direct(), true),
            ("tail/resize-indirect", tail_resize_indirect(), true),
        ];
        for (name, wat, tail_calls) in benchmarks {
            if ordinary_only && tail_calls {
                continue;
            }
            let engine = engine(strategy, tail_calls);
            let module = Module::new(&engine, wat).unwrap();
            let mut store = Store::new(&engine, ());
            let instance = wasmtime::Instance::new(&mut store, &module, &[]).unwrap();
            let run = instance
                .get_typed_func::<i64, i64>(&mut store, "run")
                .unwrap();

            group.bench_function(BenchmarkId::new(name, compiler), |b| {
                b.iter(|| {
                    let result = run
                        .call(&mut store, black_box(RUNTIME_CALLS as i64))
                        .unwrap();
                    black_box(result);
                });
            });
        }
    }
    group.finish();
}

fn bench_compile(c: &mut Criterion, ordinary_only: bool) {
    let mut group = c.benchmark_group(format!("tail-calls/{}/compile", std::env::consts::ARCH));
    group.warm_up_time(Duration::from_secs(1));
    group.measurement_time(Duration::from_secs(3));
    group.sample_size(20);

    for strategy in [Strategy::Winch, Strategy::Cranelift] {
        for tail_calls in [false, true] {
            if ordinary_only && tail_calls {
                continue;
            }
            let compiler = compiler_name(strategy);
            let kind = if tail_calls { "tail" } else { "ordinary" };
            let wasm = compile_fixture(tail_calls);
            let engine = engine(strategy, tail_calls);

            group.bench_function(BenchmarkId::new(kind, compiler), |b| {
                b.iter(|| Module::new(&engine, black_box(&wasm)).unwrap());
            });
        }
    }
    group.finish();
}

fn report_artifact_sizes(ordinary_only: bool) {
    println!(
        "precompiled artifact bytes for {} ({COMPILE_FUNCTIONS} high-arity functions)",
        std::env::consts::ARCH
    );
    for strategy in [Strategy::Winch, Strategy::Cranelift] {
        for tail_calls in [false, true] {
            if ordinary_only && tail_calls {
                continue;
            }
            let compiler = compiler_name(strategy);
            let kind = if tail_calls { "tail" } else { "ordinary" };
            let wasm = compile_fixture(tail_calls);
            let engine = engine(strategy, tail_calls);
            let artifact = engine.precompile_module(&wasm).unwrap();
            println!("{compiler:10} {kind:8} {}", artifact.len());
        }
    }
}

fn compile_fixture(tail_calls: bool) -> Vec<u8> {
    let mut wat = String::from("(module\n");
    for i in 0..COMPILE_FUNCTIONS {
        write!(
            wat,
            "(func $f{i} (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)\n"
        )
        .unwrap();
        if i + 1 == COMPILE_FUNCTIONS {
            wat.push_str("local.get 0)\n");
        } else {
            for arg in 0..10 {
                write!(wat, "local.get {arg}\n").unwrap();
            }
            let op = if tail_calls { "return_call" } else { "call" };
            writeln!(wat, "{op} $f{} )", i + 1).unwrap();
        }
    }
    wat.push_str(")");
    wat::parse_str(wat).unwrap()
}

fn ordinary_register_args() -> &'static str {
    r#"
        (module
          (func $callee)
          (func (export "run") (param $count i64) (result i64)
            (local $i i64)
            local.get $count
            local.set $i
            loop $loop
              call $callee
              local.get $i
              i64.const 1
              i64.sub
              local.tee $i
              i64.const 0
              i64.ne
              br_if $loop
            end
            local.get $count))
    "#
}

fn ordinary_stack_args() -> &'static str {
    r#"
        (module
          (func $callee (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64))
          (func (export "run") (param $count i64) (result i64)
            (local $i i64)
            local.get $count
            local.set $i
            loop $loop
              local.get $i
              i64.const 1
              i64.const 2
              i64.const 3
              i64.const 4
              i64.const 5
              i64.const 6
              i64.const 7
              i64.const 8
              i64.const 9
              call $callee
              local.get $i
              i64.const 1
              i64.sub
              local.tee $i
              i64.const 0
              i64.ne
              br_if $loop
            end
            local.get $count))
    "#
}

fn tail_fixed_register_args() -> &'static str {
    r#"
        (module
          (func $tail (param $count i64) (result i64)
            local.get $count
            i64.eqz
            if (result i64)
              i64.const 42
            else
              local.get $count
              i64.const 1
              i64.sub
              return_call $tail
            end)
          (func (export "run") (param i64) (result i64)
            local.get 0
            return_call $tail))
    "#
}

fn tail_fixed_stack_args() -> &'static str {
    r#"
        (module
          (func $tail
            (param $count i64)
            (param i64 i64 i64 i64 i64 i64 i64 i64 i64)
            (result i64)
            local.get $count
            i64.eqz
            if (result i64)
              i64.const 42
            else
              local.get $count
              i64.const 1
              i64.sub
              local.get 1
              local.get 2
              local.get 3
              local.get 4
              local.get 5
              local.get 6
              local.get 7
              local.get 8
              local.get 9
              return_call $tail
            end)
          (func (export "run") (param i64) (result i64)
            local.get 0
            i64.const 1
            i64.const 2
            i64.const 3
            i64.const 4
            i64.const 5
            i64.const 6
            i64.const 7
            i64.const 8
            i64.const 9
            return_call $tail))
    "#
}

fn tail_resize_direct() -> &'static str {
    r#"
        (module
          (func $small (param i64 i64 i64 i64 i64) (result i64)
            local.get 0
            i64.eqz
            if (result i64)
              i64.const 42
            else
              local.get 0
              i64.const 1
              i64.sub
              local.get 1
              local.get 2
              local.get 3
              local.get 4
              i64.const 5
              i64.const 6
              i64.const 7
              i64.const 8
              return_call $large
            end)
          (func $large (param i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)
            local.get 0
            i64.eqz
            if (result i64)
              i64.const 42
            else
              local.get 0
              i64.const 1
              i64.sub
              local.get 1
              local.get 2
              local.get 3
              local.get 4
              return_call $small
            end)
          (func (export "run") (param i64) (result i64)
            local.get 0
            i64.const 1
            i64.const 2
            i64.const 3
            i64.const 4
            return_call $small))
    "#
}

fn tail_resize_indirect() -> &'static str {
    r#"
        (module
          (type $small-ty (func (param i64 i64 i64 i64 i64) (result i64)))
          (type $large-ty
            (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)))
          (table funcref (elem $small $large))
          (func $small (type $small-ty)
            local.get 0
            i64.eqz
            if (result i64)
              i64.const 42
            else
              local.get 0
              i64.const 1
              i64.sub
              local.get 1
              local.get 2
              local.get 3
              local.get 4
              i64.const 5
              i64.const 6
              i64.const 7
              i64.const 8
              i32.const 1
              return_call_indirect (type $large-ty)
            end)
          (func $large (type $large-ty)
            local.get 0
            i64.eqz
            if (result i64)
              i64.const 42
            else
              local.get 0
              i64.const 1
              i64.sub
              local.get 1
              local.get 2
              local.get 3
              local.get 4
              i32.const 0
              return_call_indirect (type $small-ty)
            end)
          (func (export "run") (param i64) (result i64)
            local.get 0
            i64.const 1
            i64.const 2
            i64.const 3
            i64.const 4
            return_call $small))
    "#
}
