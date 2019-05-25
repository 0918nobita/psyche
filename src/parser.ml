module AST = struct
  type ast =
    | IntLiteral of int
    | Add of ast * ast
    | Sub of ast * ast
    | Mul of ast * ast
    | Div of ast * ast
    | And of ast * ast
    | Or of ast * ast
end

open AST

module Parser = Parser_combinator.ParserCombinator (AST)

open Parser

let non_zero_digit =
  choice
    [ token "1"
    ; token "2"
    ; token "3"
    ; token "4"
    ; token "5"
    ; token "6"
    ; token "7"
    ; token "8"
    ; token "9" ]

let zero = token "0"

let digit = choice [zero; non_zero_digit]

let integer target position =
  match
    sequence
      [option (choice [token "+"; token "-"]); choice [zero; sequence [non_zero_digit; many digit]]]
      target position
  with
  | Failure -> Failure
  | Success (ast_list, _, p) ->
      Success
        ( [ Ast (IntLiteral
              ( int_of_string
              @@ List.fold_left
                  (fun str -> function Token t -> str ^ t | _ -> failwith "integer" )
                  "" ast_list )) ]
        , target
        , p )

let rec factor () target position =
  match choice [integer; sequence [token "("; lazy_parse logical_expr_or; token ")"]] target position with
    | Success ([Ast IntLiteral _], _, _) as result -> result
    | Success ([Token "("; expr; Token ")"], _, p) -> Success ([expr], target, p)
    | _ -> Failure

and term target position =
  match sequence [lazy_parse factor; many @@ sequence [choice [token "*"; token "/"]; lazy_parse factor]] target position with
    | Success (tokens, _, p) ->
        (match tokens with
          | [Ast _] as ast_list -> Success (ast_list, target, p)
          | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when op = Token "*" || op = Token "/" ->
              let ast = ref @@ if op = Token "*" then Mul (lhs, rhs) else Div (lhs, rhs) in
              let rec conv base = function
                | [] -> ()
                | op :: Ast (_ as r) :: tail when op = Token "*" || op = Token "/" ->
                    base := if op = Token "*" then Mul (!base, r) else Div (!base, r);
                    conv base tail
                | _ -> failwith "(term) Fatal Error"
              in
                conv ast tail;
                Success ([Ast !ast], target, p)
          | _ -> Failure)
    | _ -> Failure

and arithmetic_expr target position =
  match sequence [term; many @@ sequence [choice [token "+"; token "-"]; term]] target position with
    | Success (tokens, _, p) ->
        (match tokens with
          | [Ast _] as ast_list -> Success (ast_list, target, p)
          | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when op = Token "+" || op = Token "-" ->
              let ast = ref @@ if op = Token "+" then Add (lhs, rhs) else Sub (lhs, rhs) in
              let rec conv base = function
                | [] -> ()
                | op :: Ast (_ as r) :: tail when op = Token "+" || op = Token "-" ->
                    base := if op = Token "+" then Add (!base, r) else Sub (!base, r);
                    conv base tail
                | _ -> failwith "(arithmetic_expr) Fatal Error"
              in
                conv ast tail;
                Success ([Ast !ast], target, p)
          | _ -> Failure)
    | _ -> Failure

and logical_expr_and target position =
  match sequence [arithmetic_expr; many @@ sequence [token "&&"; arithmetic_expr]] target position with
    | Success (tokens, _, p) ->
        (match tokens with
          | [Ast _] as ast_list -> Success (ast_list, target, p)
          | Ast (_ as lhs) :: Token "&&" :: Ast (_ as rhs) :: tail ->
              let ast = ref @@ And (lhs, rhs) in
              let rec conv base = function
                | [] -> ()
                | Token "&&" :: Ast (_ as r) :: tail ->
                    base := And (!base, r);
                    conv base tail
                | _ -> failwith "(logical_expr_and) Fatal Error"
              in
                conv ast tail;
                Success ([Ast !ast], target, p)
          | _ -> Failure)
    | _ -> Failure

and logical_expr_or () target position =
  match sequence [logical_expr_and; many @@ sequence [token "||"; logical_expr_and]] target position with
    | Success (tokens, _, p) ->
        (match tokens with
          | [Ast _] as ast_list -> Success (ast_list, target, p)
          | Ast (_ as lhs) :: Token "||" :: Ast (_ as rhs) :: tail ->
              let ast = ref @@ Or (lhs, rhs) in
              let rec conv base = function
                | [] -> ()
                | Token "||" :: Ast (_ as r) :: tail ->
                    base := Or (!base, r);
                    conv base tail
                | _ -> failwith "(logical_expr_or) Fatal Error"
              in
                conv ast tail;
                Success ([Ast !ast], target, p)
          | _ -> Failure)
    | _ -> Failure
