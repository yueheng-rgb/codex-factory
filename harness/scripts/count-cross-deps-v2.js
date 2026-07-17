var fs = require("fs");
var path = require("path");
var src = "C:/Codex_App_Factory/harness/runs/dry15-mini-catalog-search-performance-app/canonical-integrated/src";
var files = fs.readdirSync(src).filter(function(f) { return f.endsWith(".js"); });

var workers = {
    w1: ["itemTypes.js","createItem.js","itemStore.js","filterByCategory.js","filterByStatus.js","filterByPrice.js","sortItems.js","itemExporter.js"],
    w2: ["searchTypes.js","normalizeText.js","tokenizeText.js","buildIndex.js","searchIndex.js","searchRanker.js","searchComposer.js"],
    w3: ["paginationTypes.js","paginateOffset.js","paginateCursor.js","cursorCodec.js","filterPipeline.js","filterCombinator.js","sortStable.js"],
    w4: ["fixtureTypes.js","generateFixture.js","measureQuery.js","performanceBudget.js","searchReportGenerator.js","dataIntegrity.js","fixtureLoader.js"],
    w5: ["server.js","handlers.js","handlerHelpers.js","requestParser.js","responseBuilder.js","routeTable.js","cli.js","staticPage.js","appJs.js","searchScenarios.js","serverMain.js","exportHandler.js","facetsHandler.js"]
};

// integrationWiring.js depends on all workers - it's a special file
workers.wAll = ["integrationWiring.js"];

function getWorker(file) {
    for (var w in workers) {
        if (workers[w].indexOf(file) !== -1) return w;
    }
    return null;
}

var totalFiles = 0;
var crossDeps = [];

files.forEach(function(file) {
    var content = fs.readFileSync(path.join(src, file), "utf8");
    var worker = getWorker(file);
    
    var pattern = /require\(['"]\.\/([^'"]+\.js)['"]\)/g;
    var match;
    while ((match = pattern.exec(content)) !== null) {
        var depFile = match[1];
        var depWorker = getWorker(depFile);
        if (depWorker && depWorker !== worker) {
            crossDeps.push(file + " (" + worker + ") -> " + depFile + " (" + depWorker + ")");
            totalFiles++;
        }
    }
});

console.log("Cross-worker dependencies: " + crossDeps.length);
console.log("Unique dependency pairs: " + totalFiles);
if (crossDeps.length <= 60) {
    crossDeps.forEach(function(d) { console.log("  " + d); });
}
