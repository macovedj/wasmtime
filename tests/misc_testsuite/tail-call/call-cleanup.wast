;;! reference_types = true

;; Keep an operand live across local, imported, and indirect ordinary calls.
;; Consume every argument and result, including the mixed-type stack results.
;; This exercises combined padding/spill cleanup as well as the stack-result
;; path, where result movement must precede the final cleanup.
;; These signatures cover no arguments, register arguments, padding, and stack
;; arguments; the same code must work whether or not a stack-result area is used.
;; Repeat each set of calls three times on the same instance.

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

(assert_return (invoke "local" (i64.const -17)) (i64.const -17))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -17))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -17))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -17))

(assert_return (invoke "local" (i64.const -17)) (i64.const -17))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -17))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -17))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -17))

(assert_return (invoke "local" (i64.const 0)) (i64.const 0))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 0))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 0))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 0))

(assert_return (invoke "local" (i64.const 0)) (i64.const 0))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 0))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 0))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 0))

(assert_return (invoke "local" (i64.const 0)) (i64.const 0))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 0))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 0))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 0))

(assert_return (invoke "local" (i64.const 42)) (i64.const 42))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 42))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 42))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 42))

(assert_return (invoke "local" (i64.const 42)) (i64.const 42))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 42))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 42))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 42))

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

(assert_return (invoke "local" (i64.const -17)) (i64.const 109))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 109))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 109))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 109))

(assert_return (invoke "local" (i64.const -17)) (i64.const 109))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 109))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 109))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 109))

(assert_return (invoke "local" (i64.const 0)) (i64.const 126))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 126))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 126))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 126))

(assert_return (invoke "local" (i64.const 0)) (i64.const 126))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 126))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 126))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 126))

(assert_return (invoke "local" (i64.const 0)) (i64.const 126))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 126))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 126))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 126))

(assert_return (invoke "local" (i64.const 42)) (i64.const 168))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 168))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 168))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 168))

(assert_return (invoke "local" (i64.const 42)) (i64.const 168))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 168))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 168))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 168))

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

(assert_return (invoke "local" (i64.const -17)) (i64.const -33))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -33))

(assert_return (invoke "local" (i64.const -17)) (i64.const -33))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -33))

(assert_return (invoke "local" (i64.const 0)) (i64.const 1))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 1))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 1))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 1))

(assert_return (invoke "local" (i64.const 0)) (i64.const 1))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 1))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 1))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 1))

(assert_return (invoke "local" (i64.const 0)) (i64.const 1))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 1))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 1))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 1))

(assert_return (invoke "local" (i64.const 42)) (i64.const 85))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 85))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 85))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 85))

(assert_return (invoke "local" (i64.const 42)) (i64.const 85))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 85))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 85))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 85))

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

(assert_return (invoke "local" (i64.const -17)) (i64.const 93))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 93))

(assert_return (invoke "local" (i64.const -17)) (i64.const 93))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 93))

(assert_return (invoke "local" (i64.const 0)) (i64.const 127))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 127))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 127))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 127))

(assert_return (invoke "local" (i64.const 0)) (i64.const 127))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 127))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 127))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 127))

(assert_return (invoke "local" (i64.const 0)) (i64.const 127))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 127))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 127))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 127))

(assert_return (invoke "local" (i64.const 42)) (i64.const 211))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 211))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 211))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 211))

(assert_return (invoke "local" (i64.const 42)) (i64.const 211))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 211))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 211))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 211))

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

(assert_return (invoke "local" (i64.const -17)) (i64.const -87))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -87))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -87))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -87))

(assert_return (invoke "local" (i64.const -17)) (i64.const -87))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -87))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -87))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -87))

(assert_return (invoke "local" (i64.const 0)) (i64.const 15))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 15))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 15))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 15))

(assert_return (invoke "local" (i64.const 0)) (i64.const 15))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 15))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 15))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 15))

(assert_return (invoke "local" (i64.const 0)) (i64.const 15))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 15))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 15))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 15))

(assert_return (invoke "local" (i64.const 42)) (i64.const 267))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 267))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 267))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 267))

(assert_return (invoke "local" (i64.const 42)) (i64.const 267))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 267))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 267))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 267))

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

(assert_return (invoke "local" (i64.const -17)) (i64.const 39))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 39))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 39))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 39))

(assert_return (invoke "local" (i64.const -17)) (i64.const 39))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 39))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 39))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 39))

(assert_return (invoke "local" (i64.const 0)) (i64.const 141))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 141))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 141))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 141))

(assert_return (invoke "local" (i64.const 0)) (i64.const 141))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 141))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 141))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 141))

(assert_return (invoke "local" (i64.const 0)) (i64.const 141))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 141))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 141))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 141))

(assert_return (invoke "local" (i64.const 42)) (i64.const 393))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 393))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 393))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 393))

(assert_return (invoke "local" (i64.const 42)) (i64.const 393))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 393))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 393))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 393))

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

(assert_return (invoke "local" (i64.const -17)) (i64.const -132))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -132))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -132))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -132))

(assert_return (invoke "local" (i64.const -17)) (i64.const -132))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -132))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -132))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -132))

(assert_return (invoke "local" (i64.const 0)) (i64.const 55))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 55))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 55))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 55))

(assert_return (invoke "local" (i64.const 0)) (i64.const 55))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 55))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 55))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 55))

(assert_return (invoke "local" (i64.const 0)) (i64.const 55))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 55))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 55))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 55))

(assert_return (invoke "local" (i64.const 42)) (i64.const 517))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 517))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 517))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 517))

(assert_return (invoke "local" (i64.const 42)) (i64.const 517))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 517))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 517))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 517))

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

(assert_return (invoke "local" (i64.const -17)) (i64.const -6))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -6))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -6))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -6))

(assert_return (invoke "local" (i64.const -17)) (i64.const -6))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -6))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -6))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -6))

(assert_return (invoke "local" (i64.const 0)) (i64.const 181))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 181))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 181))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 181))

(assert_return (invoke "local" (i64.const 0)) (i64.const 181))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 181))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 181))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 181))

(assert_return (invoke "local" (i64.const 0)) (i64.const 181))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 181))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 181))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 181))

(assert_return (invoke "local" (i64.const 42)) (i64.const 643))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 643))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 643))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 643))

(assert_return (invoke "local" (i64.const 42)) (i64.const 643))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 643))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 643))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 643))

(assert_return (invoke "local" (i64.const 42)) (i64.const 643))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 643))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 643))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 643))

;; 32 arguments, one result.
(module $args32_single
  (func (export "leaf") (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add))
(register "p" $args32_single)

(module
  (type $t (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)))
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add)
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 1 call_indirect (type $t) i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const -33))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -33))

(assert_return (invoke "local" (i64.const -17)) (i64.const -33))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -33))

(assert_return (invoke "local" (i64.const -17)) (i64.const -33))
(assert_return (invoke "imported" (i64.const -17)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const -33))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const -33))

(assert_return (invoke "local" (i64.const 0)) (i64.const 528))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 528))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 528))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 528))

(assert_return (invoke "local" (i64.const 0)) (i64.const 528))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 528))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 528))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 528))

(assert_return (invoke "local" (i64.const 0)) (i64.const 528))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 528))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 528))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 528))

(assert_return (invoke "local" (i64.const 42)) (i64.const 1914))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 1914))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 1914))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 1914))

(assert_return (invoke "local" (i64.const 42)) (i64.const 1914))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 1914))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 1914))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 1914))

(assert_return (invoke "local" (i64.const 42)) (i64.const 1914))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 1914))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 1914))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 1914))

;; 32 arguments, multiple results.
(module $args32_multi
  (func (export "leaf") (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64 i64 f64)
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    i64.const 123 f64.const 3.5))
(register "p" $args32_multi)

(module
  (type $t (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64 i64 f64)))
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 1 call_indirect (type $t)
    i64.trunc_f64_s i64.add i64.add i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const 93))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 93))

(assert_return (invoke "local" (i64.const -17)) (i64.const 93))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 93))

(assert_return (invoke "local" (i64.const -17)) (i64.const 93))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 93))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 93))

(assert_return (invoke "local" (i64.const 0)) (i64.const 654))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 654))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 654))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 654))

(assert_return (invoke "local" (i64.const 0)) (i64.const 654))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 654))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 654))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 654))

(assert_return (invoke "local" (i64.const 0)) (i64.const 654))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 654))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 654))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 654))

(assert_return (invoke "local" (i64.const 42)) (i64.const 2040))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 2040))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 2040))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 2040))

(assert_return (invoke "local" (i64.const 42)) (i64.const 2040))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 2040))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 2040))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 2040))

(assert_return (invoke "local" (i64.const 42)) (i64.const 2040))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 2040))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 2040))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 2040))

;; 64 arguments, one result.
(module $args64_single
  (func (export "leaf") (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    local.get 32 i64.add
    local.get 33 i64.add
    local.get 34 i64.add
    local.get 35 i64.add
    local.get 36 i64.add
    local.get 37 i64.add
    local.get 38 i64.add
    local.get 39 i64.add
    local.get 40 i64.add
    local.get 41 i64.add
    local.get 42 i64.add
    local.get 43 i64.add
    local.get 44 i64.add
    local.get 45 i64.add
    local.get 46 i64.add
    local.get 47 i64.add
    local.get 48 i64.add
    local.get 49 i64.add
    local.get 50 i64.add
    local.get 51 i64.add
    local.get 52 i64.add
    local.get 53 i64.add
    local.get 54 i64.add
    local.get 55 i64.add
    local.get 56 i64.add
    local.get 57 i64.add
    local.get 58 i64.add
    local.get 59 i64.add
    local.get 60 i64.add
    local.get 61 i64.add
    local.get 62 i64.add
    local.get 63 i64.add))
(register "p" $args64_single)

(module
  (type $t (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)))
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    local.get 32 i64.add
    local.get 33 i64.add
    local.get 34 i64.add
    local.get 35 i64.add
    local.get 36 i64.add
    local.get 37 i64.add
    local.get 38 i64.add
    local.get 39 i64.add
    local.get 40 i64.add
    local.get 41 i64.add
    local.get 42 i64.add
    local.get 43 i64.add
    local.get 44 i64.add
    local.get 45 i64.add
    local.get 46 i64.add
    local.get 47 i64.add
    local.get 48 i64.add
    local.get 49 i64.add
    local.get 50 i64.add
    local.get 51 i64.add
    local.get 52 i64.add
    local.get 53 i64.add
    local.get 54 i64.add
    local.get 55 i64.add
    local.get 56 i64.add
    local.get 57 i64.add
    local.get 58 i64.add
    local.get 59 i64.add
    local.get 60 i64.add
    local.get 61 i64.add
    local.get 62 i64.add
    local.get 63 i64.add)
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
    local.get 1 call_indirect (type $t) i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const 975))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 975))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 975))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 975))

(assert_return (invoke "local" (i64.const -17)) (i64.const 975))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 975))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 975))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 975))

(assert_return (invoke "local" (i64.const -17)) (i64.const 975))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 975))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 975))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 975))

(assert_return (invoke "local" (i64.const 0)) (i64.const 2080))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 2080))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 2080))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 2080))

(assert_return (invoke "local" (i64.const 0)) (i64.const 2080))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 2080))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 2080))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 2080))

(assert_return (invoke "local" (i64.const 0)) (i64.const 2080))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 2080))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 2080))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 2080))

(assert_return (invoke "local" (i64.const 42)) (i64.const 4810))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 4810))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 4810))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 4810))

(assert_return (invoke "local" (i64.const 42)) (i64.const 4810))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 4810))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 4810))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 4810))

(assert_return (invoke "local" (i64.const 42)) (i64.const 4810))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 4810))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 4810))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 4810))

;; 64 arguments, multiple results.
(module $args64_multi
  (func (export "leaf") (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64 i64 f64)
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    local.get 32 i64.add
    local.get 33 i64.add
    local.get 34 i64.add
    local.get 35 i64.add
    local.get 36 i64.add
    local.get 37 i64.add
    local.get 38 i64.add
    local.get 39 i64.add
    local.get 40 i64.add
    local.get 41 i64.add
    local.get 42 i64.add
    local.get 43 i64.add
    local.get 44 i64.add
    local.get 45 i64.add
    local.get 46 i64.add
    local.get 47 i64.add
    local.get 48 i64.add
    local.get 49 i64.add
    local.get 50 i64.add
    local.get 51 i64.add
    local.get 52 i64.add
    local.get 53 i64.add
    local.get 54 i64.add
    local.get 55 i64.add
    local.get 56 i64.add
    local.get 57 i64.add
    local.get 58 i64.add
    local.get 59 i64.add
    local.get 60 i64.add
    local.get 61 i64.add
    local.get 62 i64.add
    local.get 63 i64.add
    i64.const 123 f64.const 3.5))
(register "p" $args64_multi)

(module
  (type $t (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64 i64 f64)))
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    local.get 32 i64.add
    local.get 33 i64.add
    local.get 34 i64.add
    local.get 35 i64.add
    local.get 36 i64.add
    local.get 37 i64.add
    local.get 38 i64.add
    local.get 39 i64.add
    local.get 40 i64.add
    local.get 41 i64.add
    local.get 42 i64.add
    local.get 43 i64.add
    local.get 44 i64.add
    local.get 45 i64.add
    local.get 46 i64.add
    local.get 47 i64.add
    local.get 48 i64.add
    local.get 49 i64.add
    local.get 50 i64.add
    local.get 51 i64.add
    local.get 52 i64.add
    local.get 53 i64.add
    local.get 54 i64.add
    local.get 55 i64.add
    local.get 56 i64.add
    local.get 57 i64.add
    local.get 58 i64.add
    local.get 59 i64.add
    local.get 60 i64.add
    local.get 61 i64.add
    local.get 62 i64.add
    local.get 63 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
    local.get 1 call_indirect (type $t)
    i64.trunc_f64_s i64.add i64.add i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1101))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1101))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1101))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1101))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1101))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1101))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1101))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1101))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1101))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1101))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1101))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1101))

(assert_return (invoke "local" (i64.const 0)) (i64.const 2206))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 2206))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 2206))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 2206))

(assert_return (invoke "local" (i64.const 0)) (i64.const 2206))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 2206))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 2206))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 2206))

(assert_return (invoke "local" (i64.const 0)) (i64.const 2206))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 2206))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 2206))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 2206))

(assert_return (invoke "local" (i64.const 42)) (i64.const 4936))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 4936))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 4936))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 4936))

(assert_return (invoke "local" (i64.const 42)) (i64.const 4936))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 4936))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 4936))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 4936))

(assert_return (invoke "local" (i64.const 42)) (i64.const 4936))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 4936))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 4936))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 4936))

;; 80 arguments, one result.
(module $args80_single
  (func (export "leaf") (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    local.get 32 i64.add
    local.get 33 i64.add
    local.get 34 i64.add
    local.get 35 i64.add
    local.get 36 i64.add
    local.get 37 i64.add
    local.get 38 i64.add
    local.get 39 i64.add
    local.get 40 i64.add
    local.get 41 i64.add
    local.get 42 i64.add
    local.get 43 i64.add
    local.get 44 i64.add
    local.get 45 i64.add
    local.get 46 i64.add
    local.get 47 i64.add
    local.get 48 i64.add
    local.get 49 i64.add
    local.get 50 i64.add
    local.get 51 i64.add
    local.get 52 i64.add
    local.get 53 i64.add
    local.get 54 i64.add
    local.get 55 i64.add
    local.get 56 i64.add
    local.get 57 i64.add
    local.get 58 i64.add
    local.get 59 i64.add
    local.get 60 i64.add
    local.get 61 i64.add
    local.get 62 i64.add
    local.get 63 i64.add
    local.get 64 i64.add
    local.get 65 i64.add
    local.get 66 i64.add
    local.get 67 i64.add
    local.get 68 i64.add
    local.get 69 i64.add
    local.get 70 i64.add
    local.get 71 i64.add
    local.get 72 i64.add
    local.get 73 i64.add
    local.get 74 i64.add
    local.get 75 i64.add
    local.get 76 i64.add
    local.get 77 i64.add
    local.get 78 i64.add
    local.get 79 i64.add))
(register "p" $args80_single)

(module
  (type $t (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64)))
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    local.get 32 i64.add
    local.get 33 i64.add
    local.get 34 i64.add
    local.get 35 i64.add
    local.get 36 i64.add
    local.get 37 i64.add
    local.get 38 i64.add
    local.get 39 i64.add
    local.get 40 i64.add
    local.get 41 i64.add
    local.get 42 i64.add
    local.get 43 i64.add
    local.get 44 i64.add
    local.get 45 i64.add
    local.get 46 i64.add
    local.get 47 i64.add
    local.get 48 i64.add
    local.get 49 i64.add
    local.get 50 i64.add
    local.get 51 i64.add
    local.get 52 i64.add
    local.get 53 i64.add
    local.get 54 i64.add
    local.get 55 i64.add
    local.get 56 i64.add
    local.get 57 i64.add
    local.get 58 i64.add
    local.get 59 i64.add
    local.get 60 i64.add
    local.get 61 i64.add
    local.get 62 i64.add
    local.get 63 i64.add
    local.get 64 i64.add
    local.get 65 i64.add
    local.get 66 i64.add
    local.get 67 i64.add
    local.get 68 i64.add
    local.get 69 i64.add
    local.get 70 i64.add
    local.get 71 i64.add
    local.get 72 i64.add
    local.get 73 i64.add
    local.get 74 i64.add
    local.get 75 i64.add
    local.get 76 i64.add
    local.get 77 i64.add
    local.get 78 i64.add
    local.get 79 i64.add)
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
    local.get 0 i64.const 65 i64.add
    local.get 0 i64.const 66 i64.add
    local.get 0 i64.const 67 i64.add
    local.get 0 i64.const 68 i64.add
    local.get 0 i64.const 69 i64.add
    local.get 0 i64.const 70 i64.add
    local.get 0 i64.const 71 i64.add
    local.get 0 i64.const 72 i64.add
    local.get 0 i64.const 73 i64.add
    local.get 0 i64.const 74 i64.add
    local.get 0 i64.const 75 i64.add
    local.get 0 i64.const 76 i64.add
    local.get 0 i64.const 77 i64.add
    local.get 0 i64.const 78 i64.add
    local.get 0 i64.const 79 i64.add
    local.get 0 i64.const 80 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
    local.get 0 i64.const 65 i64.add
    local.get 0 i64.const 66 i64.add
    local.get 0 i64.const 67 i64.add
    local.get 0 i64.const 68 i64.add
    local.get 0 i64.const 69 i64.add
    local.get 0 i64.const 70 i64.add
    local.get 0 i64.const 71 i64.add
    local.get 0 i64.const 72 i64.add
    local.get 0 i64.const 73 i64.add
    local.get 0 i64.const 74 i64.add
    local.get 0 i64.const 75 i64.add
    local.get 0 i64.const 76 i64.add
    local.get 0 i64.const 77 i64.add
    local.get 0 i64.const 78 i64.add
    local.get 0 i64.const 79 i64.add
    local.get 0 i64.const 80 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
    local.get 0 i64.const 65 i64.add
    local.get 0 i64.const 66 i64.add
    local.get 0 i64.const 67 i64.add
    local.get 0 i64.const 68 i64.add
    local.get 0 i64.const 69 i64.add
    local.get 0 i64.const 70 i64.add
    local.get 0 i64.const 71 i64.add
    local.get 0 i64.const 72 i64.add
    local.get 0 i64.const 73 i64.add
    local.get 0 i64.const 74 i64.add
    local.get 0 i64.const 75 i64.add
    local.get 0 i64.const 76 i64.add
    local.get 0 i64.const 77 i64.add
    local.get 0 i64.const 78 i64.add
    local.get 0 i64.const 79 i64.add
    local.get 0 i64.const 80 i64.add
    local.get 1 call_indirect (type $t) i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1863))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1863))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1863))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1863))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1863))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1863))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1863))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1863))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1863))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1863))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1863))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1863))

(assert_return (invoke "local" (i64.const 0)) (i64.const 3240))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 3240))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 3240))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 3240))

(assert_return (invoke "local" (i64.const 0)) (i64.const 3240))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 3240))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 3240))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 3240))

(assert_return (invoke "local" (i64.const 0)) (i64.const 3240))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 3240))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 3240))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 3240))

(assert_return (invoke "local" (i64.const 42)) (i64.const 6642))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 6642))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 6642))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 6642))

(assert_return (invoke "local" (i64.const 42)) (i64.const 6642))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 6642))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 6642))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 6642))

(assert_return (invoke "local" (i64.const 42)) (i64.const 6642))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 6642))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 6642))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 6642))

;; 80 arguments, multiple results.
(module $args80_multi
  (func (export "leaf") (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64 i64 f64)
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    local.get 32 i64.add
    local.get 33 i64.add
    local.get 34 i64.add
    local.get 35 i64.add
    local.get 36 i64.add
    local.get 37 i64.add
    local.get 38 i64.add
    local.get 39 i64.add
    local.get 40 i64.add
    local.get 41 i64.add
    local.get 42 i64.add
    local.get 43 i64.add
    local.get 44 i64.add
    local.get 45 i64.add
    local.get 46 i64.add
    local.get 47 i64.add
    local.get 48 i64.add
    local.get 49 i64.add
    local.get 50 i64.add
    local.get 51 i64.add
    local.get 52 i64.add
    local.get 53 i64.add
    local.get 54 i64.add
    local.get 55 i64.add
    local.get 56 i64.add
    local.get 57 i64.add
    local.get 58 i64.add
    local.get 59 i64.add
    local.get 60 i64.add
    local.get 61 i64.add
    local.get 62 i64.add
    local.get 63 i64.add
    local.get 64 i64.add
    local.get 65 i64.add
    local.get 66 i64.add
    local.get 67 i64.add
    local.get 68 i64.add
    local.get 69 i64.add
    local.get 70 i64.add
    local.get 71 i64.add
    local.get 72 i64.add
    local.get 73 i64.add
    local.get 74 i64.add
    local.get 75 i64.add
    local.get 76 i64.add
    local.get 77 i64.add
    local.get 78 i64.add
    local.get 79 i64.add
    i64.const 123 f64.const 3.5))
(register "p" $args80_multi)

(module
  (type $t (func (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64) (result i64 i64 f64)))
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
    local.get 10 i64.add
    local.get 11 i64.add
    local.get 12 i64.add
    local.get 13 i64.add
    local.get 14 i64.add
    local.get 15 i64.add
    local.get 16 i64.add
    local.get 17 i64.add
    local.get 18 i64.add
    local.get 19 i64.add
    local.get 20 i64.add
    local.get 21 i64.add
    local.get 22 i64.add
    local.get 23 i64.add
    local.get 24 i64.add
    local.get 25 i64.add
    local.get 26 i64.add
    local.get 27 i64.add
    local.get 28 i64.add
    local.get 29 i64.add
    local.get 30 i64.add
    local.get 31 i64.add
    local.get 32 i64.add
    local.get 33 i64.add
    local.get 34 i64.add
    local.get 35 i64.add
    local.get 36 i64.add
    local.get 37 i64.add
    local.get 38 i64.add
    local.get 39 i64.add
    local.get 40 i64.add
    local.get 41 i64.add
    local.get 42 i64.add
    local.get 43 i64.add
    local.get 44 i64.add
    local.get 45 i64.add
    local.get 46 i64.add
    local.get 47 i64.add
    local.get 48 i64.add
    local.get 49 i64.add
    local.get 50 i64.add
    local.get 51 i64.add
    local.get 52 i64.add
    local.get 53 i64.add
    local.get 54 i64.add
    local.get 55 i64.add
    local.get 56 i64.add
    local.get 57 i64.add
    local.get 58 i64.add
    local.get 59 i64.add
    local.get 60 i64.add
    local.get 61 i64.add
    local.get 62 i64.add
    local.get 63 i64.add
    local.get 64 i64.add
    local.get 65 i64.add
    local.get 66 i64.add
    local.get 67 i64.add
    local.get 68 i64.add
    local.get 69 i64.add
    local.get 70 i64.add
    local.get 71 i64.add
    local.get 72 i64.add
    local.get 73 i64.add
    local.get 74 i64.add
    local.get 75 i64.add
    local.get 76 i64.add
    local.get 77 i64.add
    local.get 78 i64.add
    local.get 79 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
    local.get 0 i64.const 65 i64.add
    local.get 0 i64.const 66 i64.add
    local.get 0 i64.const 67 i64.add
    local.get 0 i64.const 68 i64.add
    local.get 0 i64.const 69 i64.add
    local.get 0 i64.const 70 i64.add
    local.get 0 i64.const 71 i64.add
    local.get 0 i64.const 72 i64.add
    local.get 0 i64.const 73 i64.add
    local.get 0 i64.const 74 i64.add
    local.get 0 i64.const 75 i64.add
    local.get 0 i64.const 76 i64.add
    local.get 0 i64.const 77 i64.add
    local.get 0 i64.const 78 i64.add
    local.get 0 i64.const 79 i64.add
    local.get 0 i64.const 80 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
    local.get 0 i64.const 65 i64.add
    local.get 0 i64.const 66 i64.add
    local.get 0 i64.const 67 i64.add
    local.get 0 i64.const 68 i64.add
    local.get 0 i64.const 69 i64.add
    local.get 0 i64.const 70 i64.add
    local.get 0 i64.const 71 i64.add
    local.get 0 i64.const 72 i64.add
    local.get 0 i64.const 73 i64.add
    local.get 0 i64.const 74 i64.add
    local.get 0 i64.const 75 i64.add
    local.get 0 i64.const 76 i64.add
    local.get 0 i64.const 77 i64.add
    local.get 0 i64.const 78 i64.add
    local.get 0 i64.const 79 i64.add
    local.get 0 i64.const 80 i64.add
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
    local.get 0 i64.const 11 i64.add
    local.get 0 i64.const 12 i64.add
    local.get 0 i64.const 13 i64.add
    local.get 0 i64.const 14 i64.add
    local.get 0 i64.const 15 i64.add
    local.get 0 i64.const 16 i64.add
    local.get 0 i64.const 17 i64.add
    local.get 0 i64.const 18 i64.add
    local.get 0 i64.const 19 i64.add
    local.get 0 i64.const 20 i64.add
    local.get 0 i64.const 21 i64.add
    local.get 0 i64.const 22 i64.add
    local.get 0 i64.const 23 i64.add
    local.get 0 i64.const 24 i64.add
    local.get 0 i64.const 25 i64.add
    local.get 0 i64.const 26 i64.add
    local.get 0 i64.const 27 i64.add
    local.get 0 i64.const 28 i64.add
    local.get 0 i64.const 29 i64.add
    local.get 0 i64.const 30 i64.add
    local.get 0 i64.const 31 i64.add
    local.get 0 i64.const 32 i64.add
    local.get 0 i64.const 33 i64.add
    local.get 0 i64.const 34 i64.add
    local.get 0 i64.const 35 i64.add
    local.get 0 i64.const 36 i64.add
    local.get 0 i64.const 37 i64.add
    local.get 0 i64.const 38 i64.add
    local.get 0 i64.const 39 i64.add
    local.get 0 i64.const 40 i64.add
    local.get 0 i64.const 41 i64.add
    local.get 0 i64.const 42 i64.add
    local.get 0 i64.const 43 i64.add
    local.get 0 i64.const 44 i64.add
    local.get 0 i64.const 45 i64.add
    local.get 0 i64.const 46 i64.add
    local.get 0 i64.const 47 i64.add
    local.get 0 i64.const 48 i64.add
    local.get 0 i64.const 49 i64.add
    local.get 0 i64.const 50 i64.add
    local.get 0 i64.const 51 i64.add
    local.get 0 i64.const 52 i64.add
    local.get 0 i64.const 53 i64.add
    local.get 0 i64.const 54 i64.add
    local.get 0 i64.const 55 i64.add
    local.get 0 i64.const 56 i64.add
    local.get 0 i64.const 57 i64.add
    local.get 0 i64.const 58 i64.add
    local.get 0 i64.const 59 i64.add
    local.get 0 i64.const 60 i64.add
    local.get 0 i64.const 61 i64.add
    local.get 0 i64.const 62 i64.add
    local.get 0 i64.const 63 i64.add
    local.get 0 i64.const 64 i64.add
    local.get 0 i64.const 65 i64.add
    local.get 0 i64.const 66 i64.add
    local.get 0 i64.const 67 i64.add
    local.get 0 i64.const 68 i64.add
    local.get 0 i64.const 69 i64.add
    local.get 0 i64.const 70 i64.add
    local.get 0 i64.const 71 i64.add
    local.get 0 i64.const 72 i64.add
    local.get 0 i64.const 73 i64.add
    local.get 0 i64.const 74 i64.add
    local.get 0 i64.const 75 i64.add
    local.get 0 i64.const 76 i64.add
    local.get 0 i64.const 77 i64.add
    local.get 0 i64.const 78 i64.add
    local.get 0 i64.const 79 i64.add
    local.get 0 i64.const 80 i64.add
    local.get 1 call_indirect (type $t)
    i64.trunc_f64_s i64.add i64.add i64.add))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1989))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1989))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1989))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1989))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1989))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1989))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1989))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1989))

(assert_return (invoke "local" (i64.const -17)) (i64.const 1989))
(assert_return (invoke "imported" (i64.const -17)) (i64.const 1989))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 0)) (i64.const 1989))
(assert_return (invoke "indirect" (i64.const -17) (i32.const 1)) (i64.const 1989))

(assert_return (invoke "local" (i64.const 0)) (i64.const 3366))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 3366))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 3366))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 3366))

(assert_return (invoke "local" (i64.const 0)) (i64.const 3366))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 3366))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 3366))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 3366))

(assert_return (invoke "local" (i64.const 0)) (i64.const 3366))
(assert_return (invoke "imported" (i64.const 0)) (i64.const 3366))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 0)) (i64.const 3366))
(assert_return (invoke "indirect" (i64.const 0) (i32.const 1)) (i64.const 3366))

(assert_return (invoke "local" (i64.const 42)) (i64.const 6768))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 6768))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 6768))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 6768))

(assert_return (invoke "local" (i64.const 42)) (i64.const 6768))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 6768))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 6768))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 6768))

(assert_return (invoke "local" (i64.const 42)) (i64.const 6768))
(assert_return (invoke "imported" (i64.const 42)) (i64.const 6768))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 0)) (i64.const 6768))
(assert_return (invoke "indirect" (i64.const 42) (i32.const 1)) (i64.const 6768))
