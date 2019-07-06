clang --target=wasm32-unknown-wasi --sysroot /opt/wasi-sysroot -s -o hello.wasm ./hello.c
lucetc --bindings bindings.json -o hello.o hello.wasm
lucet-wasi hello.o
