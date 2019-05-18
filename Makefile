build:
	ocamlopt parser_combinator.ml parser.ml basic.ml

clean:
	rm -f *.cmi *.cma *.cmx *.cmo *.o *.out *.wasm
