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

let unary =
  let
    plus = char '+' >> return (fun x -> x) and
    minus = char '-' >>= (fun (loc, _) -> return (fun ast -> Minus (loc, ast)))
  in
    plus <|> minus <|> return (fun x -> x)

let nat =
  let
    digit = (fun (_, c) -> int_of_char c - 48) <$> oneOf "0123456789" and
    toNum x acc = x * 10 + acc
  in
  Parser (function (loc, _) as input ->
    parse (some digit) input
    |> List.map (fun result ->
      { result with ast = IntLiteral (loc, List.fold_left toNum 0 result.ast) }))

exception Syntax_error of location

exception Out_of_loop of int * location

let comment =
  token "(*"
  >> Parser (fun (_, src) ->
    let line = ref 0 in
    let chr = ref 0 in
    let nests = ref 1 in
    let asterisk = ref false in
    let left_parenthesis = ref false in
    let (idx, loc) =
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
        Out_of_loop (i, location) -> (i, location)
      in
      [{ ast = (); loc; rest = String.sub src (idx + 1) (String.length src - idx - 1) }])

let spaces = drop (some @@ ((drop @@ oneOf " \t\n") <|> comment))

let spaces_opt = drop (many @@ ((drop @@ oneOf " \t\n") <|> comment))

(*
let addop =
  let
    add = char '+' >> (fun _ -> return (fun lhs rhs -> Add (bof, lhs, rhs))) and
    sub = char '-' >> (fun _ -> return (fun lhs rhs -> Sub (bof, lhs, rhs)))
  in
    add <|> sub

let mulop =
  let
    mul = char '*' >> (fun _ -> return (fun lhs rhs -> Mul (bof, lhs, rhs))) and
    div = char '/' >> (fun _ -> return (fun lhs rhs -> Div (bof, lhs, rhs)))
  in
    mul <|> div

let cmpop =
  (token "==" >> (fun _ -> return (fun lhs rhs -> Eq (bof, lhs, rhs))))
  <|> (token "!=" >> (fun _ -> return (fun lhs rhs -> Ne (bof, lhs, rhs))))
  <|> (token "<=" >> (fun _ -> return (fun lhs rhs -> LessE (bof, lhs, rhs))))
  <|> (token "<"  >> (fun _ -> return (fun lhs rhs -> Less (bof, lhs, rhs))))
  <|> (token ">=" >> (fun _ -> return (fun lhs rhs -> GreaterE (bof, lhs, rhs))))
  <|> (token ">"  >> (fun _ -> return (fun lhs rhs -> Greater (bof, lhs, rhs))))

let andop = token "&&" >> (fun _ -> return (fun lhs rhs -> And (bof, lhs, rhs)))

let orop = token "||" >> (fun _ -> return (fun lhs rhs -> Or (bof, lhs, rhs)))

let chain1 base_loc p op =
  let rec rest ~loc:_ a =
      (spaces_opt
      >> (fun loc -> ((fun f b -> f a b) <$> op <*> (spaces_opt >> p) >>= rest)))
    <|>
      return a
  in
    p base_loc
    >>= rest
    >>= (fun ~loc:_ ast -> spaces_opt >> (fun _ -> return ast))

let letter = satisfy (fun c ->
  let code = Char.code c in
    (65 <= code && code <= 90) || (97 <= code && code <= 122))

let digit = oneOf "0123456789"

let rec string_of_chars = function
  | [] -> ""
  | c :: cs -> String.make 1 c ^ string_of_chars cs

let identifier = (fun c cs -> string_of_chars (c :: cs)) <$> letter <*> (many (letter <|> digit))

let rec factor base_loc =
  let if_expr = MParser (fun src ->
    parse (
      token "if"
      >> (fun _ -> spaces
      >> logical_expr_or
      >>= (fun ~loc ast ->
        spaces_opt
        >> (fun _ -> token "then"
        >> (fun _ -> spaces
        >> logical_expr_or
        >>= (fun ~loc:_ then_clause ->
          spaces_opt
          >> (fun _ -> token "else"
          >> (fun _ -> spaces
          >> logical_expr_or
          >>= (fun ~loc:_ else_clause ->
            spaces_opt
            >> (fun _ -> return @@ If (bof, ast, then_clause, else_clause))))))))))) src)
  in
  let let_expr = MParser (fun src ->
    parse (
      token "let"
      >> (fun _ -> spaces
      >> (fun _ -> identifier
      >>= (fun ~loc:_ ident ->
        spaces_opt
        >> (fun _ -> char '='
        >> (fun _ -> spaces_opt
        >> logical_expr_or
        >>= (fun ~loc:_ bound_expr ->
          token "in"
          >> (fun _ -> spaces
          >> logical_expr_or
          >>= (fun ~loc:_ expr ->
            return @@ Let (bof, ident, bound_expr, expr)))))))))) src)
  in
    MParser (fun src ->
      parse (
        integer base_loc
        <|> (char '(' >> (fun loc -> (logical_expr_or loc >>= (fun ~loc:_ c -> char ')' >> (fun _ -> return c)))))
        <|> if_expr
        <|> let_expr
        <|> (identifier >>= (fun ~loc:_ name -> return @@ Ident (bof, name)))) src)

and term base_loc = chain1 base_loc (fun loc -> factor loc) mulop

and arithmetic_expr base_loc = (fun op n -> op n) <$> unary <*> chain1 base_loc term addop

and comparison_expr base_loc = chain1 base_loc arithmetic_expr cmpop

and logical_expr_and base_loc = chain1 base_loc comparison_expr andop

and logical_expr_or base_loc = chain1 base_loc logical_expr_and orop

let export_def =
  token "export"
  >> (fun _ -> spaces
  >> (fun _ -> identifier
  >>= (fun ~loc:_ ident ->
    spaces_opt
    >> (fun _ -> char '='
    >> (fun _ -> spaces_opt
    >> logical_expr_or
    >>= (fun ~loc:_ expr ->
      spaces_opt
      >> (fun _ -> return @@ ExportDef (bof, ident, expr))))))))

let program src =
  let parser =
    (spaces_opt
    >> (fun _ -> export_def
    >>= (fun ~loc:_ head ->
      many (char ';' >> (fun _ -> spaces_opt >> (fun _ -> export_def)))
      >>= (fun ~loc:_ tail ->
        spaces_opt
        >> (fun _ -> option (' ') (char ';')
        >> (fun _ -> spaces_opt
        >> (fun _ -> return @@ head :: tail))))))
    <|> (spaces_opt >> (fun _ -> return [])))
  in
  begin
    let result = parse parser src in
    result
    |> List.iter (function
      | { ast = _; loc; rest } when rest <> "" -> raise @@ Syntax_error loc
      | _ -> ());
    (List.hd result).ast;
  end
*)
