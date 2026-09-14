//! Runtime return-address signing on macOS.

pub(super) fn return_address_signing_enabled() -> bool {
    let sample = 0_u8;
    let original = &sample as *const u8 as usize;

    // A valid signature can leave the pointer unchanged. Try multiple
    // discriminators before conservatively leaving signing disabled.
    for discriminator in 0_usize..16 {
        let mut signed = original;
        // SAFETY: PACIB1716 signs x17 using the B key and x16 as its modifier.
        // It does not access memory or modify the stack or condition flags.
        // Its HINT encoding is a no-op when pointer authentication is absent.
        // The result is compared as an integer and never dereferenced.
        unsafe {
            core::arch::asm!(
                "pacib1716",
                inout("x17") signed,
                in("x16") discriminator,
                options(nomem, nostack, preserves_flags),
            );
        }
        if signed != original {
            return true;
        }
    }

    false
}
