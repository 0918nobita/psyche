(async () => {
  const result = await WebAssembly.instantiateStreaming(fetch('./out.wasm'));
  console.log(result.instance.exports.main());
})();
