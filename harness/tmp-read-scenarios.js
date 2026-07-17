const fs = require("fs");
const ar = fs.readFileSync("C:/Codex_App_Factory/harness/runs/dry20-vendor-procurement-risk-app/canonical-integrated/src/acceptance-runner.js","utf8");
const ids = ["V04","V05","V06","P02","P03","P06","P07","P10","I02","I03","I04","I07","I08","A02","A03","A04","A05"];
ids.forEach(id => {
  const search = id + "\x27,";
  const idx = ar.indexOf(search);
  if(idx >= 0) {
    const end = Math.min(ar.length, idx + 450);
    const snippet = ar.substring(idx, end);
    const close = snippet.indexOf("});  scenario(");
    const text = close > 0 ? snippet.substring(0, close) : snippet.substring(0, 350);
    console.log("--- " + id + " ---");
    console.log(text);
    console.log("");
  }
});