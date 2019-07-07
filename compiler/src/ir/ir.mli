type ir

val ir_of_ast : Parser.expr_ast -> ir list

val instructions_of_ir : ir list -> int ref -> int list
