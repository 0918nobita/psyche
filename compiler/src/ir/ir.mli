type instruction

val instructions_of_ast : Parser.expr_ast -> instruction list

val bin_of_instructions : instruction list -> int ref -> int list
