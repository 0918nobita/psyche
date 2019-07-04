let time f =
  let start = Sys.time () in
  let res = f () in
  let end_ = Sys.time () in
    (end_ -. start, res)

let () = print_endline "スピードテスト"; exit (-1)
