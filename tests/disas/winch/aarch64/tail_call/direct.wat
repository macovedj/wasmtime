;;! target = "aarch64"
;;! test = "winch"

(module
  ;; Grow the incoming argument area from zero bytes to one aligned slot.
  (func $from_no_stack (result i32)
    (return_call $one_stack
      (i32.const 1)
      (i32.const 2)
      (i32.const 3)
      (i32.const 4)
      (i32.const 5)))

  ;; Grow from one aligned stack-argument slot to three.
  (func $one_stack (param i32 i32 i32 i32 i32) (result i32)
    (return_call $many_stack
      (local.get 0)
      (local.get 1)
      (local.get 2)
      (local.get 3)
      (local.get 4)
      (i32.const 6)
      (i32.const 7)
      (i32.const 8)
      (i32.const 9)))

  ;; Shrink back to one aligned stack-argument slot.
  (func $many_stack (param i32 i32 i32 i32 i32 i32 i32 i32 i32) (result i32)
    (return_call $one_stack
      (local.get 0)
      (local.get 1)
      (local.get 2)
      (local.get 3)
      (local.get 4)))
)
;; wasm[0]::function[0]::from_no_stack:
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
;;       b.lo    #0xa0
;;   2c: mov     x9, x0
;;       sub     x28, x28, #0x10
;;       mov     sp, x28
;;       stur    x0, [x28, #8]
;;       stur    x1, [x28]
;;       mov     x0, x9
;;       mov     x1, x9
;;       mov     x2, #1
;;       mov     x3, #2
;;       mov     x4, #3
;;       mov     x5, #4
;;       mov     x6, #5
;;       sub     x28, x28, #0x10
;;       mov     sp, x28
;;       ldur    x16, [x29, #-0x10]
;;       ldur    x30, [x29, #8]
;;       ldur    x17, [x29]
;;       stur    x17, [x28]
;;       add     x17, x29, #0x10
;;       ldur    x29, [x28]
;;       mov     sp, x17
;;       mov     x28, x16
;;       b       #0xc0
;;   88: add     x28, x28, #0x10
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   a0: udf     #0xc11f
;;
;; wasm[0]::function[1]::one_stack:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x6c
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x208
;;   ec: mov     x9, x0
;;       sub     x28, x28, #0x28
;;       mov     sp, x28
;;       stur    x0, [x28, #0x20]
;;       stur    x1, [x28, #0x18]
;;       stur    w2, [x28, #0x14]
;;       stur    w3, [x28, #0x10]
;;       stur    w4, [x28, #0xc]
;;       stur    w5, [x28, #8]
;;       stur    w6, [x28, #4]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       sub     x28, x28, #0x20
;;       mov     sp, x28
;;       mov     x0, x9
;;       mov     x1, x9
;;       ldur    w2, [x28, #0x30]
;;       ldur    w3, [x28, #0x2c]
;;       ldur    w4, [x28, #0x28]
;;       ldur    w5, [x28, #0x24]
;;       ldur    w6, [x28, #0x20]
;;       mov     x7, #6
;;       mov     x16, #7
;;       stur    w16, [x28]
;;       mov     x16, #8
;;       stur    w16, [x28, #8]
;;       mov     x16, #9
;;       stur    w16, [x28, #0x10]
;;       sub     x28, x28, #0x10
;;       mov     sp, x28
;;       ldur    x16, [x29, #-0x10]
;;       ldur    x30, [x29, #8]
;;       ldur    x17, [x29]
;;       stur    x17, [x28]
;;       ldur    x17, [x28, #0x28]
;;       stur    x17, [x29, #8]
;;       ldur    x17, [x28, #0x20]
;;       stur    x17, [x29]
;;       ldur    x17, [x28, #0x18]
;;       stur    x17, [x29, #-8]
;;       ldur    x17, [x28, #0x10]
;;       stur    x17, [x29, #-0x10]
;;       sub     x17, x29, #0x10
;;       ldur    x29, [x28]
;;       mov     sp, x17
;;       mov     x28, x16
;;       b       #0x220
;;  1f0: add     x28, x28, #0x28
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  208: udf     #0xc11f
;;
;; wasm[0]::function[2]::many_stack:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x4c
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0x328
;;  24c: mov     x9, x0
;;       sub     x28, x28, #0x28
;;       mov     sp, x28
;;       stur    x0, [x28, #0x20]
;;       stur    x1, [x28, #0x18]
;;       stur    w2, [x28, #0x14]
;;       stur    w3, [x28, #0x10]
;;       stur    w4, [x28, #0xc]
;;       stur    w5, [x28, #8]
;;       stur    w6, [x28, #4]
;;       stur    w7, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       ldur    w16, [x28, #0x14]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w16, [x28]
;;       mov     x0, x9
;;       mov     x1, x9
;;       ldur    w2, [x28, #0x10]
;;       ldur    w3, [x28, #0xc]
;;       ldur    w4, [x28, #8]
;;       ldur    w5, [x28, #4]
;;       ldur    w6, [x28]
;;       sub     x28, x28, #0x10
;;       mov     sp, x28
;;       ldur    x16, [x29, #-0x10]
;;       ldur    x30, [x29, #8]
;;       ldur    x17, [x29]
;;       stur    x17, [x28]
;;       add     x17, x29, #0x30
;;       ldur    x29, [x28]
;;       mov     sp, x17
;;       mov     x28, x16
;;       b       #0xc0
;;  310: add     x28, x28, #0x28
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  328: udf     #0xc11f
