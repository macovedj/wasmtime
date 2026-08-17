;;! exceptions = true
;;! reference_types = true
;;! bulk_memory = true
;;! simd = true

;; Cover several payload shapes: a mix of types, an empty payload list,
;; and more payloads than there are registers.

(module
  (tag $empty)
  (tag $one (param i32))
  (tag $mixed (param i32 i64 f64))

  (func (export "throw-empty") (throw $empty))
  (func (export "throw-one") (throw $one (i32.const 42)))
  (func (export "throw-mixed")
    (throw $mixed (i32.const 1) (i64.const 2) (f64.const 3)))

  ;; More payloads than there are registers.
  (tag $many (param i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32))
  (func (export "throw-many")
    (i32.const 0)
    (i32.const 1)
    (i32.const 2)
    (i32.const 3)
    (i32.const 4)
    (i32.const 5)
    (i32.const 6)
    (i32.const 7)
    (i32.const 8)
    (i32.const 9)
    (i32.const 10)
    (i32.const 11)
    (i32.const 12)
    (i32.const 13)
    (i32.const 14)
    (i32.const 15)
    (i32.const 16)
    (i32.const 17)
    (i32.const 18)
    (i32.const 19)
    (i32.const 20)
    (i32.const 21)
    (i32.const 22)
    (i32.const 23)
    (i32.const 24)
    (i32.const 25)
    (i32.const 26)
    (i32.const 27)
    (i32.const 28)
    (i32.const 29)
    (i32.const 30)
    (i32.const 31)
    (i32.const 32)
    (i32.const 33)
    (i32.const 34)
    (i32.const 35)
    (i32.const 36)
    (i32.const 37)
    (i32.const 38)
    (i32.const 39)
    (throw $many))

  ;; `v128` payloads occupy a full slot.
  (tag $vec (param i32 v128 f64))
  (func (export "throw-vec")
    (throw $vec (i32.const 1) (v128.const i64x2 2 3) (f64.const 4))))

(assert_exception (invoke "throw-empty"))
(assert_exception (invoke "throw-one"))
(assert_exception (invoke "throw-mixed"))
(assert_exception (invoke "throw-many"))
(assert_exception (invoke "throw-vec"))

;; A reference payload remains live across the exception allocation.
(module
  (tag $eref (param externref))
  (func (export "throw-ref") (param externref)
    (throw $eref (local.get 0))))

(assert_exception (invoke "throw-ref" (ref.extern 5)))

;; A function reference is interned before it is stored in the GC heap.
(module
  (tag $fref (param funcref))
  (func $f)
  (elem declare func $f)
  (func (export "throw-funcref")
    (throw $fref (ref.func $f))))

(assert_exception (invoke "throw-funcref"))
