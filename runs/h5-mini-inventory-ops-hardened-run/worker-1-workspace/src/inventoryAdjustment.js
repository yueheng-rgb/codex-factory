// inventoryAdjustment.js — AdjustmentType enum and Adjustment model
// Node.js built-ins only, no npm packages

const AdjustmentType = Object.freeze({
  INBOUND: "INBOUND",
  OUTBOUND: "OUTBOUND",
  TRANSFER_IN: "TRANSFER_IN",
  TRANSFER_OUT: "TRANSFER_OUT",
});

const AdjustmentType_values = Object.values(AdjustmentType);

/**
 * @typedef {{ adjustmentId: string, skuId: string, type: string, quantity: number, idempotencyKey: string, version: number, timestamp: string }} Adjustment
 */

function createAdjustment(adjustmentId, skuId, type, quantity, idempotencyKey, version, timestamp) {
  if (!adjustmentId || !skuId || !type || quantity == null || !idempotencyKey || version == null) {
    throw new Error("Adjustment requires adjustmentId, skuId, type, quantity, idempotencyKey, version");
  }
  if (!AdjustmentType_values.includes(type)) {
    throw new Error(`Invalid AdjustmentType: ${type}`);
  }
  if (typeof quantity !== "number" || quantity <= 0) {
    throw new Error("quantity must be a positive number");
  }
  if (typeof version !== "number" || version < 0) {
    throw new Error("version must be a non-negative number");
  }
  return Object.freeze({
    adjustmentId, skuId, type, quantity, idempotencyKey, version,
    timestamp: timestamp || new Date().toISOString(),
  });
}

module.exports = {
  AdjustmentType,
  createAdjustment,
};
