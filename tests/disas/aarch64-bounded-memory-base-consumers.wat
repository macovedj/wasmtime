;;! target = "aarch64"
;;! test = "compile"
;;! flags = "-Wthreads"

(module
  (memory 1 1 shared)

  (func $store_to_checked_span
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (param $value i32)

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
    local.get $value
    i32.store)

  (func $atomic_load_from_checked_span
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
    i32.atomic.load)
)
;; wasm[0]::function[0]::store_to_checked_span:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x88
;;   1c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x7
;;       mov     x21, x5
;;       ldr     x14, [x2, #0x30]
;;       add     x15, x14, #8
;;       ldar    x15, [x15]
;;       mov     w0, w4
;;       mov     x5, #0x2000
;;       add     x0, x0, #2, lsl #12
;;       cmp     x0, x15
;;       b.hi    #0x8c
;;   4c: ldr     x0, [x14]
;;       add     x19, x0, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x254
;;   60: mov     x5, x21
;;       cmp     w5, #0x800
;;       b.hs    #0x90
;;   6c: and     w0, w5, #0x7ff
;;       mov     x7, x20
;;       str     w7, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   88: udf     #0xc11f
;;   8c: udf     #0xc11f
;;   90: udf     #0xc11f
;;
;; wasm[0]::function[1]::atomic_load_from_checked_span:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x13c
;;   bc: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x19, x5
;;       ldr     x0, [x2, #0x30]
;;       add     x1, x0, #8
;;       ldar    x1, [x1]
;;       mov     w3, w4
;;       mov     x5, #0x2000
;;       add     x3, x3, #2, lsl #12
;;       cmp     x3, x1
;;       b.hi    #0x140
;;   e8: ldr     x0, [x0]
;;       add     x20, x0, w4, uxtw
;;       mov     x21, x4
;;       mov     x4, x6
;;       mov     x3, x20
;;       bl      #0x254
;;  100: mov     x5, x19
;;       cmp     w5, #0x800
;;       b.hs    #0x144
;;  10c: mov     x4, x21
;;       add     w0, w4, w5, lsl #2
;;       and     w0, w0, #3
;;       cbnz    w0, #0x148
;;  11c: and     w0, w5, #0x7ff
;;       mov     w0, w0
;;       add     x0, x20, x0, lsl #2
;;       ldar    w2, [x0]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  13c: udf     #0xc11f
;;  140: udf     #0xc11f
;;  144: udf     #0xc11f
;;  148: udf     #0xc11f
