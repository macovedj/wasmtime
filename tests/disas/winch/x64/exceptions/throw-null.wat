;;! target = "x86_64"
;;! test = "winch"
;;! flags = "-W exceptions -C collector=null"

;; Exercise the Null collector's inline exception allocation path.
(module
  (tag $e (param i32))
  (func
    (throw $e (i32.const 42))))
;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x14a
;;   1c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movq    %r14, %rdi
;;       callq   0x23e
;;       movq    8(%rsp), %r14
;;       movq    0x20(%r14), %rcx
;;       movl    (%rcx), %edx
;;       addl    $7, %edx
;;       jb      0x14c
;;   4e: andl    $0xfffffff8, %edx
;;       movl    %edx, %ebx
;;       addl    $0x18, %ebx
;;       jb      0x14e
;;   62: subq    $4, %rsp
;;       movl    %eax, (%rsp)
;;       subq    $4, %rsp
;;       movl    %edx, (%rsp)
;;       subq    $4, %rsp
;;       movl    %ebx, (%rsp)
;;       movl    (%rsp), %eax
;;       addq    $4, %rsp
;;       movq    8(%r14), %rcx
;;       movq    0x28(%rcx), %rdx
;;       movq    0x20(%rcx), %rcx
;;       cmpq    %rdx, %rax
;;       jbe     0xbb
;;   9f: subq    %rdx, %rax
;;       pushq   %rax
;;       movq    %r14, %rdi
;;       movq    (%rsp), %rsi
;;       callq   0x1f7
;;       addq    $8, %rsp
;;       movq    0x10(%rsp), %r14
;;       movl    (%rsp), %eax
;;       addq    $4, %rsp
;;       movq    8(%r14), %rcx
;;       movq    0x28(%rcx), %rdx
;;       movq    0x20(%rcx), %rcx
;;       movq    %rcx, %rdx
;;       addq    %rax, %rdx
;;       movl    $0x4000018, (%rdx)
;;       movq    0x28(%r14), %rcx
;;       movl    8(%rcx), %ecx
;;       movl    %ecx, 4(%rdx)
;;       movq    0x20(%r14), %rcx
;;       movl    %eax, %ebx
;;       addl    $0x18, %ebx
;;       movl    %ebx, (%rcx)
;;       movl    (%rsp), %ecx
;;       addq    $4, %rsp
;;       movl    %ecx, 8(%rdx)
;;       movl    $0, %ecx
;;       movl    %ecx, 0xc(%rdx)
;;       movl    $0x2a, 0x10(%rdx)
;;       subq    $4, %rsp
;;       movl    %eax, (%rsp)
;;       subq    $0xc, %rsp
;;       movq    %r14, %rdi
;;       movl    0xc(%rsp), %esi
;;       callq   0x26b
;;       addq    $0xc, %rsp
;;       addq    $4, %rsp
;;       movq    8(%rsp), %r14
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;  14a: ud2
;;  14c: ud2
;;  14e: ud2
