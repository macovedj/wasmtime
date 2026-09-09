//! Compile the actual C helpers with a controlled runtime symbol lookup. These
//! fixtures use ordinary linker settings: the optional APIs need not be exported
//! by either the fixture or the SDK.
#![cfg(all(target_os = "macos", not(miri)))]

use std::path::Path;
use std::process::Command;

fn compiler() -> cc::Tool {
    let target = format!("{}-apple-darwin", std::env::consts::ARCH);
    cc::Build::new()
        .cargo_metadata(false)
        .host(&target)
        .target(&target)
        .opt_level(0)
        .get_compiler()
}

fn run(command: &mut Command) {
    let output = command.output().unwrap();
    assert!(
        output.status.success(),
        "{command:?} failed: {:?}\n{}\n{}",
        output.status,
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr),
    );
}

fn check_availability(provider: &str, available: u8) {
    let dir = tempfile::tempdir().unwrap();
    let binary = dir.path().join("native-unwind-helpers");
    let source =
        Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/native_unwind_helpers/availability.c");
    run(compiler()
        .to_command()
        .args([
            "-std=c11",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-DCFG_TARGET_OS_macos",
        ])
        .arg(format!("-DPROVIDER={provider}"))
        .arg(format!("-DAVAILABLE={available}"))
        .arg(source)
        .arg("-o")
        .arg(&binary));
    run(&mut Command::new(binary));
}

#[test]
fn neither_section_api() {
    check_availability("MATCHING", 0);
}

#[test]
fn only_add_section_api() {
    check_availability("MATCHING", 1);
}

#[test]
fn only_remove_section_api() {
    check_availability("MATCHING", 2);
}

#[test]
fn both_section_apis() {
    check_availability("MATCHING", 3);
}

#[test]
fn unavailable_unwinder() {
    check_availability("UNAVAILABLE", 3);
}

#[test]
fn unknown_unwinder() {
    check_availability("UNKNOWN", 3);
}

#[test]
fn mismatched_registration_provider() {
    check_availability("WRONG_REGISTER", 3);
}

#[test]
fn mismatched_deregistration_provider() {
    check_availability("WRONG_DEREGISTER", 3);
}

#[test]
fn linked_unwinder() {
    let source = Path::new(env!("CARGO_MANIFEST_DIR"));
    let fixtures = source.join("tests/native_unwind_helpers");
    // Exercise real dyld lookup with a linked provider whose dependencies also
    // include the system unwinder. Missing APIs must not come from that registry.
    for available in 0..=3 {
        let dir = tempfile::tempdir().unwrap();
        let provider = dir.path().join("libtest-unwind.dylib");
        let binary = dir.path().join("native-unwind-linked");
        run(compiler()
            .to_command()
            .args(["-std=c11", "-Wall", "-Wextra", "-Werror", "-dynamiclib"])
            .arg(format!("-DAVAILABLE={available}"))
            .arg(fixtures.join("provider.c"))
            .arg("-o")
            .arg(&provider));
        run(compiler()
            .to_command()
            .args([
                "-std=c11",
                "-Wall",
                "-Wextra",
                "-Werror",
                "-DCFG_TARGET_OS_macos",
                "-DVERSIONED_SUFFIX=_test",
            ])
            .arg(format!("-DAVAILABLE={available}"))
            .arg(fixtures.join("linked.c"))
            .arg(source.join("src/runtime/vm/helpers.c"))
            .arg(&provider)
            .arg("-o")
            .arg(&binary));
        run(&mut Command::new(binary));
    }
}
