(module
  (func (export "main") (result i32) (local i32) (local i32)
    i32.const 1
    tee_local 0
    i32.eqz
    (if (result i32)
      (then
        i32.const 2
        tee_local 1
        i32.eqz
        (if (result i32)
          (then i32.const 3)
          (else get_local 1)))
      (else get_local 0))))
