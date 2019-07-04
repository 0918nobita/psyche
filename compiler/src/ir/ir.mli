type ir

val ir_of_ast : Parser.ast -> ir list

val instructions_of_ir : ir list * int * int ref -> int list
