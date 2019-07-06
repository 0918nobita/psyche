let substr str start len =
  let str_len = String.length str in
    if str_len >= start + len then Some (String.sub str start len) else None

(* Function Composition *)
let ( <.> ) f g x = f @@ g x

let concatMap f = List.(concat <.> map f)

type 'a parser = MParser of (string -> ('a * string) list)

let parse (MParser p) = p

let token tok =
  let length = String.length tok in
    MParser (fun src ->
        match substr src 0 length with
          | Some cut when cut = tok ->
              [(cut, String.sub src length (String.length src - length))]
          | _ ->
              [] )

let ( <*> ) precede succeed =
  MParser
    (fun src -> parse precede src
                |> concatMap (fun (f, str) ->
                  parse succeed str
                  |> List.map (fun (ast, str') -> (f ast, str'))))

let ( <$> ) f p = MParser (fun src ->
  List.map (fun (a, str) -> (f a, str)) @@ (parse p) src)

let return ast = MParser (fun src -> [(ast, src)])

let ( >>= ) p f =
  MParser
    (fun src -> parse p src
                |> concatMap (fun (a, str) -> parse (f a) str))

let ( >> ) m f = m >>= fun _ -> f

let mzero = MParser (fun _ -> [])

let ( <|> ) p q =
  MParser (fun src ->
    let result = parse p src in
      if List.length result = 0
        then parse q src
        else result)

let item = MParser (function
  | "" -> []
  | s  -> String.([(get (sub s 0 1) 0, sub s 1 (length s - 1))]))

let satisfy f = item >>= (fun ast -> if f ast then return ast else mzero)

let char c = satisfy ((==) c)

let oneOf cs = satisfy (String.contains cs)

let option default p = p <|> return default

let (<~>) p q = p >>= fun r -> q >>= fun rs -> return (r :: rs)

let rec many p = option [] (p >>= fun r -> many p >>= fun rs -> return (r :: rs))

let some p = lazy (p <~> many p)
