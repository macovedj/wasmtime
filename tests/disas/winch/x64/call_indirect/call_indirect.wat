;;! target="x86_64"
;;! test = "winch"

(module
  (type $over-i32 (func (param i32) (result i32)))

  (table funcref
    (elem
      $fib-i32
    )
  )

  (func $fib-i32 (export "fib-i32") (type $over-i32)
    (if (result i32) (i32.le_u (local.get 0) (i32.const 1))
      (then (i32.const 1))
      (else
        (i32.add
          (call_indirect (type $over-i32)
            (i32.sub (local.get 0) (i32.const 2))
            (i32.const 0)
          )
          (call_indirect (type $over-i32)
            (i32.sub (local.get 0) (i32.const 1))
            (i32.const 0)
          )
        )
      )
    )
  )
)


;; wasm[0]::function[0]::fib-i32:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x30, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x21f
;;   1c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movl    %edx, 0xc(%rsp)
;;       movl    0xc(%rsp), %eax
;;       cmpl    $1, %eax
;;       movl    $0, %eax
;;       setbe   %al
;;       testl   %eax, %eax
;;       je      0x55
;;   4b: movl    $1, %eax
;;       jmp     0x216
;;   55: movl    0xc(%rsp), %eax
;;       subl    $2, %eax
;;       subq    $4, %rsp
;;       movl    %eax, (%rsp)
;;       movl    $0, %ecx
;;       movq    %r14, %rdx
;;       movq    0x38(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0x221
;;   7d: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0x30(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0xdb
;;   a4: subq    $4, %rsp
;;       movl    %ecx, (%rsp)
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movl    8(%rsp), %edx
;;       callq   0x343
;;       leaq    -0x28(%rbp), %rsp
;;       addq    $4, %rsp
;;       movq    0x1c(%rsp), %r14
;;       jmp     0xe1
;;   db: andq    $0xfffffffffffffffe, %rax
;;       testq   %rax, %rax
;;       je      0x223
;;   ea: movq    0x28(%r14), %r11
;;       movl    (%r11), %ecx
;;       movl    0x10(%rax), %edx
;;       cmpl    %edx, %ecx
;;       jne     0x225
;;   fc: pushq   %rax
;;       popq    %rcx
;;       movq    0x18(%rcx), %r8
;;       movq    8(%rcx), %rbx
;;       subq    $0xc, %rsp
;;       movq    %r8, %rdi
;;       movq    %r14, %rsi
;;       movl    0xc(%rsp), %edx
;;       callq   *%rbx
;;       leaq    -0x24(%rbp), %rsp
;;       addq    $4, %rsp
;;       movq    0x18(%rsp), %r14
;;       movl    0xc(%rsp), %ecx
;;       subl    $1, %ecx
;;       subq    $4, %rsp
;;       movl    %eax, (%rsp)
;;       subq    $4, %rsp
;;       movl    %ecx, (%rsp)
;;       movl    $0, %ecx
;;       movq    %r14, %rdx
;;       movq    0x38(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0x227
;;  15c: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0x30(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0x1ba
;;  183: subq    $4, %rsp
;;       movl    %ecx, (%rsp)
;;       subq    $4, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movl    4(%rsp), %edx
;;       callq   0x343
;;       leaq    -0x2c(%rbp), %rsp
;;       addq    $4, %rsp
;;       movq    0x20(%rsp), %r14
;;       jmp     0x1c0
;;  1ba: andq    $0xfffffffffffffffe, %rax
;;       testq   %rax, %rax
;;       je      0x229
;;  1c9: movq    0x28(%r14), %r11
;;       movl    (%r11), %ecx
;;       movl    0x10(%rax), %edx
;;       cmpl    %edx, %ecx
;;       jne     0x22b
;;  1db: pushq   %rax
;;       popq    %rcx
;;       movq    0x18(%rcx), %r8
;;       movq    8(%rcx), %rbx
;;       subq    $8, %rsp
;;       movq    %r8, %rdi
;;       movq    %r14, %rsi
;;       movl    8(%rsp), %edx
;;       callq   *%rbx
;;       leaq    -0x28(%rbp), %rsp
;;       addq    $4, %rsp
;;       movq    0x1c(%rsp), %r14
;;       movl    (%rsp), %ecx
;;       addq    $4, %rsp
;;       addl    %eax, %ecx
;;       movl    %ecx, %eax
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  21f: ud2
;;  221: ud2
;;  223: ud2
;;  225: ud2
;;  227: ud2
;;  229: ud2
;;  22b: ud2
