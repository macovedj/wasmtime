;;! target = "x86_64"
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
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x30, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xbd
;;   1c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       subq    $0x10, %rsp
;;       movl    $0x2a, %eax
;;       movl    %eax, (%rsp)
;;       leaq    (%rsp), %rax
;;       movl    $0, %ecx
;;       subq    $4, %rsp
;;       movl    %ecx, (%rsp)
;;       pushq   %rax
;;       subq    $4, %rsp
;;       movq    %r14, %rdi
;;       movl    0xc(%rsp), %esi
;;       movq    4(%rsp), %rdx
;;       callq   0x1ba
;;       addq    $4, %rsp
;;       addq    $0xc, %rsp
;;       movq    0x18(%rsp), %r14
;;       subq    $4, %rsp
;;       movl    %eax, (%rsp)
;;       subq    $0xc, %rsp
;;       movq    %r14, %rdi
;;       movl    0xc(%rsp), %esi
;;       callq   0x173
;;       addq    $0xc, %rsp
;;       addq    $4, %rsp
;;       movq    0x18(%rsp), %r14
;;       addq    $0x10, %rsp
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   bd: ud2
