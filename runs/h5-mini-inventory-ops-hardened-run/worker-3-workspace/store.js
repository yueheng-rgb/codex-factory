// store.js — Shared in-memory state and inventory operations
// Node.js built-ins only. Referenced by server.js and cli.js.

const { createSKU } = require("../worker-1-workspace/src/itemTypes");
const crypto = require("crypto");

// ─── In-Memory State ────────────────────────────────────────────────
const state = {
  items: Object.create(null),       // skuId -> { skuId, name, category }
  stock: Object.create(null),       // skuId -> number
  reservations: Object.create(null), // reservationId -> { reservationId, skuId, quantity, createdAt }
  adjustments: [],                  // [{ id, type, skuId, quantity, reason, timestamp }]
  audit: [],                        // [{ id, event, details, timestamp }]
  idempotencyKeys: new Set(),       // processed inbound idempotency keys
};

let adjustmentSeq = 0;
let auditSeq = 0;

function nextAdjustmentId() {
  adjustmentSeq += 1;
  return `adj-${adjustmentSeq}`;
}

function nextAuditId() {
  auditSeq += 1;
  return `audit-${auditSeq}`;
}

function timestamp() {
  return new Date().toISOString();
}

function logAudit(event, details) {
  state.audit.push({
    id: nextAuditId(),
    event,
    details,
    timestamp: timestamp(),
  });
}

// ─── Item Operations ────────────────────────────────────────────────

function addItem(skuId, name, category) {
  if (state.items[skuId]) {
    throw new Error(`Item ${skuId} already exists`);
  }
  state.items[skuId] = createSKU(skuId, name, category);
  if (state.stock[skuId] === undefined) {
    state.stock[skuId] = 0;
  }
  logAudit("ITEM_CREATED", { skuId, name, category });
  return state.items[skuId];
}

function getItems() {
  return Object.values(state.items);
}

function getItem(skuId) {
  const item = state.items[skuId];
  if (!item) throw new Error(`Item ${skuId} not found`);
  return item;
}

// ─── Stock Operations ───────────────────────────────────────────────

function getStock() {
  return Object.keys(state.stock).map((skuId) => ({
    skuId,
    quantity: state.stock[skuId],
  }));
}

function getStockLevel(skuId) {
  if (state.stock[skuId] === undefined) {
    throw new Error(`Stock for ${skuId} not found`);
  }
  return state.stock[skuId];
}

function setStock(skuId, quantity) {
  if (state.stock[skuId] === undefined) {
    throw new Error(`Stock for ${skuId} not found`);
  }
  if (quantity < 0) {
    throw new Error(`Stock cannot be negative for ${skuId}`);
  }
  state.stock[skuId] = quantity;
}

// ─── Inbound ────────────────────────────────────────────────────────

function inbound(skuId, quantity, idempotencyKey) {
  getItem(skuId); // validates existence
  if (!Number.isInteger(quantity) || quantity <= 0) {
    throw new Error("Quantity must be a positive integer");
  }
  if (idempotencyKey && state.idempotencyKeys.has(idempotencyKey)) {
    logAudit("INBOUND_IDEMPOTENT_SKIP", { skuId, quantity, idempotencyKey });
    return null; // already processed
  }
  if (idempotencyKey) {
    state.idempotencyKeys.add(idempotencyKey);
  }
  const before = state.stock[skuId];
  state.stock[skuId] += quantity;
  const adj = {
    id: nextAdjustmentId(),
    type: "INBOUND",
    skuId,
    quantity,
    before,
    after: state.stock[skuId],
    idempotencyKey: idempotencyKey || null,
    timestamp: timestamp(),
  };
  state.adjustments.push(adj);
  logAudit("INBOUND", { skuId, quantity, idempotencyKey, before, after: state.stock[skuId] });
  return adj;
}

// ─── Outbound ───────────────────────────────────────────────────────

function outbound(skuId, quantity) {
  getItem(skuId);
  if (!Number.isInteger(quantity) || quantity <= 0) {
    throw new Error("Quantity must be a positive integer");
  }
  const available = state.stock[skuId];
  if (available < quantity) {
    throw new Error(`Insufficient stock for ${skuId}: have ${available}, need ${quantity}`);
  }
  const before = state.stock[skuId];
  state.stock[skuId] -= quantity;
  const adj = {
    id: nextAdjustmentId(),
    type: "OUTBOUND",
    skuId,
    quantity,
    before,
    after: state.stock[skuId],
    timestamp: timestamp(),
  };
  state.adjustments.push(adj);
  logAudit("OUTBOUND", { skuId, quantity, before, after: state.stock[skuId] });
  return adj;
}

// ─── Reservations ───────────────────────────────────────────────────

function reserve(skuId, quantity) {
  getItem(skuId);
  if (!Number.isInteger(quantity) || quantity <= 0) {
    throw new Error("Quantity must be a positive integer");
  }
  const available = state.stock[skuId];
  if (available < quantity) {
    throw new Error(`Insufficient stock for reservation ${skuId}: have ${available}, need ${quantity}`);
  }
  const reservationId = crypto.randomUUID();
  state.stock[skuId] -= quantity;
  const reservation = {
    reservationId,
    skuId,
    quantity,
    createdAt: timestamp(),
  };
  state.reservations[reservationId] = reservation;
  logAudit("RESERVATION_CREATED", { reservationId, skuId, quantity });
  return reservation;
}

function releaseReservation(reservationId) {
  const reservation = state.reservations[reservationId];
  if (!reservation) {
    throw new Error(`Reservation ${reservationId} not found`);
  }
  state.stock[reservation.skuId] += reservation.quantity;
  delete state.reservations[reservationId];
  logAudit("RESERVATION_RELEASED", { reservationId, skuId: reservation.skuId, quantity: reservation.quantity });
  return reservation;
}

function getReservations() {
  return Object.values(state.reservations);
}

// ─── Transfer ───────────────────────────────────────────────────────

function transfer(fromSkuId, toSkuId, quantity) {
  getItem(fromSkuId);
  getItem(toSkuId);
  if (!Number.isInteger(quantity) || quantity <= 0) {
    throw new Error("Quantity must be a positive integer");
  }
  const available = state.stock[fromSkuId];
  if (available < quantity) {
    throw new Error(`Insufficient stock for transfer from ${fromSkuId}: have ${available}, need ${quantity}`);
  }
  const fromBefore = state.stock[fromSkuId];
  const toBefore = state.stock[toSkuId];
  state.stock[fromSkuId] -= quantity;
  state.stock[toSkuId] += quantity;
  const adj = {
    id: nextAdjustmentId(),
    type: "TRANSFER",
    fromSkuId,
    toSkuId,
    quantity,
    fromBefore,
    fromAfter: state.stock[fromSkuId],
    toBefore,
    toAfter: state.stock[toSkuId],
    timestamp: timestamp(),
  };
  state.adjustments.push(adj);
  logAudit("TRANSFER", { fromSkuId, toSkuId, quantity, fromBefore, toBefore });
  return adj;
}

// ─── Query ──────────────────────────────────────────────────────────

function getAdjustments() {
  return state.adjustments;
}

function getAudit() {
  return state.audit;
}

// ─── Export / Import ────────────────────────────────────────────────

function exportState() {
  return {
    items: { ...state.items },
    stock: { ...state.stock },
    reservations: { ...state.reservations },
    adjustments: state.adjustments.slice(),
    audit: state.audit.slice(),
    idempotencyKeys: [...state.idempotencyKeys],
    adjustmentSeq,
    auditSeq,
  };
}

function importState(data) {
  if (!data || typeof data !== "object") {
    throw new Error("Invalid state data");
  }
  state.items = Object.create(null);
  Object.assign(state.items, data.items || {});
  state.stock = Object.create(null);
  Object.assign(state.stock, data.stock || {});
  state.reservations = Object.create(null);
  Object.assign(state.reservations, data.reservations || {});
  state.adjustments = Array.isArray(data.adjustments) ? data.adjustments.slice() : [];
  state.audit = Array.isArray(data.audit) ? data.audit.slice() : [];
  state.idempotencyKeys = new Set(data.idempotencyKeys || []);
  adjustmentSeq = data.adjustmentSeq || 0;
  auditSeq = data.auditSeq || 0;
  logAudit("STATE_IMPORTED", {});
}

// ─── Report ─────────────────────────────────────────────────────────

function generateReport() {
  const items = getItems();
  const stock = getStock();
  const reservations = getReservations();
  const adjustments = getAdjustments();
  const totalStock = stock.reduce((sum, s) => sum + s.quantity, 0);
  const totalItems = items.length;
  const totalReservations = reservations.length;
  const reservedQty = reservations.reduce((sum, r) => sum + r.quantity, 0);

  let md = "# Inventory Report\n\n";
  md += `**Generated**: ${timestamp()}\n\n`;
  md += "## Summary\n\n";
  md += `| Metric | Value |\n`;
  md += `|--------|-------|\n`;
  md += `| Total Items | ${totalItems} |\n`;
  md += `| Total Stock | ${totalStock} |\n`;
  md += `| Active Reservations | ${totalReservations} |\n`;
  md += `| Reserved Quantity | ${reservedQty} |\n`;
  md += `| Total Adjustments | ${adjustments.length} |\n\n`;

  md += "## Items\n\n";
  md += "| SKU ID | Name | Category | Stock |\n";
  md += "|--------|------|----------|-------|\n";
  for (const item of items) {
    md += `| ${item.skuId} | ${item.name} | ${item.category} | ${state.stock[item.skuId]} |\n`;
  }

  if (reservations.length > 0) {
    md += "\n## Active Reservations\n\n";
    md += "| Reservation ID | SKU ID | Quantity | Created |\n";
    md += "|---------------|--------|----------|--------|\n";
    for (const r of reservations) {
      md += `| ${r.reservationId} | ${r.skuId} | ${r.quantity} | ${r.createdAt} |\n`;
    }
  }

  if (adjustments.length > 0) {
    md += "\n## Recent Adjustments\n\n";
    md += "| ID | Type | SKU | Qty | Before | After | Time |\n";
    md += "|----|------|-----|-----|--------|-------|------|\n";
    const recent = adjustments.slice(-20).reverse();
    for (const a of recent) {
      const sku = a.skuId || `${a.fromSkuId}->${a.toSkuId}`;
      md += `| ${a.id} | ${a.type} | ${sku} | ${a.quantity} | ${a.before ?? "-"} | ${a.after ?? "-"} | ${a.timestamp} |\n`;
    }
  }

  return md;
}

// ─── Exports ────────────────────────────────────────────────────────

module.exports = {
  addItem,
  getItems,
  getItem,
  getStock,
  getStockLevel,
  setStock,
  inbound,
  outbound,
  reserve,
  releaseReservation,
  getReservations,
  transfer,
  getAdjustments,
  getAudit,
  exportState,
  importState,
  generateReport,
};
