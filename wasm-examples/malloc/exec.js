(async () => {
  const memory = new WebAssembly.Memory({ initial: 1 });

  const importObject = {
    env: {
      log(n) { console.log(n); },
      mem: memory
    }
  };
  const { instance } = await WebAssembly.instantiateStreaming(fetch('./malloc.wasm'), importObject);
  console.log("result", instance.exports.main());
})();
