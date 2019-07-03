let read filename =
	let
    f = open_in filename and
    str = ref ""
  in
    (try
      while true do str := !str ^ input_line f done;
    with
      _ -> ());
    close_in f;
    !str

let make_list len elem = Array.to_list @@ Array.make len elem

let write f bytes = List.iter (output_byte f) bytes

let adjust_size size bytes =
  let lack = size - List.length bytes in
    if lack = 0
      then bytes
      else
        if lack > 0
          then bytes @ make_list lack 0
          else failwith "(adjust_arr_length) Invalid format"

let header = Binary.to_uint32 1836278016 @ Binary.to_uint32 1

let type_header =
  [ 1 (* section code *)
  ; 5 (* section size *)
  ; 1 (* num types *)
  ]

let type_0 =
  [ 96  (* func *)
  ; 0   (* num params *)
  ; 1   (* num results *)
  ; 127 (* i32 *)
  ]

let function_header =
  [ 3 (* section code *)
  ; 2 (* section size *)
  ; 1 (* num functions *)
  ; 0 (* function 0 signature index *)
  ]

let export =
  [ 7 (* section code *)
  ; 8 (* section size *)
  ; 1 (* num exports *)
  ; 4 (* string length *)
  ] @
  (List.map Base.Char.to_int @@ Base.String.to_list "main") @
  [ 0 (* export kind *)
  ; 0 (* export func index *)
  ]

let code ast =
  let max = ref (-1) in
  let instructions = Ir.instructions_of_ir (Ir.ir_of_ast ast, -1, max) @ [ 11 (* end *)] in
  let local_decl_count = !max + 1 in
  let decl =
    (if local_decl_count > 0
      then
        1 :: (* local decl count *)
        Binary.leb128_of_int local_decl_count @ (* local type count *)
        [127 (* i32 *)]
      else
        [0 (* local decl count *)]) @
    instructions in
  let body = (Binary.leb128_of_int @@ List.length decl) @ decl in
    10 :: (* section code *)
    Binary.leb128_of_int (1 + List.length body) @ (* section size *)
    [ 1 (* num functions *)
    ] @
    body

open Parser

let () =
  if Array.length Sys.argv = 1
    then
      print_string @@
        "    ____                  __\n" ^
        "   / __ \\_______  _______/ /_  ___\n" ^
        "  / /_/ / ___/ / / / ___/ __ \\/ _ \\\n" ^
        " / ____(__  ) /_/ / /__/ / / /  __/\n" ^
        "/_/   /____/\\__, /\\___/_/ /_/\\___/\n" ^
        "           /____/\n\n" ^
        "A WASM friendly lightweight programming language\n" ^
        "Version 0.0.1\n"
    else
      let src = read @@ Sys.argv.(1) in
      let ast = program src in
        let
          out = open_out "out.wasm"
        in
          write out @@
            header
            @ type_header
            @ type_0
            @ function_header
            @ export
            @ code ast;
          close_out out
