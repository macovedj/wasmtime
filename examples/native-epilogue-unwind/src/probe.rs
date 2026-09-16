use capstone::prelude::*;
use std::sync::atomic::{AtomicPtr, AtomicU8, AtomicUsize, Ordering};
use wasmtime::{Config, Engine, Inlining, Instance, Module, Store, Strategy};

#[link(name = "gcc_s")]
unsafe extern "C" {
    fn _Unwind_Backtrace(
        callback: extern "C" fn(*mut libc::c_void, *mut libc::c_void) -> i32,
        arg: *mut libc::c_void,
    ) -> i32;
    fn _Unwind_GetIPInfo(context: *mut libc::c_void, before_instruction: *mut i32) -> usize;
}

#[derive(Clone, Copy, Default)]
struct Frame {
    ip: usize,
    before_instruction: i32,
}

#[derive(Default)]
struct Capture {
    frames: Vec<Frame>,
    len: usize,
    hits: usize,
}

static CAPTURE: AtomicPtr<Capture> = AtomicPtr::new(std::ptr::null_mut());
static SITE: AtomicUsize = AtomicUsize::new(0);
static BYTE: AtomicU8 = AtomicU8::new(0);

extern "C" fn capture_frame(context: *mut libc::c_void, arg: *mut libc::c_void) -> i32 {
    let capture = unsafe { &mut *arg.cast::<Capture>() };
    if capture.len == capture.frames.len() {
        return 5; // _URC_END_OF_STACK; the caller rejects a saturated capture.
    }
    // Storage is allocated before installing the handler, never in the callback.
    let frame = &mut capture.frames[capture.len];
    frame.ip = unsafe { _Unwind_GetIPInfo(context, &mut frame.before_instruction) };
    capture.len += 1;
    0 // _URC_NO_REASON
}

extern "C" fn trap(_: i32, _: *mut libc::siginfo_t, context: *mut libc::c_void) {
    unsafe {
        let context = &mut *context.cast::<libc::ucontext_t>();
        let pc = context.uc_mcontext.gregs[libc::REG_RIP as usize] as usize;
        let site = SITE.load(Ordering::Relaxed);
        let capture = CAPTURE.load(Ordering::Relaxed);
        if site == 0 || pc != site + 1 || capture.is_null() {
            libc::_exit(91);
        }
        (*capture).hits += 1;
        // INT3 reports site+1, but registers describe the state BEFORE the
        // replaced instruction. Normalize RIP before unwinding so we query CFI
        // at that boundary, particularly for one-byte POP and RET instructions.
        context.uc_mcontext.gregs[libc::REG_RIP as usize] = site as libc::greg_t;
        _Unwind_Backtrace(capture_frame, capture.cast());
        // Resume the original instruction once sigreturn restores this context.
        (site as *mut u8).write_volatile(BYTE.load(Ordering::Relaxed));
    }
}

pub fn run() -> Result<(usize, usize), Box<dyn std::error::Error>> {
    let cs = Capstone::new()
        .x86()
        .mode(arch::x86::ArchMode::Mode64)
        .syntax(arch::x86::ArchSyntax::Intel)
        .build()?;
    let mut capture = Capture {
        frames: vec![Frame::default(); 128],
        ..Capture::default()
    };
    let mut previous: libc::sigaction = unsafe { std::mem::zeroed() };
    unsafe {
        // Warm up libgcc before any signal. This is a constrained diagnostic,
        // not a guarantee of arbitrary unwinder async-signal safety.
        _Unwind_Backtrace(capture_frame, (&raw mut capture).cast());
        CAPTURE.store(&raw mut capture, Ordering::Relaxed);
        let mut action: libc::sigaction = std::mem::zeroed();
        action.sa_sigaction = trap as *const () as usize;
        action.sa_flags = libc::SA_SIGINFO;
        libc::sigemptyset(&mut action.sa_mask);
        assert_eq!(libc::sigaction(libc::SIGTRAP, &action, &mut previous), 0);
    }
    let page_size = unsafe { libc::sysconf(libc::_SC_PAGESIZE) };
    assert!(page_size > 0 && (page_size as usize).is_power_of_two());
    let page_size = page_size as usize;
    let (mut complete, mut total) = (0, 0);

    for (compiler, strategy) in [
        ("winch", Strategy::Winch),
        ("cranelift", Strategy::Cranelift),
    ] {
        let mut config = Config::new();
        config
            .strategy(strategy)
            .wasm_tail_call(false)
            .native_unwind_info(true);
        if compiler == "cranelift" {
            config.compiler_inlining(Inlining::No);
        }
        let engine = Engine::new(&config)?;
        for (label, argc) in [("register-args", 1), ("stack-args", 10)] {
            let params = "i64 ".repeat(argc);
            let args = "i64.const 1 ".repeat(argc - 1);
            let module = Module::new(
                &engine,
                format!(
                    r#"(module
                        (func $leaf (param {params}) (result i64) local.get 0)
                        (func $run (export "run") (result i64)
                            i64.const 42 {args} call $leaf i64.const 1 i64.add))"#,
                ),
            )?;
            let start = module.text().as_ptr() as usize;
            let functions = module
                .functions()
                .map(|f| (f.name.unwrap_or_default(), start + f.offset, f.len))
                .collect::<Vec<_>>();
            let leaf = functions.iter().find(|f| f.0 == "leaf").unwrap();
            assert!(functions.iter().any(|f| f.0 == "run"));
            let instructions = cs.disasm_all(
                unsafe { std::slice::from_raw_parts(leaf.1 as *const u8, leaf.2) },
                leaf.1 as u64,
            )?;
            let instructions = instructions.iter().collect::<Vec<_>>();
            let ret = instructions
                .iter()
                .position(|i| i.mnemonic() == Some("ret"))
                .expect("expected a RET in leaf");
            let pop = (0..ret)
                .rev()
                .find(|&i| {
                    instructions[i].mnemonic() == Some("pop")
                        && instructions[i].op_str() == Some("rbp")
                })
                .expect("expected a POP RBP before RET in leaf");
            let mut store = Store::new(&engine, ());
            let instance = Instance::new(&mut store, &module, &[])?;
            let run = instance.get_typed_func::<(), i64>(&mut store, "run")?;
            assert_eq!(run.call(&mut store, ())?, 43);

            let first = leaf.1 & !(page_size - 1);
            let end = (leaf.1 + leaf.2 + page_size - 1) & !(page_size - 1);
            // Only this disposable process's own JIT pages are made writable.
            assert_eq!(
                unsafe {
                    libc::mprotect(
                        first as *mut _,
                        end - first,
                        libc::PROT_READ | libc::PROT_WRITE | libc::PROT_EXEC,
                    )
                },
                0,
                "mprotect RWX failed: {}",
                std::io::Error::last_os_error()
            );
            for instruction in &instructions[pop..=ret] {
                let pc = instruction.address() as usize;
                capture.len = 0;
                capture.hits = 0;
                SITE.store(pc, Ordering::Relaxed);
                BYTE.store(unsafe { (pc as *const u8).read() }, Ordering::Relaxed);
                unsafe { (pc as *mut u8).write_volatile(0xcc) };
                assert_eq!(run.call(&mut store, ())?, 43);
                assert_eq!(capture.hits, 1);
                assert_eq!(
                    unsafe { (pc as *const u8).read() },
                    BYTE.load(Ordering::Relaxed)
                );
                assert!(capture.len < capture.frames.len(), "capture truncated");
                let frames = &capture.frames[..capture.len];
                assert!(
                    frames
                        .iter()
                        .any(|f| f.ip == pc && f.before_instruction != 0),
                    "unwinder did not observe the normalized interrupted PC"
                );
                let names = frames
                    .iter()
                    .filter_map(|frame| {
                        // Signal frames describe an interrupted instruction;
                        // ordinary frames carry return addresses after a call.
                        let pc = if frame.before_instruction != 0 {
                            frame.ip
                        } else {
                            frame.ip.checked_sub(1)?
                        };
                        functions
                            .iter()
                            .find(|(_, lo, len)| pc >= *lo && pc < *lo + *len)
                            .map(|f| f.0.as_str())
                    })
                    .collect::<Vec<_>>();
                let both = names == ["leaf", "run"];
                println!(
                    "{:<24} before {:<12} => {names:?}; complete={both}",
                    format!("{compiler}/{label}:"),
                    format!(
                        "{} {}",
                        instruction.mnemonic().unwrap_or(""),
                        instruction.op_str().unwrap_or("")
                    )
                    .trim(),
                );
                if instruction.address() == instructions[pop].address() {
                    assert!(
                        both,
                        "pre-restoration control must recover both Wasm frames"
                    );
                }
                complete += usize::from(both);
                total += 1;
            }
            assert_eq!(
                unsafe {
                    libc::mprotect(
                        first as *mut _,
                        end - first,
                        libc::PROT_READ | libc::PROT_EXEC,
                    )
                },
                0
            );
            SITE.store(0, Ordering::Relaxed);
        }
    }
    unsafe {
        assert_eq!(
            libc::sigaction(libc::SIGTRAP, &previous, std::ptr::null_mut()),
            0
        );
    }
    CAPTURE.store(std::ptr::null_mut(), Ordering::Relaxed);
    Ok((complete, total))
}
