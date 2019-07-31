(async () => {
  const mem = new WebAssembly.Memory({ initial: 1 });
  const log = (n) => console.log(n);
  const importObject = { env: { mem, log } };
  const { instance } =
    await WebAssembly.instantiateStreaming(
      fetch('./linked-list.wasm'),
      importObject);
  try {
    instance.exports.main();
  } catch (e) {
    console.error('panic', instance.exports.status.value);
  }
})();
