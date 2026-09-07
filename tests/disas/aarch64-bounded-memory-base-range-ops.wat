;;! target = "aarch64"
;;! test = "compile"

(module
  (memory 1)

  ;; Shifting an arbitrary i32 right by 21 produces a value no larger than
  ;; 2047, but structural shift propagation is deliberately out of scope.
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

  ;; Both arms fit, but structural select propagation is out of scope. Retain
  ;; the original address form rather than inferring a range from the arms.
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
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x78
;;   1c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x21, x5
;;       ldr     x13, [x2, #0x40]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x7c
;;   40: ldr     x19, [x2, #0x38]
;;       add     x3, x19, w4, uxtw
;;       mov     x20, x4
;;       mov     x4, x6
;;       bl      #0x340
;;   54: mov     x5, x21
;;       lsr     w0, w5, #0x15
;;       mov     x4, x20
;;       add     w0, w4, w0, lsl #2
;;       ldr     w2, [x19, w0, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   78: udf     #0xc11f
;;   7c: udf     #0xc11f
;;
;; wasm[0]::function[1]::load_through_select:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x104
;;   9c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x21, x5
;;       ldr     x15, [x2, #0x40]
;;       mov     w0, w4
;;       mov     x5, #0x2000
;;       add     x0, x0, #2, lsl #12
;;       cmp     x0, x15
;;       b.hi    #0x108
;;   c0: ldr     x19, [x2, #0x38]
;;       add     x3, x19, w4, uxtw
;;       mov     x20, x4
;;       mov     x4, x6
;;       bl      #0x340
;;   d4: mov     w0, #0x400
;;       mov     w1, #0x7ff
;;       mov     x5, x21
;;       cmp     w5, wzr
;;       csel    x0, x0, x1, ne
;;       mov     x4, x20
;;       add     w0, w4, w0, lsl #2
;;       ldr     w2, [x19, w0, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  104: udf     #0xc11f
;;  108: udf     #0xc11f
;;
;; wasm[0]::function[2]::load_through_safe_subtraction:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x198
;;  13c: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x13, [x2, #0x40]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x19c
;;  15c: ldr     x15, [x2, #0x38]
;;       add     x19, x15, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x340
;;  170: mov     x5, x20
;;       cbz     w5, #0x1a0
;;  178: cmp     w5, #0x801
;;       b.hs    #0x1a4
;;  180: sub     w0, w5, #1
;;       and     w0, w0, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  198: udf     #0xc11f
;;  19c: udf     #0xc11f
;;  1a0: udf     #0xc11f
;;  1a4: udf     #0xc11f
;;
;; wasm[0]::function[3]::load_through_monotonic_or_bound:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x234
;;  1dc: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x13, [x2, #0x40]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x238
;;  1fc: ldr     x15, [x2, #0x38]
;;       add     x19, x15, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x340
;;  210: mov     x5, x20
;;       orr     w0, w5, #1
;;       cmp     w0, #0x800
;;       b.hs    #0x23c
;;  220: and     w0, w5, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  234: udf     #0xc11f
;;  238: udf     #0xc11f
;;  23c: udf     #0xc11f
;;
;; wasm[0]::function[4]::load_through_extend_reduce:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x2b0
;;  25c: stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x12, [x2, #0x40]
;;       mov     w13, w4
;;       mov     x5, #0x2000
;;       add     x13, x13, #2, lsl #12
;;       cmp     x13, x12
;;       b.hi    #0x2b4
;;  27c: ldr     x14, [x2, #0x38]
;;       add     x19, x14, w4, uxtw
;;       mov     x4, x6
;;       mov     x3, x19
;;       bl      #0x340
;;  290: mov     x5, x20
;;       cmp     w5, #0x800
;;       b.hs    #0x2b8
;;  29c: and     w0, w5, #0x7ff
;;       ldr     w2, [x19, w0, uxtw #2]
;;       ldp     x19, x20, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  2b0: udf     #0xc11f
;;  2b4: udf     #0xc11f
;;  2b8: udf     #0xc11f
