type ast = Token of string | IntLiteral of int

type result = Success of (ast list * string * int) | Failure

let substr str start len =
  let str_len = String.length str in
  if str_len >= start + len then Some (String.sub str start len) else None

let token str target position =
  let length = String.length str in
  match substr target position length with
  | Some cut ->
      if cut = str then Success ([Token str], target, position + length)
      else Failure
  | None ->
      Failure

let many parser target position =
  let rec many_inner parser target position ast_list =
    match parser target position with
    | Success (ast, str, p) ->
        many_inner parser str p @@ ast_list @ ast
    | Failure ->
        Success (ast_list, target, position)
  in
  many_inner parser target position []

let rec choice parser_list target position =
  match parser_list with
  | parser :: rest ->
      let result = parser target position in
      if result = Failure then choice rest target position else result
  | [] ->
      Failure

let sequence parser_list target position =
  let rec sequence_inner parser_list target position ast_list =
    match parser_list with
    | parser :: rest -> (
      match parser target position with
      | Success (ast, str, p) ->
          sequence_inner rest str p @@ ast_list @ ast
      | Failure ->
          Failure )
    | [] ->
        Success (ast_list, target, position)
  in
  sequence_inner parser_list target position []

let option parser target position =
  let result = parser target position in
  if result = Failure then Success ([], target, position) else result

let non_zero_digit =
  choice
    [ token "1"
    ; token "2"
    ; token "3"
    ; token "4"
    ; token "5"
    ; token "6"
    ; token "7"
    ; token "8"
    ; token "9" ]

let digit = choice [token "0"; non_zero_digit]

let rec sublist b e = function
  | [] ->
      failwith "sublist"
  | h :: t ->
      let tail = if e = 0 then [] else sublist (b - 1) (e - 1) t in
      if b > 0 then tail else h :: tail

let integer target position =
  match
    sequence
      [option (choice [token "+"; token "-"]); non_zero_digit; many digit]
      target position
  with
  | Failure -> Failure
  | Success (ast_list, _, p) ->
      Success
        ( [ IntLiteral
              ( int_of_string
              @@ List.fold_left
                  (fun str -> function Token t -> str ^ t | _ -> failwith "integer" )
                  "" ast_list ) ]
        , target
        , p )

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

let write_code_header f =
  output_byte f 10; (* section code *)
  output_byte f 6; (* section size *)
  output_byte f 1 (* num functions *)

let write_code f =
  output_byte f 4; (* func body size *)
  output_byte f 0; (* local decl count *)
  output_byte f 65; (* i32.const *)
  output_byte f 42; (* i32.literal *)
  output_byte f 11 (* end *)

let bin_of_int = function
  | 0 -> "0"
  | n ->
      let rec conv = function
        | (0, bin) -> (0, bin)
        | (decimal, bin) ->
            conv (decimal / 2, (string_of_int @@ decimal mod 2) ^ bin)
      in
        let (_, bin) = conv (n, "") in bin

let rec chars_of_string = function
  | "" -> []
  | s -> String.get s 0 :: (chars_of_string @@ String.sub s 1 (String.length s - 1))

let () =
  let
    out = open_out "out.wasm"
  in
    write_header out;
    write_type_header out;
    write_type out;
    write_function_header out;
    write_export out;
    write_code_header out;
    write_code out;
    close_out out
