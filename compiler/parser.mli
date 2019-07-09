type expr_ast =
  | IntLiteral of Parser_combinator.location * int
  | Ident of string
  | Minus of expr_ast
  | Add of expr_ast * expr_ast
  | Sub of expr_ast * expr_ast
  | Mul of expr_ast * expr_ast
  | Div of expr_ast * expr_ast
  | Eq of expr_ast * expr_ast
  | Ne of expr_ast * expr_ast
  | Less of expr_ast * expr_ast
  | LessE of expr_ast * expr_ast
  | Greater of expr_ast * expr_ast
  | GreaterE of expr_ast * expr_ast
  | And of expr_ast * expr_ast
  | Or of expr_ast * expr_ast
  | If of expr_ast * expr_ast * expr_ast
  | Let of string * expr_ast * expr_ast

type stmt_ast = ExportDef of string * expr_ast

exception Syntax_error of Parser_combinator.location

val program : string -> stmt_ast list
