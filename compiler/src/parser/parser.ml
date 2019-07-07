open Parser_combinator

type expr_ast =
  | IntLiteral of int
  | Minus of expr_ast
  | Add of expr_ast * expr_ast
  | Sub of expr_ast * expr_ast
  | Mul of expr_ast * expr_ast
  | Div of expr_ast * expr_ast
  | Eq of expr_ast * expr_ast
  | Ne of expr_ast * expr_ast
  | Less of expr_ast * expr_ast
  | LessE of expr_ast * expr_ast
  | Greater of expr_ast * expr_ast
  | GreaterE of expr_ast * expr_ast
  | And of expr_ast * expr_ast
  | Or of expr_ast * expr_ast
  | If of expr_ast * expr_ast * expr_ast
  [@@deriving knights]

type stmt_ast = ExportDef of string * expr_ast

let unary =
  let
    plus = char '+' >> return (fun x -> x) and
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
  <|> (token "<=" >> return (fun lhs rhs -> LessE (lhs, rhs)))
  <|> (token "<"  >> return (fun lhs rhs -> Less (lhs, rhs)))
  <|> (token ">=" >> return (fun lhs rhs -> GreaterE (lhs, rhs)))
  <|> (token ">"  >> return (fun lhs rhs -> Greater (lhs, rhs)))

let andop = token "&&" >> return (fun lhs rhs -> And (lhs, rhs))

let orop = token "||" >> return (fun lhs rhs -> Or (lhs, rhs))

let spaces = Lazy.force @@ some @@ oneOf " \t\n"

let spaces_opt = many @@ oneOf " \t\n"

let chain1 p op =
  let rec rest a =
      (spaces_opt
      >> ((fun f b -> f a b) <$> op <*> (spaces_opt >> p) >>= rest))
    <|>
      return a
  in
    p
    >>= rest
    >>= (fun ast -> spaces_opt >> return ast)

let rec factor () =
  let if_expr = MParser (fun src ->
    parse (
      token "if"
      >> spaces
      >> logical_expr_or ()
      >>= (fun ast ->
        spaces_opt
        >> token "then"
        >> spaces
        >> logical_expr_or ()
        >>= (fun then_clause ->
          spaces_opt
          >> token "else"
          >> spaces
          >> logical_expr_or ()
          >>= (fun else_clause ->
            spaces_opt
            >> return @@ If (ast, then_clause, else_clause))))) src)
  in
    MParser (fun src ->
      match parse integer src with
        | []  ->
            (match parse (char '(' >> (logical_expr_or () >>= (fun c -> char ')' >> return c))) src with
              | [] -> parse if_expr src
              | ast -> ast)
        | ast -> ast)

and term () = chain1 (factor ()) mulop

and arithmetic_expr () = (fun op n -> op n) <$> unary <*> chain1 (term ()) addop

and comparison_expr () = chain1 (arithmetic_expr ()) cmpop

and logical_expr_and () = chain1 (comparison_expr ()) andop

and logical_expr_or () = chain1 (logical_expr_and ()) orop

let letter = satisfy (fun c -> let code = Char.code c in (65 <= code && code <= 90) || (97 <= code && code <= 122))

let digit = oneOf "0123456789"

let rec string_of_chars = function
  | [] -> ""
  | c :: cs -> String.make 1 c ^ string_of_chars cs

let identifier = (fun c cs -> string_of_chars (c :: cs)) <$> letter <*> (many (letter <|> digit))

let export_def =
  token "export"
  >> spaces
  >> identifier
  >>= (fun ident ->
    spaces_opt
    >> char '='
    >> spaces_opt
    >> logical_expr_or ()
    >>= (fun expr ->
      spaces_opt
      >> return @@ ExportDef (ident, expr)))

exception Syntax_error

let program src =
  let parser = option []
    (spaces_opt
    >> export_def
    >>= (fun head ->
      many (char ';' >> spaces_opt >> export_def)
      >>= (fun tail ->
        spaces_opt
        >> option (' ') (char ';')
        >> spaces_opt
        >> return @@ head :: tail))) in
  parse parser src
  |> List.filter (fun (_, rest) -> rest = "")
  |> (fun list ->
    if List.length list = 0
      then raise Syntax_error
      else List.hd list)
    |> fst
