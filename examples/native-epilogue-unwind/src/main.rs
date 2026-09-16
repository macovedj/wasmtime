//! Reproduce missing x86-64 epilogue unwind metadata using native libgcc.

#[cfg(all(target_os = "linux", target_arch = "x86_64", target_env = "gnu"))]
mod probe;

#[cfg(all(target_os = "linux", target_arch = "x86_64", target_env = "gnu"))]
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = std::env::args().skip(1).collect::<Vec<_>>();
    let check = match args.as_slice() {
        [] => false,
        [arg] if arg == "--check" => true,
        _ => return Err("usage: native-epilogue-unwind-repro [--check]".into()),
    };
    let (complete, total) = probe::run()?;
    println!("\nRecovered both Wasm frames at {complete}/{total} instruction boundaries.");
    println!("All Wasm calls returned 43; each probe received exactly one SIGTRAP.");
    if check && complete != total {
        eprintln!("Missing Wasm caller frames: epilogue unwind gap reproduced.");
        std::process::exit(1);
    }
    Ok(())
}

#[cfg(not(all(target_os = "linux", target_arch = "x86_64", target_env = "gnu")))]
fn main() {
    eprintln!("This diagnostic requires native x86-64 GNU/Linux and libgcc_s.");
    std::process::exit(2);
}
