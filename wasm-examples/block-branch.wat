(module
  (global (mut i32) (i32.const 0))
  (func (result i32)
    (block
      (block
        (br 0)) (; ここを 0 から 1 に変更すると、この関数の戻り値が 2 から 0 に変わる ;)
      (set_global 0 (i32.const 2)))
    (get_global 0))
  (export "main" (func 0)))
