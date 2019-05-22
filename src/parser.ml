module AST : sig
  type ast = IntLiteral of int
end = struct
  type ast = IntLiteral of int
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

let digit = choice [token "0"; non_zero_digit]

let integer target position =
  match
    sequence
      [option (choice [token "+"; token "-"]); non_zero_digit; many digit]
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

let many_integers target position =
  match sequence [integer; many (sequence [token " "; integer])] target position with
    | Success (ast_list, _, p) ->
        Success (List.filter (function Token _ -> false | _ -> true) ast_list, target, p)
    | _ -> Failure
