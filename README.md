# Psyche

A WASM friendly lightweight programming language implemented in OCaml

## Building

In order to build the Psyche compiler, ensure that you have Git and OPAM installed.

Clone a copy of the repo:

```bash
git clone https://github.com/0918nobita/psyche
```

Change to the Psyche compiler directory:

```bash
cd psyche/compiler
```

Install dev dependencies:

```bash
opam install . --deps-only
```

Build the compiler :

```bash
make  # produces _build/psyche (executable file)
```

## REPL

```bash
psyche repl
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
