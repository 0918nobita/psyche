module AST = struct
  type ast =
    | IntLiteral of int
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
    | And of ast * ast
    | Or of ast * ast
    | If of ast * ast * ast
    [@@deriving variants]
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

let spaces target position =
  match sequence [atom " "; many @@ atom " "] target position with
    | Success (_, _, p) -> Success ([], target, p)
    | _ -> Failure

let spaces_opt = option spaces

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

let choice_token tokens = choice @@ List.map atom tokens

let which_of tokens target =
  List.fold_left
    (fun acc next -> acc || next)
    false
    @@ List.map (fun tok -> Token tok = target) tokens

let rec factor () target position =
  match choice [integer; sequence [atom "("; spaces_opt; lazy_parse if_expr; spaces_opt; atom ")"]] target position with
    | Success ([Ast IntLiteral _] as ast, _, p) -> Success (ast, target, p)
    | Success ([Token "("; expr; Token ")"], _, p) -> Success ([expr], target, p)
    | _ -> Failure

and term target position =
  let operators = ["*"; "/"] in
    match sequence [lazy_parse factor; many @@ sequence [spaces_opt; choice_token operators; spaces_opt; lazy_parse factor]] target position with
      | Success (tokens, _, p) ->
          (match tokens with
            | [Ast _] as ast_list -> Success (ast_list, target, p)
            | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when which_of operators op ->
                let ast = ref @@ if op = Token "*" then Mul (lhs, rhs) else Div (lhs, rhs) in
                let rec conv base = function
                  | [] -> ()
                  | op :: Ast (_ as r) :: tail when which_of operators op ->
                      base := if op = Token "/" then Mul (!base, r) else Div (!base, r);
                      conv base tail
                  | _ -> failwith "(term) Fatal Error"
                in
                  conv ast tail;
                  Success ([Ast !ast], target, p)
            | _ -> Failure)
      | _ -> Failure

and arithmetic_expr target position =
  let operators = ["+"; "-"] in
    match sequence [term; many @@ sequence [spaces_opt; choice_token operators; spaces_opt; term]] target position with
      | Success (tokens, _, p) ->
          (match tokens with
            | [Ast _] as ast_list -> Success (ast_list, target, p)
            | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when which_of operators op ->
                let ast = ref @@ if op = Token "+" then Add (lhs, rhs) else Sub (lhs, rhs) in
                let rec conv base = function
                  | [] -> ()
                  | op :: Ast (_ as r) :: tail when which_of operators op ->
                      base := if op = Token "+" then Add (!base, r) else Sub (!base, r);
                      conv base tail
                  | _ -> failwith "(arithmetic_expr) Fatal Error"
                in
                  conv ast tail;
                  Success ([Ast !ast], target, p)
            | _ -> Failure)
      | _ -> Failure

and comparison_expr target position =
  let operators = ["=="; "!="; "<="; "<"; ">="; ">"] in
  match sequence [arithmetic_expr; many @@ sequence [spaces_opt; choice_token operators; spaces_opt; arithmetic_expr]] target position with
    | Success (tokens, _, p) ->
        let ast_gen_of_op = function
          | Token "==" -> eq
          | Token "!=" -> ne
          | Token "<" -> less
          | Token "<=" -> lesse
          | Token ">" -> greater
          | Token ">=" -> greatere
          | _ -> failwith "(comparison_expr) Fatal Error"
        in
        (match tokens with
          | [Ast _] as ast_list -> Success (ast_list, target, p)
          | Ast (_ as lhs) :: op :: Ast (_ as rhs) :: tail when which_of operators op ->
              let ast = ref @@ ast_gen_of_op op lhs rhs in
              let rec conv base = function
                | [] -> ()
                | op :: Ast (_ as r) :: tail ->
                    base := ast_gen_of_op op !base r;
                    conv base tail
                | _ -> failwith "(comparison_expr) Fatal Error"
              in
                conv ast tail;
                Success ([Ast !ast], target, p)
          | _ -> Failure)
    | _ -> Failure

and logical_expr_and target position =
  match sequence [comparison_expr; many @@ sequence [spaces_opt; atom "&&"; spaces_opt; comparison_expr]] target position with
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

and logical_expr_or target position =
  match sequence [logical_expr_and; many @@ sequence [spaces_opt; atom "||"; spaces_opt; logical_expr_and]] target position with
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

and if_expr () target position =
  match choice
    [logical_expr_or; sequence
      [ atom "if"
      ; spaces
      ; logical_expr_or
      ; spaces
      ; atom "then"
      ; spaces
      ; logical_expr_or
      ; spaces
      ; atom "else"
      ; spaces
      ; logical_expr_or
      ]
    ] target position with
    | Success ([Ast _] as ast_list, _, p) -> Success (ast_list, target, p)
    | Success ([Token "if"; Ast (_ as cond); Token "then"; Ast (_ as t); Token "else"; Ast (_ as e)], _, p) ->
        Success ([Ast (If (cond, t, e))], target, p)
    | _ -> Failure

let program = sequence [spaces_opt; lazy_parse if_expr; spaces_opt]
