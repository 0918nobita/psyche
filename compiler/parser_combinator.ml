type location = { line : int; chr : int }

let string_of_loc loc = string_of_int (loc.line + 1) ^ ":" ^ string_of_int (loc.chr + 1)

let plus_loc base diff = {
  line = base.line + diff.line;
  chr = if diff.line >= 1 then diff.chr else base.chr + diff.chr
}

type 'a result = { ast : 'a; loc : location ; rest : string }

type 'a parser = Parser of (location * string -> 'a result list)

let parse (Parser p) = p

let substr str start len =
  let str_len = String.length str in
    if str_len >= start + len
      then Some (String.sub str start len)
      else None

let rec last = function
  | [] -> failwith "empty list"
  | [x] -> x
  | _ :: tail -> last tail

let token tok =
  let length = String.length tok in
  Parser (fun (loc, src) ->
    match substr src 0 length with
      | Some cut when cut = tok ->
          let lines = String.split_on_char '\n' tok in
          [{
            ast = (loc, cut);
            loc = plus_loc loc {
              line = List.length lines - 1;
              chr = String.length @@ last lines
            };
            rest = String.sub src length (String.length src - length)
          }]
      | _ -> [])

let ( <$> ) f p = Parser (fun input ->
  List.map (function { ast; loc; rest } ->
    { ast = f ast; loc; rest }) @@ (parse p) input)

let concatMap f list = List.(concat @@ map f list)

let ( <*> ) precede succeed =
  Parser (fun input ->
    parse precede input
    |> concatMap (function { ast = f; loc = precede_loc; rest } ->
      parse succeed (precede_loc, rest)
      |> List.map (function { ast; loc = _; rest = _ } as result ->
        { result with ast = f ast })))

let return ast = Parser (fun (loc, rest) -> [{ ast; loc; rest }])

let ( >>= ) p f =
  Parser (fun input ->
    parse p input
    |> concatMap (function { ast; loc; rest} ->
      parse (f ast) (loc, rest)))

let ( >> ) m f = m >>= fun _ -> f

(*
let mzero = MParser (fun _ -> [])

let ( <|> ) p q =
  MParser (fun src ->
    let result = parse p src in
      if List.length result = 0
        then parse q src
        else result)

let item = MParser (function
  | "" -> []
  | s  ->
    let c = String.(get (sub s 0 1) 0) in
    [{
      ast = c;
      loc =
        if c = '\n'
          then { line = 1; chr = 0 } 
          else { line = 0; chr = 1 };
      rest = String.(sub s 1 (length s - 1))
    }])

let satisfy f = item >>= (fun ~loc:_ ast -> if f ast then return ast else mzero)

let char c = satisfy ((==) c)

let oneOf cs = satisfy (String.contains cs)

let option default p = p <|> return default

let (<~>) p q = p >>= fun ~loc:_ r -> q >>= fun ~loc:_ rs -> return (r :: rs)

let rec many p = option [] (p >>= fun ~loc:_ r -> many p >>= fun ~loc:_ rs -> return (r :: rs))

let some p = lazy (p <~> many p)
*)
