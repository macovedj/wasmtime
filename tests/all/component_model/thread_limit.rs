//! Tests for the per-instance limit on live `thread.new-indirect` threads
//! (`Config::max_component_instance_threads` /
//! `Store::set_max_component_instance_threads`).

#![cfg(not(miri))]

use super::config;
use crate::ErrorExt;
use wasmtime::component::{Component, ComponentNamedList, Instance, Lift, Linker, Lower};
use wasmtime::{Engine, Result, Store};

/// A component that creates threads on request. `create(n, suspend-once)`
/// calls `thread.new-indirect` `n` times and returns how many succeeded; it
/// traps on any result that is neither -1 nor a valid index, and on a
/// success that follows a refusal in the same call. Created threads are kept
/// on a stack. `resume-last` resumes the newest one with
/// `thread.yield-then-resume` and returns how many start functions have
/// returned. A thread created with `suspend-once` = 1 suspends once after it
/// starts, so it is started but unfinished until resumed again.
const CREATOR: &str = r#"
  (type $res (resource (rep i32)))
  (core module $Table (table (export "t") 1 funcref))
  (core instance $table (instantiate $Table))
  (core module $Core
    (import "" "new" (func $new (param i32 i32) (result i32)))
    (import "" "yield-to" (func $yield-to (param i32) (result i32)))
    (import "" "suspend" (func $suspend (result i32)))
    (import "" "resource.new" (func $resource.new (param i32) (result i32)))
    (import "" "return" (func $return (param i32)))
    (import "" "return-s32" (func $return-s32 (param i32)))
    (import "" "t" (table $t 1 funcref))
    (memory 1)
    (global $parked (mut i32) (i32.const 0))
    (global $started (mut i32) (i32.const 0))
    (global $returned (mut i32) (i32.const 0))
    (global $last (mut i32) (i32.const 0))

    (func $start (param $suspend-once i32)
      (global.set $started (i32.add (global.get $started) (i32.const 1)))
      (if (local.get $suspend-once) (then (drop (call $suspend))))
      (global.set $returned (i32.add (global.get $returned) (i32.const 1))))
    (elem (table $t) (i32.const 0) func $start)

    (func (export "create") (param $n i32) (param $suspend-once i32)
      (local $r i32) (local $ok i32) (local $refused i32)
      (block $done
        (loop $next
          (br_if $done (i32.eqz (local.get $n)))
          (local.set $r (call $new (i32.const 0) (local.get $suspend-once)))
          (global.set $last (local.get $r))
          (if (i32.eq (local.get $r) (i32.const -1))
            (then (local.set $refused (i32.const 1)))
            (else
              (if (i32.or (local.get $refused) (i32.lt_s (local.get $r) (i32.const 0)))
                (then unreachable))
              (i32.store (i32.shl (global.get $parked) (i32.const 2)) (local.get $r))
              (global.set $parked (i32.add (global.get $parked) (i32.const 1)))
              (local.set $ok (i32.add (local.get $ok) (i32.const 1)))))
          (local.set $n (i32.sub (local.get $n) (i32.const 1)))
          (br $next)))
      (call $return (local.get $ok)))

    (func (export "resume-last")
      (local $before i32)
      (if (i32.eqz (global.get $parked)) (then unreachable))
      (local.set $before (global.get $returned))
      (drop (call $yield-to
        (i32.load (i32.shl (i32.sub (global.get $parked) (i32.const 1)) (i32.const 2)))))
      (if (i32.ne (global.get $returned) (local.get $before))
        (then (global.set $parked (i32.sub (global.get $parked) (i32.const 1)))))
      (call $return (global.get $returned)))

    (func (export "started") (call $return (global.get $started)))

    (func (export "last-result") (call $return-s32 (global.get $last)))

    (func (export "make-resources") (param $n i32)
      (local $i i32)
      (block $done
        (loop $next
          (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
          (drop (call $resource.new (local.get $i)))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $next)))
      (call $return (local.get $n)))
  )
  (core type $start-ty (func (param i32)))
  (alias core export $table "t" (core table $t))
  (core func $new (canon thread.new-indirect $start-ty (core table $t)))
  (core func $yield-to (canon thread.yield-then-resume))
  (core func $suspend (canon thread.suspend))
  (core func $resource.new (canon resource.new $res))
  (core func $return (canon task.return (result u32)))
  (core func $return-s32 (canon task.return (result s32)))
  (core instance $core (instantiate $Core (with "" (instance
    (export "new" (func $new))
    (export "yield-to" (func $yield-to))
    (export "suspend" (func $suspend))
    (export "resource.new" (func $resource.new))
    (export "return" (func $return))
    (export "return-s32" (func $return-s32))
    (export "t" (table $t))))))
  (func (export "create") async (param "n" u32) (param "suspend-once" u32) (result u32)
    (canon lift (core func $core "create") async))
  (func (export "resume-last") async (result u32)
    (canon lift (core func $core "resume-last") async))
  (func (export "started") async (result u32)
    (canon lift (core func $core "started") async))
  (func (export "last-result") async (result s32)
    (canon lift (core func $core "last-result") async))
  (func (export "make-resources") async (param "n" u32) (result u32)
    (canon lift (core func $core "make-resources") async))
"#;

fn engine() -> Result<Engine> {
    let mut config = config();
    config.wasm_component_model_async(true);
    config.wasm_component_model_async_stackful(true);
    config.wasm_component_model_threading(true);
    Ok(Engine::new(&config)?)
}

/// An engine with the async, stackful and threading component features and an
/// engine-wide thread limit that its stores start with.
fn engine_with_limit(limit: Option<usize>) -> Result<Engine> {
    let mut config = config();
    config.wasm_component_model_async(true);
    config.wasm_component_model_async_stackful(true);
    config.wasm_component_model_threading(true);
    config.max_component_instance_threads(limit);
    Ok(Engine::new(&config)?)
}

fn creator(engine: &Engine) -> Result<Component> {
    Ok(Component::new(engine, format!("(component {CREATOR})"))?)
}

/// Two instances of the creator nested in one top-level component, exported
/// as `a-create` and `b-create`.
fn nested_pair(engine: &Engine) -> Result<Component> {
    let text = format!(
        r#"(component
  (component $C {CREATOR})
  (instance $a (instantiate $C))
  (instance $b (instantiate $C))
  (func (export "a-create") (alias export $a "create"))
  (func (export "b-create") (alias export $b "create")))"#
    );
    Ok(Component::new(engine, text)?)
}

fn new_store(engine: &Engine, limit: Option<usize>) -> Store<()> {
    let mut store = Store::new(engine, ());
    store.set_max_component_instance_threads(limit);
    store
}

async fn instantiate(store: &mut Store<()>, component: &Component) -> Result<Instance> {
    Ok(Linker::<()>::new(store.engine())
        .instantiate_async(&mut *store, component)
        .await?)
}

async fn call<P, R>(store: &mut Store<()>, instance: &Instance, name: &str, params: P) -> Result<R>
where
    P: ComponentNamedList + Lower,
    R: ComponentNamedList + Lift + 'static,
{
    let func = instance.get_typed_func::<P, R>(&mut *store, name)?;
    Ok(func.call_async(&mut *store, params).await?)
}

async fn create(
    store: &mut Store<()>,
    instance: &Instance,
    n: u32,
    suspend_once: bool,
) -> Result<u32> {
    let (ok,) =
        call::<(u32, u32), (u32,)>(store, instance, "create", (n, suspend_once.into())).await?;
    Ok(ok)
}

async fn resume_last(store: &mut Store<()>, instance: &Instance) -> Result<u32> {
    let (returned,) = call::<(), (u32,)>(store, instance, "resume-last", ()).await?;
    Ok(returned)
}

async fn started(store: &mut Store<()>, instance: &Instance) -> Result<u32> {
    let (started,) = call::<(), (u32,)>(store, instance, "started", ()).await?;
    Ok(started)
}

async fn last_result(store: &mut Store<()>, instance: &Instance) -> Result<i32> {
    let (last,) = call::<(), (i32,)>(store, instance, "last-result", ()).await?;
    Ok(last)
}

/// Entries in the store's concurrency table, which holds every thread and
/// task record.
fn concurrency_records(store: &mut Store<()>) -> usize {
    store
        .concurrent_resource_table()
        .expect("the async engine supports concurrency")
        .iter_mut()
        .count()
}

#[test]
fn a_new_store_has_no_per_instance_thread_limit() -> Result<()> {
    let engine = engine()?;
    let mut store = Store::new(&engine, ());
    assert_eq!(store.max_component_instance_threads(), None);
    store.set_max_component_instance_threads(Some(7));
    assert_eq!(store.max_component_instance_threads(), Some(7));
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn a_store_starts_at_its_engines_limit_unless_it_sets_one() -> Result<()> {
    let engine = engine_with_limit(Some(3))?;
    let component = creator(&engine)?;

    let mut store = Store::new(&engine, ());
    assert_eq!(store.max_component_instance_threads(), Some(3));
    let instance = instantiate(&mut store, &component).await?;
    assert_eq!(create(&mut store, &instance, 4, false).await?, 3);

    let mut store = Store::new(&engine, ());
    store.set_max_component_instance_threads(Some(5));
    let instance = instantiate(&mut store, &component).await?;
    assert_eq!(create(&mut store, &instance, 6, false).await?, 5);

    let mut store = Store::new(&engine, ());
    store.set_max_component_instance_threads(None);
    let instance = instantiate(&mut store, &component).await?;
    assert_eq!(create(&mut store, &instance, 8, false).await?, 8);

    let unlimited = engine_with_limit(None)?;
    assert_eq!(
        Store::new(&unlimited, ()).max_component_instance_threads(),
        None
    );
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn the_creation_past_the_limit_answers_minus_one_until_a_thread_returns() -> Result<()> {
    let engine = engine()?;
    let component = creator(&engine)?;
    let mut store = new_store(&engine, Some(4));
    let instance = instantiate(&mut store, &component).await?;

    assert_eq!(create(&mut store, &instance, 4, false).await?, 4);
    // All four are parked at birth: none has run, and each still counts.
    assert_eq!(started(&mut store, &instance).await?, 0);
    assert_eq!(create(&mut store, &instance, 1, false).await?, 0);
    assert_eq!(last_result(&mut store, &instance).await?, -1);

    // One thread runs to its return, which frees exactly one slot.
    assert_eq!(resume_last(&mut store, &instance).await?, 1);
    assert_eq!(create(&mut store, &instance, 1, false).await?, 1);
    assert_eq!(create(&mut store, &instance, 1, false).await?, 0);
    assert_eq!(last_result(&mut store, &instance).await?, -1);
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn a_started_thread_holds_its_slot_until_its_start_function_returns() -> Result<()> {
    let engine = engine()?;
    let component = creator(&engine)?;
    let mut store = new_store(&engine, Some(2));
    let instance = instantiate(&mut store, &component).await?;

    assert_eq!(create(&mut store, &instance, 2, true).await?, 2);
    // The newest thread starts and suspends without returning.
    assert_eq!(resume_last(&mut store, &instance).await?, 0);
    assert_eq!(started(&mut store, &instance).await?, 1);
    assert_eq!(create(&mut store, &instance, 1, true).await?, 0);

    // Resumed again, it returns, and its slot is free.
    assert_eq!(resume_last(&mut store, &instance).await?, 1);
    assert_eq!(create(&mut store, &instance, 1, false).await?, 1);
    assert_eq!(create(&mut store, &instance, 1, false).await?, 0);
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn a_flood_of_never_resumed_threads_gets_exactly_the_limit() -> Result<()> {
    const LIMIT: u32 = 1024;
    let engine = engine()?;
    let component = creator(&engine)?;
    let mut store = new_store(&engine, Some(LIMIT.try_into()?));
    let instance = instantiate(&mut store, &component).await?;

    assert_eq!(
        create(&mut store, &instance, 4 * LIMIT, false).await?,
        LIMIT
    );
    assert_eq!(last_result(&mut store, &instance).await?, -1);
    assert_eq!(create(&mut store, &instance, 4 * LIMIT, false).await?, 0);
    assert_eq!(started(&mut store, &instance).await?, 0);

    // Other handles are still available, and the instance keeps working.
    let (made,) = call::<(u32,), (u32,)>(&mut store, &instance, "make-resources", (16,)).await?;
    assert_eq!(made, 16);
    assert_eq!(resume_last(&mut store, &instance).await?, 1);
    assert_eq!(create(&mut store, &instance, 2, false).await?, 1);
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn a_refused_creation_takes_no_handle_and_leaves_no_thread_record() -> Result<()> {
    const LIMIT: u32 = 8;
    let engine = engine()?;
    let component = creator(&engine)?;

    // The smallest store handle limit at which `create(LIMIT)` succeeds with
    // no thread limit: those threads plus whatever one call holds.
    let mut tight = None;
    for handles in 0..usize::try_from(LIMIT)? + 64 {
        let mut store = new_store(&engine, None);
        store.set_max_component_handles(handles);
        let Ok(instance) = instantiate(&mut store, &component).await else {
            continue;
        };
        if create(&mut store, &instance, LIMIT, false).await.is_ok() {
            tight = Some(handles);
            break;
        }
    }
    let tight = tight.expect("some handle limit admits the threads");

    // At that handle limit, one more thread with no thread limit traps.
    let mut store = new_store(&engine, None);
    store.set_max_component_handles(tight);
    let instance = instantiate(&mut store, &component).await?;
    create(&mut store, &instance, LIMIT + 1, false)
        .await
        .unwrap_err()
        .assert_contains("handle limit");

    // With the thread limit, the same calls refuse with -1 instead of
    // trapping, so no refusal took a handle.
    let mut store = new_store(&engine, Some(LIMIT.try_into()?));
    store.set_max_component_handles(tight);
    let instance = instantiate(&mut store, &component).await?;
    assert_eq!(
        create(&mut store, &instance, 4 * LIMIT, false).await?,
        LIMIT
    );
    assert_eq!(last_result(&mut store, &instance).await?, -1);

    // A refused call leaves the same records behind whether it is refused
    // once or a thousand times.
    let before = concurrency_records(&mut store);
    assert_eq!(create(&mut store, &instance, 1, false).await?, 0);
    let once = concurrency_records(&mut store);
    assert_eq!(create(&mut store, &instance, 1000, false).await?, 0);
    let many = concurrency_records(&mut store);
    assert_eq!(
        (once.abs_diff(before), once <= before),
        (many.abs_diff(once), many <= once),
        "refusals left thread records behind ({before}, then {once}, then {many})"
    );
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn nested_instances_share_their_top_level_limit_and_top_level_instances_do_not() -> Result<()>
{
    let engine = engine()?;
    let mut store = new_store(&engine, Some(3));

    let pair = nested_pair(&engine)?;
    let nested = instantiate(&mut store, &pair).await?;
    let (a,) = call::<(u32, u32), (u32,)>(&mut store, &nested, "a-create", (2, 0)).await?;
    let (b,) = call::<(u32, u32), (u32,)>(&mut store, &nested, "b-create", (2, 0)).await?;
    assert_eq!((a, b), (2, 1));

    let component = creator(&engine)?;
    let first = instantiate(&mut store, &component).await?;
    let second = instantiate(&mut store, &component).await?;
    assert_eq!(create(&mut store, &first, 4, false).await?, 3);
    assert_eq!(create(&mut store, &second, 4, false).await?, 3);
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn without_a_limit_creation_is_unchanged() -> Result<()> {
    let engine = engine()?;
    let component = creator(&engine)?;
    let mut store = new_store(&engine, None);
    let instance = instantiate(&mut store, &component).await?;
    assert_eq!(create(&mut store, &instance, 2048, false).await?, 2048);
    assert!(last_result(&mut store, &instance).await? >= 0);
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn a_limit_of_zero_refuses_the_first_creation() -> Result<()> {
    let engine = engine()?;
    let component = creator(&engine)?;
    let mut store = new_store(&engine, Some(0));
    let instance = instantiate(&mut store, &component).await?;
    assert_eq!(create(&mut store, &instance, 1, false).await?, 0);
    assert_eq!(last_result(&mut store, &instance).await?, -1);
    Ok(())
}

#[tokio::test(flavor = "current_thread")]
async fn lowering_the_limit_below_the_count_refuses_until_enough_threads_return() -> Result<()> {
    let engine = engine()?;
    let component = creator(&engine)?;
    let mut store = new_store(&engine, Some(8));
    let instance = instantiate(&mut store, &component).await?;
    assert_eq!(create(&mut store, &instance, 4, false).await?, 4);

    store.set_max_component_instance_threads(Some(2));
    assert_eq!(create(&mut store, &instance, 1, false).await?, 0);
    assert_eq!(resume_last(&mut store, &instance).await?, 1);
    assert_eq!(resume_last(&mut store, &instance).await?, 2);
    assert_eq!(create(&mut store, &instance, 1, false).await?, 0);
    assert_eq!(resume_last(&mut store, &instance).await?, 3);
    assert_eq!(create(&mut store, &instance, 1, false).await?, 1);
    Ok(())
}
