const fs = require('fs');

const source = fs.readFileSync('./out.wasm');
const typedArray = new Uint8Array(source);

const env = {
  log(n) {
    console.log(n);
    return n;
  }
};

WebAssembly.instantiate(typedArray, { env }).then(result => {
  result.instance.exports.main();
});
