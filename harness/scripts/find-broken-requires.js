var fs = require("fs");
var path = require("path");
var src = "C:/Codex_App_Factory/harness/runs/dry15-mini-catalog-search-performance-app/canonical-integrated/src";
var files = fs.readdirSync(src).filter(function(f) { return f.endsWith(".js"); });

files.forEach(function(file) {
    var filepath = path.join(src, file);
    var content = fs.readFileSync(filepath, "utf8");
    
    // Find requires referencing worker directories
    var pattern = /require\(['"](\.\.\/[^'"]+)['"]\)/g;
    var match;
    var modified = false;
    while ((match = pattern.exec(content)) !== null) {
        console.log(file + ": " + match[1]);
        modified = true;
    }
    if (!modified) {
        // also check for direct cross-worker relative paths
        var absPattern = /require\(['"]([^'"]*worker-\d[^'"]*)['"]\)/g;
        while ((match = absPattern.exec(content)) !== null) {
            console.log(file + ": " + match[1] + " (cross-worker ref)");
        }
    }
});
