(;
pub fn main() {
  fib(7)
};

fn fib(n) {
  if n = 0
    then 0
    else
      (if n = 1
        then 1
        else fib(n - 1) + fib(n - 2))
}

↑ をコンパイルする状況を想定する (main の実行結果は 13)
;)

(module
  (func (export "main") (result i32)
    (call $fib (i32.const 7))) ;; => 13

  (func $fib (param i32) (result i32)
    (if (result i32) (i32.eqz (i32.eq (get_local 0) (i32.const 0)))
      (then
        (if (result i32) (i32.eqz (i32.eq (get_local 0) (i32.const 1)))
          (then
            (i32.add
              (call $fib
                (i32.sub (get_local 0) (i32.const 1)))
              (call $fib
                (i32.sub (get_local 0) (i32.const 2)))))
          (else
            (i32.const 1))))
      (else
        (i32.const 0)))))
