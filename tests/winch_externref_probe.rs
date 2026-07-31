//! Local-only probe (untracked) for the Winch `externref` use-after-free.
//!
//! Found while reviewing `winch-trap-on-exception`. Removing `GC_TYPES` from
//! Winch's unsupported feature set was needed so exception tags could be
//! registered, but `GC_TYPES` was also the gate keeping `externref` away from
//! Winch. Winch emits no stack maps and no GC barriers (grep `winch/codegen`
//! for `push_user_stack_map` or `write_barrier` -- there are none), so it has
//! no way to keep a GC reference alive across a collection.
//!
//! The module below makes a Winch frame hold the *only* reference to a fresh
//! `externref` across a GC, then hands it back. Nothing else roots it.
//!
//! Run:  cargo test --test winch_externref_probe -- --nocapture
//!
//! Expected outcomes by commit:
//!
//!   499306131f (main, pre-branch)  module refused: "gc types are disallowed"
//!   580626cc1f (traps, unfixed)    PANIC "BUG: invalid ExternRefHostDataId"
//!   cafb53895d (externref guard)   module refused: "Unsupported Wasm type"
//!
//! Swap `Strategy::Winch` for `Strategy::Cranelift` to see the correct
//! behaviour: the value round-trips as 0xdeadbeef.

const WAT: &str = r#"
    (module
      (import "" "make" (func $make (result externref)))
      (import "" "gc" (func $gc))
      (func (export "hold") (result externref)
        (call $make)
        (call $gc)))
"#;

#[test]
fn winch_externref_sole_ref_across_gc() -> wasmtime::Result<()> {
    let mut config = wasmtime::Config::new();
    config.strategy(wasmtime::Strategy::Winch);
    let engine = wasmtime::Engine::new(&config)?;

    // A guard that refuses this module is the *correct* outcome for now:
    // supporting `externref` needs stack maps, which Winch does not have.
    let module = match wasmtime::Module::new(&engine, WAT) {
        Ok(m) => m,
        Err(e) => {
            println!("REFUSED (guard working): {e:#}");
            return Ok(());
        }
    };
    println!("compiled -- Winch accepted a live externref, so the guard is gone");

    let mut store = wasmtime::Store::new(&engine, ());
    let make = wasmtime::Func::wrap(
        &mut store,
        |mut cx: wasmtime::Caller<'_, ()>| -> wasmtime::Result<
            Option<wasmtime::Rooted<wasmtime::ExternRef>>,
        > { Ok(Some(wasmtime::ExternRef::new(&mut cx, 0xDEADBEEFu32)?)) },
    );
    let gc = wasmtime::Func::wrap(&mut store, |mut cx: wasmtime::Caller<'_, ()>| {
        let _ = cx.gc(None);
    });

    let instance = wasmtime::Instance::new(&mut store, &module, &[make.into(), gc.into()])?;
    let hold = instance
        .get_typed_func::<(), Option<wasmtime::Rooted<wasmtime::ExternRef>>>(&mut store, "hold")?;

    // On the unfixed traps commit this panics inside `data()` with
    // "BUG: invalid ExternRefHostDataId" -- the object was collected during
    // `$gc` because the Winch frame holding it was invisible to the collector.
    match hold.call(&mut store, ())? {
        Some(r) => {
            let got = r
                .data(&store)?
                .and_then(|d| d.downcast_ref::<u32>().copied());
            println!("returned {got:#x?} (want Some(0xdeadbeef))");
            assert_eq!(got, Some(0xDEADBEEF), "externref did not survive the GC");
        }
        None => panic!("got null back; the externref did not survive the GC"),
    }
    Ok(())
}

/// The barrier probe: a Winch frame stores the *only* reference into a
/// global, a collection runs, and the global is read back.
///
/// Under DRC this requires the write barrier: the plain store leaves the
/// object's reference count unaware of the global, so the next collection
/// frees it and `global.get` returns a dangling reference. Null and copying
/// need no barrier and exercise Winch's plain-store path.
#[test]
fn winch_global_barrier_across_gc() -> wasmtime::Result<()> {
    for collector in [
        wasmtime::Collector::Null,
        wasmtime::Collector::DeferredReferenceCounting,
        wasmtime::Collector::Copying,
    ] {
        let mut config = wasmtime::Config::new();
        config.strategy(wasmtime::Strategy::Winch);
        config.collector(collector);
        let engine = wasmtime::Engine::new(&config)?;
        let module = wasmtime::Module::new(
            &engine,
            r#"
            (module
              (import "" "make" (func $make (result externref)))
              (import "" "gc" (func $gc))
              (global $g (mut externref) (ref.null extern))
              (func (export "run") (result externref)
                (global.set $g (call $make))
                (call $gc)
                (global.get $g)))
            "#,
        )?;
        let mut store = wasmtime::Store::new(&engine, ());
        let make = wasmtime::Func::wrap(
            &mut store,
            |mut cx: wasmtime::Caller<'_, ()>| -> wasmtime::Result<
                Option<wasmtime::Rooted<wasmtime::ExternRef>>,
            > { Ok(Some(wasmtime::ExternRef::new(&mut cx, 0xDEADBEEFu32)?)) },
        );
        let gc = wasmtime::Func::wrap(&mut store, |mut cx: wasmtime::Caller<'_, ()>| {
            let _ = cx.gc(None);
        });
        let instance = wasmtime::Instance::new(&mut store, &module, &[make.into(), gc.into()])?;
        let run = instance.get_typed_func::<(), Option<wasmtime::Rooted<wasmtime::ExternRef>>>(
            &mut store, "run",
        )?;
        let out = run
            .call(&mut store, ())?
            .expect("global should not be null");
        let got = out
            .data(&store)?
            .and_then(|d| d.downcast_ref::<u32>().copied());
        println!("{collector:?}: returned {got:#x?}");
        assert_eq!(got, Some(0xDEADBEEF), "under {collector:?}");
    }
    Ok(())
}
