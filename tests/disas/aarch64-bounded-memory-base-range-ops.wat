;;! target = "aarch64"
;;! test = "compile"

(module
  (memory 1)

  ;; Shifting an arbitrary i32 right by 21 produces a value no larger than
  ;; 2047.
  (func $load_through_unsigned_shift
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    local.get $base
    local.get $index
    i32.const 21
    i32.shr_u
    i32.const 2
    i32.shl
    i32.add
    i32.load)

  ;; Both arms of the select are inside the checked span.
  (func $load_through_select
    (param $base i32)
    (param $condition i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    local.get $base
    i32.const 1024
    i32.const 2047
    local.get $condition
    select
    i32.const 2
    i32.shl
    i32.add
    i32.load)

  ;; The lower bound proves that subtraction cannot wrap, and the upper bound
  ;; keeps its result at or below 2047.
  (func $load_through_safe_subtraction
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    local.get $index
    i32.eqz
    if
      unreachable
    end
    local.get $index
    i32.const 2049
    i32.ge_u
    if
      unreachable
    end

    local.get $base
    local.get $index
    i32.const 1
    i32.sub
    i32.const 2
    i32.shl
    i32.add
    i32.load)

  ;; Since `index | 1` is never less than `index`, bounding the former also
  ;; bounds the latter.
  (func $load_through_monotonic_or_bound
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    local.get $index
    i32.const 1
    i32.or
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

  ;; Zero-extension followed by a lossless reduction preserves the range.
  (func $load_through_extend_reduce
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
    i64.extend_i32_u
    i32.wrap_i64
    i32.const 2
    i32.shl
    i32.add
    i32.load)
)
;; wasm[0]::function[0]::load_through_unsigned_shift:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x6c
;;   1c: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x13, [x2, #0x40]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x70
;;   3c: ldr     x15, [x2, #0x38]
;;       add     x19, x15, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x320
;;   50: mov     x5, x20
;;       lsr     w0, w5, #0x15
;;       and     w0, w0, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   6c: udf     #0xc11f
;;   70: udf     #0xc11f
;;
;; wasm[0]::function[1]::load_through_select:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0xf8
;;   9c: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x15, [x2, #0x40]
;;       mov     w0, w4
;;       mov     x5, #0x2000
;;       add     x0, x0, #2, lsl #12
;;       cmp     x0, x15
;;       b.hi    #0xfc
;;   bc: ldr     x0, [x2, #0x38]
;;       add     x19, x0, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x320
;;   d0: mov     w0, #0x400
;;       mov     w1, #0x7ff
;;       mov     x5, x20
;;       cmp     w5, wzr
;;       csel    x0, x0, x1, ne
;;       and     w0, w0, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   f8: udf     #0xc11f
;;   fc: udf     #0xc11f
;;
;; wasm[0]::function[2]::load_through_safe_subtraction:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x178
;;  11c: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x13, [x2, #0x40]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x17c
;;  13c: ldr     x15, [x2, #0x38]
;;       add     x19, x15, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x320
;;  150: mov     x5, x20
;;       cbz     w5, #0x180
;;  158: cmp     w5, #0x801
;;       b.hs    #0x184
;;  160: sub     w0, w5, #1
;;       and     w0, w0, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  178: udf     #0xc11f
;;  17c: udf     #0xc11f
;;  180: udf     #0xc11f
;;  184: udf     #0xc11f
;;
;; wasm[0]::function[3]::load_through_monotonic_or_bound:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x214
;;  1bc: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x13, [x2, #0x40]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x218
;;  1dc: ldr     x15, [x2, #0x38]
;;       add     x19, x15, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x320
;;  1f0: mov     x5, x20
;;       orr     w0, w5, #1
;;       cmp     w0, #0x800
;;       b.hs    #0x21c
;;  200: and     w0, w5, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  214: udf     #0xc11f
;;  218: udf     #0xc11f
;;  21c: udf     #0xc11f
;;
;; wasm[0]::function[4]::load_through_extend_reduce:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x290
;;  23c: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x12, [x2, #0x40]
;;       mov     w13, w4
;;       mov     x5, #0x2000
;;       add     x13, x13, #2, lsl #12
;;       cmp     x13, x12
;;       b.hi    #0x294
;;  25c: ldr     x14, [x2, #0x38]
;;       add     x19, x14, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x320
;;  270: mov     x5, x20
;;       cmp     w5, #0x800
;;       b.hs    #0x298
;;  27c: and     w0, w5, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  290: udf     #0xc11f
;;  294: udf     #0xc11f
;;  298: udf     #0xc11f
