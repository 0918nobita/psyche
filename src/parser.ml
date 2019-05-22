module AST : sig
  type ast = IntLiteral of int | Add of ast * ast | Sub of ast * ast | Mul of ast * ast | Div of ast * ast
end = struct
  type ast = IntLiteral of int | Add of ast * ast | Sub of ast * ast | Mul of ast * ast | Div of ast * ast
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

let term target position =
  match sequence [integer; many @@ sequence [choice [token "*"; token "/"]; integer]] target position with
    | Success (tokens, _, p) ->
        (match tokens with
          | [Ast IntLiteral _] as ast_list -> Success (ast_list, target, p)
          | Ast (IntLiteral _ as lhs) :: op :: Ast (IntLiteral _ as rhs) :: tail when op = Token "*" || op = Token "/" ->
              let ast = ref @@ if op = Token "*" then Mul (lhs, rhs) else Div (lhs, rhs) in
              let rec conv base = function
                | [] -> ()
                | op :: Ast (IntLiteral _ as r) :: tail when op = Token "*" || op = Token "/" ->
                    base := if op = Token "*" then Mul (!base, r) else Div (!base, r);
                    conv base tail
                | _ -> failwith ""
              in
                conv ast tail;
                Success ([Ast !ast], target, p)
          | _ -> Failure)
    | _ -> Failure

let many_integers target position =
  match sequence [integer; many (sequence [token " "; integer])] target position with
    | Success (ast_list, _, p) ->
        Success (List.filter (function Token _ -> false | _ -> true) ast_list, target, p)
    | _ -> Failure
