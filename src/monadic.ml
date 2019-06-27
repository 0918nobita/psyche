type 'a parser = MParser of (string -> ('a * string) list)

let parse (MParser p) = p

let substr str start len =
  let str_len = String.length str in
    if str_len >= start + len then Some (String.sub str start len) else None

let return x = MParser x

let token tok =
  let length = String.length tok in
    return (fun src ->
        match substr src 0 length with
          | Some cut when cut = tok ->
              [(cut, String.sub src length (String.length src - length))]
          | _ ->
              [] )

(* Function Composition *)
let ( <.> ) f g x = f @@ g x

let concatMap f = List.(concat <.> map f)

let ( >>= ) p f =
  return
    (fun src ->
       parse p src
       |> concatMap (fun (a, str) -> parse (f a) str))

let ( >> ) m f = m >>= fun _ -> f

let ( <*> ) fs xs = fs >>= fun f -> xs >>= fun x -> return (f x)
