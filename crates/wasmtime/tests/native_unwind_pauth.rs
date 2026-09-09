//! Native frame recovery with the macOS arm64 process ABI's default settings.
#![cfg(all(
    target_os = "macos",
    target_arch = "aarch64",
    feature = "cranelift",
    feature = "runtime",
    feature = "std",
    feature = "wat",
    not(miri)
))]

use std::ffi::c_void;
use wasmtime::{Caller, Config, Engine, Func, Inlining, Instance, Module, Result, Store};

unsafe extern "C" {
    fn _Unwind_Backtrace(
        callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32,
        data: *mut c_void,
    ) -> i32;
    fn _Unwind_GetIP(context: *mut c_void) -> usize;
}

unsafe extern "C" fn record_frame(context: *mut c_void, data: *mut c_void) -> i32 {
    // SAFETY: the caller exclusively borrows this Vec during _Unwind_Backtrace.
    // The unwinder supplies a valid context.
    let frames = unsafe { &mut *data.cast::<Vec<usize>>() };
    if frames.len() == frames.capacity() {
        return 5; // _URC_END_OF_STACK; do not allocate in this callback.
    }
    frames.push(unsafe { _Unwind_GetIP(context) });
    0 // _URC_NO_REASON: keep walking.
}

fn check_stack(wat: &str, expected: &[&str], value: i32) -> Result<()> {
    // This regression concerns ordinary arm64 processes, whose signing
    // instructions are disabled by macOS. The arm64e default is unchanged.
    // SAFETY: dyld image zero is the process's permanently mapped executable.
    let header = unsafe { &*mach2::dyld::_dyld_get_image_header(0) };
    if header.cpusubtype as u32 & 0x00ff_ffff == 2 {
        return Ok(());
    }
    let mut config = Config::new();
    config
        .native_unwind_info(true)
        .compiler_inlining(Inlining::No);
    let engine = Engine::new(&config)?;
    let module = Module::new(&engine, wat)?;
    let start = module.text().as_ptr() as usize;
    let functions = module
        .functions()
        .map(|f| (f.name, start + f.offset, f.len))
        .collect::<Vec<_>>();
    let mut store = Store::new(&engine, Vec::<usize>::with_capacity(128));
    let capture = Func::wrap(&mut store, |mut caller: Caller<'_, Vec<usize>>| {
        // SAFETY: record_frame has the unwinder callback ABI. The exclusively
        // borrowed Vec stays alive for the whole synchronous walk.
        unsafe { _Unwind_Backtrace(record_frame, (caller.data_mut() as *mut Vec<usize>).cast()) };
        10_i32
    });
    let instance = Instance::new(&mut store, &module, &[capture.into()])?;
    let actual = instance
        .get_typed_func::<(), i32>(&mut store, "run")?
        .call(&mut store, ())?;
    assert_eq!(actual, value);
    let names = store
        .data()
        .iter()
        .filter_map(|pc| {
            // A recovered return address may point one byte past a function.
            functions
                .iter()
                .find(|(_, lo, len)| *pc > *lo && *pc <= *lo + *len)
                .and_then(|(name, _, _)| name.as_deref())
        })
        .collect::<Vec<_>>();
    assert_eq!(names, expected);
    Ok(())
}

#[test]
fn native_unwind_default_process_abi() -> Result<()> {
    check_stack(
        r#"(module
            (import "" "capture" (func $capture (result i32)))
            (func $inner (result i32) call $capture i32.const 1 i32.add)
            (func $middle (result i32) call $inner i32.const 2 i32.add)
            (func $run (export "run") (result i32) call $middle i32.const 4 i32.add))"#,
        &["inner", "middle", "run"],
        17,
    )
}

#[test]
fn native_unwind_after_tail_call_changes_stack_arguments() -> Result<()> {
    // More arguments than fit in registers forces the tail caller to resize
    // the stack. Its frame must disappear, while its caller remains walkable.
    let params = "i32 ".repeat(24);
    let args = "i32.const 1 ".repeat(24);
    check_stack(
        &format!(
            r#"(module
                (import "" "capture" (func $capture (result i32)))
                (func $inner (param {params}) (result i32)
                    call $capture local.get 23 i32.add)
                (func $tail (result i32) {args} return_call $inner)
                (func $run (export "run") (result i32)
                    call $tail i32.const 4 i32.add))"#,
        ),
        &["inner", "run"],
        15,
    )
}

#[test]
fn native_unwind_after_tail_call_to_host() -> Result<()> {
    check_stack(
        r#"(module
            (import "" "capture" (func $capture (result i32)))
            (func $tail (result i32) return_call $capture)
            (func $run (export "run") (result i32) call $tail i32.const 4 i32.add))"#,
        &["run"],
        14,
    )
}

#[test]
fn native_unwind_after_tail_call_removes_stack_arguments() -> Result<()> {
    let params = "i32 ".repeat(24);
    let args = "i32.const 1 ".repeat(24);
    check_stack(
        &format!(
            r#"(module
                (import "" "capture" (func $capture (result i32)))
                (func $inner (result i32) call $capture i32.const 1 i32.add)
                (func $tail (param {params}) (result i32) return_call $inner)
                (func $run (export "run") (result i32)
                    {args} call $tail i32.const 4 i32.add))"#,
        ),
        &["inner", "run"],
        15,
    )
}
