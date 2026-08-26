;;! target = "aarch64"
;;! test = "compile"
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
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       add     x2, x4, #3
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;
;; wasm[0]::function[1]::odd-step:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       add     x2, x4, #5
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;
;; wasm[0]::function[2]::dispatch:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x30
;;       cmp     sp, x16
;;       b.lo    #0xc4
;;   5c: str     x21, [sp, #-0x10]!
;;       stp     x19, x20, [sp, #-0x10]!
;;       mov     x21, x2
;;       mov     w19, #0
;;       mov     x12, #0
;;       mov     x20, x4
;;       mov     x4, x12
;;       cbz     x20, #0xb0
;;       cbz     w19, #0x90
;;   80: mov     x2, x21
;;       mov     x3, x21
;;       bl      #0x20
;;       b       #0x9c
;;   90: mov     x2, x21
;;       mov     x3, x21
;;       bl      #0
;;   9c: sub     x20, x20, #1
;;       cmp     w19, #0
;;       cset    x19, eq
;;       mov     x4, x2
;;       b       #0x78
;;   b0: mov     x2, x4
;;       ldp     x19, x20, [sp], #0x10
;;       ldr     x21, [sp], #0x10
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   c4: udf     #0xc11f
;;
;; wasm[0]::function[3]::tail-even:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x10
;;       cmp     sp, x16
;;       b.lo    #0x120
;;       cbz     x4, #0x114
;;  100: sub     x4, x4, #1
;;       add     x5, x5, #3
;;       mov     x3, x2
;;       ldp     x29, x30, [sp], #0x10
;;       b       #0x140
;;  114: mov     x2, x5
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  120: udf     #0xc11f
;;
;; wasm[0]::function[4]::tail-odd:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x10
;;       cmp     sp, x16
;;       b.lo    #0x180
;;       cbz     x4, #0x174
;;  160: sub     x4, x4, #1
;;       add     x5, x5, #5
;;       mov     x3, x2
;;       ldp     x29, x30, [sp], #0x10
;;       b       #0xe0
;;  174: mov     x2, x5
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;  180: udf     #0xc11f
;;
;; wasm[0]::function[5]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldur    x16, [x2, #8]
;;       ldur    x16, [x16, #0x18]
;;       add     x16, x16, #0x10
;;       cmp     sp, x16
;;       b.lo    #0x1cc
;;  1bc: mov     x5, #0
;;       mov     x3, x2
;;       ldp     x29, x30, [sp], #0x10
;;       b       #0xe0
;;  1cc: udf     #0xc11f
