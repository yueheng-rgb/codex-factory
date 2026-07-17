// verify-dry15-b-negatives.js - Validate all 9 DRY15-B negative control bugs
var fs = require("fs");
var path = require("path");
var runsDir = path.join(__dirname, "..", "runs");

var negatives = [
  { id: "dry15-b-negative-search-text-match",           test: "search" },
  { id: "dry15-b-negative-filter-combination",          test: "filter" },
  { id: "dry15-b-negative-sort-stable-order",           test: "sort" },
  { id: "dry15-b-negative-offset-pagination-duplicates",test: "offset" },
  { id: "dry15-b-negative-cursor-roundtrip",            test: "cursor" },
  { id: "dry15-b-negative-invalid-query-rejected",      test: "query" },
  { id: "dry15-b-negative-large-fixture-generated",     test: "fixture" },
  { id: "dry15-b-negative-performance-budget",          test: "budget" },
  { id: "dry15-b-negative-facets-counts",               test: "facets" }
];

var allPass = true;

negatives.forEach(function(neg) {
  var runPath = path.join(runsDir, neg.id);
  var srcPath = path.join(runPath, "canonical-integrated", "src");
  
  Object.keys(require.cache).forEach(function(k) { delete require.cache[k]; });
  
  try {
    var result = { pass: true, detail: "" };
    
    switch (neg.test) {
      case "search":
        var sc = require(path.join(srcPath, "searchComposer.js"));
        var items = [{ id: "i1", name: "Test Widget", category: "ELECTRONICS", price: 50, status: "ACTIVE", description: "a test", tags: ["test"] }];
        var r = sc.composeSearch(items, {}, { q: "test" });
        result.pass = r.total === 0;
        result.detail = "search total=" + r.total + " (expected 0)";
        break;
        
      case "filter":
        var fp = require(path.join(srcPath, "filterByPrice.js"));
        var items2 = [
          { id: "i1", name: "Cheap", price: 5 },
          { id: "i2", name: "Mid", price: 50 },
          { id: "i3", name: "Expensive", price: 500 }
        ];
        var f = fp(items2, 10, 100);
        result.pass = f.length === 3;
        result.detail = "filter [10,100] returned " + f.length + " items (expected 3, price filter disabled)";
        break;
        
      case "sort":
        var ss = require(path.join(srcPath, "sortStable.js"));
        // Create 20 items with same price ¡ª stability matters
        var orig = [];
        for (var i = 0; i < 20; i++) {
          orig.push({ id: "item-" + i, name: "Name-" + i, price: 100 });
        }
        var sorted = ss.stableSort(orig, "price", "asc");
        // Check if original order is preserved (should NOT be due to bug)
        var preservedCount = 0;
        for (var j = 0; j < sorted.length; j++) {
          if (sorted[j].id === "item-" + j) preservedCount++;
        }
        result.pass = preservedCount < sorted.length;
        result.detail = "preserved order count=" + preservedCount + "/" + sorted.length + " (expected <" + sorted.length + ", unstable)";
        break;
        
      case "offset":
        var po = require(path.join(srcPath, "paginateOffset.js"));
        var items4 = [];
        for (var i = 0; i < 30; i++) items4.push({ id: "item-" + i });
        var p1 = po.paginateOffset(items4, 1, 10);
        var p2 = po.paginateOffset(items4, 2, 10);
        var p1Ids = p1.items.map(function(x) { return x.id; });
        var p2Ids = p2.items.map(function(x) { return x.id; });
        var overlap = p1Ids.filter(function(x) { return p2Ids.indexOf(x) !== -1; });
        result.pass = overlap.length > 0;
        result.detail = "page overlap count=" + overlap.length + " (expected >0)";
        break;
        
      case "cursor":
        var cc = require(path.join(srcPath, "cursorCodec.js"));
        var decoded = cc.decodeCursor("eyJsYXN0SWQiOiJpMSJ9");
        result.pass = decoded === null;
        result.detail = "decodeCursor returns null=" + (decoded === null) + " (expected true)";
        break;
        
      case "query":
        var rp = require(path.join(srcPath, "requestParser.js"));
        var p = rp.parsePagination({ page: "-5", pageSize: "9999" });
        // Bug: accepts negative page and large pageSize without validation
        result.pass = p.page === -5 && p.pageSize === 9999;
        result.detail = "accepted: page=" + p.page + " pageSize=" + p.pageSize + " (expected -5/9999)";
        break;
        
      case "fixture":
        var gf = require(path.join(srcPath, "generateFixture.js"));
        var items5 = gf.generateItems(500);
        result.pass = items5.length === 10;
        result.detail = "generateItems(500) returned " + items5.length + " (expected 10, capped)";
        break;
        
      case "budget":
        var pb = require(path.join(srcPath, "performanceBudget.js"));
        var check = pb.checkBudget(5, 1000);
        result.pass = check.withinBudget === false && pb.BUDGET_MS === 1;
        result.detail = "withinBudget=" + check.withinBudget + " BUDGET_MS=" + pb.BUDGET_MS + " (expected false/1)";
        break;
        
      case "facets":
        var fh = require(path.join(srcPath, "facetsHandler.js"));
        var items6 = [
          { id: "i1", name: "A", category: "ELECTRONICS", price: 10, status: "ACTIVE" },
          { id: "i2", name: "B", category: "ELECTRONICS", price: 20, status: "ACTIVE" }
        ];
        var facets = fh.computeFacets(items6);
        result.pass = facets.categories["ELECTRONICS"] === 4;
        result.detail = "ELECTRONICS count=" + facets.categories["ELECTRONICS"] + " (expected 4, double-count)";
        break;
    }
    
    var status = result.pass ? "PASS" : "BUG_NOT_DETECTED";
    if (!result.pass) allPass = false;
    console.log(status + ": " + neg.id + " - " + result.detail);
    
  } catch (e) {
    console.log("ERROR: " + neg.id + " - " + e.message);
    allPass = false;
  }
});

console.log("\n" + (allPass ? "ALL_NEGATIVE_BUGS_CONFIRMED" : "SOME_BUGS_NOT_DETECTED"));
process.exit(allPass ? 0 : 1);
