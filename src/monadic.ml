type 'a parser = MParser of (string -> ('a * string) list)

let parse (MParser p) = p

let substr str start len =
  let str_len = String.length str in
    if str_len >= start + len
      then Some (String.sub str start len)
      else None

let token tok =
  let length = String.length tok in
    MParser (fun src -> match substr src 0 length with
      | Some cut when cut = tok ->
          [(cut, String.sub src length (length - String.length cut + 1))]
      | _ -> [])

let ( >>= ) p f =
  MParser (fun src ->
    parse p src
      |> List.map (fun (a, str) -> parse (f a) str)
      |> List.concat)

