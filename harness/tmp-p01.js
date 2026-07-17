const fs = require("fs");
const ar = fs.readFileSync("C:/Codex_App_Factory/harness/runs/dry20-vendor-procurement-risk-app/canonical-integrated/src/acceptance-runner.js","utf8");
const ids = ["P01","P08","P09","V01","V03"];
ids.forEach(id => {
  const search = id + "\x27,";
  const idx = ar.indexOf(search);
  if(idx >= 0) {
    const end = Math.min(ar.length, idx + 400);
    const snippet = ar.substring(idx, end);
    const close = snippet.indexOf("});  scenario(");
    console.log("--- " + id + " ---");
    console.log(close > 0 ? snippet.substring(0, close) : snippet.substring(0, 350));
    console.log("");
  }
});