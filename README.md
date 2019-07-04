# Psyche

A WASM friendly lightweight programming language implemented in OCaml

## Structure

- compiler ( ``compiler/`` ) : The Psyche compiler
- ir ( ``compiler/src/ir/`` ) : Intermediate representation and its converters
- parser ( ``compiler/src/parser/`` )
- parser_combinator ( ``compiler/src/parser_combinator/`` ) : Monadic parser combinator
- binary ( ``compiler/src/binary/`` ) : Toolkit for outputting little-endian binary
- knights ( ``compiler/src/knights/`` ) : Toolkit for snapshot testing / performance reporting
