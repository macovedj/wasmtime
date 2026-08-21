;;! target = "x86_64"
;;! test = "winch"

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.init $t0 1 (i32.const 7) (i32.const 0) (i32.const 4))
         (elem.drop 1)
         (table.init $t0 3 (i32.const 15) (i32.const 1) (i32.const 3))
         (elem.drop 3)
         (table.copy $t0 0 (i32.const 20) (i32.const 15) (i32.const 5))
         (table.copy $t0 0 (i32.const 21) (i32.const 29) (i32.const 1))
         (table.copy $t0 0 (i32.const 24) (i32.const 10) (i32.const 1))
         (table.copy $t0 0 (i32.const 13) (i32.const 11) (i32.const 4))
         (table.copy $t0 0 (i32.const 19) (i32.const 20) (i32.const 5)))
  (func (export "check") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
)
;; wasm[0]::function[5]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x10, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x3d
;;   1c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movl    $5, %eax
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   3d: ud2
;;
;; wasm[0]::function[6]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x10, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x7d
;;   5c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movl    $6, %eax
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   7d: ud2
;;
;; wasm[0]::function[7]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x10, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xbd
;;   9c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movl    $7, %eax
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   bd: ud2
;;
;; wasm[0]::function[8]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x10, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xfd
;;   dc: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movl    $8, %eax
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   fd: ud2
;;
;; wasm[0]::function[9]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x10, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x13d
;;  11c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movl    $9, %eax
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;  13d: ud2
;;
;; wasm[0]::function[10]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x40, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xa2c
;;  15c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       callq   0x1160
;;       leaq    -0x10(%rbp), %rsp
;;       movq    8(%rsp), %r14
;;       pushq   %rax
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       callq   0x118b
;;       leaq    -0x18(%rbp), %rsp
;;       movq    0x10(%rsp), %r14
;;       movq    %r14, %r11
;;       movq    0xd8(%r11), %rcx
;;       popq    %rdx
;;       movl    $4, %ebx
;;       movl    $0, %esi
;;       movl    $7, %edi
;;       movl    %ebx, %ebx
;;       movl    %esi, %r8d
;;       addl    %ebx, %r8d
;;       jb      0xa2e
;;  1cb: cmpl    %edx, %r8d
;;       ja      0xa30
;;  1d4: movl    %edi, %r8d
;;       addl    %ebx, %r8d
;;       jb      0xa32
;;  1e0: cmpl    %ecx, %r8d
;;       ja      0xa34
;;  1e9: movl    %esi, %esi
;;       imulq   $0x10, %rsi, %rsi
;;       addq    %rsi, %rax
;;       cmpq    $0, %rbx
;;       je      0x257
;;  1ff: movq    (%rax), %rcx
;;       addq    $0x10, %rax
;;       movl    %edi, %edx
;;       movq    %r14, %rsi
;;       movq    0xd8(%rsi), %r8
;;       cmpq    %r8, %rdx
;;       jae     0xa36
;;  21d: movq    %rdx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rsi), %rsi
;;       movq    %rsi, %r9
;;       addq    %r11, %rsi
;;       cmpq    %r8, %rdx
;;       cmovaeq %r9, %rsi
;;       orq     $1, %rcx
;;       movq    %rcx, (%rsi)
;;       addl    $1, %edi
;;       subq    $1, %rbx
;;       jmp     0x1f5
;;  257: movq    %r14, %rdi
;;       movl    $0, %esi
;;       callq   0x11b6
;;       leaq    -0x10(%rbp), %rsp
;;       movq    8(%rsp), %r14
;;       movq    %r14, %rdi
;;       movl    $1, %esi
;;       callq   0x1160
;;       leaq    -0x10(%rbp), %rsp
;;       movq    8(%rsp), %r14
;;       pushq   %rax
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $1, %esi
;;       callq   0x118b
;;       leaq    -0x18(%rbp), %rsp
;;       movq    0x10(%rsp), %r14
;;       movq    %r14, %r11
;;       movq    0xd8(%r11), %rcx
;;       popq    %rdx
;;       movl    $3, %ebx
;;       movl    $1, %esi
;;       movl    $0xf, %edi
;;       movl    %ebx, %ebx
;;       movl    %esi, %r8d
;;       addl    %ebx, %r8d
;;       jb      0xa38
;;  2c9: cmpl    %edx, %r8d
;;       ja      0xa3a
;;  2d2: movl    %edi, %r8d
;;       addl    %ebx, %r8d
;;       jb      0xa3c
;;  2de: cmpl    %ecx, %r8d
;;       ja      0xa3e
;;  2e7: movl    %esi, %esi
;;       imulq   $0x10, %rsi, %rsi
;;       addq    %rsi, %rax
;;       cmpq    $0, %rbx
;;       je      0x355
;;  2fd: movq    (%rax), %rcx
;;       addq    $0x10, %rax
;;       movl    %edi, %edx
;;       movq    %r14, %rsi
;;       movq    0xd8(%rsi), %r8
;;       cmpq    %r8, %rdx
;;       jae     0xa40
;;  31b: movq    %rdx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rsi), %rsi
;;       movq    %rsi, %r9
;;       addq    %r11, %rsi
;;       cmpq    %r8, %rdx
;;       cmovaeq %r9, %rsi
;;       orq     $1, %rcx
;;       movq    %rcx, (%rsi)
;;       addl    $1, %edi
;;       subq    $1, %rbx
;;       jmp     0x2f3
;;  355: movq    %r14, %rdi
;;       movl    $1, %esi
;;       callq   0x11b6
;;       leaq    -0x10(%rbp), %rsp
;;       movq    8(%rsp), %r14
;;       movl    $5, %eax
;;       movl    $0xf, %ecx
;;       movl    $0x14, %edx
;;       movl    %eax, %eax
;;       movl    %ecx, %ecx
;;       movl    %edx, %edx
;;       movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rcx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa42
;;  396: cmpq    %rbx, %rsi
;;       ja      0xa44
;;  39f: movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rdx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa46
;;  3b5: cmpq    %rbx, %rsi
;;       ja      0xa48
;;  3be: cmpq    %rcx, %rdx
;;       jbe     0x3e7
;;  3c7: movq    $18446744073709551615, %rbx
;;       addq    %rax, %rcx
;;       subq    $1, %rcx
;;       addq    %rax, %rdx
;;       subq    $1, %rdx
;;       jmp     0x3ec
;;  3e7: movl    $1, %ebx
;;       cmpq    $0, %rax
;;       je      0x4c3
;;  3f6: movq    %rcx, %rsi
;;       pushq   %rbx
;;       pushq   %rax
;;       pushq   %rdx
;;       pushq   %rcx
;;       pushq   %rsi
;;       popq    %rcx
;;       movq    %r14, %rdx
;;       movq    0xd8(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0xa4a
;;  412: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0x46b
;;  43c: pushq   %rcx
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movq    8(%rsp), %rdx
;;       callq   0x1225
;;       leaq    -0x38(%rbp), %rsp
;;       addq    $8, %rsp
;;       movq    0x28(%rsp), %r14
;;       jmp     0x471
;;  46b: andq    $0xfffffffffffffffe, %rax
;;       popq    %rcx
;;       popq    %rdx
;;       movq    %rdx, %rbx
;;       movq    %r14, %rsi
;;       movq    0xd8(%rsi), %rdi
;;       cmpq    %rdi, %rbx
;;       jae     0xa4c
;;  489: movq    %rbx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rsi), %rsi
;;       movq    %rsi, %r8
;;       addq    %r11, %rsi
;;       cmpq    %rdi, %rbx
;;       cmovaeq %r8, %rsi
;;       orq     $1, %rax
;;       movq    %rax, (%rsi)
;;       popq    %rax
;;       popq    %rbx
;;       addq    %rbx, %rdx
;;       addq    %rbx, %rcx
;;       subq    $1, %rax
;;       jmp     0x3ec
;;  4c3: movl    $1, %eax
;;       movl    $0x1d, %ecx
;;       movl    $0x15, %edx
;;       movl    %eax, %eax
;;       movl    %ecx, %ecx
;;       movl    %edx, %edx
;;       movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rcx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa4e
;;  4ee: cmpq    %rbx, %rsi
;;       ja      0xa50
;;  4f7: movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rdx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa52
;;  50d: cmpq    %rbx, %rsi
;;       ja      0xa54
;;  516: cmpq    %rcx, %rdx
;;       jbe     0x53f
;;  51f: movq    $18446744073709551615, %rbx
;;       addq    %rax, %rcx
;;       subq    $1, %rcx
;;       addq    %rax, %rdx
;;       subq    $1, %rdx
;;       jmp     0x544
;;  53f: movl    $1, %ebx
;;       cmpq    $0, %rax
;;       je      0x61b
;;  54e: movq    %rcx, %rsi
;;       pushq   %rbx
;;       pushq   %rax
;;       pushq   %rdx
;;       pushq   %rcx
;;       pushq   %rsi
;;       popq    %rcx
;;       movq    %r14, %rdx
;;       movq    0xd8(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0xa56
;;  56a: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0x5c3
;;  594: pushq   %rcx
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movq    8(%rsp), %rdx
;;       callq   0x1225
;;       leaq    -0x38(%rbp), %rsp
;;       addq    $8, %rsp
;;       movq    0x28(%rsp), %r14
;;       jmp     0x5c9
;;  5c3: andq    $0xfffffffffffffffe, %rax
;;       popq    %rcx
;;       popq    %rdx
;;       movq    %rdx, %rbx
;;       movq    %r14, %rsi
;;       movq    0xd8(%rsi), %rdi
;;       cmpq    %rdi, %rbx
;;       jae     0xa58
;;  5e1: movq    %rbx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rsi), %rsi
;;       movq    %rsi, %r8
;;       addq    %r11, %rsi
;;       cmpq    %rdi, %rbx
;;       cmovaeq %r8, %rsi
;;       orq     $1, %rax
;;       movq    %rax, (%rsi)
;;       popq    %rax
;;       popq    %rbx
;;       addq    %rbx, %rdx
;;       addq    %rbx, %rcx
;;       subq    $1, %rax
;;       jmp     0x544
;;  61b: movl    $1, %eax
;;       movl    $0xa, %ecx
;;       movl    $0x18, %edx
;;       movl    %eax, %eax
;;       movl    %ecx, %ecx
;;       movl    %edx, %edx
;;       movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rcx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa5a
;;  646: cmpq    %rbx, %rsi
;;       ja      0xa5c
;;  64f: movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rdx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa5e
;;  665: cmpq    %rbx, %rsi
;;       ja      0xa60
;;  66e: cmpq    %rcx, %rdx
;;       jbe     0x697
;;  677: movq    $18446744073709551615, %rbx
;;       addq    %rax, %rcx
;;       subq    $1, %rcx
;;       addq    %rax, %rdx
;;       subq    $1, %rdx
;;       jmp     0x69c
;;  697: movl    $1, %ebx
;;       cmpq    $0, %rax
;;       je      0x773
;;  6a6: movq    %rcx, %rsi
;;       pushq   %rbx
;;       pushq   %rax
;;       pushq   %rdx
;;       pushq   %rcx
;;       pushq   %rsi
;;       popq    %rcx
;;       movq    %r14, %rdx
;;       movq    0xd8(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0xa62
;;  6c2: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0x71b
;;  6ec: pushq   %rcx
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movq    8(%rsp), %rdx
;;       callq   0x1225
;;       leaq    -0x38(%rbp), %rsp
;;       addq    $8, %rsp
;;       movq    0x28(%rsp), %r14
;;       jmp     0x721
;;  71b: andq    $0xfffffffffffffffe, %rax
;;       popq    %rcx
;;       popq    %rdx
;;       movq    %rdx, %rbx
;;       movq    %r14, %rsi
;;       movq    0xd8(%rsi), %rdi
;;       cmpq    %rdi, %rbx
;;       jae     0xa64
;;  739: movq    %rbx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rsi), %rsi
;;       movq    %rsi, %r8
;;       addq    %r11, %rsi
;;       cmpq    %rdi, %rbx
;;       cmovaeq %r8, %rsi
;;       orq     $1, %rax
;;       movq    %rax, (%rsi)
;;       popq    %rax
;;       popq    %rbx
;;       addq    %rbx, %rdx
;;       addq    %rbx, %rcx
;;       subq    $1, %rax
;;       jmp     0x69c
;;  773: movl    $4, %eax
;;       movl    $0xb, %ecx
;;       movl    $0xd, %edx
;;       movl    %eax, %eax
;;       movl    %ecx, %ecx
;;       movl    %edx, %edx
;;       movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rcx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa66
;;  79e: cmpq    %rbx, %rsi
;;       ja      0xa68
;;  7a7: movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rdx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa6a
;;  7bd: cmpq    %rbx, %rsi
;;       ja      0xa6c
;;  7c6: cmpq    %rcx, %rdx
;;       jbe     0x7ef
;;  7cf: movq    $18446744073709551615, %rbx
;;       addq    %rax, %rcx
;;       subq    $1, %rcx
;;       addq    %rax, %rdx
;;       subq    $1, %rdx
;;       jmp     0x7f4
;;  7ef: movl    $1, %ebx
;;       cmpq    $0, %rax
;;       je      0x8cb
;;  7fe: movq    %rcx, %rsi
;;       pushq   %rbx
;;       pushq   %rax
;;       pushq   %rdx
;;       pushq   %rcx
;;       pushq   %rsi
;;       popq    %rcx
;;       movq    %r14, %rdx
;;       movq    0xd8(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0xa6e
;;  81a: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0x873
;;  844: pushq   %rcx
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movq    8(%rsp), %rdx
;;       callq   0x1225
;;       leaq    -0x38(%rbp), %rsp
;;       addq    $8, %rsp
;;       movq    0x28(%rsp), %r14
;;       jmp     0x879
;;  873: andq    $0xfffffffffffffffe, %rax
;;       popq    %rcx
;;       popq    %rdx
;;       movq    %rdx, %rbx
;;       movq    %r14, %rsi
;;       movq    0xd8(%rsi), %rdi
;;       cmpq    %rdi, %rbx
;;       jae     0xa70
;;  891: movq    %rbx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rsi), %rsi
;;       movq    %rsi, %r8
;;       addq    %r11, %rsi
;;       cmpq    %rdi, %rbx
;;       cmovaeq %r8, %rsi
;;       orq     $1, %rax
;;       movq    %rax, (%rsi)
;;       popq    %rax
;;       popq    %rbx
;;       addq    %rbx, %rdx
;;       addq    %rbx, %rcx
;;       subq    $1, %rax
;;       jmp     0x7f4
;;  8cb: movl    $5, %eax
;;       movl    $0x14, %ecx
;;       movl    $0x13, %edx
;;       movl    %eax, %eax
;;       movl    %ecx, %ecx
;;       movl    %edx, %edx
;;       movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rcx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa72
;;  8f6: cmpq    %rbx, %rsi
;;       ja      0xa74
;;  8ff: movq    %r14, %r11
;;       movq    0xd8(%r11), %rbx
;;       movq    %rdx, %rsi
;;       addq    %rax, %rsi
;;       jb      0xa76
;;  915: cmpq    %rbx, %rsi
;;       ja      0xa78
;;  91e: cmpq    %rcx, %rdx
;;       jbe     0x947
;;  927: movq    $18446744073709551615, %rbx
;;       addq    %rax, %rcx
;;       subq    $1, %rcx
;;       addq    %rax, %rdx
;;       subq    $1, %rdx
;;       jmp     0x94c
;;  947: movl    $1, %ebx
;;       cmpq    $0, %rax
;;       je      0xa23
;;  956: movq    %rcx, %rsi
;;       pushq   %rbx
;;       pushq   %rax
;;       pushq   %rdx
;;       pushq   %rcx
;;       pushq   %rsi
;;       popq    %rcx
;;       movq    %r14, %rdx
;;       movq    0xd8(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0xa7a
;;  972: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0x9cb
;;  99c: pushq   %rcx
;;       subq    $8, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movq    8(%rsp), %rdx
;;       callq   0x1225
;;       leaq    -0x38(%rbp), %rsp
;;       addq    $8, %rsp
;;       movq    0x28(%rsp), %r14
;;       jmp     0x9d1
;;  9cb: andq    $0xfffffffffffffffe, %rax
;;       popq    %rcx
;;       popq    %rdx
;;       movq    %rdx, %rbx
;;       movq    %r14, %rsi
;;       movq    0xd8(%rsi), %rdi
;;       cmpq    %rdi, %rbx
;;       jae     0xa7c
;;  9e9: movq    %rbx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rsi), %rsi
;;       movq    %rsi, %r8
;;       addq    %r11, %rsi
;;       cmpq    %rdi, %rbx
;;       cmovaeq %r8, %rsi
;;       orq     $1, %rax
;;       movq    %rax, (%rsi)
;;       popq    %rax
;;       popq    %rbx
;;       addq    %rbx, %rdx
;;       addq    %rbx, %rcx
;;       subq    $1, %rax
;;       jmp     0x94c
;;  a23: addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;  a2c: ud2
;;  a2e: ud2
;;  a30: ud2
;;  a32: ud2
;;  a34: ud2
;;  a36: ud2
;;  a38: ud2
;;  a3a: ud2
;;  a3c: ud2
;;  a3e: ud2
;;  a40: ud2
;;  a42: ud2
;;  a44: ud2
;;  a46: ud2
;;  a48: ud2
;;  a4a: ud2
;;  a4c: ud2
;;  a4e: ud2
;;  a50: ud2
;;  a52: ud2
;;  a54: ud2
;;  a56: ud2
;;  a58: ud2
;;  a5a: ud2
;;  a5c: ud2
;;  a5e: ud2
;;  a60: ud2
;;  a62: ud2
;;  a64: ud2
;;  a66: ud2
;;  a68: ud2
;;  a6a: ud2
;;  a6c: ud2
;;  a6e: ud2
;;  a70: ud2
;;  a72: ud2
;;  a74: ud2
;;  a76: ud2
;;  a78: ud2
;;  a7a: ud2
;;  a7c: ud2
;;
;; wasm[0]::function[11]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x18(%r11), %r11
;;       addq    $0x30, %r11
;;       cmpq    %rsp, %r11
;;       ja      0xb87
;;  a9c: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movl    %edx, 0xc(%rsp)
;;       movl    0xc(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    (%rsp), %ecx
;;       addq    $4, %rsp
;;       movq    %r14, %rdx
;;       movq    0xd8(%rdx), %rbx
;;       cmpq    %rbx, %rcx
;;       jae     0xb89
;;  ae1: movq    %rcx, %r11
;;       imulq   $8, %r11, %r11
;;       movq    0xd0(%rdx), %rdx
;;       movq    %rdx, %rsi
;;       addq    %r11, %rdx
;;       cmpq    %rbx, %rcx
;;       cmovaeq %rsi, %rdx
;;       movq    (%rdx), %rax
;;       testq   %rax, %rax
;;       jne     0xb42
;;  b0b: subq    $4, %rsp
;;       movl    %ecx, (%rsp)
;;       subq    $0xc, %rsp
;;       movq    %r14, %rdi
;;       movl    $0, %esi
;;       movl    0xc(%rsp), %edx
;;       callq   0x1225
;;       leaq    -0x24(%rbp), %rsp
;;       addq    $4, %rsp
;;       movq    0x18(%rsp), %r14
;;       jmp     0xb48
;;  b42: andq    $0xfffffffffffffffe, %rax
;;       testq   %rax, %rax
;;       je      0xb8b
;;  b51: movq    0x28(%r14), %r11
;;       movl    (%r11), %ecx
;;       movl    0x10(%rax), %edx
;;       cmpl    %edx, %ecx
;;       jne     0xb8d
;;  b63: pushq   %rax
;;       popq    %rcx
;;       movq    0x18(%rcx), %rbx
;;       movq    8(%rcx), %rdx
;;       movq    %rbx, %rdi
;;       movq    %r14, %rsi
;;       callq   *%rdx
;;       leaq    -0x20(%rbp), %rsp
;;       movq    0x18(%rsp), %r14
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;  b87: ud2
;;  b89: ud2
;;  b8b: ud2
;;  b8d: ud2
