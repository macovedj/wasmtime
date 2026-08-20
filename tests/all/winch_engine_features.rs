use wasmtime::*;
use wasmtime_test_macros::wasmtime_test;

#[wasmtime_test(strategies(only(Winch)))]
#[cfg_attr(miri, ignore)]
fn tail_calls_preserve_caller_clean_stack(config: &mut Config) -> Result<()> {
    if !cfg!(target_arch = "x86_64") {
        return Ok(());
    }

    config.wasm_tail_call(true);
    let engine = Engine::new(&config)?;
    let module = Module::new(
        &engine,
        r#"
            (module
              (func $small (param i32 i32 i32 i32 i32) (result i32)
                local.get 0
                i32.eqz
                if (result i32)
                  local.get 1
                else
                  local.get 0
                  i32.const 1
                  i32.sub
                  local.get 1
                  local.get 2
                  local.get 3
                  local.get 4
                  i32.const 5
                  i32.const 6
                  i32.const 7
                  i32.const 8
                  return_call $large
                end)

              (func $large (param i32 i32 i32 i32 i32 i32 i32 i32 i32) (result i32)
                local.get 0
                i32.eqz
                if (result i32)
                  local.get 1
                else
                  local.get 0
                  i32.const 1
                  i32.sub
                  local.get 1
                  local.get 2
                  local.get 3
                  local.get 4
                  return_call $small
                end)

              (func (export "run") (param i32) (result i32)
                local.get 0
                i32.const 42
                i32.const 2
                i32.const 3
                i32.const 4
                call $small))
        "#,
    )?;
    let mut store = Store::new(&engine, ());
    let instance = Instance::new(&mut store, &module, &[])?;
    let run = instance.get_typed_func::<i32, i32>(&mut store, "run")?;

    assert_eq!(run.call(&mut store, 100_000)?, 42);
    Ok(())
}

#[wasmtime_test(strategies(only(Winch)))]
#[cfg_attr(miri, ignore)]
fn tail_call_to_imported_wasm_function(config: &mut Config) -> Result<()> {
    if !cfg!(target_arch = "x86_64") {
        return Ok(());
    }

    config.wasm_tail_call(true);
    let engine = Engine::new(&config)?;
    let callee_module = Module::new(
        &engine,
        r#"
            (module
              (func (export "callee") (param i32 i32 i32 i32 i32) (result i32)
                local.get 0))
        "#,
    )?;
    let caller_module = Module::new(
        &engine,
        r#"
            (module
              (import "m" "callee" (func $callee (param i32 i32 i32 i32 i32) (result i32)))
              (func (export "run") (param i32) (result i32)
                local.get 0
                i32.const 2
                i32.const 3
                i32.const 4
                i32.const 5
                return_call $callee))
        "#,
    )?;
    let mut store = Store::new(&engine, ());
    let callee_instance = Instance::new(&mut store, &callee_module, &[])?;
    let callee = callee_instance
        .get_func(&mut store, "callee")
        .expect("callee export");
    let caller_instance = Instance::new(&mut store, &caller_module, &[callee.into()])?;
    let run = caller_instance.get_typed_func::<i32, i32>(&mut store, "run")?;

    assert_eq!(run.call(&mut store, 42)?, 42);

    let host_callee = Func::wrap(&mut store, |first: i32, _: i32, _: i32, _: i32, _: i32| {
        first
    });
    let host_caller_instance = Instance::new(&mut store, &caller_module, &[host_callee.into()])?;
    let host_run = host_caller_instance.get_typed_func::<i32, i32>(&mut store, "run")?;
    assert_eq!(host_run.call(&mut store, 84)?, 84);
    Ok(())
}

#[wasmtime_test(strategies(only(Winch)))]
#[cfg_attr(miri, ignore)]
fn tail_call_indirect_preserves_caller_clean_stack(config: &mut Config) -> Result<()> {
    if !cfg!(target_arch = "x86_64") {
        return Ok(());
    }

    config.wasm_tail_call(true);
    let engine = Engine::new(&config)?;
    let module = Module::new(
        &engine,
        r#"
            (module
              (type $small-ty (func (param i32 i32 i32 i32 i32) (result i32)))
              (type $large-ty
                (func (param i32 i32 i32 i32 i32 i32 i32 i32 i32) (result i32)))

              (table funcref (elem $small $large))

              (func $small (type $small-ty)
                local.get 0
                i32.eqz
                if (result i32)
                  local.get 1
                else
                  local.get 0
                  i32.const 1
                  i32.sub
                  local.get 1
                  local.get 2
                  local.get 3
                  local.get 4
                  i32.const 5
                  i32.const 6
                  i32.const 7
                  i32.const 8
                  i32.const 1
                  return_call_indirect (type $large-ty)
                end)

              (func $large (type $large-ty)
                local.get 0
                i32.eqz
                if (result i32)
                  local.get 1
                else
                  local.get 0
                  i32.const 1
                  i32.sub
                  local.get 1
                  local.get 2
                  local.get 3
                  local.get 4
                  i32.const 0
                  return_call_indirect (type $small-ty)
                end)

              (func (export "run") (param i32) (result i32)
                local.get 0
                i32.const 42
                i32.const 2
                i32.const 3
                i32.const 4
                call $small))
        "#,
    )?;
    let mut store = Store::new(&engine, ());
    let instance = Instance::new(&mut store, &module, &[])?;
    let run = instance.get_typed_func::<i32, i32>(&mut store, "run")?;

    assert_eq!(run.call(&mut store, 100_000)?, 42);
    Ok(())
}

#[wasmtime_test(strategies(only(Winch)))]
#[cfg_attr(miri, ignore)]
fn tail_call_indirect_traps(config: &mut Config) -> Result<()> {
    if !cfg!(target_arch = "x86_64") {
        return Ok(());
    }

    config.wasm_tail_call(true);
    let engine = Engine::new(&config)?;
    let module = Module::new(
        &engine,
        r#"
            (module
              (type $expected (func (result i32)))
              (type $wrong (func (result i64)))

              (func $good (type $expected) i32.const 7)
              (func $bad (type $wrong) i64.const 8)

              (table 3 funcref)
              (elem (i32.const 0) $good $bad)

              (func (export "run") (param i32) (result i32)
                local.get 0
                return_call_indirect (type $expected)))
        "#,
    )?;
    let mut store = Store::new(&engine, ());
    let instance = Instance::new(&mut store, &module, &[])?;
    let run = instance.get_typed_func::<i32, i32>(&mut store, "run")?;

    assert_eq!(run.call(&mut store, 0)?, 7);
    assert_eq!(
        run.call(&mut store, 1).unwrap_err().downcast::<Trap>()?,
        Trap::BadSignature
    );
    assert_eq!(
        run.call(&mut store, 2).unwrap_err().downcast::<Trap>()?,
        Trap::IndirectCallToNull
    );
    Ok(())
}

#[wasmtime_test(strategies(only(Winch)))]
#[cfg_attr(miri, ignore)]
fn tail_calls_forward_stack_results(config: &mut Config) -> Result<()> {
    if !cfg!(target_arch = "x86_64") {
        return Ok(());
    }

    config.wasm_tail_call(true);
    let engine = Engine::new(&config)?;
    let module = Module::new(
        &engine,
        r#"
            (module
              (type $small-ty
                (func (param i32 i32 i64 i32 i64) (result i32 i64 i32 i64)))
              (type $large-ty
                (func
                  (param i32 i32 i64 i32 i64 i32 i32 i32 i32)
                  (result i32 i64 i32 i64)))

              (table funcref (elem $small $large))

              (func $small (type $small-ty)
                local.get 0
                i32.eqz
                if (result i32 i64 i32 i64)
                  local.get 1
                  local.get 2
                  local.get 3
                  local.get 4
                else
                  local.get 0
                  i32.const 1
                  i32.sub
                  local.get 1
                  local.get 2
                  local.get 3
                  local.get 4
                  i32.const 5
                  i32.const 6
                  i32.const 7
                  i32.const 8
                  i32.const 1
                  return_call_indirect (type $large-ty)
                end)

              (func $large (type $large-ty)
                local.get 0
                i32.eqz
                if (result i32 i64 i32 i64)
                  local.get 1
                  local.get 2
                  local.get 3
                  local.get 4
                else
                  local.get 0
                  i32.const 1
                  i32.sub
                  local.get 1
                  local.get 2
                  local.get 3
                  local.get 4
                  return_call $small
                end)

              (func (export "run") (param i32) (result i32 i64 i32 i64)
                local.get 0
                i32.const 42
                i64.const 43
                i32.const 44
                i64.const 45
                return_call $small))
        "#,
    )?;
    let mut store = Store::new(&engine, ());
    let instance = Instance::new(&mut store, &module, &[])?;
    let run = instance.get_typed_func::<i32, (i32, i64, i32, i64)>(&mut store, "run")?;

    assert_eq!(run.call(&mut store, 100_000)?, (42, 43, 44, 45));
    Ok(())
}

#[wasmtime_test(strategies(only(Winch)))]
#[cfg_attr(miri, ignore)]
fn ensure_compatibility_between_winch_and_table_lazy_init(config: &mut Config) -> Result<()> {
    config.table_lazy_init(false);
    let result = Engine::new(&config);
    match result {
        Ok(_) => {
            wasmtime::bail!(
                "Expected incompatibility between the `table_lazy_init` option and Winch"
            )
        }
        Err(e) => {
            assert_eq!(
                e.to_string(),
                "Winch requires the table-lazy-init option to be enabled"
            );
        }
    }

    Ok(())
}

#[wasmtime_test(strategies(only(Winch)))]
#[cfg_attr(miri, ignore)]
fn ensure_compatibility_between_winch_and_signals_based_traps(config: &mut Config) -> Result<()> {
    config.signals_based_traps(false);
    let result = Engine::new(&config);
    match result {
        Ok(_) => {
            wasmtime::bail!(
                "Expected incompatibility between the `signals_based_traps` option and Winch"
            )
        }
        Err(e) => {
            assert_eq!(
                e.to_string(),
                "Winch requires the signals-based-traps option to be enabled"
            );
        }
    }

    Ok(())
}

#[wasmtime_test(strategies(only(Winch)))]
#[cfg_attr(miri, ignore)]
fn ensure_compatibility_between_winch_and_debug_native(config: &mut Config) -> Result<()> {
    config.debug_info(true);
    let result = Engine::new(&config);
    match result {
        Ok(_) => {
            wasmtime::bail!("Expected incompatibility between the `debug_native` option and Winch")
        }
        Err(e) => {
            assert_eq!(
                e.to_string(),
                "Winch does not currently support generating native debug information"
            );
        }
    }

    Ok(())
}
