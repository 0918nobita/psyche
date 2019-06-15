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

## Proposals

### Comments

```text
(* comment *)
```

### Constants

```text
const a = if 1 + 2 * 3 > 5 then 7 else 9
```

### Let Expressions

```text
let
  n = 3
in
  4 + n
```

### Progn

Use ``;`` as delimiter of multiple expressions evaluated in order.

```text
1 + 2; 3 - 4; 5 * 6
```

### Functions

#### Function definitions

The type annotations of parameters and return value are required.

```text
fn square(n: i32): i32 = n * n

fn add(x: i32, y: i32): i32 = x + y
```

Anonymous functions:

```text
const square = (n: i32): i32 => n * n

const add = (x: i32, y: i32): i32 => x + y
```

#### Funcall

```text
fn foo(): i32 =
  let
    side = 7
  in
    square(side)  (* --> 49 *)

fn add3(n: i32): i32 = add(3, n)
```

### Exports

```
pub fn double(n: i32): i32 = 2 * n
```
