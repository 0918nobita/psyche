open Parser

type instruction =
  | I32Const of int
  | I32Add
  | I32Sub
  | I32Mul
  | I32DivS
  | I32Eq
  | I32Ne
  | I32Gt
  | I32Ge
  | I32Lt
  | I32Le
  | I32Eqz
  | I32If of instruction list * instruction list
  | I32Local of instruction list
  | TeeLocal of int
  | GetLocal of int

let rec instructions_of_ast = function
  | IntLiteral n -> [I32Const n]
  | Minus (expr) ->
      instructions_of_ast expr @ [I32Const (-1); I32Mul]
  | Add (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Add]
  | Sub (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Sub]
  | Mul (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Mul]
  | Div (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32DivS]
  | Eq (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Eq]
  | Ne (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Ne]
  | Greater (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Gt]
  | GreaterE (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Ge]
  | Less (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Lt]
  | LessE (lhs, rhs) ->
      instructions_of_ast lhs @ instructions_of_ast rhs @ [I32Le]
  | And (lhs, rhs) ->
      instructions_of_ast lhs @ [I32Eqz; I32If ([I32Const 0], instructions_of_ast rhs)]
  | Or (lhs, rhs) ->
      instructions_of_ast lhs @ [I32Local [TeeLocal 0; I32Eqz; I32If (instructions_of_ast rhs, [GetLocal 0])]]
  | If (cond, t, e) ->
      instructions_of_ast cond @ [I32Eqz; I32If (instructions_of_ast e, instructions_of_ast t)]
  | Let (_, _, _) -> failwith "Not implemented"
  | Ident _ -> failwith "Not implemented"

let bin_of_instructions irs max =
  let rec inner (irs, current, max) = match irs with
    | [] -> []
    | I32Const n :: tail ->
        65 :: Binary.leb128_of_int n @
        inner (tail, current, max)
    | I32Add :: tail ->
        106 :: inner (tail, current, max)
    | I32Sub :: tail ->
        107 :: inner (tail, current, max)
    | I32Mul :: tail ->
        108 :: inner (tail, current, max)
    | I32DivS :: tail ->
        109 :: inner (tail, current, max)
    | I32Eq :: tail ->
        70 :: inner (tail, current, max)
    | I32Ne :: tail ->
        71 :: inner (tail, current, max)
    | I32Gt :: tail ->
        74 :: inner (tail, current, max)
    | I32Ge :: tail ->
        78 :: inner (tail, current, max)
    | I32Lt :: tail ->
        72 :: inner (tail, current, max)
    | I32Le :: tail ->
        76 :: inner (tail, current, max)
    | I32Eqz :: tail ->
        69 :: inner (tail, current, max)
    | I32If (t, e) :: tail ->
        4 (* if *) ::
        127 (* i32 *) ::
        inner (t, current, max) @
        [ 5 (* else *)
        ] @
        inner (e, current, max) @
        [ 11 (* end*)
        ] @
        inner (tail, current, max)
    | I32Local inner_irs :: tail ->
        (if !max = current
          then
            (max := !max + 1;
            inner (inner_irs, current + 1,  max))
          else inner (inner_irs, current + 1, max)) @
        inner (tail, current, max)
    | TeeLocal n :: tail ->
        34 :: Binary.leb128_of_int (n + current) @
        inner (tail, current, max)
    | GetLocal n :: tail ->
        32 :: Binary.leb128_of_int (n + current) @
        inner (tail, current, max)
  in
    inner (irs, -1, max)
