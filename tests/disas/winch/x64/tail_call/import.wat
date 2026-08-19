;;! target = "x86_64"
;;! test = "winch"

(module
  (import "m" "callee" (func $callee (param i32 i32 i32 i32 i32) (result i32)))

  (func (export "run") (param i32) (result i32)
    (return_call $callee
      (local.get 0)
      (i32.const 2)
      (i32.const 3)
      (i32.const 4)
      (i32.const 5)))
)
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x44, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xc1
;;   1c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movl    %edx, 0xc(%rsp)
;;       movq    0x48(%r14), %r10
;;       movq    0x38(%r14), %rbx
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       subq    $0x10, %rsp
;;       movq    %r10, %rdi
;;       movq    %r14, %rsi
;;       movl    0x10(%rsp), %edx
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
;;       jmpq    *%rbx
;;   b8: addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;   c1: ud2
