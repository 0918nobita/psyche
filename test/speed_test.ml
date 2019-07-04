let time f =
  let start = Sys.time () in
  let res = f () in
  let end_ = Sys.time () in
    (res, end_ -. start)

let () = print_endline "スピードテスト"; exit (-1)
