(async () => {
  const mem = new WebAssembly.Memory({ initial: 1 });
  const importObject = { env: { mem } };
  const { instance } = await WebAssembly.instantiateStreaming(fetch('./malloc.wasm'), importObject);
  instance.exports.main();
})();
