val ( <.> ) : ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b

type location = { line : int; chr : int }

val string_of_loc : location -> string

type 'a result = { ast : 'a; loc : location; rest : string }

type 'a parser = MParser of (string -> 'a result list)

val parse : 'a parser -> string -> 'a result list

val token : string -> string parser

val ( <*> ) : ('a -> 'b) parser -> 'a parser -> 'b parser

val ( <$> ) : ('a -> 'b) -> 'a parser -> 'b parser

val return : 'a -> 'a parser

val satisfy : (char -> bool) -> char parser

val char : char -> char parser

val ( >>= ) : 'a parser -> (loc:location -> 'a -> 'b parser) -> 'b parser

val ( >> ) : 'a parser -> (location -> 'b parser) -> 'b parser

val ( <|> ) : 'a parser -> 'a parser -> 'a parser

val oneOf : string -> char parser

val option : 'a -> 'a parser -> 'a parser

val many : 'a parser -> 'a list parser

val some : 'a parser -> 'a list parser lazy_t
