open Parser

let rec split size str =
  if size < 1
    then
      failwith "(split) Invalid size"
    else
      match str with
        | "" -> []
        | s ->
          let len = String.length s in
            if len >= size
              then
                (split size @@ String.sub s 0 (len - size))
                @ [String.sub s (len - size) size]
              else
                failwith "(split) Invalid format"

let make_list n len = Array.to_list @@ Array.make n len

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

let bin_of_int size = function
  | 0 -> "0"
  | n ->
      let rec conv = function
        | (0, bin) -> (0, bin)
        | (decimal, bin) ->
            conv (decimal / 2, (string_of_int @@ decimal mod 2) ^ bin)
      in
        let (_, bin) = conv (n, "") in
        let lack = size - String.length bin in
          if lack >= 0
            then String.make lack '0' ^ bin
            else failwith "(bin_of_int) Overflow"

let rec chars_of_string = function
  | "" -> []
  | s -> String.get s 0 :: (chars_of_string @@ String.sub s 1 (String.length s - 1))

let int_of_bin bin =
  let chars = List.rev @@ chars_of_string bin in
    List.fold_left (fun acc sum -> sum + acc) 0 @@
      List.mapi (fun i c -> if c = '1' then int_of_float @@ 2. ** (float_of_int i) else 0) chars

let twos_complement size bin =
  bin_of_int size @@ 1 + int_of_bin (String.map (function '0' -> '1' | '1' -> '0' | c -> c) bin)

let leb128_of_int n =
  List.rev @@
    List.mapi
      (fun i bin -> int_of_string @@ "0b" ^ (if i = 0 then "0" else "1") ^ bin)
      @@ split 7
      @@ if n >= 0
        then
          adjust_str_length 7 @@ bin_of_int 32 n
        else
          adjust_str_length 7 @@ twos_complement 32
          @@ bin_of_int 32 @@ (-1) * n

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
  let src = read Sys.argv.(1) in
  let result = integer src 0 in
    match result with
      | Failure -> failwith "(1) Syntax Error"
      | Success (ast_list, _, p) ->
          match ast_list with
            | [Ast (IntLiteral n)] ->
                let
                  out = open_out "out.wasm" and
                  leb128 = leb128_of_int n
                in
                  List.iter print_int leb128;
                  write_header out;
                  write_type_header out;
                  write_type out;
                  write_function_header out;
                  write_export out;
                  write_code_header out leb128;
                  write_code out leb128;
                  close_out out;
            | _ -> failwith "(2) Syntax Error"
