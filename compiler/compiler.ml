open Parser_combinator

open Parser

open Binary

let read filename =
	let
    f = open_in filename and
    str = ref ""
  in
    (try
      while true do str := !str ^ input_line f ^ "\n" done;
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

let checkDuplication =
  let rec inner checked = function
    | [] -> ()
    | ExportDef (loc, (_, name), _) :: tail ->
        if List.mem name checked
          then (print_endline @@ string_of_loc loc ^ ": Duplicate export `" ^ name ^ "`"; exit (-1))
          else inner (name :: checked) tail
  in
    inner []

let header = to_uint32 1836278016 @ to_uint32 1

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

let function_section ast =
  let num_functions = List.length ast in
    [ 3 (* section code *)
    ; num_functions + 1 (* section size *)
    ; num_functions (* num functions *)
    ] @
    List.init num_functions (fun _ -> 0 (* function 0 signature index *))

let memory =
  [ 5 (* section code *)
  ; 3 (* section size *)
  ; 1 (* num memories *)
  ; 0 (* limits: flags *)
  ; 1 (* limits: initial *)
  ]

let ( <.> ) f g x = f @@ g x

let concatMap f = List.(concat <.> map f)

let export stmt_ast =
  let export_sig =
    let export_func_index = ref (-1) in
    stmt_ast
      |> concatMap (function ExportDef (_, (_, name), _) ->
        export_func_index := !export_func_index + 1;
        String.length name :: (* string length *)
        (List.map Base.Char.to_int @@ Base.String.to_list name) @ (* export name *)
        [ 0 (* export kind *)
        ; !export_func_index
        ])
  in
  let num_exports = leb128_of_int @@ List.length stmt_ast in
    7 :: (* section code *)
    List.length export_sig + List.length num_exports :: (* section size *)
    num_exports @
    export_sig

let function_body expr_ast =
  let max = ref (-1) in
  let instructions = (Ir.bin_of_insts (Ir.insts_of_expr_ast expr_ast) max) @ [ 11 (* end *)] in
  let local_decl_count = !max + 1 in
  let decl =
    (if local_decl_count > 0
      then
        1 :: (* local decl count *)
        leb128_of_int local_decl_count @ (* local type count *)
        [127 (* i32 *)]
      else
        [0 (* local decl count *)]) @
    instructions in
  (leb128_of_int @@ List.length decl) @ decl

let code stmt_ast =
  let function_code =
    stmt_ast
      |> concatMap (function ExportDef (_, _, expr_ast) -> function_body expr_ast)
  in
  let num_functions = leb128_of_int @@ List.length stmt_ast in
    10 :: (* section code *)
    List.length num_functions + List.length function_code :: (* section size *)
    num_functions @
    function_code

let compile src =
  let ast = program src in
    checkDuplication ast;
    let out = open_out "out.wasm" in
      write out @@
        header
        @ type_header
        @ type_0
        @ function_section ast
        @ memory
        @ export ast
        @ code ast;
      close_out out

let syntax_error src loc =
  begin
    print_endline @@ List.nth (String.split_on_char '\n' src) loc.line;
    print_endline @@ String.make loc.chr ' ' ^ "^";
    print_endline @@ string_of_loc loc ^ ": Syntax Error"
  end

let repl () =
  while true do
    let input = read_line () in
    try
      if input = ":quit" || input = ":exit" then exit 0;
      compile @@ input;
      match Sys.command "wasm-interp --run-all-exports ./out.wasm" with
        | 0 -> ()
        | _ -> failwith "wasm-interp との連携に失敗しました"
    with
      Syntax_error loc ->
        syntax_error input loc
  done

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
      match Sys.argv.(1) with
        | "repl" ->
            repl ()
        | "make" ->
            if Array.length Sys.argv >= 3
              then
                let input = read @@ Sys.argv.(2) in
                try
                  compile input
                with
                  Syntax_error loc ->
                    begin
                      syntax_error input loc;
                      exit (-1)
                    end
              else
                (print_endline "Source files were not provided"; exit (-1))
        | str ->
            (print_endline @@ "Invalid subcommand: " ^ str; exit (-1))
