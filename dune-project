(lang dune 3.7)

(name psyche)

(generate_opam_files true)

(source
 (github 0918nobita/psyche))

(authors "0918nobita <nobita.0918@gmail.com>")

(maintainers "0918nobita <nobita.0918@gmail.com>")

(license MIT)

(documentation https://github.com/0918nobita/psyche)

(package
 (name psyche)
 (synopsis "A WASM-friendly lightweight programming language")
 (description "A WASM-friendly lightweight programming language implemented in OCaml")
 (depends ocaml dune)
 (tags (wasm programming-language)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
