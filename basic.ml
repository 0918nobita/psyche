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

let write_header f = 
  List.iter
      (fun hex -> output_byte f @@ int_of_string @@ "0x" ^ hex)
      ["00"; "61"; "73"; "6d"; "01"; "00"; "00"; "00"]

let () =
  let
    f = open_out "out.wasm"
  in
    write_header f;
    close_out f
