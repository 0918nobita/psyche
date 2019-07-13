(async () => {
  const memory = new WebAssembly.Memory({ initial: 1 });

  const consoleLogString = (offset, length) => {
    console.log({ offset, length });
    const bytes = new Uint8Array(memory.buffer, offset, length);
    const string = new TextDecoder('utf8').decode(bytes);
    console.log(string);
  };

  const importObject = { env: { log: consoleLogString, mem: memory } };
  const { instance } = await WebAssembly.instantiateStreaming(fetch('./string.wasm'), importObject);
  instance.exports.main();
})();
