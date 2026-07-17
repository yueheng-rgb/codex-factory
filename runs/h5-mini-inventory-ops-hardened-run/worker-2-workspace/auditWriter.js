const { store, generateId } = require('./store');

function writeAuditEvent(eventType, skuId, details) {
  const event = {
    id: generateId(),
    eventType,
    skuId,
    details: details || {},
    timestamp: new Date().toISOString(),
  };
  store.auditEvents.push(event);
  return event;
}

module.exports = { writeAuditEvent };
