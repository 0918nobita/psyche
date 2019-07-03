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

type ast =
  | IntLiteral of int
  | Plus of ast
  | Minus of ast
  | Add of ast * ast
  | Sub of ast * ast
  | Mul of ast * ast
  | Div of ast * ast
  | Eq of ast * ast
  | Ne of ast * ast
  | Less of ast * ast
  | LessE of ast * ast
  | Greater of ast * ast
  | GreaterE of ast * ast

let unary =
  let
    plus = char '+' >> return (fun ast -> Plus ast) and
    minus = char '-' >> return (fun ast -> Minus ast)
  in
    plus <|> minus <|> return (fun x -> x)

let addop =
  let
    add = char '+' >> return (fun lhs rhs -> Add (lhs, rhs)) and
    sub = char '-' >> return (fun lhs rhs -> Sub (lhs, rhs))
  in
    add <|> sub

let mulop =
  let
    mul = char '*' >> return (fun lhs rhs -> Mul (lhs, rhs)) and
    div = char '/' >> return (fun lhs rhs -> Div (lhs, rhs))
  in
    mul <|> div

let integer =
  let
    digit = (fun c -> c - 48) <.> int_of_char <$> oneOf "0123456789" and
    toNum x acc = x * 10 + acc
  in
    (fun n -> IntLiteral n) <.> (List.fold_left toNum 0) <$> Lazy.force @@ some digit

let cmpop =
  (token "==" >> return (fun lhs rhs -> Eq (lhs, rhs)))
  <|> (token "!=" >> return (fun lhs rhs -> Ne (lhs, rhs)))
  <|> (token "<"  >> return (fun lhs rhs -> Less (lhs, rhs)))
  <|> (token "<=" >> return (fun lhs rhs -> LessE (lhs, rhs)))
  <|> (token ">"  >> return (fun lhs rhs -> Greater (lhs, rhs)))
  <|> (token "<=" >> return (fun lhs rhs -> GreaterE (lhs, rhs)))

let chain1 p op =
  let rec rest a = ((fun f b -> f a b) <$> op <*> p >>= rest) <|> return a in
    p >>= rest

let rec factor () =
  MParser (fun src ->
    match parse integer src with
      | [] -> parse (char '(' >> (comparison_expr () >>= (fun c -> char ')' >> return c))) src
      | n  -> n)

and term () = chain1 (factor ()) mulop

and arithmetic_expr () = (fun op n -> op n) <$> unary <*> chain1 (term ()) addop

and comparison_expr () = chain1 (arithmetic_expr ()) cmpop
