;;! target = "x86_64"
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
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x4e
;;   1c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movl    %edx, 0xc(%rsp)
;;       movl    %ecx, 8(%rsp)
;;       movl    %r8d, 4(%rsp)
;;       movl    %r9d, (%rsp)
;;       movl    0xc(%rsp), %eax
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;   4e: ud2
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x44, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x1a8
;;   6c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movl    %edx, 0xc(%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    $0, %ecx
;;       movq    %r14, %rdx
;;       movq    0x38(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0x1aa
;;   a9: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0x30(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0x107
;;   d0: subq    $4, %rsp
;;       movl    %ecx, (%rsp)
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movl    8(%rsp), %edx
;;       callq   0x409
;;       leaq    -0x28(%rbp), %rsp
;;       addq    $4, %rsp
;;       movq    0x1c(%rsp), %r14
;;       jmp     0x10d
;;  107: andq    $0xfffffffffffffffe, %rax
;;       testq   %rax, %rax
;;       je      0x1ac
;;  116: movq    0x28(%r14), %r11
;;       movl    (%r11), %ecx
;;       movl    0x10(%rax), %edx
;;       cmpl    %edx, %ecx
;;       jne     0x1ae
;;  128: pushq   %rax
;;       popq    %rbx
;;       movq    0x18(%rbx), %r12
;;       movq    8(%rbx), %r10
;;       subq    $0x10, %rsp
;;       movq    %r12, %rdi
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
;;       jmpq    *%r10
;;  19f: addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  1a8: ud2
;;  1aa: ud2
;;  1ac: ud2
;;  1ae: ud2
