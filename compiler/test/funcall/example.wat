(module
  (import "env" "log" (func (param i32) (result i32)))
  (memory 1)
  (func (result i32)
    (i32.const 42))
  (export "main" (func 1)))
