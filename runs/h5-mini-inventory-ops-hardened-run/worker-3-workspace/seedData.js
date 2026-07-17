// seedData.js — Creates 5 sample inventory items with initial stock
// Node.js built-ins only.

const store = require("./store");

/**
 * Seed 5 sample items into the store with initial stock levels.
 * Idempotent: skips items that already exist.
 */
function seedSampleData() {
  const samples = [
    { skuId: "SKU-001", name: "无线蓝牙耳机", category: "电子产品", stock: 100 },
    { skuId: "SKU-002", name: "USB-C 数据线", category: "配件", stock: 500 },
    { skuId: "SKU-003", name: "机械键盘", category: "电子产品", stock: 50 },
    { skuId: "SKU-004", name: "鼠标垫", category: "配件", stock: 200 },
    { skuId: "SKU-005", name: "显示器支架", category: "办公设备", stock: 30 },
  ];

  const results = [];
  for (const s of samples) {
    try {
      const item = store.addItem(s.skuId, s.name, s.category);
      store.setStock(s.skuId, s.stock);
      results.push({ skuId: s.skuId, status: "created", stock: s.stock });
    } catch (err) {
      if (err.message.includes("already exists")) {
        results.push({ skuId: s.skuId, status: "skipped", reason: "already exists" });
      } else {
        results.push({ skuId: s.skuId, status: "error", reason: err.message });
      }
    }
  }
  return results;
}

module.exports = { seedSampleData };
