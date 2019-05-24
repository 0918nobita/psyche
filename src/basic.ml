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

open Parser.AST

let code ast =
  let rec gen_instructions base = function
    | IntLiteral n -> base := !base @ 65 :: Binary.leb128_of_int n 
    | Add (lhs, rhs) -> gen_instructions base lhs; gen_instructions base rhs; base := !base @ [106]
    | Sub (lhs, rhs) -> gen_instructions base lhs; gen_instructions base rhs; base := !base @ [107]
    | Mul (lhs, rhs) -> gen_instructions base lhs; gen_instructions base rhs; base := !base @ [108]
    | Div (lhs, rhs) -> gen_instructions base lhs; gen_instructions base rhs; base := !base @ [109]
  in
  let
    instructions = ref []
  in
    gen_instructions instructions ast;
    let embedded_data_length = List.length !instructions in
      [ 10 (* section code *)
      ; 4 + embedded_data_length (* section size *)
      ; 1 (* num functions *)
      ] @
      [ 2 + embedded_data_length (* func body size *)
      ] @
      [ 0 (* local decl count *)
      ] @
      !instructions @
      [ 11 (* end *)
      ]

open Parser

let () =
  let src = read @@ Sys.argv.(1) in
    match expr () src 0 with
      | Success ([Ast ast], _, p) when p = String.length src ->
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
      | _ -> failwith "Syntax Error"
