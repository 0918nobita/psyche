open Binary

type func_sig = { params: int; results: int }

type imported_func = { module_name: string * string; signature: func_sig }

type func =
  | ImportedFunc of imported_func
  | Func of { signature: func_sig; locals: int; code: int list }
  | ExportedFunc of { signature: func_sig; name: string; locals: int; code: int list }

type mem = { module_name: string * string; limits: bool; initial: int }

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
      :: make_list params 127 (* i32 *)
      @ results (* num results *)
      :: make_list results 127 (* i32 *))
  in
  1 (* section code *)
  :: leb128_of_int (List.length num_types + List.length type_decls) (* section size *)
  @ num_types
  @ type_decls

let imports_of_functions = List.fold_left (fun imports -> function
  | ImportedFunc decl -> decl :: imports
  | _ -> imports) []

let rec find elem = function
  | [] -> raise Not_found
  | h :: t -> if elem = h then 0 else 1 + find elem t

let import_section types functions memories =
  let imported_functions =
    imports_of_functions functions
    |> List.map (fun { module_name; signature } ->
      (String.length @@ fst module_name)
      :: (List.map Base.Char.to_int @@ Base.String.to_list (fst module_name))
      @ (String.length @@ snd module_name)
      :: (List.map Base.Char.to_int @@ Base.String.to_list (snd module_name))
      @ 0 (* import kind *)
      :: leb128_of_int (find signature types))
  in
  let imported_memories =
    memories
    |> List.map (fun { module_name; limits; initial } ->
      (String.length @@ fst module_name)
      :: (List.map Base.Char.to_int @@ Base.String.to_list (fst module_name))
      @ (String.length @@ snd module_name)
      :: (List.map Base.Char.to_int @@ Base.String.to_list (snd module_name))
      @ 2 (* import kind *)
      :: (if limits then 1 else 0)
      :: [initial])
  in
  let entries = imported_functions @ imported_memories in
  let num_imports = leb128_of_int @@ List.length entries in
  let body = num_imports @ List.concat entries in
  2 (* section code *)
  :: leb128_of_int (List.length body) (* section size *)
  @ body

let bin_of_wasm { functions; memories } =
  let types = types_of_functions functions in
  header
  @ type_section types functions
  @ import_section types functions memories

let func1 = ImportedFunc { module_name = ("env", "log"); signature = { params = 0; results = 1 } }

let func2 = Func { signature = { params = 0; results = 1 }; locals = 0; code = [] }

let memory = { module_name = ("env", "mem"); limits = false; initial = 1 }

let example = { functions = [func1; func2]; memories = [memory] }
