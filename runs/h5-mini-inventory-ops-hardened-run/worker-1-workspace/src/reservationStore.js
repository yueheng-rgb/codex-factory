// reservationStore.js — In-memory store for Reservations
// Node.js built-ins only, no npm packages

const { createReservation, ReservationStatus } = require("./reservation.js");

const reservations = new Map();

function addReservation(reservationId, skuId, quantity, status) {
  if (reservations.has(reservationId)) {
    throw new Error(`Reservation already exists: ${reservationId}`);
  }
  const res = createReservation(reservationId, skuId, quantity, status);
  reservations.set(reservationId, res);
  return res;
}

function getReservation(reservationId) {
  return reservations.get(reservationId) || null;
}

function releaseReservation(reservationId) {
  const existing = reservations.get(reservationId);
  if (!existing) {
    throw new Error(`Reservation not found: ${reservationId}`);
  }
  if (existing.status === ReservationStatus.RELEASED) {
    throw new Error(`Reservation already released: ${reservationId}`);
  }
  const released = createReservation(
    existing.reservationId,
    existing.skuId,
    existing.quantity,
    ReservationStatus.RELEASED
  );
  reservations.set(reservationId, released);
  return released;
}

function getActiveReservations() {
  return Array.from(reservations.values()).filter((r) => r.status === ReservationStatus.ACTIVE);
}

module.exports = {
  addReservation,
  getReservation,
  releaseReservation,
  getActiveReservations,
};
