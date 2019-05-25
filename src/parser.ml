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
    [ atom "1"
    ; atom "2"
    ; atom "3"
    ; atom "4"
    ; atom "5"
    ; atom "6"
    ; atom "7"
    ; atom "8"
    ; atom "9" ]

let zero = atom "0"

let digit = choice [zero; non_zero_digit]

let integer target position =
  match
    sequence
      [option (choice [atom "+"; atom "-"]); choice [zero; sequence [non_zero_digit; many digit]]]
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
  match choice [integer; sequence [atom "("; lazy_parse logical_expr_or; atom ")"]] target position with
    | Success ([Ast IntLiteral _], _, _) as result -> result
    | Success ([Token "("; expr; Token ")"], _, p) -> Success ([expr], target, p)
    | _ -> Failure

and term target position =
  let mul = "*" and div = "/" in
  let mul_tok = token mul and div_tok = token div in
    match sequence [lazy_parse factor; many @@ sequence [choice [atom mul; atom div]; lazy_parse factor]] target position with
      | Success (tokens, _, p) ->
          (match tokens with
            | [Ast _] as ast_list -> Success (ast_list, target, p)
            | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when op = mul_tok || op = div_tok ->
                let ast = ref @@ if op = mul_tok then Mul (lhs, rhs) else Div (lhs, rhs) in
                let rec conv base = function
                  | [] -> ()
                  | op :: Ast (_ as r) :: tail when op = mul_tok || op = div_tok ->
                      base := if op = div_tok then Mul (!base, r) else Div (!base, r);
                      conv base tail
                  | _ -> failwith "(term) Fatal Error"
                in
                  conv ast tail;
                  Success ([Ast !ast], target, p)
            | _ -> Failure)
      | _ -> Failure

and arithmetic_expr target position =
  let add = "+" and sub = "-" in
  let add_tok = token add and sub_tok = token sub in
    match sequence [term; many @@ sequence [choice [atom add; atom sub]; term]] target position with
      | Success (tokens, _, p) ->
          (match tokens with
            | [Ast _] as ast_list -> Success (ast_list, target, p)
            | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when op = add_tok || op = sub_tok ->
                let ast = ref @@ if op = add_tok then Add (lhs, rhs) else Sub (lhs, rhs) in
                let rec conv base = function
                  | [] -> ()
                  | op :: Ast (_ as r) :: tail when op = add_tok || op = sub_tok ->
                      base := if op = add_tok then Add (!base, r) else Sub (!base, r);
                      conv base tail
                  | _ -> failwith "(arithmetic_expr) Fatal Error"
                in
                  conv ast tail;
                  Success ([Ast !ast], target, p)
            | _ -> Failure)
      | _ -> Failure

and logical_expr_and target position =
  let and_op = "&&" in
  let and_tok = token and_op in
    match sequence [arithmetic_expr; many @@ sequence [atom and_op; arithmetic_expr]] target position with
      | Success (atomss, _, p) ->
          (match atomss with
            | [Ast _] as ast_list -> Success (ast_list, target, p)
            | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when op = and_tok ->
                let ast = ref @@ And (lhs, rhs) in
                let rec conv base = function
                  | [] -> ()
                  | op :: Ast (_ as r) :: tail when op = and_tok ->
                      base := And (!base, r);
                      conv base tail
                  | _ -> failwith "(logical_expr_and) Fatal Error"
                in
                  conv ast tail;
                  Success ([Ast !ast], target, p)
            | _ -> Failure)
      | _ -> Failure

and logical_expr_or () target position =
  let or_op = "||" in
  let or_tok = token or_op in
    match sequence [logical_expr_and; many @@ sequence [atom or_op; logical_expr_and]] target position with
      | Success (tokens, _, p) ->
          (match tokens with
            | [Ast _] as ast_list -> Success (ast_list, target, p)
            | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when op = or_tok ->
                let ast = ref @@ Or (lhs, rhs) in
                let rec conv base = function
                  | [] -> ()
                  | op :: Ast (_ as r) :: tail when op = or_tok ->
                      base := Or (!base, r);
                      conv base tail
                  | _ -> failwith "(logical_expr_or) Fatal Error"
                in
                  conv ast tail;
                  Success ([Ast !ast], target, p)
            | _ -> Failure)
      | _ -> Failure
