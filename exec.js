(async () => {
  const result = await WebAssembly.instantiateStreaming(fetch('./out.wasm'));
})();
