//! Exercise the system DWARF registry and native stack walking, including removal
//! of a section while others remain registered. WasmBacktrace uses a separate unwinder.
#![cfg(all(target_os = "macos", not(miri)))]

use wasmtime::{Config, Engine, Module, Result};

// Do not let another test allocate code at an address whose registration we are
// checking after its module has been dropped.
static TEST_LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());

#[repr(C)]
#[derive(Default)]
struct DwarfEhBases {
    tbase: usize,
    dbase: usize,
    func: usize,
}

unsafe extern "C" {
    fn _Unwind_Find_FDE(pc: *const u8, bases: *mut DwarfEhBases) -> *const u8;
}

fn find_fde(pc: usize) -> (usize, usize) {
    let mut bases = DwarfEhBases::default();
    // SAFETY: the API only looks up the address, and bases is a valid out pointer.
    let fde = unsafe { _Unwind_Find_FDE(pc as *const u8, &mut bases) as usize };
    (fde, bases.func)
}

fn check_module(module: &Module) -> Vec<usize> {
    let start = module.text().as_ptr() as usize;
    let image = module.image_range();
    let pcs = module
        .functions()
        .map(|f| start + f.offset + 1)
        .collect::<Vec<_>>();
    assert_eq!(pcs.len(), 3, "expected all three defined functions");
    for pc in &pcs {
        let (fde, func) = find_fde(*pc);
        assert!(fde >= image.start as usize && fde < image.end as usize);
        assert_eq!(func, pc - 1);
    }

    pcs
}

#[test]
fn native_unwind_sections_survive_non_lifo_removal() -> Result<()> {
    let _guard = TEST_LOCK.lock().unwrap();
    let mut config = Config::new();
    config.native_unwind_info(true);
    let engine = Engine::new(&config)?;
    let wasm = wat::parse_str(
        r#"(module
            (import "" "capture" (func $capture))
            (func $inner call $capture)
            (func $middle call $inner)
            (func (export "run") call $middle))"#,
    )?;
    let make_module = || Module::from_binary(&engine, &wasm);
    let first = make_module()?;
    let middle = make_module()?;
    let last = make_module()?;
    check_module(&first);
    let middle_pcs = check_module(&middle);
    check_module(&last);

    drop(middle);
    for pc in middle_pcs {
        assert_eq!(
            find_fde(pc).0,
            0,
            "dropped module still has registered unwind info"
        );
    }
    let first_pcs = check_module(&first);
    check_module(&last);
    drop(first);
    for pc in first_pcs {
        assert_eq!(find_fde(pc).0, 0);
    }
    let last_pcs = check_module(&last);
    drop(last);
    for pc in last_pcs {
        assert_eq!(find_fde(pc).0, 0);
    }
    // Exercise registration again after the registry has removed every section.
    let fresh = make_module()?;
    let fresh_pcs = check_module(&fresh);
    drop(fresh);
    for pc in fresh_pcs {
        assert_eq!(find_fde(pc).0, 0);
    }
    Ok(())
}

// The system unwinder currently stops before reaching the guest on aarch64,
// including without bulk registration. Keep this check on x86-64, where native
// stack walking traverses the host/guest transition.
#[cfg(target_arch = "x86_64")]
#[test]
fn native_unwind_walks_nested_wasm_frames() -> Result<()> {
    use std::ffi::c_void;
    use wasmtime::{Caller, Func, Inlining, Instance, Store, Strategy};

    let _guard = TEST_LOCK.lock().unwrap();

    unsafe extern "C" {
        fn _Unwind_Backtrace(
            callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32,
            data: *mut c_void,
        ) -> i32;
        fn _Unwind_GetIP(context: *mut c_void) -> usize;
    }

    unsafe extern "C" fn record_frame(context: *mut c_void, data: *mut c_void) -> i32 {
        // SAFETY: the caller passes an exclusively borrowed Vec for the duration
        // of _Unwind_Backtrace. The unwinder supplies a valid context.
        let frames = unsafe { &mut *data.cast::<Vec<usize>>() };
        if frames.len() == frames.capacity() {
            return 5; // _URC_END_OF_STACK; do not allocate in the callback.
        }
        frames.push(unsafe { _Unwind_GetIP(context) });
        0 // _URC_NO_REASON: continue walking.
    }

    let mut config = Config::new();
    config
        .strategy(Strategy::Cranelift)
        .native_unwind_info(true)
        .compiler_inlining(Inlining::No);
    let engine = Engine::new(&config)?;
    // Post-call arithmetic keeps each guest caller live instead of tail calling.
    let module = Module::new(
        &engine,
        r#"(module
            (import "" "capture" (func $capture (result i32)))
            (func $inner (result i32) call $capture i32.const 1 i32.add)
            (func $middle (result i32) call $inner i32.const 2 i32.add)
            (func $run (export "run") (result i32) call $middle i32.const 4 i32.add))"#,
    )?;
    let start = module.text().as_ptr() as usize;
    let functions = module
        .functions()
        .map(|f| (f.name, start + f.offset, f.len))
        .collect::<Vec<_>>();
    let mut store = Store::new(&engine, Vec::<usize>::with_capacity(128));
    let capture = Func::wrap(&mut store, |mut caller: Caller<'_, Vec<usize>>| {
        // SAFETY: record_frame has the callback ABI required by the unwinder.
        // The Vec remains alive and exclusively borrowed until the call returns.
        unsafe {
            _Unwind_Backtrace(record_frame, (caller.data_mut() as *mut Vec<usize>).cast());
        }
        10_i32
    });
    let instance = Instance::new(&mut store, &module, &[capture.into()])?;
    assert_eq!(
        instance
            .get_typed_func::<(), i32>(&mut store, "run")?
            .call(&mut store, ())?,
        17
    );
    let names = store
        .data()
        .iter()
        .filter_map(|pc| {
            // Return addresses point after the call instruction. Match actual
            // guest functions, not any trampoline inside the module's text.
            functions
                .iter()
                .find(|(_, start, len)| *pc > *start && *pc <= start + len)
                .map(|(name, _, _)| name.as_deref().unwrap_or_default())
        })
        .collect::<Vec<_>>();
    assert_eq!(names, ["inner", "middle", "run"]);
    Ok(())
}
