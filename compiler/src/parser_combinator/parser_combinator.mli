val ( <.> ) : ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b

type 'a parser = MParser of (string -> ('a * string) list)

val parse : 'a parser -> string -> ('a * string) list

val token : string -> string parser

val ( <*> ) : ('a -> 'b) parser -> 'a parser -> 'b parser

val ( <$> ) : ('a -> 'b) -> 'a parser -> 'b parser

val return : 'a -> 'a parser

val satisfy : (char -> bool) -> char parser

val char : char -> char parser

val ( >>= ) : 'a parser -> ('a -> 'b parser) -> 'b parser

val ( >> ) : 'a parser -> 'b parser -> 'b parser

val ( <|> ) : 'a parser -> 'a parser -> 'a parser

val oneOf : string -> char parser

val option : 'a -> 'a parser -> 'a parser

val many : 'a parser -> 'a list parser

val some : 'a parser -> 'a list parser lazy_t
