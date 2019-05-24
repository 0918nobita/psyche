(module
  (func (export "main") (result i32)
    (if (result i32) (i32.eq (i32.const 2) (i32.const 1))
      (then i32.const 3)
      (else
        (if (result i32) (i32.le_s (i32.const 3) (i32.const 4))
          (then i32.const 5)
          (else i32.const 6))))))
