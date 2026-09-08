//! Compile the actual C helpers with a controlled runtime symbol lookup. These
//! fixtures use ordinary linker settings: the optional APIs need not be exported
//! by either the fixture or the SDK.
#![cfg(all(target_os = "macos", not(miri)))]

use std::path::Path;
use std::process::Command;

fn check_availability(provider_available: bool, available: u8) {
    let dir = tempfile::tempdir().unwrap();
    let target = format!("{}-apple-darwin", std::env::consts::ARCH);
    let compiler = cc::Build::new()
        .cargo_metadata(false)
        .host(&target)
        .target(&target)
        .opt_level(0)
        .get_compiler();
    let binary = dir.path().join("native-unwind-helpers");
    let source =
        Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/native_unwind_helpers/availability.c");
    let output = compiler
        .to_command()
        .args([
            "-std=c11",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-DCFG_TARGET_OS_macos",
        ])
        .arg(format!(
            "-DPROVIDER_AVAILABLE={}",
            u8::from(provider_available)
        ))
        .arg(format!("-DAVAILABLE={available}"))
        .arg(source)
        .arg("-o")
        .arg(&binary)
        .output()
        .unwrap();
    assert!(
        output.status.success(),
        "failed to compile availability={available}:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    let output = Command::new(binary).output().unwrap();
    assert!(
        output.status.success(),
        "availability={available} failed: {:?}\n{}",
        output.status,
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn neither_section_api() {
    check_availability(true, 0);
}

#[test]
fn only_add_section_api() {
    check_availability(true, 1);
}

#[test]
fn only_remove_section_api() {
    check_availability(true, 2);
}

#[test]
fn both_section_apis() {
    check_availability(true, 3);
}

#[test]
fn unavailable_unwinder() {
    check_availability(false, 3);
}
