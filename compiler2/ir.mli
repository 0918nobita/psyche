type instruction

val insts_of_expr_ast : Parser.expr_ast -> instruction list

val bin_of_insts : instruction list -> int ref -> int list