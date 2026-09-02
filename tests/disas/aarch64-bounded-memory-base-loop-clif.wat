;;! target = "aarch64"
;;! test = "clif"

(module
  (memory 1)

  (func $load_through_decreasing_loop
    (param $base i32)
    (param $fill i32)
    (result i32)
    (local $i i32)
    (local $sum i32)

    local.get $base
    local.get $fill
    i32.const 8192
    memory.fill

    i32.const 2048
    local.set $i

    loop $again
      local.get $i
      i32.const 1
      i32.sub
      local.set $i

      local.get $sum
      local.get $base
      local.get $i
      i32.const 2
      i32.shl
      i32.add
      i32.load
      i32.add
      local.set $sum

      local.get $i
      br_if $again
    end

    local.get $sum)
)
;; function u0:0(i64 vmctx, i64, i32, i32) -> i32 tail {
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
;;                                 block0(v0: i64, v1: i64, v2: i32, v3: i32):
;; @001f                               v4 = iconst.i32 0
;; @0025                               v5 = iconst.i32 8192
;; @0029                               v6 = load.i64 notrap aligned region3 v0+64
;; @0029                               v7 = uextend.i64 v2
;; @0029                               v8 = uextend.i64 v5  ; v5 = 8192
;; @0029                               v9 = iconst.i64 1
;; @0029                               v10 = imul v8, v9  ; v9 = 1
;; @0029                               v11 = iadd v7, v10
;; @0029                               v12 = icmp ugt v11, v6
;; @0029                               trapnz v12, heap_oob
;; @0029                               v13 = load.i64 notrap aligned readonly can_move region2 v0+56
;; @0029                               v14 = uextend.i64 v2
;; @0029                               v15 = iconst.i64 1
;; @0029                               v16 = imul v14, v15  ; v15 = 1
;; @0029                               v17 = iadd v13, v16
;; @0029                               v18 = uextend.i64 v5  ; v5 = 8192
;; @0029                               call fn0(v0, v17, v3, v18)
;; @002c                               v19 = iconst.i32 2048
;; @0031                               jump block2(v19, v4)  ; v19 = 2048, v4 = 0
;;
;;                                 block2(v20: i32, v23: i32):
;; @0035                               v21 = iconst.i32 1
;; @0037                               v22 = isub v20, v21  ; v21 = 1
;; @0040                               v25 = iconst.i32 2
;; @0042                               v26 = ishl v22, v25  ; v25 = 2
;; @0043                               v27 = iadd.i32 v2, v26
;; @0044                               v28 = uextend.i64 v27
;; @0044                               v29 = load.i64 notrap aligned readonly can_move region2 v0+56
;;                                     v33 = iconst.i32 2047
;;                                     v34 = band v22, v33  ; v33 = 2047
;;                                     v35 = uextend.i64 v34
;;                                     v36 = iconst.i64 2
;;                                     v37 = ishl v35, v36  ; v36 = 2
;;                                     v38 = iadd.i64 v17, v37
;; @0044                               v31 = load.i32 little region4 v38
;; @0047                               v32 = iadd v23, v31
;; @004c                               brif v22, block2(v22, v32), block4
;;
;;                                 block4:
;; @004e                               jump block3
;;
;;                                 block3:
;; @0051                               jump block1
;;
;;                                 block1:
;; @0051                               return v32
;; }
