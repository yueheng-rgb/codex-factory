const { store, resetStore } = require('./store');
const { applyInbound } = require('./applyInbound');
const { applyOutbound } = require('./applyOutbound');
const { reserveStock } = require('./reserveStock');
const { releaseReservation } = require('./releaseReservation');
const { transferStock } = require('./transferStock');
const { rejectStaleVersion } = require('./rejectStaleVersion');
const { writeAuditEvent } = require('./auditWriter');

/**
 * Seed an initial stock level for a SKU.
 * Only allowed when no stock level exists for the skuId.
 */
function seedStock(skuId, onHand) {
  if (store.stockLevels.has(skuId)) {
    const err = new Error(`SKU '${skuId}' already seeded`);
    err.code = 'SKU_ALREADY_EXISTS';
    err.skuId = skuId;
    throw err;
  }
  const stock = {
    skuId,
    onHand,
    available: onHand,
    reserved: 0,
    version: 1,
  };
  store.stockLevels.set(skuId, stock);
  writeAuditEvent('SEED', skuId, { onHand, version: 1 });
  return { ...stock };
}

/**
 * Process an inbound operation.
 * Returns the new StockLevel.
 */
function processInbound(skuId, quantity, idempotencyKey, expectedVersion) {
  return applyInbound(skuId, quantity, idempotencyKey, expectedVersion);
}

/**
 * Process an outbound operation.
 * Returns the new StockLevel.
 */
function processOutbound(skuId, quantity, expectedVersion) {
  return applyOutbound(skuId, quantity, expectedVersion);
}

/**
 * Process a reservation.
 * Returns { reservation, stock }.
 */
function processReserve(skuId, quantity, expectedVersion) {
  return reserveStock(skuId, quantity, expectedVersion);
}

/**
 * Process a reservation release.
 * Returns { reservation, stock }.
 */
function processRelease(reservationId) {
  return releaseReservation(reservationId);
}

/**
 * Process a stock transfer from one SKU to another.
 * Returns { transferId, from: StockLevel, to: StockLevel }.
 */
function processTransfer(fromSkuId, toSkuId, quantity, fromExpectedVersion, toExpectedVersion) {
  return transferStock(fromSkuId, toSkuId, quantity, fromExpectedVersion, toExpectedVersion);
}

/**
 * Returns the full engine state snapshot.
 */
function getState() {
  const stockLevels = {};
  for (const [skuId, stock] of store.stockLevels) {
    stockLevels[skuId] = { ...stock };
  }

  const reservations = {};
  for (const [reservationId, reservation] of store.reservations) {
    reservations[reservationId] = { ...reservation };
  }

  return {
    stockLevels,
    reservations,
    auditEvents: [...store.auditEvents],
    idempotencyKeyCount: store.idempotencyKeys.size,
  };
}

module.exports = {
  seedStock,
  processInbound,
  processOutbound,
  processReserve,
  processRelease,
  processTransfer,
  rejectStaleVersion,
  writeAuditEvent,
  getState,
  resetStore,
};
