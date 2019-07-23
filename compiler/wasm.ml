open Binary

type func_sig = { params: int; results: int }

type func =
  | ImportedFunc of { module_name: string * string; signature: func_sig }
  | Func of { signature: func_sig; locals: int; code: int list }
  | ExportedFunc of { signature: func_sig; name: string; locals: int; code: int list }

type mem =
  | ImportedMem of { module_name: string * string; limits: bool; initial: int }

type wasm = {
  functions: func list;
  memories: mem list
}

let sig_of_func = function
  | ImportedFunc { signature } -> signature
  | Func { signature } -> signature
  | ExportedFunc { signature } -> signature

let types_of_functions =
  let collect table func =
    let signature = sig_of_func func in
    if List.mem signature table then table else signature :: table
  in
  List.fold_left collect []

let header = to_uint32 1836278016 @ to_uint32 1

let concatMap f list = List.(concat @@ map f list)

let make_list len elem = Array.to_list @@ Array.make len elem

let type_section types functions =
  let num_types = leb128_of_int @@ List.length types in
  let type_decls =
    types
    |> concatMap (fun { params; results } ->
      96 (* func *)
      :: params (* num params *)
      :: make_list params 127
      @ results (* num results *)
      :: make_list results 127)
  in
  1 (* section code *)
  :: leb128_of_int (List.length num_types + List.length type_decls) (* section size *)
  @ num_types
  @ type_decls

let import_section types functions =
  [ 2 (* section code *)
  ]

let bin_of_wasm { functions; memories } =
  let types = types_of_functions functions in
  header
  @ type_section types functions
  @ import_section types functions

let func1 = ImportedFunc { module_name = ("env", "log"); signature = { params = 0; results = 1 } }

let func2 = Func { signature = { params = 0; results = 1 }; locals = 0; code = [] }

let example = { functions = [func1; func2]; memories = [] }
