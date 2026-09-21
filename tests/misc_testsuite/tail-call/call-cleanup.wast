;;! reference_types = true

;; Keep an operand live across local, imported, and indirect ordinary calls.
;; Consume every argument and result, including the mixed-type stack results.
;; This exercises combined padding/spill cleanup as well as the stack-result
;; path, where result movement must precede the final cleanup.
;; These signatures cover no arguments, register arguments, padding, and stack
;; arguments; the same code must work whether or not a stack-result area is used.

;; 0 arguments, one result.
(module $args0_single
  (func (export "leaf") (result i64)
    i64.const 0))
(register "p" $args0_single)

(module
  (type $t (func (result i64)))
  (import "p" "leaf" (func $imported (type $t)))
  (func $local (type $t)
    i64.const 0)
  (table funcref (elem $local $imported))
  (func (export "local") (param i64) (result i64)
    local.get 0
    call $local i64.add)
  (func (export "imported") (param i64) (result i64)
    local.get 0
    call $imported i64.add)
  (func (export "indirect") (param i64 i32) (result i64)
    local.get 0
    local.get 1 call_indirect (type $t) i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const -17))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -17))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -17))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -17))

(assert_return (invoke "local" (i64.const 0)) (i64.const 0))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 0))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 0))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 0))

(assert_return (invoke "local" (i64.const 42)) (i64.const 42))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 42))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 42))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 42))

;; 0 arguments, multiple results.
(module $args0_multi
  (func (export "leaf") (result i64 i64 f64)
    i64.const 0
    i64.const 123 f64.const 3.5))
(register "p" $args0_multi)

(module
  (type $t (func (result i64 i64 f64)))
  (import "p" "leaf" (func $imported (type $t)))
  (func $local (type $t)
    i64.const 0
    i64.const 123 f64.const 3.5)
  (table funcref (elem $local $imported))
  (func (export "local") (param i64) (result i64)
    local.get 0
    call $local
    i64.trunc_f64_s i64.add i64.add i64.add)
  (func (export "imported") (param i64) (result i64)
    local.get 0
    call $imported
    i64.trunc_f64_s i64.add i64.add i64.add)
  (func (export "indirect") (param i64 i32) (result i64)
    local.get 0
    local.get 1 call_indirect (type $t)
    i64.trunc_f64_s i64.add i64.add i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const 109))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 109))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 109))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 109))

(assert_return (invoke "local" (i64.const 0)) (i64.const 126))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 126))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 126))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 126))

(assert_return (invoke "local" (i64.const 42)) (i64.const 168))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 168))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 168))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 168))

;; 1 argument, one result.
(module $args1_single
  (func (export "leaf") (param i64) (result i64)
    i64.const 0
    local.get 0 i64.add))
(register "p" $args1_single)

(module
  (type $t (func (param i64) (result i64)))
  (import "p" "leaf" (func $imported (type $t)))
  (func $local (type $t)
    i64.const 0
    local.get 0 i64.add)
  (table funcref (elem $local $imported))
  (func (export "local") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    call $local i64.add)
  (func (export "imported") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    call $imported i64.add)
  (func (export "indirect") (param i64 i32) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 1 call_indirect (type $t) i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const -33))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -33))

(assert_return (invoke "local" (i64.const 0)) (i64.const 1))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 1))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 1))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 1))

(assert_return (invoke "local" (i64.const 42)) (i64.const 85))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 85))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 85))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 85))

;; 1 argument, multiple results.
(module $args1_multi
  (func (export "leaf") (param i64) (result i64 i64 f64)
    i64.const 0
    local.get 0 i64.add
    i64.const 123 f64.const 3.5))
(register "p" $args1_multi)

(module
  (type $t (func (param i64) (result i64 i64 f64)))
  (import "p" "leaf" (func $imported (type $t)))
  (func $local (type $t)
    i64.const 0
    local.get 0 i64.add
    i64.const 123 f64.const 3.5)
  (table funcref (elem $local $imported))
  (func (export "local") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    call $local
    i64.trunc_f64_s i64.add i64.add i64.add)
  (func (export "imported") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    call $imported
    i64.trunc_f64_s i64.add i64.add i64.add)
  (func (export "indirect") (param i64 i32) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 1 call_indirect (type $t)
    i64.trunc_f64_s i64.add i64.add i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const 93))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 93))

(assert_return (invoke "local" (i64.const 0)) (i64.const 127))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 127))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 127))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 127))

(assert_return (invoke "local" (i64.const 42)) (i64.const 211))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 211))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 211))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 211))

;; 5 arguments, one result.
(module $args5_single
  (func (export "leaf") (param i64 i64 i64 i64 i64) (result i64)
    i64.const 0
    local.get 0 i64.add
    local.get 1 i64.add
    local.get 2 i64.add
    local.get 3 i64.add
    local.get 4 i64.add))
(register "p" $args5_single)

(module
  (type $t (func (param i64 i64 i64 i64 i64) (result i64)))
  (import "p" "leaf" (func $imported (type $t)))
  (func $local (type $t)
    i64.const 0
    local.get 0 i64.add
    local.get 1 i64.add
    local.get 2 i64.add
    local.get 3 i64.add
    local.get 4 i64.add)
  (table funcref (elem $local $imported))
  (func (export "local") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    call $local i64.add)
  (func (export "imported") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    call $imported i64.add)
  (func (export "indirect") (param i64 i32) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    local.get 1 call_indirect (type $t) i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const -87))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -87))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -87))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -87))

(assert_return (invoke "local" (i64.const 0)) (i64.const 15))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 15))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 15))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 15))

(assert_return (invoke "local" (i64.const 42)) (i64.const 267))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 267))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 267))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 267))

;; 5 arguments, multiple results.
(module $args5_multi
  (func (export "leaf") (param i64 i64 i64 i64 i64) (result i64 i64 f64)
    i64.const 0
    local.get 0 i64.add
    local.get 1 i64.add
    local.get 2 i64.add
    local.get 3 i64.add
    local.get 4 i64.add
    i64.const 123 f64.const 3.5))
(register "p" $args5_multi)

(module
  (type $t (func (param i64 i64 i64 i64 i64) (result i64 i64 f64)))
  (import "p" "leaf" (func $imported (type $t)))
  (func $local (type $t)
    i64.const 0
    local.get 0 i64.add
    local.get 1 i64.add
    local.get 2 i64.add
    local.get 3 i64.add
    local.get 4 i64.add
    i64.const 123 f64.const 3.5)
  (table funcref (elem $local $imported))
  (func (export "local") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    call $local
    i64.trunc_f64_s i64.add i64.add i64.add)
  (func (export "imported") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    call $imported
    i64.trunc_f64_s i64.add i64.add i64.add)
  (func (export "indirect") (param i64 i32) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    local.get 1 call_indirect (type $t)
    i64.trunc_f64_s i64.add i64.add i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const 39))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 39))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 39))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 39))

(assert_return (invoke "local" (i64.const 0)) (i64.const 141))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 141))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 141))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 141))

(assert_return (invoke "local" (i64.const 42)) (i64.const 393))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 393))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 393))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 393))

;; 10 arguments, one result.
(module $args10_single
  (func (export "leaf") (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)
    i64.const 0
    local.get 0 i64.add
    local.get 1 i64.add
    local.get 2 i64.add
    local.get 3 i64.add
    local.get 4 i64.add
    local.get 5 i64.add
    local.get 6 i64.add
    local.get 7 i64.add
    local.get 8 i64.add
    local.get 9 i64.add))
(register "p" $args10_single)

(module
  (type $t (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)))
  (import "p" "leaf" (func $imported (type $t)))
  (func $local (type $t)
    i64.const 0
    local.get 0 i64.add
    local.get 1 i64.add
    local.get 2 i64.add
    local.get 3 i64.add
    local.get 4 i64.add
    local.get 5 i64.add
    local.get 6 i64.add
    local.get 7 i64.add
    local.get 8 i64.add
    local.get 9 i64.add)
  (table funcref (elem $local $imported))
  (func (export "local") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    local.get 0 i64.const 6 i64.add
    local.get 0 i64.const 7 i64.add
    local.get 0 i64.const 8 i64.add
    local.get 0 i64.const 9 i64.add
    local.get 0 i64.const 10 i64.add
    call $local i64.add)
  (func (export "imported") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    local.get 0 i64.const 6 i64.add
    local.get 0 i64.const 7 i64.add
    local.get 0 i64.const 8 i64.add
    local.get 0 i64.const 9 i64.add
    local.get 0 i64.const 10 i64.add
    call $imported i64.add)
  (func (export "indirect") (param i64 i32) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    local.get 0 i64.const 6 i64.add
    local.get 0 i64.const 7 i64.add
    local.get 0 i64.const 8 i64.add
    local.get 0 i64.const 9 i64.add
    local.get 0 i64.const 10 i64.add
    local.get 1 call_indirect (type $t) i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const -132))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -132))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -132))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -132))

(assert_return (invoke "local" (i64.const 0)) (i64.const 55))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 55))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 55))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 55))

(assert_return (invoke "local" (i64.const 42)) (i64.const 517))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 517))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 517))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 517))

;; 10 arguments, multiple results.
(module $args10_multi
  (func (export "leaf") (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64 i64 f64)
    i64.const 0
    local.get 0 i64.add
    local.get 1 i64.add
    local.get 2 i64.add
    local.get 3 i64.add
    local.get 4 i64.add
    local.get 5 i64.add
    local.get 6 i64.add
    local.get 7 i64.add
    local.get 8 i64.add
    local.get 9 i64.add
    i64.const 123 f64.const 3.5))
(register "p" $args10_multi)

(module
  (type $t (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64 i64 f64)))
  (import "p" "leaf" (func $imported (type $t)))
  (func $local (type $t)
    i64.const 0
    local.get 0 i64.add
    local.get 1 i64.add
    local.get 2 i64.add
    local.get 3 i64.add
    local.get 4 i64.add
    local.get 5 i64.add
    local.get 6 i64.add
    local.get 7 i64.add
    local.get 8 i64.add
    local.get 9 i64.add
    i64.const 123 f64.const 3.5)
  (table funcref (elem $local $imported))
  (func (export "local") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    local.get 0 i64.const 6 i64.add
    local.get 0 i64.const 7 i64.add
    local.get 0 i64.const 8 i64.add
    local.get 0 i64.const 9 i64.add
    local.get 0 i64.const 10 i64.add
    call $local
    i64.trunc_f64_s i64.add i64.add i64.add)
  (func (export "imported") (param i64) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    local.get 0 i64.const 6 i64.add
    local.get 0 i64.const 7 i64.add
    local.get 0 i64.const 8 i64.add
    local.get 0 i64.const 9 i64.add
    local.get 0 i64.const 10 i64.add
    call $imported
    i64.trunc_f64_s i64.add i64.add i64.add)
  (func (export "indirect") (param i64 i32) (result i64)
    local.get 0
    local.get 0 i64.const 1 i64.add
    local.get 0 i64.const 2 i64.add
    local.get 0 i64.const 3 i64.add
    local.get 0 i64.const 4 i64.add
    local.get 0 i64.const 5 i64.add
    local.get 0 i64.const 6 i64.add
    local.get 0 i64.const 7 i64.add
    local.get 0 i64.const 8 i64.add
    local.get 0 i64.const 9 i64.add
    local.get 0 i64.const 10 i64.add
    local.get 1 call_indirect (type $t)
    i64.trunc_f64_s i64.add i64.add i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const -6))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -6))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -6))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -6))

(assert_return (invoke "local" (i64.const 0)) (i64.const 181))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 181))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 181))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 181))

(assert_return (invoke "local" (i64.const 42)) (i64.const 643))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 643))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 643))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 643))
