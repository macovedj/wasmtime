;;! target = "aarch64"
;;! test = "winch"
;;! flags = "-W tail-call"

(module
  (func $even-step (param $acc i64) (result i64)
    local.get $acc
    i64.const 3
    i64.add)

  (func $odd-step (param $acc i64) (result i64)
    local.get $acc
    i64.const 5
    i64.add)

  (func $dispatch (export "dispatch") (param $count i64) (result i64)
    (local $remaining i64)
    (local $state i32)
    (local $acc i64)
    local.get $count
    local.set $remaining
    block $done
      loop $loop
        local.get $remaining
        i64.eqz
        br_if $done
        local.get $state
        i32.eqz
        if
          local.get $acc
          call $even-step
          local.set $acc
        else
          local.get $acc
          call $odd-step
          local.set $acc
        end
        local.get $state
        i32.eqz
        local.set $state
        local.get $remaining
        i64.const 1
        i64.sub
        local.set $remaining
        br $loop
      end
    end
    local.get $acc)

  (func $tail-even (param $remaining i64) (param $acc i64) (result i64)
    local.get $remaining
    i64.eqz
    if (result i64)
      local.get $acc
    else
      local.get $remaining
      i64.const 1
      i64.sub
      local.get $acc
      i64.const 3
      i64.add
      return_call $tail-odd
    end)

  (func $tail-odd (param $remaining i64) (param $acc i64) (result i64)
    local.get $remaining
    i64.eqz
    if (result i64)
      local.get $acc
    else
      local.get $remaining
      i64.const 1
      i64.sub
      local.get $acc
      i64.const 5
      i64.add
      return_call $tail-even
    end)

  (func (export "tail") (param $count i64) (result i64)
    local.get $count
    i64.const 0
    return_call $tail-even))
;; wasm[0]::function[0]::even-step:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x18
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x64
;;   2c: mov     x9, x0
;;       sub     x28, x28, #0x18
;;       mov     sp, x28
;;       stur    x0, [x28, #0x10]
;;       stur    x1, [x28, #8]
;;       stur    x2, [x28]
;;       ldur    x0, [x28]
;;       add     x0, x0, #3
;;       add     x28, x28, #0x18
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   64: udf     #0xc11f
;;
;; wasm[0]::function[1]::odd-step:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x18
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0xe4
;;   ac: mov     x9, x0
;;       sub     x28, x28, #0x18
;;       mov     sp, x28
;;       stur    x0, [x28, #0x10]
;;       stur    x1, [x28, #8]
;;       stur    x2, [x28]
;;       ldur    x0, [x28]
;;       add     x0, x0, #5
;;       add     x28, x28, #0x18
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   e4: udf     #0xc11f
;;
;; wasm[0]::function[2]::dispatch:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x40
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x24c
;;  12c: mov     x9, x0
;;       sub     x28, x28, #0x30
;;       mov     sp, x28
;;       stur    x0, [x28, #0x28]
;;       stur    x1, [x28, #0x20]
;;       stur    x2, [x28, #0x18]
;;       mov     x16, #0
;;       stur    x16, [x28, #0x10]
;;       stur    x16, [x28, #8]
;;       stur    x16, [x28]
;;       ldur    x0, [x28, #0x18]
;;       stur    x0, [x28, #0x10]
;;       ldur    x0, [x28, #0x10]
;;       cmp     x0, #0
;;       cset    x0, eq
;;       tst     w0, w0
;;       b.ne    #0x230
;;       b       #0x174
;;  174: ldur    w0, [x28, #0xc]
;;       cmp     w0, #0
;;       cset    x0, eq
;;       tst     w0, w0
;;       b.eq    #0x1d0
;;       b       #0x18c
;;  18c: ldur    x16, [x28]
;;       sub     x28, x28, #8
;;       mov     sp, x28
;;       stur    x16, [x28]
;;       sub     x28, x28, #8
;;       mov     sp, x28
;;       mov     x0, x9
;;       mov     x1, x9
;;       ldur    x2, [x28, #8]
;;       bl      #0
;;  1b4: add     x28, x28, #8
;;       mov     sp, x28
;;       add     x28, x28, #8
;;       mov     sp, x28
;;       ldur    x9, [x28, #0x28]
;;       stur    x0, [x28]
;;       b       #0x210
;;  1d0: ldur    x16, [x28]
;;       sub     x28, x28, #8
;;       mov     sp, x28
;;       stur    x16, [x28]
;;       sub     x28, x28, #8
;;       mov     sp, x28
;;       mov     x0, x9
;;       mov     x1, x9
;;       ldur    x2, [x28, #8]
;;       bl      #0x80
;;  1f8: add     x28, x28, #8
;;       mov     sp, x28
;;       add     x28, x28, #8
;;       mov     sp, x28
;;       ldur    x9, [x28, #0x28]
;;       stur    x0, [x28]
;;       ldur    w0, [x28, #0xc]
;;       cmp     w0, #0
;;       cset    x0, eq
;;       stur    w0, [x28, #0xc]
;;       ldur    x0, [x28, #0x10]
;;       sub     x0, x0, #1
;;       stur    x0, [x28, #0x10]
;;       b       #0x15c
;;  230: ldur    x0, [x28]
;;       add     x28, x28, #0x30
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  24c: udf     #0xc11f
;;
;; wasm[0]::function[3]::tail-even:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x20
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x310
;;  28c: mov     x9, x0
;;       sub     x28, x28, #0x20
;;       mov     sp, x28
;;       stur    x0, [x28, #0x18]
;;       stur    x1, [x28, #0x10]
;;       stur    x2, [x28, #8]
;;       stur    x3, [x28]
;;       ldur    x0, [x28, #8]
;;       cmp     x0, #0
;;       cset    x0, eq
;;       tst     w0, w0
;;       b.eq    #0x2c8
;;       b       #0x2c0
;;  2c0: ldur    x0, [x28]
;;       b       #0x2f8
;;  2c8: ldur    x0, [x28, #8]
;;       sub     x0, x0, #1
;;       ldur    x1, [x28]
;;       add     x1, x1, #3
;;       mov     x2, x0
;;       mov     x3, x1
;;       mov     x0, x9
;;       mov     x1, x9
;;       ldur    x28, [x29, #-0x10]
;;       mov     sp, x29
;;       ldp     x29, x30, [sp], #0x10
;;       b       #0x320
;;  2f8: add     x28, x28, #0x20
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  310: udf     #0xc11f
;;
;; wasm[0]::function[4]::tail-odd:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x20
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x3d0
;;  34c: mov     x9, x0
;;       sub     x28, x28, #0x20
;;       mov     sp, x28
;;       stur    x0, [x28, #0x18]
;;       stur    x1, [x28, #0x10]
;;       stur    x2, [x28, #8]
;;       stur    x3, [x28]
;;       ldur    x0, [x28, #8]
;;       cmp     x0, #0
;;       cset    x0, eq
;;       tst     w0, w0
;;       b.eq    #0x388
;;       b       #0x380
;;  380: ldur    x0, [x28]
;;       b       #0x3b8
;;  388: ldur    x0, [x28, #8]
;;       sub     x0, x0, #1
;;       ldur    x1, [x28]
;;       add     x1, x1, #5
;;       mov     x2, x0
;;       mov     x3, x1
;;       mov     x0, x9
;;       mov     x1, x9
;;       ldur    x28, [x29, #-0x10]
;;       mov     sp, x29
;;       ldp     x29, x30, [sp], #0x10
;;       b       #0x260
;;  3b8: add     x28, x28, #0x20
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  3d0: udf     #0xc11f
;;
;; wasm[0]::function[5]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x20
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x46c
;;  40c: mov     x9, x0
;;       sub     x28, x28, #0x18
;;       mov     sp, x28
;;       stur    x0, [x28, #0x10]
;;       stur    x1, [x28, #8]
;;       stur    x2, [x28]
;;       ldur    x16, [x28]
;;       sub     x28, x28, #8
;;       mov     sp, x28
;;       stur    x16, [x28]
;;       mov     x0, x9
;;       mov     x1, x9
;;       ldur    x2, [x28]
;;       mov     x3, #0
;;       ldur    x28, [x29, #-0x10]
;;       mov     sp, x29
;;       ldp     x29, x30, [sp], #0x10
;;       b       #0x260
;;  454: add     x28, x28, #0x18
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  46c: udf     #0xc11f
