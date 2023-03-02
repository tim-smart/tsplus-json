const stdin = process.stdin;
const inputChunks = [];

stdin.setEncoding("utf8");
stdin.resume();

stdin.on("data", function (chunk) {
  inputChunks.push(chunk);
});

stdin.on("end", function () {
  const inputJSON = inputChunks.join();
  const parsedData = JSON.parse(inputJSON);
  process.stdout.write(parsedData[0].tarball_url);
});
