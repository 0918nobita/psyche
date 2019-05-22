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

let code literals =
  let
    instructions = ref [] and
    first = Binary.leb128_of_int @@ List.nth literals 0
  in
    List.iteri
      (fun i literal ->
        if i != 0
          then instructions := !instructions @
            65 (* i32.const *)
            :: Binary.leb128_of_int literal @ (* i32 literal *)
            [ 106 (* i32.add *)
            ])
      literals;
    let embedded_data_length = List.length first + List.length !instructions in
      [ 10 (* section size *)
      ; 5 + embedded_data_length
      ; 1 (* num functions *)
      ] @
      [ 3 + embedded_data_length (* func body size *)
      ] @
      [ 0 (* local decl count *)
      ; 65 (* i32.const *)
      ] @
      first @
      !instructions @
      [ 11 (* end *)
      ]

open Parser

let () =
  let src = read @@ Sys.argv.(1) in
  let rec literal_list_of_ast = function
    | [] -> []
    | Parser.Ast (IntLiteral n) :: tail -> n :: literal_list_of_ast tail
    | _ -> failwith "Invalid format"
  in
    match many_integers src 0 with
      | Success (ast, _, p) when p = String.length src ->
          let
            out = open_out "out.wasm" and
            literals = literal_list_of_ast ast
          in
            write out @@
              header
              @ type_header
              @ type_0
              @ function_header
              @ export
              @ code literals;
            close_out out
      | _ -> failwith "Syntax Error"
