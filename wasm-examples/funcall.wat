(;
  fn bar(x, y) = x * (y + 1);
  export main() = bar(2, 3) + 3;
  ↑ をコンパイルする状況を想定する (main の実行結果は 11)
;)

(module
  (memory 1)
  (global $sp (mut i32) (i32.const 63999))
  (global $result (mut i32) (i32.const 0))

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
      (get_global 0)))

  (func $is_empty (result i32)
    (i32.eq (get_global $sp) (i32.const 63999)))

  (func (export "main") (result i32) (local $state i32)
    (call $push (i32.const 0)) (; entrypoint: main[1] ;)
    (block
      (loop
        (set_local $state (call $pop))
        (if (; main[1] ;) (i32.eq (get_local $state) (i32.const 0))
          (then
            (call $push (i32.const 1)) (; call main[2] ;)
            (call $push (i32.const 3)) (; y ;)
            (call $push (i32.const 2)) (; x ;)
            (call $push (i32.const 2))) (; call bar ;)
          (else
            (if (; main[2] ;) (i32.eq (get_local $state) (i32.const 1))
              (then
                get_global $result
                i32.const 3
                i32.add
                set_global $result)
              (else
                (if (; bar ;) (i32.eq (get_local $state) (i32.const 2))
                  (then
                    call $pop (; x ;)
                    call $pop (; y ;)
                    i32.const 1
                    i32.add
                    i32.mul
                set_global $result))))))
        (br_if 0 (i32.ne (call $is_empty) (i32.const 1)))))
    (get_global $result))) (; => 11 ;)
