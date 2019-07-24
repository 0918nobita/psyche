build:
	ocamlopt -o test test.ml
	rm test.cmi test.cmx test.o

test: build
	./test

clean:
	rm -f test tmp result out.wasm
