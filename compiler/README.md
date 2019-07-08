# The Psyche compiler

## Build

```bash
make build
```

## Run tests

```bash
dune runtest
```

## REPL

```bash
dune exec psyche repl
export foo = 1 + 2
foo() => i32:3
export bar = 2 * 4 - 1
bar() => i32:7
export baz = 2 * if 2 > 0 then 3 else 4 + 5
baz() => i32:6
...
```

### Commands

`:quit`, `:exit` : Exit the REPL

## Test

```bash
dune exec psyche make test/example.psy
```

## EBNF

```
comment = "(*", <STRING?>, "*)"
non_zero_digit = "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
zero = "0"
digit = zero | non_zero_digit
integer = ["+" | "-"], (zero | (non_zero_digit, { digit }))
letter = "a" | "b" | "c" | ... | "z" | "A" | "B" | "C" | ... | "Z"
identifier = letter, { letter | digit }
factor = integer | identifier | if_expr | ("(", logical_expr_or, ")") | let_expr
term = factor, { ("*" | "/"), factor }
arithmetic_expr = term, { ("+" | "-"), term }
comparison_expr = arithmetic_expr, { ("==" | "!=" | "<" | "<=" | "=>" | ">"), arithmetic_expr }
logical_expr_and = comparison_expr, { "&&", comparison_expr }
logical_expr_or = logical_expr_and, { "||", logical_expr_and }
if_expr = "if", logical_expr_or, "then", logical_expr_or, "else", logical_expr_or
let_expr = "let", identifier, "=", logical_expr_or, "in", logical_expr_or
statement = "export", identifier, "=", logical_expr_or
program = { statement }
```

## Code Example

```text
export main = 1 + 2 * if 3 < 0 then 4 else 5 + 6
```

## Proposals

### Comments

```text
(* comment *)
```

### Constants

#### Code example

```text
const a = if 1 + 2 * 3 > 5 then 7 else 9
```

#### Syntax

```text
"const", symbol, "=", logical_expr_or
```

#### Semantics

This statement defines a constant named ``symbol``.  
The value is assigned when the program is initialized.  
Reassigning to the constant is forbidden.  
This feature will be implemented using global variables of WASM.

### Let Expressions

```text
let
  n = 3
in
  4 + n
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

### Dependent Types

inspired by Idris
