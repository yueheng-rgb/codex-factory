// auditEvent.js — AuditEvent model
// Node.js built-ins only, no npm packages

function createAuditEvent(eventId, eventType, skuId, details, timestamp) {
  if (!eventId || !eventType || !skuId) {
    throw new Error("AuditEvent requires eventId, eventType, and skuId");
  }
  return Object.freeze({
    eventId,
    eventType,
    skuId,
    details: details || {},
    timestamp: timestamp || new Date().toISOString(),
  });
}

module.exports = {
  createAuditEvent,
};
