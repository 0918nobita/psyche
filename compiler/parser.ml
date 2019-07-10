open Parser_combinator

type expr_ast =
  | IntLiteral of location * int
  | Ident of location * string
  | Minus of location * expr_ast
  | Add of location * expr_ast * expr_ast
  | Sub of location * expr_ast * expr_ast
  | Mul of location * expr_ast * expr_ast
  | Div of location * expr_ast * expr_ast
  | Eq of location * expr_ast * expr_ast
  | Ne of location * expr_ast * expr_ast
  | Less of location * expr_ast * expr_ast
  | LessE of location * expr_ast * expr_ast
  | Greater of location * expr_ast * expr_ast
  | GreaterE of location * expr_ast * expr_ast
  | And of location * expr_ast * expr_ast
  | Or of location * expr_ast * expr_ast
  | If of location * expr_ast * expr_ast * expr_ast
  | Let of location * string * expr_ast * expr_ast

type stmt_ast = ExportDef of location * string * expr_ast

let bof = { line = 0; chr = 0 }

let unary =
  let
    plus = char '+' >> return (fun x -> x) and
    minus = char '-' >> return (fun ast -> Minus (bof, ast))
  in
    plus <|> minus <|> return (fun x -> x)

let addop =
  let
    add = char '+' >> return (fun lhs rhs -> Add (bof, lhs, rhs)) and
    sub = char '-' >> return (fun lhs rhs -> Sub (bof, lhs, rhs))
  in
    add <|> sub

let mulop =
  let
    mul = char '*' >> return (fun lhs rhs -> Mul (bof, lhs, rhs)) and
    div = char '/' >> return (fun lhs rhs -> Div (bof, lhs, rhs))
  in
    mul <|> div

let integer =
  let
    digit = (fun c -> c - 48) <.> int_of_char <$> oneOf "0123456789" and
    toNum x acc = x * 10 + acc
  in
    (fun n -> IntLiteral (bof, n))
    <.> (List.fold_left toNum 0)
    <$> Lazy.force @@ some digit

let cmpop =
  (token "==" >> return (fun lhs rhs -> Eq (bof, lhs, rhs)))
  <|> (token "!=" >> return (fun lhs rhs -> Ne (bof, lhs, rhs)))
  <|> (token "<=" >> return (fun lhs rhs -> LessE (bof, lhs, rhs)))
  <|> (token "<"  >> return (fun lhs rhs -> Less (bof, lhs, rhs)))
  <|> (token ">=" >> return (fun lhs rhs -> GreaterE (bof, lhs, rhs)))
  <|> (token ">"  >> return (fun lhs rhs -> Greater (bof, lhs, rhs)))

let andop = token "&&" >> return (fun lhs rhs -> And (bof, lhs, rhs))

let orop = token "||" >> return (fun lhs rhs -> Or (bof, lhs, rhs))

exception Syntax_error of location

exception Out_of_loop of int * location

let comment =
  token "(*"
  >> MParser (fun src ->
    let loc = ref bof in
    let line = ref 0 in
    let chr = ref 0 in
    let idx = ref (-1) in
    let nests = ref 1 in
    let asterisk = ref false in
    let left_parenthesis = ref false in
      try
        for index = 0 to (String.length src - 1) do
          let c = String.get src index in
            begin match c with
              | '(' ->
                  begin
                    if !asterisk then asterisk := false;
                    if !left_parenthesis = false then left_parenthesis := true;
                  end
              | '*' ->
                  begin
                    if !asterisk = false then asterisk := true;
                    if !left_parenthesis then (nests := !nests + 1; left_parenthesis := false)
                  end
              | ')' ->
                  begin
                    if !asterisk then (nests := !nests - 1; asterisk := false);
                    if !left_parenthesis then left_parenthesis := false
                  end
              | _ ->
                begin
                  if c = '\n' then (line := !line + 1; chr := 0) else chr := !chr + 1;
                  if !asterisk then asterisk := false;
                  if !left_parenthesis then left_parenthesis := false
                end
            end;
            if !nests = 0 then raise @@ Out_of_loop (index, { line = !line; chr = !chr });
        done;
        raise @@ Syntax_error { line = !line; chr = !chr }
      with
        Out_of_loop (i, location) -> (idx := i; loc := location);
      [{ ast = ' '; loc = !loc; rest = String.sub src (!idx + 1) (String.length src - !idx - 1)}])

let spaces = Lazy.force @@ some @@ (oneOf " \t\n" <|> comment)

let spaces_opt = many @@ (oneOf " \t\n" <|> comment)

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

let letter = satisfy (fun c ->
  let code = Char.code c in
    (65 <= code && code <= 90) || (97 <= code && code <= 122))

let digit = oneOf "0123456789"

let rec string_of_chars = function
  | [] -> ""
  | c :: cs -> String.make 1 c ^ string_of_chars cs

let identifier = (fun c cs -> string_of_chars (c :: cs)) <$> letter <*> (many (letter <|> digit))

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
            >> return @@ If (bof, ast, then_clause, else_clause))))) src)
  in
  let let_expr = MParser (fun src ->
    parse (
      token "let"
      >> spaces
      >> identifier
      >>= (fun ident ->
        spaces_opt
        >> char '='
        >> spaces_opt
        >> logical_expr_or ()
        >>= (fun bound_expr ->
          token "in"
          >> spaces
          >> logical_expr_or ()
          >>= (fun expr ->
            return @@ Let (bof, ident, bound_expr, expr))))) src)
  in
    MParser (fun src ->
      parse (
        integer
        <|> (char '(' >> (logical_expr_or () >>= (fun c -> char ')' >> return c)))
        <|> if_expr
        <|> let_expr
        <|> (identifier >>= (fun name -> return @@ Ident (bof, name)))) src)

and term () = chain1 (factor ()) mulop

and arithmetic_expr () = (fun op n -> op n) <$> unary <*> chain1 (term ()) addop

and comparison_expr () = chain1 (arithmetic_expr ()) cmpop

and logical_expr_and () = chain1 (comparison_expr ()) andop

and logical_expr_or () = chain1 (logical_expr_and ()) orop

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
      >> return @@ ExportDef (bof, ident, expr)))

let program src =
  let parser =
    (spaces_opt
    >> export_def
    >>= (fun head ->
      many (char ';' >> spaces_opt >> export_def)
      >>= (fun tail ->
        spaces_opt
        >> option (' ') (char ';')
        >> spaces_opt
        >> return @@ head :: tail)))
    <|> (spaces_opt >> return [])
  in
  begin
    let result = parse parser src in
    result
    |> List.iter (function
      | { ast = _; loc; rest } when rest <> "" -> raise @@ Syntax_error loc
      | _ -> ());
    (List.hd result).ast;
  end
