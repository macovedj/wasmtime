;;! target = "aarch64"
;;! test = "clif"

(module
  (memory 1)

  (func $load_from_checked_span
    (param $base i32)
    (param $index i32)
    (param $fill i32)
    (result i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    local.get $index
    i32.const 2048
    i32.ge_u
    if
      unreachable
    end

    local.get $base
    local.get $index
    i32.const 2
    i32.shl
    i32.add
    i32.load)
)
;; function u0:0(i64 vmctx, i64, i32, i32, i32) -> i32 tail {
;;     region0 = 8 "VMContext+0x8"
;;     region1 = 67108888 "VMStoreContext+0x18"
;;     region2 = 603979776 "VMMemoryDefinition+0x0"
;;     region3 = 603979784 "VMMemoryDefinition+0x8"
;;     region4 = 201326592 "DefinedMemory(StaticModuleIndex(0), DefinedMemoryIndex(0))"
;;     gv0 = vmctx
;;     gv1 = load.i64 notrap aligned readonly can_move region0 gv0+8
;;     gv2 = load.i64 notrap aligned region1 gv1+24
;;     sig0 = (i64 vmctx, i64, i32, i64) tail
;;     fn0 = colocated u805306368:2 sig0
;;     stack_limit = gv2
;;
;;                                 block0(v0: i64, v1: i64, v2: i32, v3: i32, v4: i32):
;; @0024                               v5 = iconst.i32 8192
;; @0028                               v6 = load.i64 notrap aligned region3 v0+64
;; @0028                               v7 = uextend.i64 v2
;; @0028                               v8 = uextend.i64 v5  ; v5 = 8192
;; @0028                               v9 = iconst.i64 1
;; @0028                               v10 = imul v8, v9  ; v9 = 1
;; @0028                               v11 = iadd v7, v10
;; @0028                               v12 = icmp ugt v11, v6
;; @0028                               trapnz v12, heap_oob
;; @0028                               v13 = load.i64 notrap aligned readonly can_move region2 v0+56
;; @0028                               v14 = uextend.i64 v2
;; @0028                               v15 = iconst.i64 1
;; @0028                               v16 = imul v14, v15  ; v15 = 1
;; @0028                               v17 = iadd v13, v16
;; @0028                               v18 = uextend.i64 v5  ; v5 = 8192
;; @0028                               call fn0(v0, v17, v4, v18)
;; @002d                               v19 = iconst.i32 2048
;; @0030                               v20 = icmp uge v3, v19  ; v19 = 2048
;; @0030                               v21 = uextend.i32 v20
;; @0031                               brif v21, block2, block3
;;
;;                                 block2:
;; @0033                               trap user12
;;
;;                                 block3:
;; @0039                               v22 = iconst.i32 2
;; @003b                               v23 = ishl.i32 v3, v22  ; v22 = 2
;; @003c                               v24 = iadd.i32 v2, v23
;; @003d                               v25 = uextend.i64 v24
;; @003d                               v26 = load.i64 notrap aligned readonly can_move region2 v0+56
;;                                     v29 = iconst.i32 2047
;;                                     v30 = band.i32 v3, v29  ; v29 = 2047
;;                                     v31 = uextend.i64 v30
;;                                     v32 = iconst.i64 2
;;                                     v33 = ishl v31, v32  ; v32 = 2
;;                                     v34 = iadd.i64 v17, v33
;; @003d                               v27 = iadd v26, v25
;; @003d                               v28 = load.i32 little region4 v34
;; @0040                               jump block1
;;
;;                                 block1:
;; @0040                               return v28
;; }
