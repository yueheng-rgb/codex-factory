const { store } = require('./store');
const { writeAuditEvent } = require('./auditWriter');
const { rejectStaleVersion } = require('./rejectStaleVersion');

function applyInbound(skuId, quantity, idempotencyKey, expectedVersion) {
  if (store.idempotencyKeys.has(idempotencyKey)) {
    const err = new Error(`Idempotency key '${idempotencyKey}' already used for SKU '${skuId}'`);
    err.code = 'DUPLICATE_IDEMPOTENCY_KEY';
    err.skuId = skuId;
    err.idempotencyKey = idempotencyKey;
    throw err;
  }

  let stock = store.stockLevels.get(skuId);
  if (stock) {
    const currentVersion = stock.version;
    rejectStaleVersion(skuId, currentVersion, expectedVersion);

    stock.onHand += quantity;
    stock.available += quantity;
    stock.version += 1;
  } else {
    stock = {
      skuId,
      onHand: quantity,
      available: quantity,
      reserved: 0,
      version: 1,
    };
    store.stockLevels.set(skuId, stock);
  }

  store.idempotencyKeys.add(idempotencyKey);

  writeAuditEvent('INBOUND', skuId, {
    quantity,
    idempotencyKey,
    newOnHand: stock.onHand,
    newAvailable: stock.available,
    version: stock.version,
  });

  return { ...stock };
}

module.exports = { applyInbound };
