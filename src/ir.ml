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
  | Add (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Add]
  | Sub (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Sub]
  | Mul (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Mul]
  | Div (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32DivS]
  | Eq (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Eq]
  | Ne (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Ne]
  | Greater (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Gt]
  | GreaterE (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Ge]
  | Less (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Lt]
  | LessE (lhs, rhs) -> ir_of_ast lhs @ ir_of_ast rhs @ [I32Le]
  | And (lhs, rhs) -> ir_of_ast lhs @ [I32Eqz; I32If ([I32Const 0], ir_of_ast rhs)]
  | Or (lhs, rhs) -> ir_of_ast lhs @ [I32Local [TeeLocal 0; I32Eqz; I32If (ir_of_ast rhs, [GetLocal 0])]]
