var fs = require("fs");
var src = "C:/Codex_App_Factory/harness/runs/dry15-mini-catalog-search-performance-app/canonical-integrated/src";
var files = fs.readdirSync(src).filter(function(f) { return f.endsWith(".js"); });
files.forEach(function(f) {
    var c = fs.readFileSync(src + "/" + f, "utf8");
    var reqs = c.match(/require\(/g);
    if (reqs) console.log(f + ": " + reqs.length + " requires");
});
