module Psyche.AST.SExpr

open AnnotatedAst

type Atom =
    | SBool of bool
    | SInt of int
    | SFloat of float
    | Symbol of string

type SExpr =
    | Atom of Atom
    | SList of SExpr list

val toAnnotatedAst : SExpr -> Result<AnnotatedAst, string>
