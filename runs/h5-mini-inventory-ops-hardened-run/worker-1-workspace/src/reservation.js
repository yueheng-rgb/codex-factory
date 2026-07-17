// reservation.js — Reservation model with ACTIVE/RELEASED status
// Node.js built-ins only, no npm packages

const ReservationStatus = Object.freeze({
  ACTIVE: "ACTIVE",
  RELEASED: "RELEASED",
});

const ReservationStatus_values = Object.values(ReservationStatus);

function createReservation(reservationId, skuId, quantity, status) {
  if (!reservationId || !skuId) {
    throw new Error("Reservation requires reservationId and skuId");
  }
  if (typeof quantity !== "number" || quantity <= 0) {
    throw new Error("quantity must be a positive number");
  }
  const _status = status || ReservationStatus.ACTIVE;
  if (!ReservationStatus_values.includes(_status)) {
    throw new Error(`Invalid ReservationStatus: ${_status}`);
  }
  return Object.freeze({ reservationId, skuId, quantity, status: _status });
}

module.exports = {
  ReservationStatus,
  createReservation,
};
