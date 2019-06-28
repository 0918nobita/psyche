let substr str start len =
  let str_len = String.length str in
    if str_len >= start + len then Some (String.sub str start len) else None

(* Function Composition *)
let ( <.> ) f g x = f @@ g x

let concatMap f = List.(concat <.> map f)


module Parser = struct
  type 'a parser = MParser of (string -> ('a * string) list)

  let parse (MParser p) = p

  let token tok =
    let length = String.length tok in
      MParser (fun src ->
          match substr src 0 length with
            | Some cut when cut = tok ->
                [(cut, String.sub src length (String.length src - length))]
            | _ ->
                [] )


  (* Functor *)

  let fmap f p =
    MParser (fun src ->
        List.map (fun (a, str) -> (f a, str)) @@ (parse p) src)


  (* Applicative *)

  let pure ast = MParser (fun src -> [(ast, src)])

  (** Sequential application *)
  let ( <*> ) precede succeed =
    MParser
      (fun src -> parse precede src
                  |> concatMap (fun (f, str) ->
                      parse succeed str
                      |> List.map (fun (ast, str') -> (f ast, str'))))

  let ( <$> ) = fmap


  (* Monad *)

  let return = pure

  (**
    Sequentially compose two actions,
    passing any value produced by the first as a argument to the second.
  *)
  let ( >>= ) p f =
    MParser
      (fun src -> parse p src
                  |> concatMap (fun (a, str) -> parse (f a) str))

  (**
    Sequentially compose two actions, discarding any value produced by the first,
    like sequencing operators (such as the semicolon) in imperative languages
  *)
  let ( >> ) m f = m >>= fun _ -> f


  (* Alternative - A monoid on applicative functors *)

  (** The identity of '<|>' *)
  let empty = MParser (fun _ -> [])

  (** An associative binary operation *)
  let ( <|> ) p q = MParser (fun src -> parse p src @ parse q src)


  (* MonadPlus - Monads that also support choice and failure *)
  let mzero = empty
  let mplus = (<|>)
end


let mparser =
  Parser.(token "a"
  >>= fun cut ->
  MParser (fun src ->
      let result = parse (token "b") src in
        List.map (fun (a, str) -> (cut ^ a, str)) result))

let item = Parser.(MParser (function
  | "" -> []
  | s  -> String.([(get (sub s 0 1) 0, sub s 1 (length s - 1))])))

let satisfy f = Parser.(item >>= (fun ast -> if f ast then return ast else mzero))

let char c = satisfy ((==) c)

let oneOf cs = satisfy (String.contains cs)

let d1 = Parser.(int_of_char <$> oneOf "123456789")

let d0 = Parser.(d1 <|> (int_of_char <$> char '0'))
