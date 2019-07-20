(module
  (import "env" "log" (func $log (param i32)))
  (import "env" "mem" (memory 1))

  (global $result (mut i32) (i32.const 0))
  (global $sp (mut i32) (i32.const 63999)) ;; stack pointer

  (func $push (param i32)
    (i32.store
      (get_global $sp)
      (get_local 0))
    (set_global $sp
      (i32.sub
        (get_global $sp)
        (i32.const 4))))

  (func $pop (result i32)
    (set_global $sp
      (i32.add
        (get_global $sp)
        (i32.const 4)))
    (i32.load
      (get_global $sp)))

  (func $malloc (param $size i32) (result i32)
    ;; 未使用リストを線形探索して、要求されたサイズで格納できるものを探す
    (local $elem_p i32) ;; 今注目しているブロックのポインタ
    (set_local $elem_p (i32.const 0))
    (block $break
      (loop $loop
        (set_local $elem_p (i32.load (get_local $elem_p))) ;; $elem_p を次の未使用ブロックのポインタにする
        (if (i32.ge_s (i32.load (i32.add (get_local $elem_p) (i32.const 4))) (get_local $size))
          (then
            (return (i32.const 1))))
        (br_if $loop (i32.ne (i32.load (get_local $elem_p)) (i32.const 0)))))
    (i32.const 0))

  (func $free (param $ptr i32)
    ;; 未使用リストを線形探索して、$ptr 以上 / 以下の直近の要素を探し、
    ;; それぞれの ptr を更新することで、未使用リストに要素を追加する
    (nop))

  (func $init
    ;; header of base
    (i32.store (i32.const 0) (i32.const 0)) ;; ptr
    (i32.store (i32.const 4) (i32.const 43986))) ;; size

  (func (export "main") (result i32)
    (call $init)
    (call $malloc (i32.const 10))))
