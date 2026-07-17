const { store } = require('./store');
const { writeAuditEvent } = require('./auditWriter');
const { rejectStaleVersion } = require('./rejectStaleVersion');

function applyOutbound(skuId, quantity, expectedVersion) {
  const stock = store.stockLevels.get(skuId);

  if (!stock) {
    const err = new Error(`SKU '${skuId}' not found`);
    err.code = 'SKU_NOT_FOUND';
    err.skuId = skuId;
    throw err;
  }

  const currentVersion = stock.version;
  rejectStaleVersion(skuId, currentVersion, expectedVersion);

  if (stock.available < quantity) {
    const err = new Error(
      `Insufficient available stock for SKU '${skuId}': requested ${quantity}, available ${stock.available}`
    );
    err.code = 'INSUFFICIENT_STOCK';
    err.skuId = skuId;
    err.requested = quantity;
    err.available = stock.available;
    throw err;
  }

  stock.onHand -= quantity;
  stock.available -= quantity;
  stock.version += 1;

  writeAuditEvent('OUTBOUND', skuId, {
    quantity,
    newOnHand: stock.onHand,
    newAvailable: stock.available,
    version: stock.version,
  });

  return { ...stock };
}

module.exports = { applyOutbound };
