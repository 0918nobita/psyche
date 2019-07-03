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

let ( <|> ) p q = MParser (fun src -> parse p src @ parse q src)

let liftA2 f x = (<*>) (f <$> x)

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

let unary =
  let
    plus = char '+' >> return (~+) and
    minus = char '-' >> return (~-)
  in
    plus <|> minus <|> return (fun x -> x)

let addop =
  let
    add = char '+' >> return (+) and
    sub = char '-' >> return (-)
  in
    add <|> sub

let mulop =
  let
    mul = char '*' >> return ( * ) and
    div = char '/' >> return (/)
  in
    mul <|> div

let integer =
  let
    digit = (fun c -> c - 48) <.> int_of_char <$> oneOf "0123456789" and
    toNum x acc = x * 10 + acc
  in
    (List.fold_left toNum 0) <$> Lazy.force @@ some digit
