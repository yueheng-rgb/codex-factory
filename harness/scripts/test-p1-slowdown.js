var sc = require("../runs/dry15-b-p1-negative-performance-budget-slow-path/canonical-integrated/src/searchComposer.js");
var items = [];
for (var i = 0; i < 10; i++) {
  items.push({ id: "item-" + i, name: "Test " + i, category: "ELECTRONICS", price: i * 10, status: "ACTIVE", description: "desc", tags: [] });
}
var start = Date.now();
var result = sc.composeSearch(items, {}, { q: "test" });
var elapsed = Date.now() - start;
console.log("elapsedMs: " + elapsed);
console.log("total: " + result.total);
console.log("exceeds 1000ms: " + (elapsed > 1000));
