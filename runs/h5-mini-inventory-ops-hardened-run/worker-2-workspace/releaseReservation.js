const { store } = require('./store');
const { writeAuditEvent } = require('./auditWriter');

function releaseReservation(reservationId) {
  const reservation = store.reservations.get(reservationId);

  if (!reservation) {
    const err = new Error(`Reservation '${reservationId}' not found`);
    err.code = 'RESERVATION_NOT_FOUND';
    err.reservationId = reservationId;
    throw err;
  }

  if (reservation.status !== 'active') {
    const err = new Error(`Reservation '${reservationId}' is already ${reservation.status}`);
    err.code = 'RESERVATION_NOT_ACTIVE';
    err.reservationId = reservationId;
    throw err;
  }

  const stock = store.stockLevels.get(reservation.skuId);

  if (!stock) {
    const err = new Error(`SKU '${reservation.skuId}' not found for reservation '${reservationId}'`);
    err.code = 'SKU_NOT_FOUND';
    err.skuId = reservation.skuId;
    throw err;
  }

  stock.reserved -= reservation.quantity;
  stock.available += reservation.quantity;
  stock.version += 1;

  reservation.status = 'released';

  writeAuditEvent('RELEASE', reservation.skuId, {
    reservationId,
    quantity: reservation.quantity,
    newOnHand: stock.onHand,
    newAvailable: stock.available,
    newReserved: stock.reserved,
    version: stock.version,
  });

  return { reservation: { ...reservation }, stock: { ...stock } };
}

module.exports = { releaseReservation };
