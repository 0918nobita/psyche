(module
  (import "env" "mem" (memory 1))
  (import "env" "log" (func $log (param i32)))

  ;; 1: List index out of bounds
  (global $status (export "status") (mut i32) (i32.const 0))

  (func $nth (param $head i32) (param $index i32) (result i32)
    (if (i32.gt_s (i32.const 0) (get_local $index))
      (then (set_global $status (get_local 1)) unreachable))
    (if (i32.ne (get_local $index) (i32.const 0))
      (loop
        (if (i32.eqz (i32.load (i32.add (get_local $head) (i32.const 4))))
          (then (set_global $status (get_local 0)) unreachable))
        (set_local $head (i32.load (i32.add (get_local $head) (i32.const 4))))
        (set_local $index (i32.sub (get_local $index) (i32.const 1)))
        (br_if 0 (i32.gt_s (get_local $index) (i32.const 0)))))
    (i32.load (get_local $head)))

  (func (export "main")
    ;; (cons 10 (cons 20 (cons 30 nil)))
    (i32.store (i32.const 0) (i32.const 0))  ;; nil
    (i32.store (i32.const 4) (i32.const 30)) ;; car
    (i32.store (i32.const 8) (i32.const 0))  ;; cdr
    (i32.store (i32.const 12) (i32.const 20)) ;; car
    (i32.store (i32.const 16) (i32.const 4))  ;; cdr
    (i32.store (i32.const 20) (i32.const 10)) ;; car
    (i32.store (i32.const 24) (i32.const 12)) ;; cdr

    (call $log (call $nth (i32.const 20) (i32.const 0)))
    (call $log (call $nth (i32.const 20) (i32.const 1)))
    (call $log (call $nth (i32.const 20) (i32.const 4)))))
