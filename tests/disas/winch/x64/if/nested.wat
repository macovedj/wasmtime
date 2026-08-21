;;! target = "x86_64"
;;! test = "winch"
(module
  (func $dummy)
  (func (export "nested") (param i32 i32) (result i32)
    (if (result i32) (local.get 0)
      (then
        (if (local.get 1) (then (call $dummy) (nop)))
        (if (local.get 1) (then) (else (call $dummy) (nop)))
        (if (result i32) (local.get 1)
          (then (call $dummy) (i32.const 9))
          (else (call $dummy) (i32.const 10))
        )
      )
      (else
        (if (local.get 1) (then (call $dummy) (nop)))
        (if (local.get 1) (then) (else (call $dummy) (nop)))
        (if (result i32) (local.get 1)
          (then (call $dummy) (i32.const 10))
          (else (call $dummy) (i32.const 11))
        )
      )
    )
  )
)
;; wasm[0]::function[0]::dummy:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x10, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x38
;;   1c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   38: ud2
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x1a2
;;   5c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movl    %edx, 0xc(%rsp)
;;       movl    %ecx, 8(%rsp)
;;       movl    0xc(%rsp), %eax
;;       testl   %eax, %eax
;;       je      0x111
;;   84: movl    8(%rsp), %eax
;;       testl   %eax, %eax
;;       je      0xa4
;;   90: movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       callq   0
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    8(%rsp), %eax
;;       testl   %eax, %eax
;;       je      0xb5
;;       jmp     0xc9
;;   b5: movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       callq   0
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    8(%rsp), %eax
;;       testl   %eax, %eax
;;       je      0xf3
;;   d5: movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       callq   0
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    $9, %eax
;;       jmp     0x199
;;   f3: movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       callq   0
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    $0xa, %eax
;;       jmp     0x199
;;  111: movl    8(%rsp), %eax
;;       testl   %eax, %eax
;;       je      0x131
;;  11d: movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       callq   0
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    8(%rsp), %eax
;;       testl   %eax, %eax
;;       je      0x142
;;       jmp     0x156
;;  142: movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       callq   0
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    8(%rsp), %eax
;;       testl   %eax, %eax
;;       je      0x180
;;  162: movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       callq   0
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    $0xa, %eax
;;       jmp     0x199
;;  180: movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       callq   0
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    $0xb, %eax
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  1a2: ud2
