;;! target = "x86_64"
;;! test = "winch"
;;! flags = ["-W", "exceptions"]

;; A `throw` allocates the exception object with the `gc_alloc_raw`
;; builtin, initializes its fields inline, and passes it to `throw_ref`.
;; A `try_table` still compiles as a plain block.
(module
  (tag $e (param i32))
  (func (result i32)
    (block $h (result i32)
      (try_table (result i32) (catch $e $h)
        (throw $e (i32.const 42))))))
;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xee
;;   1c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movq    %r14, %rdi
;;       callq   0x1f3
;;       movq    8(%rsp), %r14
;;       movq    0x28(%r14), %rcx
;;       movl    8(%rcx), %ecx
;;       subq    $4, %rsp
;;       movl    %eax, (%rsp)
;;       subq    $4, %rsp
;;       movl    %ecx, (%rsp)
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0x4000002, %esi
;;       movl    8(%rsp), %edx
;;       movl    $0x20, %ecx
;;       movl    $0x10, %r8d
;;       callq   0x1a4
;;       addq    $8, %rsp
;;       addq    $4, %rsp
;;       movq    0xc(%rsp), %r14
;;       movq    8(%r14), %rcx
;;       movq    0x20(%rcx), %rcx
;;       addq    %rax, %rcx
;;       movl    (%rsp), %edx
;;       addq    $4, %rsp
;;       movl    %edx, 0x10(%rcx)
;;       movl    $0, %edx
;;       movl    %edx, 0x14(%rcx)
;;       movl    $0x2a, %edx
;;       movl    %edx, 0x18(%rcx)
;;       subq    $4, %rsp
;;       movl    %eax, (%rsp)
;;       subq    $0xc, %rsp
;;       movq    %r14, %rdi
;;       movl    0xc(%rsp), %esi
;;       callq   0x220
;;       addq    $0xc, %rsp
;;       addq    $4, %rsp
;;       movq    8(%rsp), %r14
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   ee: ud2
