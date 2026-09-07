;;! target = "aarch64"
;;! test = "compile"

(module
  (memory 1)

  ;; Although the branch proves `index <= 2046`, general addition is outside
  ;; this pass's structural range analysis. Retain the original address form.
  (func $load_through_add
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    local.get $index
    i32.const 2047
    i32.ge_u
    if
      unreachable
    end

    local.get $base
    local.get $index
    i32.const 1
    i32.add
    i32.const 2
    i32.shl
    i32.add
    i32.load)

  ;; The loop begins with `i = 2048`, decrements before loading, and takes the
  ;; backedge only while the decremented value is nonzero. Proving the load
  ;; safe requires combining the initial value and decreasing recurrence.
  (func $load_through_decreasing_loop
    (param $base i32)
    (param $fill i32)
    (result i32)
    (local $i i32)
    (local $sum i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    i32.const 2048
    local.set $i

    loop $again
      local.get $i
      i32.const 1
      i32.sub
      local.set $i

      local.get $sum
      local.get $base
      local.get $i
      i32.const 2
      i32.shl
      i32.add
      i32.load
      i32.add
      local.set $sum

      local.get $i
      br_if $again
    end

    local.get $sum)
)
;; wasm[0]::function[0]::load_through_add:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0x80
;;   1c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x21, x5
;;       ldr     x13, [x2, #0x40]
;;       mov     w14, w4
;;       mov     x5, #0x2000
;;       add     x14, x14, #2, lsl #12
;;       cmp     x14, x13
;;       b.hi    #0x84
;;   40: ldr     x19, [x2, #0x38]
;;       add     x3, x19, w4, uxtw
;;       mov     x20, x4
;;       mov     x4, x6
;;       bl      #0x220
;;   54: mov     x5, x21
;;       cmp     w5, #0x7ff
;;       b.hs    #0x88
;;   60: add     w0, w5, #1
;;       mov     x4, x20
;;       add     w0, w4, w0, lsl #2
;;       ldr     w2, [x19, w0, uxtw]
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   80: udf     #0xc11f
;;   84: udf     #0xc11f
;;   88: udf     #0xc11f
;;
;; wasm[0]::function[1]::load_through_decreasing_loop:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x20
;;       cmp     sp, x16
;;       b.lo    #0x118
;;   bc: str     x19, [sp, #-0x10]!
;;       mov     x3, x5
;;       ldr     x0, [x2, #0x40]
;;       mov     w1, w4
;;       mov     x5, #0x2000
;;       add     x1, x1, #2, lsl #12
;;       cmp     x1, x0
;;       b.hi    #0x11c
;;   dc: ldr     x0, [x2, #0x38]
;;       add     x19, x0, w4, uxtw
;;       mov     x4, x3
;;       mov     x3, x19
;;       bl      #0x220
;;   f0: mov     w13, #0x800
;;       mov     w2, #0
;;       sub     w13, w13, #1
;;       and     w0, w13, #0x7ff
;;       ldr     w0, [x19, w0, uxtw #2]
;;       add     w2, w2, w0
;;       cbnz    w13, #0xf8
;;  10c: ldr     x19, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  118: udf     #0xc11f
;;  11c: udf     #0xc11f
