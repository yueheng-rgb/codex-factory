var fs = require("fs");
var path = require("path");
var s = "C:/Codex_App_Factory/harness/runs/dry15-mini-catalog-search-performance-app/canonical-integrated/src";
var files = fs.readdirSync(s).filter(function(x){return x.endsWith(".js")});
var t = 0;
files.forEach(function(x){
    var c = fs.readFileSync(path.join(s,x),"utf8");
    var d = c.match(/exports\.(\w+)\s*=/g);
    var dc = d ? d.length : 0;
    var m = c.match(/module\.exports\s*=\s*\{([^}]+)\}/);
    var mc = 0;
    if(m) mc = m[1].split(",").filter(function(s){return s.trim()}).length;
    var se = c.match(/module\.exports\s*=\s*\w+\s*[;{]?/);
    if(se && !m) mc = 1;
    t += Math.max(dc, mc);
});
console.log(t);
