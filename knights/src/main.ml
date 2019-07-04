open Parsetree
open Ast_mapper
open Ast_helper
open Asttypes
open Longident

let expr_mapper mapper = function
  | { pexp_desc = Pexp_extension ({ txt = ""; loc }, pstr); _ } ->
      (match pstr with
        | PStr [{ pstr_desc = Pstr_eval (expression, _); _}] ->
            Exp.apply
              (Exp.ident {txt = Lident "+"; loc=(!default_loc)})
              [(Nolabel, expression); (Nolabel, Exp.constant (Pconst_integer ("1", None)))]
        | _ -> raise (Location.Error (Location.error ~loc "SyntaxError")))
  | x -> default_mapper.expr mapper x

let addone_mapper _ =
  { default_mapper with expr = expr_mapper }

let () = register "register" addone_mapper
