;;! target = "x86_64"
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
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x30, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xa8
;;   1c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       subq    $0x10, %rsp
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movl    $1, %edx
;;       movl    $2, %ecx
;;       movl    $3, %r8d
;;       movl    $4, %r9d
;;       movl    $5, %r11d
;;       movl    %r11d, (%rsp)
;;       subq    $0x10, %rsp
;;       movq    8(%rbp), %r11
;;       movq    %r11, (%rsp)
;;       movq    (%rbp), %r11
;;       movq    %r11, 8(%rsp)
;;       movq    0x18(%rsp), %r11
;;       movq    %r11, 8(%rbp)
;;       movq    0x10(%rsp), %r11
;;       movq    %r11, (%rbp)
;;       movq    (%rsp), %r11
;;       movq    %r11, -8(%rbp)
;;       movq    8(%rsp), %r11
;;       leaq    -8(%rbp), %rsp
;;       movq    %r11, %rbp
;;       jmp     0xb0
;;   9f: addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   a8: ud2
;;
;; wasm[0]::function[1]::one_stack:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x74, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x204
;;   cc: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movl    %edx, 0xc(%rsp)
;;       movl    %ecx, 8(%rsp)
;;       movl    %r8d, 4(%rsp)
;;       movl    %r9d, (%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    0x10(%rbp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       subq    $0x30, %rsp
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movl    0x40(%rsp), %edx
;;       movl    0x3c(%rsp), %ecx
;;       movl    0x38(%rsp), %r8d
;;       movl    0x34(%rsp), %r9d
;;       movl    0x30(%rsp), %r11d
;;       movl    %r11d, (%rsp)
;;       movl    $6, %r11d
;;       movl    %r11d, 8(%rsp)
;;       movl    $7, %r11d
;;       movl    %r11d, 0x10(%rsp)
;;       movl    $8, %r11d
;;       movl    %r11d, 0x18(%rsp)
;;       movl    $9, %r11d
;;       movl    %r11d, 0x20(%rsp)
;;       subq    $0x10, %rsp
;;       movq    8(%rbp), %r11
;;       movq    %r11, (%rsp)
;;       movq    (%rbp), %r11
;;       movq    %r11, 8(%rsp)
;;       movq    0x38(%rsp), %r11
;;       movq    %r11, 0x18(%rbp)
;;       movq    0x30(%rsp), %r11
;;       movq    %r11, 0x10(%rbp)
;;       movq    0x28(%rsp), %r11
;;       movq    %r11, 8(%rbp)
;;       movq    0x20(%rsp), %r11
;;       movq    %r11, (%rbp)
;;       movq    0x18(%rsp), %r11
;;       movq    %r11, -8(%rbp)
;;       movq    0x10(%rsp), %r11
;;       movq    %r11, -0x10(%rbp)
;;       movq    (%rsp), %r11
;;       movq    %r11, -0x18(%rbp)
;;       movq    8(%rsp), %r11
;;       leaq    -0x18(%rbp), %rsp
;;       movq    %r11, %rbp
;;       jmp     0x210
;;  1fb: addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  204: ud2
;;
;; wasm[0]::function[2]::many_stack:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x54, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x314
;;  22c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movl    %edx, 0xc(%rsp)
;;       movl    %ecx, 8(%rsp)
;;       movl    %r8d, 4(%rsp)
;;       movl    %r9d, (%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    0x10(%rbp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       subq    $0x10, %rsp
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movl    0x20(%rsp), %edx
;;       movl    0x1c(%rsp), %ecx
;;       movl    0x18(%rsp), %r8d
;;       movl    0x14(%rsp), %r9d
;;       movl    0x10(%rsp), %r11d
;;       movl    %r11d, (%rsp)
;;       subq    $0x10, %rsp
;;       movq    8(%rbp), %r11
;;       movq    %r11, (%rsp)
;;       movq    (%rbp), %r11
;;       movq    %r11, 8(%rsp)
;;       movq    0x18(%rsp), %r11
;;       movq    %r11, 0x38(%rbp)
;;       movq    0x10(%rsp), %r11
;;       movq    %r11, 0x30(%rbp)
;;       movq    (%rsp), %r11
;;       movq    %r11, 0x28(%rbp)
;;       movq    8(%rsp), %r11
;;       leaq    0x28(%rbp), %rsp
;;       movq    %r11, %rbp
;;       jmp     0xb0
;;  30b: addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  314: ud2
