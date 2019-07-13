(module
  (import "env" "log" (func $log (param i32 i32)))
  (import "env" "mem" (memory 1))
  (type (func))
  (data (i32.const 0) "hello")
  (func
    (i32.const 0)
    (i32.const 5)
    (call $log))
  (export "main" (func 1)))
