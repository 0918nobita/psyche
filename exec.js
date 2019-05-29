(async () => {
  const { instance } = await WebAssembly.instantiateStreaming(fetch('./out.wasm'));
  console.log(instance.exports.main());
})();
