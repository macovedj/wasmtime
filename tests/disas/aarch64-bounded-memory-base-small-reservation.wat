;;! target = "aarch64"
;;! test = "compile"
;;! flags = [
;;!   "-Ccranelift-enable-heap-access-spectre-mitigation",
;;!   "-Omemory-may-move=n",
;;!   "-Omemory-reservation=0x10000",
;;!   "-Omemory-guard-size=0",
;;! ]

(module
  (memory 1)

  ;; Speculation can observe a wrapped Wasm32 address unless the reservation
  ;; and guard cover the complete 32-bit address space plus the checked span.
  (func $small_spectre_reservation
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

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
;; wasm[0]::function[0]::small_spectre_reservation:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x94
;;   1c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x0, [x2, #0x40]
;;       mov     w1, w4
;;       mov     x5, #0x2000
;;       add     x1, x1, #2, lsl #12
;;       cmp     x1, x0
;;       b.hi    #0x98
;;   40: ldr     x19, [x2, #0x38]
;;       add     x3, x19, w4, uxtw
;;       mov     x21, x4
;;       mov     x4, x6
;;       bl      #0x124
;;   54: mov     x5, x20
;;       cmp     w5, #0x800
;;       b.hs    #0x9c
;;   60: mov     x4, x21
;;       add     w0, w4, w5, lsl #2
;;       mov     w1, w0
;;       mov     x2, #0xfffc
;;       mov     x3, #0
;;       add     x0, x19, w0, uxtw
;;       cmp     x1, x2
;;       csel    x0, x3, x0, hi
;;       ldr     w2, [x0]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   94: udf     #0xc11f
;;   98: udf     #0xc11f
;;   9c: udf     #0xc11f
