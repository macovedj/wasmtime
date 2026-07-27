;;! target = "aarch64"
;;! test = "winch"
;;! flags = ["-W", "exceptions"]

;; A `throw` allocates the exception object with the `gc_alloc_exn`
;; builtin and passes it to `throw_ref`. A `try_table` still compiles
;; as a plain block.
(module
  (tag $e (param i32))
  (func (result i32)
    (block $h (result i32)
      (try_table (result i32) (catch $e $h)
        (throw $e (i32.const 42))))))
;; wasm[0]::function[0]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       str     x28, [sp, #-0x10]!
;;       mov     x28, sp
;;       ldur    x16, [x0, #8]
;;       ldur    x16, [x16, #0x18]
;;       mov     x17, #0
;;       movk    x17, #0x30
;;       add     x16, x16, x17
;;       cmp     sp, x16
;;       b.lo    #0xf0
;;   2c: mov     x9, x0
;;       sub     x28, x28, #0x10
;;       mov     sp, x28
;;       stur    x0, [x28, #8]
;;       stur    x1, [x28]
;;       sub     x28, x28, #0x10
;;       mov     sp, x28
;;       mov     x0, #0x2a
;;       stur    w0, [x28]
;;       add     x0, x28, #0
;;       mov     x1, #0
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w1, [x28]
;;       sub     x28, x28, #8
;;       mov     sp, x28
;;       stur    x0, [x28]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       mov     x0, x9
;;       ldur    w1, [x28, #0xc]
;;       ldur    x2, [x28, #4]
;;       bl      #0x230
;;   88: add     x28, x28, #4
;;       mov     sp, x28
;;       add     x28, x28, #0xc
;;       mov     sp, x28
;;       ldur    x9, [x28, #0x18]
;;       sub     x28, x28, #4
;;       mov     sp, x28
;;       stur    w0, [x28]
;;       sub     x28, x28, #0xc
;;       mov     sp, x28
;;       mov     x0, x9
;;       ldur    w1, [x28, #0xc]
;;       bl      #0x1dc
;;   bc: add     x28, x28, #0xc
;;       mov     sp, x28
;;       add     x28, x28, #4
;;       mov     sp, x28
;;       ldur    x9, [x28, #0x18]
;;       add     x28, x28, #0x10
;;       mov     sp, x28
;;       add     x28, x28, #0x10
;;       mov     sp, x28
;;       mov     sp, x28
;;       ldr     x28, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   f0: udf     #0xc11f
