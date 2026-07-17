const { store } = require('./store');
const { writeAuditEvent } = require('./auditWriter');
const { rejectStaleVersion } = require('./rejectStaleVersion');

function transferStock(fromSkuId, toSkuId, quantity, fromExpectedVersion, toExpectedVersion) {
  const fromStock = store.stockLevels.get(fromSkuId);

  if (!fromStock) {
    const err = new Error(`Source SKU '${fromSkuId}' not found`);
    err.code = 'SKU_NOT_FOUND';
    err.skuId = fromSkuId;
    throw err;
  }

  rejectStaleVersion(fromSkuId, fromStock.version, fromExpectedVersion);

  if (fromStock.available < quantity) {
    const err = new Error(
      `Insufficient available stock at source SKU '${fromSkuId}': requested ${quantity}, available ${fromStock.available}`
    );
    err.code = 'INSUFFICIENT_STOCK';
    err.skuId = fromSkuId;
    err.requested = quantity;
    err.available = fromStock.available;
    throw err;
  }

  let toStock = store.stockLevels.get(toSkuId);

  if (toStock) {
    rejectStaleVersion(toSkuId, toStock.version, toExpectedVersion);
  }

  // Perform outbound from source
  fromStock.onHand -= quantity;
  fromStock.available -= quantity;
  fromStock.version += 1;

  // Perform inbound to destination
  if (toStock) {
    toStock.onHand += quantity;
    toStock.available += quantity;
    toStock.version += 1;
  } else {
    toStock = {
      skuId: toSkuId,
      onHand: quantity,
      available: quantity,
      reserved: 0,
      version: 1,
    };
    store.stockLevels.set(toSkuId, toStock);
  }

  const transferId = require('crypto').randomUUID();

  writeAuditEvent('TRANSFER_OUT', fromSkuId, {
    transferId,
    quantity,
    toSkuId,
    newOnHand: fromStock.onHand,
    newAvailable: fromStock.available,
    version: fromStock.version,
  });

  writeAuditEvent('TRANSFER_IN', toSkuId, {
    transferId,
    quantity,
    fromSkuId,
    newOnHand: toStock.onHand,
    newAvailable: toStock.available,
    version: toStock.version,
  });

  return {
    transferId,
    from: { ...fromStock },
    to: { ...toStock },
  };
}

module.exports = { transferStock };
