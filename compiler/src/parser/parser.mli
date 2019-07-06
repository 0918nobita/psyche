type ast =
  | IntLiteral of int
  | Minus of ast
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
  | ConstDef of string * ast

exception Syntax_error

val program : string -> ast
