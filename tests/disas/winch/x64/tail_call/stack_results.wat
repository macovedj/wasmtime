;;! target = "x86_64"
;;! test = "winch"

(module
  (func $callee (result i32 i64 i32 i64)
    i32.const 1
    i64.const 2
    i32.const 3
    i64.const 4)

  (func (export "run") (result i32 i64 i32 i64)
    return_call $callee)
)
;; wasm[0]::function[0]::callee:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rsi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x30, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x8a
;;   1c: movq    %rsi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rsi, 0x18(%rsp)
;;       movq    %rdx, 0x10(%rsp)
;;       movq    %rdi, 8(%rsp)
;;       movl    $4, %eax
;;       subq    $0x10, %rsp
;;       movl    $3, (%rsp)
;;       movq    $2, 4(%rsp)
;;       movl    $1, 0xc(%rsp)
;;       movq    0x18(%rsp), %rcx
;;       movl    (%rsp), %r11d
;;       addq    $4, %rsp
;;       movl    %r11d, (%rcx)
;;       popq    %r11
;;       movq    %r11, 4(%rcx)
;;       movl    (%rsp), %r11d
;;       addq    $4, %rsp
;;       movl    %r11d, 0xc(%rcx)
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;   8a: ud2
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rsi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x30, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x10a
;;   ac: movq    %rsi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rsi, 0x18(%rsp)
;;       movq    %rdx, 0x10(%rsp)
;;       movq    %rdi, 8(%rsp)
;;       movq    %r14, %rsi
;;       movq    %r14, %rdx
;;       movq    8(%rsp), %rdi
;;       subq    $0x10, %rsp
;;       movq    8(%rbp), %r11
;;       movq    %r11, (%rsp)
;;       movq    (%rbp), %r11
;;       movq    %r11, 8(%rsp)
;;       movq    (%rsp), %r11
;;       movq    %r11, 8(%rbp)
;;       movq    8(%rsp), %r11
;;       leaq    8(%rbp), %rsp
;;       movq    %r11, %rbp
;;       jmp     0
;;  101: addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  10a: ud2
