;;! target = "aarch64"
;;! test = "compile"
;;! flags = ["-Omemory-may-move=y", "-Omemory-reservation=0"]

(module
  (memory 1)

  ;; A runtime call may move this memory, invalidating a saved native pointer.
  (func $movable_memory
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
;; wasm[0]::function[0]::movable_memory:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x9c
;;   1c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x0, [x2, #0x40]
;;       mov     w1, w4
;;       mov     x5, #0x2000
;;       add     x1, x1, #2, lsl #12
;;       cmp     x1, x0
;;       b.hi    #0xa0
;;   40: ldr     x0, [x2, #0x38]
;;       mov     x19, x2
;;       add     x3, x0, w4, uxtw
;;       mov     x21, x4
;;       mov     x4, x6
;;       bl      #0x12c
;;   58: mov     x5, x20
;;       cmp     w5, #0x800
;;       b.hs    #0xa4
;;   64: ldr     x0, [x19, #0x40]
;;       ldr     x1, [x19, #0x38]
;;       mov     x4, x21
;;       add     w2, w4, w5, lsl #2
;;       mov     w3, w2
;;       mov     x4, #0
;;       add     x1, x1, w2, uxtw
;;       cmp     x3, x0
;;       csel    x0, x4, x1, hi
;;       ldr     w2, [x0]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   9c: udf     #0xc11f
;;   a0: udf     #0xc11f
;;   a4: udf     #0xc11f
