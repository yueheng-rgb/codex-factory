const { store, generateId } = require('./store');
const { writeAuditEvent } = require('./auditWriter');
const { rejectStaleVersion } = require('./rejectStaleVersion');

function reserveStock(skuId, quantity, expectedVersion) {
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
      `Insufficient reservable stock for SKU '${skuId}': requested ${quantity}, available ${stock.available}`
    );
    err.code = 'INSUFFICIENT_STOCK';
    err.skuId = skuId;
    err.requested = quantity;
    err.available = stock.available;
    throw err;
  }

  const reservationId = generateId();
  const reservation = {
    reservationId,
    skuId,
    quantity,
    status: 'active',
    createdAt: new Date().toISOString(),
  };

  store.reservations.set(reservationId, reservation);

  stock.reserved += quantity;
  stock.available -= quantity;
  stock.version += 1;

  writeAuditEvent('RESERVE', skuId, {
    reservationId,
    quantity,
    newOnHand: stock.onHand,
    newAvailable: stock.available,
    newReserved: stock.reserved,
    version: stock.version,
  });

  return { reservation: { ...reservation }, stock: { ...stock } };
}

module.exports = { reserveStock };
