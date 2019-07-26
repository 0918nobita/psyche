type func_sig = { params: int; results: int }

type imported_func = { import_name: string * string; signature: func_sig }

type exported_func = { export_name: string; signature: func_sig; locals: int; code: int list }

type func =
  | ImportedFunc of imported_func
  | Func of { signature: func_sig; locals: int; code: int list }
  | ExportedFunc of exported_func

type imported_mem = { module_name: string * string; limits: bool; initial: int }

type mem =
  | Mem of { limits: bool; initial: int }
  | ImportedMem of imported_mem

type wasm = {
  global_vars: int list list;
  functions: func list;
  memories: mem list
}

val bin_of_wasm : wasm -> int list
