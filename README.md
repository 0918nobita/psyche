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
term = integer, { ("*" | "/"), integer }
expr = term, { ("+" | "-"), term }
```
