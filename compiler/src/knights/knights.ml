open Ppxlib

let str_type_decl_generator =
  Deriving.Generator.make_noarg
    (fun ~loc ~path:_ (_ : rec_flag * type_declaration Base.List.t) ->
      ([{ pstr_desc = Pstr_value (Nonrecursive,
          [{ pvb_pat = { ppat_desc = Ppat_var { txt = "foo"; loc }; ppat_loc = loc; ppat_attributes = [] };
            pvb_expr = [%expr 42];
            pvb_attributes = []; pvb_loc = loc
          }])
        ; pstr_loc = loc }] : structure))

let deriver = Deriving.add
  ~str_type_decl:str_type_decl_generator
  "knights"
