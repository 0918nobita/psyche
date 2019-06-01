open Parser.AST

type ir =
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
  | I32If of ir list * ir list
  | I32Local of ir list
  | TeeLocal of int
  | GetLocal of int

let rec ir_of_ast = function
  | IntLiteral n -> [I32Const n]
  | Add (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Add]
  | Sub (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Sub]
  | Mul (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Mul]
  | Div (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32DivS]
  | Eq (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Eq]
  | Ne (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Ne]
  | Greater (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Gt]
  | GreaterE (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Ge]
  | Less (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Lt]
  | LessE (lhs, rhs) ->
      ir_of_ast lhs @ ir_of_ast rhs @ [I32Le]
  | And (lhs, rhs) ->
      ir_of_ast lhs @ [I32Eqz; I32If ([I32Const 0], ir_of_ast rhs)]
  | Or (lhs, rhs) ->
      ir_of_ast lhs @ [I32Local [TeeLocal 0; I32Eqz; I32If (ir_of_ast rhs, [GetLocal 0])]]
  | If (cond, t, e) ->
      ir_of_ast cond @ [I32Eqz; I32If (ir_of_ast e, ir_of_ast t)]

let rec instructions_of_ir (irs, current, max) = match irs with
  | [] -> []
  | I32Const n :: tail ->
      65 :: Binary.leb128_of_int n @
      instructions_of_ir (tail, current, max)
  | I32Add :: tail ->
      106 :: instructions_of_ir (tail, current, max)
  | I32Sub :: tail ->
      107 :: instructions_of_ir (tail, current, max)
  | I32Mul :: tail ->
      108 :: instructions_of_ir (tail, current, max)
  | I32DivS :: tail ->
      109 :: instructions_of_ir (tail, current, max)
  | I32Eq :: tail ->
      70 :: instructions_of_ir (tail, current, max)
  | I32Ne :: tail ->
      71 :: instructions_of_ir (tail, current, max)
  | I32Gt :: tail ->
      74 :: instructions_of_ir (tail, current, max)
  | I32Ge :: tail ->
      78 :: instructions_of_ir (tail, current, max)
  | I32Lt :: tail ->
      72 :: instructions_of_ir (tail, current, max)
  | I32Le :: tail ->
      76 :: instructions_of_ir (tail, current, max)
  | I32Eqz :: tail ->
      69 :: instructions_of_ir (tail, current, max)
  | I32If (t, e) :: tail ->
      4 (* if *) ::
      127 (* i32 *) ::
      instructions_of_ir (t, current, max) @
      [ 5 (* else *)
      ] @
      instructions_of_ir (e, current, max) @
      [ 11 (* end*)
      ] @
      instructions_of_ir (tail, current, max)
  | I32Local inner_irs :: tail ->
      (if !max = current
        then
          (max := !max + 1;
          instructions_of_ir (inner_irs, current + 1,  max))
        else instructions_of_ir (inner_irs, current + 1, max)) @
      instructions_of_ir (tail, current, max)
  | TeeLocal n :: tail ->
      34 :: Binary.leb128_of_int (n + current) @
      instructions_of_ir (tail, current, max)
  | GetLocal n :: tail ->
      32 :: Binary.leb128_of_int (n + current) @
      instructions_of_ir (tail, current, max)
