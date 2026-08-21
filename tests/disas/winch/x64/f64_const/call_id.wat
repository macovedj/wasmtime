;;! target = "x86_64"
;;! test = "winch"

(module
  (func $id-f64 (param f64) (result f64) (local.get 0))
  (func (export "type-first-f64") (result f64) (call $id-f64 (f64.const 1.32)))
)
;; wasm[0]::function[0]::id-f64:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x45
;;   1c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movsd   %xmm0, 8(%rsp)
;;       movsd   8(%rsp), %xmm0
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;   45: ud2
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x10, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xa4
;;   6c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movsd   0x1b(%rip), %xmm0
;;       callq   0
;;       leaq    -0x10(%rbp), %rsp
;;       movq    8(%rsp), %r14
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   a4: ud2
;;   a6: addb    %al, (%rax)
