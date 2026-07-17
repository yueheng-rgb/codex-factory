var ss = require("../runs/dry15-b-negative-sort-stable-order/canonical-integrated/src/sortStable.js");
var items = [];
for (var i = 0; i < 5; i++) items.push({ id: "item-" + i, price: 100 });
var sorted = ss.stableSort(items, "price", "asc");
var order = sorted.map(function(x) { return x.id; }).join(",");
console.log("Order: " + order);
console.log("Reversed (unstable): " + (order !== "item-0,item-1,item-2,item-3,item-4"));
