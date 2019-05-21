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

let code_header leb128 =
  [ 10 (* section code *)
  ; 5 + List.length leb128 (* section size *)
  ; 1  (* num functions *)
  ]

let code leb128 =
  [ 3 + List.length leb128 (* func body size *)
  ; 0  (* local decl count *)
  ; 65 (* i32.const *)
  ] @
  leb128 @
  [ 11 (* end *)
  ]

let () =
  let src = read @@ Sys.argv.(1) in
    match Parser.integer src 0 with
      | Success ([Ast (IntLiteral n)], _, p) when p = String.length src ->
          let
            out = open_out "out.wasm" and
            leb128 = Binary.leb128_of_int n
          in
            write out @@
              header
              @ type_header
              @ type_0
              @ function_header
              @ export
              @ code_header leb128
              @ code leb128;
            close_out out
      | _ -> failwith "Syntax Error"
