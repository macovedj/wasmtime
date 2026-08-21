;;! target = "aarch64"
;;! test = "winch"

(module
  (type $callee (func (param i32 i32 i32 i32 i32) (result i32)))

  (table funcref (elem $target))

  (func $target (type $callee)
    local.get 0)

  (func (export "run") (param i32) (result i32)
    local.get 0
    i32.const 2
    i32.const 3
    i32.const 4
    i32.const 5
    i32.const 0
    return_call_indirect (type $callee))
)
;; wasm[0]::function[0]::target:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x28
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x70
;;   2c: mov     x9, x0
;;       sub     x28, x28, #0x28
;;       mov     sp, x28
;;       stur    x0, [x28, #0x20]
;;       stur    x1, [x28, #0x18]
;;       stur    w2, [x28, #0x14]
;;       stur    w3, [x28, #0x10]
;;       stur    w4, [x28, #0xc]
;;       stur    w5, [x28, #8]
;;       stur    w6, [x28, #4]
;;       ldur    w0, [x28, #0x14]
;;       add     x28, x28, #0x28
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   70: udf     #0xc11f
;;
;; wasm[0]::function[1]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x24
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x1e0
;;   ac: mov     x9, x0
;;       sub     x28, x28, #0x18
;;       mov     sp, x28
;;       stur    x0, [x28, #0x10]
;;       stur    x1, [x28, #8]
;;       stur    w2, [x28, #4]
;;       ldur    w16, [x28, #4]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       mov     x1, #0
;;       mov     x2, x9
;;       ldur    x3, [x2, #0x38]
;;       cmp     x1, x3, uxtx
;;       sub     sp, x28, #4
;;       b.hs    #0x1e4
;;   ec: mov     sp, x28
;;       mov     x16, x1
;;       mov     x17, #8
;;       mul     x16, x16, x17
;;       ldur    x2, [x2, #0x30]
;;       mov     x4, x2
;;       add     x2, x2, x16, uxtx
;;       cmp     x1, x3, uxtx
;;       csel    x2, x4, x2, hs
;;       ldur    x0, [x2]
;;       tst     x0, x0
;;       b.ne    #0x150
;;       b       #0x120
;;  120: sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w1, [x28]
;;       mov     x0, x9
;;       mov     x1, #0
;;       ldur    w2, [x28]
;;       bl      #0x4dc
;;  13c: mov     sp, x28
;;       add     x28, x28, #4
;;       mov     sp, x28
;;       ldur    x9, [x28, #0x14]
;;       b       #0x154
;;  150: and     x0, x0, #0xfffffffffffffffe
;;       sub     sp, x28, #4
;;       cbz     x0, #0x1e8
;;  15c: mov     sp, x28
;;       ldur    x16, [x9, #0x28]
;;       ldur    w1, [x16]
;;       ldur    w2, [x0, #0x10]
;;       cmp     w1, w2, uxtx
;;       sub     sp, x28, #4
;;       b.ne    #0x1ec
;;  178: mov     sp, x28
;;       sub     x28, x28, #8
;;       mov     sp, x28
;;       stur    x0, [x28]
;;       ldur    x7, [x28]
;;       add     x28, x28, #8
;;       mov     sp, x28
;;       ldur    x10, [x7, #0x18]
;;       ldur    x8, [x7, #8]
;;       mov     x0, x10
;;       mov     x1, x9
;;       ldur    w2, [x28]
;;       mov     x3, #2
;;       mov     x4, #3
;;       mov     x5, #4
;;       mov     x6, #5
;;       ldur    x28, [x29, #-0x10]
;;       mov     sp, x29
;;       ldp     x29, x30, [sp], #0x10
;;       br      x8
;;  1c8: add     x28, x28, #0x18
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  1e0: udf     #0xc11f
;;  1e4: udf     #0xc11f
;;  1e8: udf     #0xc11f
;;  1ec: udf     #0xc11f
