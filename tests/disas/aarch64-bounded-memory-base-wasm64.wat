;;! target = "aarch64"
;;! test = "compile"
;;! flags = ["-Wmemory64", "-Omemory-may-move=n"]

(module
  (memory i64 1)

  ;; The equivalence proof is specific to Wasm32's wrapping address space.
  (func $wasm64_memory
    (param $base i64)
    (param $index i64)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i64.const 8192
    memory.fill

    local.get $index
    i64.const 2048
    i64.ge_u
    if
      unreachable
    end

    local.get $base
    local.get $index
    i64.const 2
    i64.shl
    i64.add
    i32.load)
)
;; wasm[0]::function[0]::wasm64_memory:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x90
;;   1c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x15, [x2, #0x40]
;;       mov     x5, #0x2000
;;       adds    x0, x4, x5
;;       b.hs    #0x94
;;   38: cmp     x0, x15
;;       b.hi    #0x98
;;   40: ldr     x19, [x2, #0x38]
;;       add     x3, x19, x4
;;       mov     x21, x4
;;       mov     x4, x6
;;       bl      #0x124
;;   54: mov     x5, x20
;;       cmp     x5, #0x800
;;       b.hs    #0x9c
;;   60: mov     x4, x21
;;       add     x0, x4, x5, lsl #2
;;       mov     x1, #0xfffffffc
;;       mov     x2, #0
;;       add     x3, x19, x0
;;       cmp     x0, x1
;;       csel    x0, x2, x3, hi
;;       ldr     w2, [x0]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   90: udf     #0xc11f
;;   94: udf     #0xc11f
;;   98: udf     #0xc11f
;;   9c: udf     #0xc11f
