open Parser

type instruction =
  | I32Const of int
  | I32Add
  | I32Sub
  | I32Mul
  | I32DivS
  | I32Eq
  | I32Ne
  | I32Gt
  | I32Ge
  | I32Lt
  | I32Le
  | I32Eqz
  | I32If of instruction list * instruction list
  | I32Local of instruction list
  | TeeLocal of int
  | GetLocal of int
  | I32Load
  | I32Store

let insts_of_expr_ast ast =
  let rec inner (expr_ast, env) = match expr_ast with
    | IntLiteral n -> [I32Const n]
    | Minus (expr) ->
        inner (expr, env) @ [I32Const (-1); I32Mul]
    | Add (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Add]
    | Sub (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Sub]
    | Mul (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Mul]
    | Div (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32DivS]
    | Eq (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Eq]
    | Ne (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Ne]
    | Greater (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Gt]
    | GreaterE (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Ge]
    | Less (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Lt]
    | LessE (lhs, rhs) ->
        inner (lhs, env) @ inner (rhs, env) @ [I32Le]
    | And (lhs, rhs) ->
        inner (lhs, env) @ [I32Eqz; I32If ([I32Const 0], inner (rhs, env))]
    | Or (lhs, rhs) ->
        inner (lhs, env) @ [I32Local [TeeLocal 0; I32Eqz; I32If (inner (rhs, env), [GetLocal 0])]]
    | If (cond, t, e) ->
        inner (cond, env) @ [I32Eqz; I32If (inner (e, env), inner (t, env))]
    | Let (ident, bound_expr, expr) ->
        let reserved_addr = snd env + 1 in
        let env_for_bound_expr = (fst env, reserved_addr) in
        let env_for_expr = ((ident, reserved_addr) :: fst env, reserved_addr) in
          I32Const (reserved_addr * 4) ::
          inner (bound_expr, env_for_bound_expr) @
          [I32Store] @
          inner (expr, env_for_expr)
    | Ident name ->
        let addrs =
          fst env
            |> List.filter (fun elem -> fst elem = name)
            |> List.map snd
        in
          if List.length addrs = 0
            then (print_endline @@ "Error: unbound value `" ^ name ^ "`"; exit (-1))
            else [I32Const (List.hd addrs * 4); I32Load]
  in
    inner (ast, ([], -1))

let bin_of_insts irs max =
  let rec inner (irs, current, max) = match irs with
    | [] -> []
    | I32Const n :: tail ->
        65 :: Binary.leb128_of_int n @
        inner (tail, current, max)
    | I32Add :: tail ->
        106 :: inner (tail, current, max)
    | I32Sub :: tail ->
        107 :: inner (tail, current, max)
    | I32Mul :: tail ->
        108 :: inner (tail, current, max)
    | I32DivS :: tail ->
        109 :: inner (tail, current, max)
    | I32Eq :: tail ->
        70 :: inner (tail, current, max)
    | I32Ne :: tail ->
        71 :: inner (tail, current, max)
    | I32Gt :: tail ->
        74 :: inner (tail, current, max)
    | I32Ge :: tail ->
        78 :: inner (tail, current, max)
    | I32Lt :: tail ->
        72 :: inner (tail, current, max)
    | I32Le :: tail ->
        76 :: inner (tail, current, max)
    | I32Eqz :: tail ->
        69 :: inner (tail, current, max)
    | I32If (t, e) :: tail ->
        4 (* if *) ::
        127 (* i32 *) ::
        inner (t, current, max) @
        [ 5 (* else *)
        ] @
        inner (e, current, max) @
        [ 11 (* end*)
        ] @
        inner (tail, current, max)
    | I32Local inner_irs :: tail ->
        (if !max = current
          then
            (max := !max + 1;
            inner (inner_irs, current + 1,  max))
          else inner (inner_irs, current + 1, max)) @
        inner (tail, current, max)
    | TeeLocal n :: tail ->
        34 :: Binary.leb128_of_int (n + current) @
        inner (tail, current, max)
    | GetLocal n :: tail ->
        32 :: Binary.leb128_of_int (n + current) @
        inner (tail, current, max)
    | I32Load :: tail ->
        40 :: (* opcode *)
        2 :: (* alignment *)
        0 :: (* load offset *)
        inner (tail, current, max)
    | I32Store :: tail ->
        54 :: (* opcode *)
        2 :: (* alignment *)
        0 :: (* store offset *)
        inner (tail, current, max)
  in
    inner (irs, -1, max)
