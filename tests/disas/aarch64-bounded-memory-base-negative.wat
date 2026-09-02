;;! target = "aarch64"
;;! test = "compile"

(module
  (memory $checked 1)
  (memory $other 1)

  ;; A checked span on only one side of a branch does not dominate the load.
  (func $non_dominating_span
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (param $check i32)
    (result i32)

    local.get $check
    if
      local.get $base
      local.get $fill
      i32.const 8192
      memory.fill $checked
    end

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
    i32.load $checked)

  ;; Although `index < 2048`, subtracting one can wrap when `index == 0`.
  (func $wrapping_subtraction
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill $checked

    local.get $index
    i32.const 2048
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
    i32.load $checked)

  ;; The second iteration decrements zero, so the induction variable wraps.
  (func $loop_crosses_zero
    (param $base i32)
    (param $fill i32)
    (result i32)
    (local $index i32)
    (local $trips i32)
    (local $sum i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill $checked

    i32.const 1
    local.set $index
    i32.const 2
    local.set $trips

    loop $again
      local.get $index
      i32.const 1
      i32.sub
      local.set $index

      local.get $sum
      local.get $base
      local.get $index
      i32.const 2
      i32.shl
      i32.add
      i32.load $checked
      i32.add
      local.set $sum

      local.get $trips
      i32.const 1
      i32.sub
      local.tee $trips
      br_if $again
    end

    local.get $sum)

  ;; The four-byte access at index 2047 extends one byte past this span.
  (func $span_too_short
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8191
    memory.fill $checked

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
    i32.load $checked)

  ;; The static offset makes the four-byte access cross the checked end.
  (func $static_offset_crosses_end
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill $checked

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
    i32.load $checked offset=1)

  ;; This range is architecturally safe, but 1999 is not a contiguous low-bit
  ;; mask, so there is no cheap speculative-safety mask for the rewritten form.
  (func $no_speculation_mask
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8000
    memory.fill $checked

    local.get $index
    i32.const 2000
    i32.ge_u
    if
      unreachable
    end

    local.get $base
    local.get $index
    i32.const 2
    i32.shl
    i32.add
    i32.load $checked)

  ;; A span checked in one linear memory says nothing about another memory.
  (func $different_memory
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill $checked

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
    i32.load $other)
)
;; wasm[0]::function[0]::non_dominating_span:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x98
;;   1c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       cbnz    w7, #0x3c
;;   2c: mov     x5, x20
;;       mov     x19, x2
;;       mov     x21, x4
;;       b       #0x70
;;   3c: ldr     x0, [x2, #0x48]
;;       mov     w1, w4
;;       mov     x5, #0x2000
;;       add     x1, x1, #2, lsl #12
;;       cmp     x1, x0
;;       b.hi    #0x9c
;;   54: ldr     x0, [x2, #0x40]
;;       mov     x19, x2
;;       add     x3, x0, w4, uxtw
;;       mov     x21, x4
;;       mov     x4, x6
;;       bl      #0x5f8
;;   6c: mov     x5, x20
;;       cmp     w5, #0x800
;;       b.hs    #0xa0
;;   78: ldr     x0, [x19, #0x40]
;;       mov     x4, x21
;;       add     w1, w4, w5, lsl #2
;;       ldr     w2, [x0, w1, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   98: udf     #0xc11f
;;   9c: udf     #0xc11f
;;   a0: udf     #0xc11f
;;
;; wasm[0]::function[1]::wrapping_subtraction:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x140
;;   dc: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x21, x5
;;       ldr     x13, [x2, #0x48]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x144
;;  100: ldr     x19, [x2, #0x40]
;;       add     x3, x19, w4, uxtw
;;       mov     x20, x4
;;       mov     x4, x6
;;       bl      #0x5f8
;;  114: mov     x5, x21
;;       cmp     w5, #0x800
;;       b.hs    #0x148
;;  120: sub     w0, w5, #1
;;       mov     x4, x20
;;       add     w0, w4, w0, lsl #2
;;       ldr     w2, [x19, w0, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  140: udf     #0xc11f
;;  144: udf     #0xc11f
;;  148: udf     #0xc11f
;;
;; wasm[0]::function[2]::loop_crosses_zero:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x1ec
;;  17c: stp     x21, x22, [sp, #-0x10]!
;;       mov     x6, x5
;;       ldr     x0, [x2, #0x48]
;;       mov     w1, w4
;;       mov     x5, #0x2000
;;       add     x1, x1, #2, lsl #12
;;       cmp     x1, x0
;;       b.hi    #0x1f0
;;  19c: ldr     x22, [x2, #0x40]
;;       add     x3, x22, w4, uxtw
;;       mov     x21, x4
;;       mov     x4, x6
;;       bl      #0x5f8
;;  1b0: mov     w13, #1
;;       mov     w2, #0
;;       mov     w0, #2
;;       sub     w13, w13, #1
;;       mov     x4, x21
;;       add     w1, w4, w13, lsl #2
;;       ldr     w1, [x22, w1, uxtw]
;;       sub     w0, w0, #1
;;       add     w2, w2, w1
;;       cbz     w0, #0x1e0
;;  1d8: mov     x21, x4
;;       b       #0x1bc
;;  1e0: ldp     x21, x22, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  1ec: udf     #0xc11f
;;  1f0: udf     #0xc11f
;;
;; wasm[0]::function[3]::span_too_short:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x278
;;  21c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x11, [x2, #0x48]
;;       mov     x5, #0x1fff
;;       add     x12, x5, w4, uxtw
;;       cmp     x12, x11
;;       b.hi    #0x27c
;;  23c: ldr     x19, [x2, #0x40]
;;       add     x3, x19, w4, uxtw
;;       mov     x21, x4
;;       mov     x4, x6
;;       bl      #0x5f8
;;  250: mov     x5, x20
;;       cmp     w5, #0x800
;;       b.hs    #0x280
;;  25c: mov     x4, x21
;;       add     w0, w4, w5, lsl #2
;;       ldr     w2, [x19, w0, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  278: udf     #0xc11f
;;  27c: udf     #0xc11f
;;  280: udf     #0xc11f
;;
;; wasm[0]::function[4]::static_offset_crosses_end:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x320
;;  2bc: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x13, [x2, #0x48]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x324
;;  2e0: ldr     x19, [x2, #0x40]
;;       add     x3, x19, w4, uxtw
;;       mov     x21, x4
;;       mov     x4, x6
;;       bl      #0x5f8
;;  2f4: mov     x5, x20
;;       cmp     w5, #0x800
;;       b.hs    #0x328
;;  300: mov     x4, x21
;;       add     w0, w4, w5, lsl #2
;;       add     x1, x19, #1
;;       ldr     w2, [x1, w0, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  320: udf     #0xc11f
;;  324: udf     #0xc11f
;;  328: udf     #0xc11f
;;
;; wasm[0]::function[5]::no_speculation_mask:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x3b8
;;  35c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x20, x5
;;       ldr     x11, [x2, #0x48]
;;       mov     x5, #0x1f40
;;       add     x12, x5, w4, uxtw
;;       cmp     x12, x11
;;       b.hi    #0x3bc
;;  37c: ldr     x19, [x2, #0x40]
;;       add     x3, x19, w4, uxtw
;;       mov     x21, x4
;;       mov     x4, x6
;;       bl      #0x5f8
;;  390: mov     x5, x20
;;       cmp     w5, #0x7d0
;;       b.hs    #0x3c0
;;  39c: mov     x4, x21
;;       add     w0, w4, w5, lsl #2
;;       ldr     w2, [x19, w0, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  3b8: udf     #0xc11f
;;  3bc: udf     #0xc11f
;;  3c0: udf     #0xc11f
;;
;; wasm[0]::function[6]::different_memory:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x464
;;  3fc: str     x26, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x19, x5
;;       ldr     x13, [x2, #0x48]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x468
;;  420: ldr     x15, [x2, #0x40]
;;       mov     x26, x2
;;       add     x3, x15, w4, uxtw
;;       mov     x20, x4
;;       mov     x4, x6
;;       bl      #0x5f8
;;  438: mov     x5, x19
;;       cmp     w5, #0x800
;;       b.hs    #0x46c
;;  444: ldr     x0, [x26, #0x50]
;;       mov     x4, x20
;;       add     w1, w4, w5, lsl #2
;;       ldr     w2, [x0, w1, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x26, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  464: udf     #0xc11f
;;  468: udf     #0xc11f
;;  46c: udf     #0xc11f
