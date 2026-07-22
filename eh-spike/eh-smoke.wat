(module
  (tag $e (param i32))
  (func (export "run") (result i32)
    (block $h (result i32)
      (try_table (catch $e $h)
        (throw $e (i32.const 42)))
      (i32.const -1))))
