;;! target = "x86_64"
;;! test = "winch"
;;! flags = "-W tail-call"

(module
  (func $even-step (param $acc i64) (result i64)
    local.get $acc
    i64.const 3
    i64.add)

  (func $odd-step (param $acc i64) (result i64)
    local.get $acc
    i64.const 5
    i64.add)

  (func $dispatch (export "dispatch") (param $count i64) (result i64)
    (local $remaining i64)
    (local $state i32)
    (local $acc i64)
    local.get $count
    local.set $remaining
    block $done
      loop $loop
        local.get $remaining
        i64.eqz
        br_if $done
        local.get $state
        i32.eqz
        if
          local.get $acc
          call $even-step
          local.set $acc
        else
          local.get $acc
          call $odd-step
          local.set $acc
        end
        local.get $state
        i32.eqz
        local.set $state
        local.get $remaining
        i64.const 1
        i64.sub
        local.set $remaining
        br $loop
      end
    end
    local.get $acc)

  (func $tail-even (param $remaining i64) (param $acc i64) (result i64)
    local.get $remaining
    i64.eqz
    if (result i64)
      local.get $acc
    else
      local.get $remaining
      i64.const 1
      i64.sub
      local.get $acc
      i64.const 3
      i64.add
      return_call $tail-odd
    end)

  (func $tail-odd (param $remaining i64) (param $acc i64) (result i64)
    local.get $remaining
    i64.eqz
    if (result i64)
      local.get $acc
    else
      local.get $remaining
      i64.const 1
      i64.sub
      local.get $acc
      i64.const 5
      i64.add
      return_call $tail-even
    end)

  (func (export "tail") (param $count i64) (result i64)
    local.get $count
    i64.const 0
    return_call $tail-even))

;; wasm[0]::function[0]::even-step:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x49
;;   1c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movq    %rdx, 8(%rsp)
;;       movq    8(%rsp), %rax
;;       addq    $3, %rax
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;   49: ud2
;;
;; wasm[0]::function[1]::odd-step:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x99
;;   6c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movq    %rdx, 8(%rsp)
;;       movq    8(%rsp), %rax
;;       addq    $5, %rax
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;   99: ud2
;;
;; wasm[0]::function[2]::dispatch:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x40, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x1bc
;;   bc: movq    %rdi, %r14
;;       subq    $0x30, %rsp
;;       movq    %rdi, 0x28(%rsp)
;;       movq    %rsi, 0x20(%rsp)
;;       movq    %rdx, 0x18(%rsp)
;;       xorq    %r11, %r11
;;       movq    %r11, 0x10(%rsp)
;;       movq    %r11, 8(%rsp)
;;       movq    %r11, (%rsp)
;;       movq    0x18(%rsp), %rax
;;       movq    %rax, 0x10(%rsp)
;;       movq    0x10(%rsp), %rax
;;       cmpq    $0, %rax
;;       movl    $0, %eax
;;       sete    %al
;;       testl   %eax, %eax
;;       jne     0x1af
;;  109: movl    0xc(%rsp), %eax
;;       cmpl    $0, %eax
;;       movl    $0, %eax
;;       sete    %al
;;       testl   %eax, %eax
;;       je      0x156
;;  120: movq    (%rsp), %r11
;;       pushq   %r11
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movq    8(%rsp), %rdx
;;       callq   0
;;       leaq    -0x38(%rbp), %rsp
;;       addq    $8, %rsp
;;       movq    0x28(%rsp), %r14
;;       movq    %rax, (%rsp)
;;       jmp     0x187
;;  156: movq    (%rsp), %r11
;;       pushq   %r11
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movq    8(%rsp), %rdx
;;       callq   0x50
;;       leaq    -0x38(%rbp), %rsp
;;       addq    $8, %rsp
;;       movq    0x28(%rsp), %r14
;;       movq    %rax, (%rsp)
;;       movl    0xc(%rsp), %eax
;;       cmpl    $0, %eax
;;       movl    $0, %eax
;;       sete    %al
;;       movl    %eax, 0xc(%rsp)
;;       movq    0x10(%rsp), %rax
;;       subq    $1, %rax
;;       movq    %rax, 0x10(%rsp)
;;       jmp     0xf0
;;  1af: movq    (%rsp), %rax
;;       addq    $0x30, %rsp
;;       popq    %rbp
;;       retq
;;  1bc: ud2
;;
;; wasm[0]::function[3]::tail-even:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x24c
;;  1dc: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movq    %rdx, 8(%rsp)
;;       movq    %rcx, (%rsp)
;;       movq    8(%rsp), %rax
;;       cmpq    $0, %rax
;;       movl    $0, %eax
;;       sete    %al
;;       testl   %eax, %eax
;;       je      0x21b
;;  212: movq    (%rsp), %rax
;;       jmp     0x243
;;  21b: movq    8(%rsp), %rax
;;       subq    $1, %rax
;;       movq    (%rsp), %rcx
;;       addq    $3, %rcx
;;       movq    %rax, %rdx
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       jmp     0x250
;;  243: addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  24c: ud2
;;
;; wasm[0]::function[4]::tail-odd:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x2dc
;;  26c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movq    %rdx, 8(%rsp)
;;       movq    %rcx, (%rsp)
;;       movq    8(%rsp), %rax
;;       cmpq    $0, %rax
;;       movl    $0, %eax
;;       sete    %al
;;       testl   %eax, %eax
;;       je      0x2ab
;;  2a2: movq    (%rsp), %rax
;;       jmp     0x2d3
;;  2ab: movq    8(%rsp), %rax
;;       subq    $1, %rax
;;       movq    (%rsp), %rcx
;;       addq    $5, %rcx
;;       movq    %rax, %rdx
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       jmp     0x1c0
;;  2d3: addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  2dc: ud2
;;
;; wasm[0]::function[5]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x28, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x33d
;;  2fc: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movq    %rdx, 8(%rsp)
;;       movq    8(%rsp), %r11
;;       pushq   %r11
;;       movq    %r14, %rdi
;;       movq    %r14, %rsi
;;       movq    (%rsp), %rdx
;;       movl    $0, %ecx
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       jmp     0x1c0
;;  334: addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  33d: ud2
