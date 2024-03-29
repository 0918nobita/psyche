type func_sig = { params: int; results: int }

type imported_func = { import_name: string * string; imp_signature: func_sig }

type exported_func = { export_name: string; exp_signature: func_sig; locals: int; code: int list }

type func =
  | ImportedFunc of imported_func
  | Func of { signature: func_sig; locals: int; code: int list }
  | ExportedFunc of exported_func

type imported_mem = { module_name: string * string; limits: bool; initial: int }

type mem =
  | Mem of { limits: bool; initial: int }
  | ImportedMem of imported_mem

type exported_global_var = ExportedGlobalVar of { export_name: string; code: int list }

type global =
  | Global of int list
  | ExportedGlobal of exported_global_var

type wasm = {
  global_vars: global list;
  functions: func list;
  memories: mem list
}

val bin_of_wasm : wasm -> int list
