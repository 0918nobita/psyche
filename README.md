# Psyche

A WASM friendly lightweight programming language implemented in OCaml

## Build

```bash
make build
```

## Test

```bash
dune exec psyche test/example.psy
```

## EBNF

```
non_zero_digit = "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
zero = "0"
digit = zero | non_zero_digit
integer = ["+" | "-"], (zero | (non_zero_digit, { digit }))
factor = integer | if_expr | ("(", logical_expr_or, ")")
term = factor, { ("*" | "/"), factor }
arithmetic_expr = term, { ("+" | "-"), term }
comparison_expr = arithmetic_expr, { ("==" | "!=" | "<" | "<=" | "=>" | ">"), arithmetic_expr }
logical_expr_and = comparison_expr, { "&&", comparison_expr }
logical_expr_or = logical_expr_and, { "||", logical_expr_and }
if_expr = "if", logical_expr_or, "then", logical_expr_or, "else", logical_expr_or
program = logical_expr_or
```

## Code Example

```text
1 + 2 * if 3 < 0 then 4 else 5 + 6
```

