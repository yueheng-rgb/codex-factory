// stockStore.js — In-memory store for StockLevel values
// Node.js built-ins only, no npm packages

const { createStockLevel } = require("./stockLevel.js");

const stockLevels = new Map();

function getStock(skuId) {
  const level = stockLevels.get(skuId);
  return level || null;
}

function updateStock(skuId, onHand, reserved) {
  const level = createStockLevel(skuId, onHand, reserved);
  stockLevels.set(skuId, level);
  return level;
}

function getAllStockLevels() {
  return Array.from(stockLevels.values());
}

module.exports = {
  getStock,
  updateStock,
  getAllStockLevels,
};
