//! Process ABI information that cannot be inferred from CPU features alone.

pub(super) fn is_arm64e() -> bool {
    // The main executable, rather than the architecture of this library,
    // determines whether macOS enables pointer authentication for the process.
    // Image zero is the main executable and its header remains mapped while
    // the process is running.
    // SAFETY: dyld supplies a pointer to the loaded Mach-O header. Only the
    // CPU subtype field in the common 32-/64-bit header prefix is read.
    let Some(header) = (unsafe { mach2::dyld::_dyld_get_image_header(0).as_ref() }) else {
        // Preserve signing if the process ABI cannot be determined.
        return true;
    };

    // mach/machine.h: the high byte contains capability and ABI-version bits.
    const CPU_SUBTYPE_MASK: u32 = 0xff00_0000;
    const CPU_SUBTYPE_ARM64E: u32 = 2;
    (header.cpusubtype as u32 & !CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64E
}
