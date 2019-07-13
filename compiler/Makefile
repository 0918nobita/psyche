build:
	mkdir -p _build
	ocamlopt -c binary.mli parser_combinator.mli parser.mli ir.mli
	ocamlfind ocamlopt \
		-o _build/psyche \
		-linkpkg -package base \
		binary.ml parser_combinator.ml parser.ml ir.ml compiler.ml
	rm -f *.cmx *.o

clean:
	rm -rf _build
	rm -f *.cmi
