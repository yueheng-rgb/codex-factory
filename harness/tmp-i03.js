const fs = require("fs");
const ar = fs.readFileSync("C:/Codex_App_Factory/harness/runs/dry20-vendor-procurement-risk-app/canonical-integrated/src/acceptance-runner.js","utf8");
const idx = ar.indexOf("I03\x27,");
const snippet = ar.substring(idx, idx + 700);
const match = snippet.match(/}\);  scenario\(/);
console.log(match ? snippet.substring(0, match.index) : snippet);