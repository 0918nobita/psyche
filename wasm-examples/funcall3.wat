(;
pub fn main() {
  let x = 3 in
  let y = 2 in
  sub(x, y)
};

fn sub(a, b) {
  let c = a + 1 in
  c * b
}

↑ をコンパイルする状況を想定する (main の実行結果は 8)
;)

(module
  (memory 1)
  (global $sp (mut i32) (i32.const 63999)) ;; stack pointer

  (func $push (param i32)
    (i32.store
      (get_global $sp)
      (get_local 0))
    (set_global $sp
      (i32.sub
        (get_global $sp)
        (i32.const 4))))

  (func $top (result i32)
    (i32.load (i32.add (get_global $sp) (i32.const 4))))

  (func $pop (result i32)
    (set_global $sp
      (i32.add
        (get_global $sp)
        (i32.const 4)))
    (i32.load
      (get_global $sp)))

  (func $init
    (i32.store (i32.const 0) (i32.const 8)) ;; (base block) ptr
    (i32.store (i32.const 4) (i32.const 0)) ;; (base block) size
    (i32.store (i32.const 8) (i32.const 0)) ;; ptr
    (i32.store (i32.const 12) (i32.const 43978))) ;; size

  (func $malloc (param $size i32) (result i32)
    ;; 未使用リストを線形探索して、要求されたサイズで格納できるものを探す
    (local $elem_p (; 1 ;) i32) ;; 今注目しているブロックのポインタ
    (local $elem_s (; 2 ;) i32) ;; 2回目の探索に用いるポインタ
    (local $new_header (; 3 ;) i32)
    (local $diff (; 4 ;) i32) ;; 注目しているブロックのサイズ - $size
    (block
      (loop $loop
        (set_local $elem_p (i32.load (get_local $elem_p))) ;; $elem_p を次の未使用ブロックのポインタにする
        (set_local $diff (i32.sub (i32.load (i32.add (get_local $elem_p) (i32.const 4))) (get_local $size)))
        (if (i32.gt_s (get_local $diff) (i32.const 0))
          (then
            ;; 必要以上の大きさの未使用ブロックを発見したので、書き込み処理を行う
            ;; 新規のヘッダの書き込み位置を決定
            (set_local $new_header
              (i32.sub
                (i32.add (get_local $elem_p) (i32.load (i32.add (get_local $elem_p) (i32.const 4))))
                (i32.add (get_local $size) (i32.const 8))))
            ;; 新規ヘッダの size を書き込み
            (i32.store (i32.add (i32.const 4) (get_local $new_header)) (get_local $size))
            ;; 分割されるブロックのヘッダ中の size を更新
            (i32.store
              (i32.add (get_local $elem_p) (i32.const 4))
              (i32.sub (i32.load (i32.add (get_local $elem_p) (i32.const 4))) (i32.add (get_local $size) (i32.const 8))))
            (return
              (i32.add (get_local $new_header) (i32.const 8)))))
        (if (i32.eqz (get_local $diff))
          (then
            ;; ちょうどのサイズの未使用ブロックを発見したので、未使用リストだけを更新する
            (block
              (loop $inner_loop
                (set_local $elem_s (i32.load (get_local $elem_s)))
                (if (i32.eq (i32.load (get_local $elem_s)) (get_local $elem_p))
                  (then
                    (i32.store (get_local $elem_s) (i32.load (get_local $elem_p)))
                    (return (get_local $elem_p))))
                (br_if $inner_loop (i32.ne (i32.load (get_local $elem_s)) (i32.const 0))))
              unreachable)))
        (br_if $loop (i32.ne (i32.load (get_local $elem_p)) (i32.const 0)))))
    unreachable)

  (func $free (param $ptr i32)
    ;; 未使用リストを線形探索して直近のブロックを探し、
    ;; 各ヘッダの ptr を更新することで、未使用リストに要素を追加する
    ;; 直後の未使用ブロックとメモリ上で隣接している場合、ひとつの未使用ブロックにまとめる
    (local $target (; 1 ;) i32)
    (local $current (; 2 ;) i32)
    (local $previous (; 3 ;) i32)
    (set_local $target (i32.sub (get_local $ptr) (i32.const 8)))
    (block
      (loop $loop
        (set_local $current (i32.load (get_local $current)))
        (if (i32.gt_s (get_local $current) (get_local $target))
          (then
            (i32.store (get_local $previous) (get_local $target))
            ;; 隣接しているかの判定
            (if
              (i32.eq
                (get_local $current)
                (i32.add
                  (i32.add (get_local $target) (i32.load (i32.add (get_local $target) (i32.const 4))))
                  (i32.const 8)))
              (then
                (i32.store (get_local $target) (i32.load (get_local $current)))
                (i32.store
                  (i32.add (get_local $target) (i32.const 4))
                  (i32.add
                    (i32.add (i32.load (i32.add (get_local $target) (i32.const 4))) (i32.const 8))
                    (i32.load (i32.add (get_local $current) (i32.const 4))))))
              (else
                (i32.store (get_local $target) (get_local $current))))
            return))
        (set_local $previous (get_local $current))
        (br_if $loop (i32.ne (i32.load (get_local $current)) (i32.const 0))))
      ;; 未使用リストの末尾に追加される場合
      (i32.store (get_local $previous) (get_local $target))))

  (func (export "main") (result i32)
    call $init
    (call $malloc (i32.const 8))
    call $push
    (i32.store (call $top) (i32.const 3))
    (i32.store (i32.add (call $top) (i32.const 4)) (i32.const 2))
    (call $sub
      (i32.load (call $top))
      (i32.load (i32.add (call $top) (i32.const 4))))
    call $pop
    call $free) ;; => 8

  (func $sub (param i32 i32) (result i32)
    (call $malloc (i32.const 4))
    call $push
    (i32.store (call $top) (i32.add (get_local 0) (i32.const 1)))
    (i32.mul (i32.load (call $top)) (get_local 1))
    call $pop
    call $free))
