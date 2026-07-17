const crypto = require('crypto');

const generateId = () => crypto.randomUUID();

const store = {
  stockLevels: new Map(),
  reservations: new Map(),
  auditEvents: [],
  idempotencyKeys: new Set(),
};

function resetStore() {
  store.stockLevels.clear();
  store.reservations.clear();
  store.auditEvents.length = 0;
  store.idempotencyKeys.clear();
}

module.exports = { store, resetStore, generateId };
