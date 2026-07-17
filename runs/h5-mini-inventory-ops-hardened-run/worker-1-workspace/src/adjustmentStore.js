// adjustmentStore.js — In-memory store for Adjustments with idempotency
// Node.js built-ins only, no npm packages

const { createAdjustment } = require("./inventoryAdjustment.js");

const adjustments = [];
const idempotencyKeys = new Set();

function addAdjustment(adjustmentId, skuId, type, quantity, idempotencyKey, version, timestamp) {
  const adj = createAdjustment(adjustmentId, skuId, type, quantity, idempotencyKey, version, timestamp);
  idempotencyKeys.add(idempotencyKey);
  adjustments.push(adj);
  return adj;
}

function getAdjustment(adjustmentId) {
  return adjustments.find((a) => a.adjustmentId === adjustmentId) || null;
}

function getAllAdjustments() {
  return adjustments.slice();
}

function hasIdempotencyKey(key) {
  return idempotencyKeys.has(key);
}

module.exports = {
  addAdjustment,
  getAdjustment,
  getAllAdjustments,
  hasIdempotencyKey,
};
