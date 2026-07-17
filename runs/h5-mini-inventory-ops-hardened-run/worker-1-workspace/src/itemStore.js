// itemStore.js — In-memory store for SKU items
// Node.js built-ins only, no npm packages

const { createSKU } = require("./itemTypes.js");

const items = new Map();

function addItem(sku) {
  if (items.has(sku.skuId)) {
    throw new Error(`SKU already exists: ${sku.skuId}`);
  }
  const frozen = createSKU(sku.skuId, sku.name, sku.category);
  items.set(sku.skuId, frozen);
  return frozen;
}

function getItem(skuId) {
  const item = items.get(skuId);
  return item || null;
}

function getAllItems() {
  return Array.from(items.values());
}

function updateItem(skuId, updates) {
  const existing = items.get(skuId);
  if (!existing) {
    throw new Error(`SKU not found: ${skuId}`);
  }
  const updated = createSKU(
    skuId,
    updates.name !== undefined ? updates.name : existing.name,
    updates.category !== undefined ? updates.category : existing.category
  );
  items.set(skuId, updated);
  return updated;
}

module.exports = {
  addItem,
  getItem,
  getAllItems,
  updateItem,
};
