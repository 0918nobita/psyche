let substr str start len =
  let str_len = String.length str in
    if str_len >= start + len then Some (String.sub str start len) else None

(* Function Composition *)
let ( <.> ) f g x = f @@ g x

let concatMap f = List.(concat <.> map f)

type location = { line : int; chr : int }

let string_of_loc loc = string_of_int (loc.line + 1) ^ ":" ^ string_of_int (loc.chr + 1)

type 'a result = { ast : 'a; loc : location; rest : string }

type 'a parser = MParser of (string -> 'a result list)

let parse (MParser p) = p

let rec last = function
  | [] -> failwith "empty list"
  | [x] -> x
  | _ :: tail -> last tail

let token tok =
  let length = String.length tok in
  MParser (fun src ->
      match substr src 0 length with
        | Some cut when cut = tok ->
          let lines = String.split_on_char '\n' tok in
          [{
            ast = cut;
            loc = { line = List.length lines - 1;
                    chr = String.length @@ last lines };
            rest = String.sub src length (String.length src - length)
          }]
        | _ -> [])

let update_loc base diff = {
  line = base.line + diff.line;
  chr = if diff.line >= 1 then diff.chr else base.chr + diff.chr
}

let ( <*> ) precede succeed =
  MParser (fun src ->
    parse precede src
    |> concatMap (function { ast = f; loc = precede_loc; rest = str } ->
      parse succeed str
      |> List.map (function { ast; loc = succeed_loc; rest = str'} ->
        {
          ast = f ast;
          loc = update_loc precede_loc succeed_loc;
          rest = str'
        })))

let ( <$> ) f p = MParser (fun src ->
  List.map (function { ast; loc; rest } ->
    { ast = f ast; loc; rest }) @@ (parse p) src)

let return ast = MParser (fun rest -> [{ ast; rest; loc = { line = 0; chr = 0 }}])

let start_from base_loc p =
  MParser (fun src ->
    parse p src
    |> List.map (function { ast; loc; rest } ->
      { ast; loc = update_loc base_loc loc; rest }))

let ( >>= ) p f =
  MParser (fun src ->
    parse p src
    |> concatMap (function { ast; loc = base_loc; rest } ->
      parse (start_from base_loc (f ast)) rest))

let ( >> ) m f = m >>= fun _ -> f

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

let satisfy f = item >>= (fun ast -> if f ast then return ast else mzero)

let char c = satisfy ((==) c)

let oneOf cs = satisfy (String.contains cs)

let option default p = p <|> return default

let (<~>) p q = p >>= fun r -> q >>= fun rs -> return (r :: rs)

let rec many p = option [] (p >>= fun r -> many p >>= fun rs -> return (r :: rs))

let some p = lazy (p <~> many p)
