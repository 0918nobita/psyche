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

let () =
  let src = read @@ Sys.argv.(1) in
    match Parser.integer src 0 with
      | Success ([Ast (IntLiteral n)], _, p) when p = String.length src ->
          print_int n
      | _ -> failwith "Syntax Error"

(*let make_list n len = Array.to_list @@ Array.make n len

let adjust_str_length size str =
  let lack = String.length str mod size in
    if lack = 0
      then str
      else String.make (size - lack) '0' ^ str

let write f n size =
  let
    adjust_arr_length arr size =
      let lack = size - List.length arr in
        if lack = 0
          then arr
          else
            if lack > 0
              then arr @ make_list lack 0
              else failwith "(adjust_arr_length) Invalid format" and
    base = List.rev
      @@ List.map
        (fun hex -> int_of_string @@ "0x" ^ hex)
        @@ split 2
        @@ adjust_str_length 2
        @@ Printf.sprintf "%X" n
  in
    List.iter (fun byte -> output_byte f byte) @@ adjust_arr_length base size

let write_uint32 f n = write f n 4;;

let write_hexs f hexs = List.iter (fun hex -> output_byte f  @@ int_of_string @@ "0x" ^ hex) hexs

let write_header f =
  write_uint32 f 1836278016;
  write_uint32 f 1

let write_type_header f =
  output_byte f 1; (* section code *)
  output_byte f 5; (* section size *)
  output_byte f 1 (* num types *)

let write_type f =
  output_byte f 96; (* func *)
  output_byte f 0; (* num params *)
  output_byte f 1; (* num results *)
  output_byte f 127 (* i32 *)

let write_function_header f =
  output_byte f 3; (* section code *)
  output_byte f 2; (* section size *)
  output_byte f 1; (* num functions *)
  output_byte f 0 (* function 0 signature index *)

let write_export f =
  output_byte f 7; (* section code *)
  output_byte f 8; (* section size *)
  output_byte f 1; (* num exports *)
  output_byte f 4; (* string length *)
  write_hexs f [
    "6d"; "61"; "69"; "6e"; (* main ; export name *)
  ];
  output_byte f 0; (* export kind *)
  output_byte f 0 (* export func index *)

let write_code_header f leb128 =
  output_byte f 10; (* section code *)
  output_byte f @@ 5 + List.length leb128; (* section size *)
  output_byte f 1 (* num functions *)

let write_code f leb128 =
  output_byte f @@ 3 + List.length leb128; (* func body size *)
  output_byte f 0; (* local decl count *)
  output_byte f 65; (* i32.const *)
  List.iter (output_byte f) leb128; (* i32 literal *)
  output_byte f 11 (* end *)
*)
