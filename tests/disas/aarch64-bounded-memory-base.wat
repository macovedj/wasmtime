;;! target = "aarch64"
;;! test = "compile"

(module
  (memory 1)

  (func $load_from_checked_span
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    ;; A successful fill proves that this whole 8 KiB span is in bounds.
    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    ;; This proves that the scaled offset remains inside the checked span.
    local.get $index
    i32.const 2048
    i32.ge_u
    if
      unreachable
    end

    local.get $base
    local.get $index
    i32.const 2
    i32.shl
    i32.add
    i32.load)
)
;; wasm[0]::function[0]::load_from_checked_span:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x70
;;   1c: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x12, [x2, #0x40]
;;       mov     w13, w4
;;       mov     x5, #0x2000
;;       add     x13, x13, #2, lsl #12
;;       cmp     x13, x12
;;       b.hi    #0x74
;;   3c: ldr     x14, [x2, #0x38]
;;       add     x19, x14, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x100
;;   50: mov     x5, x20
;;       cmp     w5, #0x800
;;       b.hs    #0x78
;;   5c: and     w0, w5, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   70: udf     #0xc11f
;;   74: udf     #0xc11f
;;   78: udf     #0xc11f
