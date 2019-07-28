# Psyche

[![CircleCI](https://circleci.com/gh/0918nobita/psyche.svg?style=svg)](https://circleci.com/gh/0918nobita/psyche)

A WASM friendly lightweight programming language implemented in OCaml

## Usage

```text
psyche <command> [<args>]
```

Commands:

- ``make`` : Compile a source file specified by the command line argument.

### ``make`` sub command

``example.psy`` :

```text
pub fn main() {
  fib(7)  (* => 13 *)
}

fn fib(n) {
  if n == 0 || n == 1
    then n
    else fib(n - 1) + fib(n - 2)
}
```

Compile command :

```bash
psyche make example.psy  # produces out.wasm
```

## Building

In order to build the Psyche compiler, ensure that you have Git and OPAM installed.

Clone a copy of the repo :

```bash
git clone https://github.com/0918nobita/psyche
```

Install dev dependencies :

```bash
opam install . --deps-only
```

Build the compiler :

```bash
make  # produces compiler/_build/psyche (executable file)
```

## Testing

In order to run tests, ensure that you have [WABT](https://github.com/WebAssembly/wabt) installed.

```bash
make test
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

if_expr = "if", logical_expr_or, "then", logical_expr_or, "else", logical_expr_or

let_expr = "let", identifier, "=", logical_expr_or, "in", logical_expr_or

funcall = identifier, "(", [ logical_expr_or, { ",", logical_expr_or } ], ")"

list_literal = "[", [ logical_expr_or, { ";", logical_expr_or } ], "]"

factor1 = integer | funcall | list_literal | ("(", logical_expr_or, ")") | if_expr | let_expr | identifier

factor2 = factor1, [ ".", "(", logical_expr_or, ")" ]

term = factor2, { ("*" | "/"), factor2 }

arithmetic_expr = term, { ("+" | "-"), term }

comparison_expr = arithmetic_expr, { ("==" | "!=" | "<" | "<=" | "=>" | ">"), arithmetic_expr }

logical_expr_and = comparison_expr, { "&&", comparison_expr }

logical_expr_or = logical_expr_and, { "||", logical_expr_and }

func_def = ["pub"], "fn", identifier, "(", [ identifier, { ",", identifier } ], ")", "{", logical_expr_or, "}"

program = { func_def }
```

## Reference

- [WebAssembly Specification](https://webassembly.github.io/spec/core/index.html)
- [WebAssembly Reference Manual](https://github.com/sunfishcode/wasm-reference-manual/blob/master/WebAssembly.md)
