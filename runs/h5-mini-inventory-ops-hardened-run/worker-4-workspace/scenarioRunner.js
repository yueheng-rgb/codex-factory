'use strict';

const { randomUUID } = require('crypto');

class InventorySystem {
  constructor() {
    this.items = new Map();
    this.audit = [];
    this.usedKeys = new Set();
    this.seq = 0;
  }

  _now() { return Date.now(); }

  createItem(sku, name, opts = {}) {
    if (this.items.has(sku)) return { ok: false, error: 'DUPLICATE_SKU' };
    const item = { sku, name, stock: opts.stock ?? 0, reserved: 0, version: 0 };
    this.items.set(sku, item);
    return { ok: true, item: { ...item } };
  }

  _checkKey(key) {
    if (key && this.usedKeys.has(key)) return { duplicate: true };
    if (key) this.usedKeys.add(key);
    return { duplicate: false };
  }

  inbound(sku, qty, opts = {}) {
    const item = this.items.get(sku);
    if (!item) return { ok: false, error: 'SKU_NOT_FOUND' };
    if (qty <= 0) return { ok: false, error: 'INVALID_QTY' };
    const kcheck = this._checkKey(opts.idempotencyKey);
    if (kcheck.duplicate) return { ok: false, error: 'DUPLICATE_KEY' };
    item.stock += qty;
    item.version += 1;
    this._audit('inbound', sku, qty, opts.idempotencyKey, true);
    return { ok: true, item: { ...item } };
  }

  outbound(sku, qty, opts = {}) {
    const item = this.items.get(sku);
    if (!item) return { ok: false, error: 'SKU_NOT_FOUND' };
    if (qty <= 0) return { ok: false, error: 'INVALID_QTY' };
    const available = item.stock - item.reserved;
    if (available < qty) return { ok: false, error: 'INSUFFICIENT_AVAILABLE', available };
    const kcheck = this._checkKey(opts.idempotencyKey);
    if (kcheck.duplicate) return { ok: false, error: 'DUPLICATE_KEY' };
    item.stock -= qty;
    item.version += 1;
    this._audit('outbound', sku, -qty, opts.idempotencyKey, true);
    return { ok: true, item: { ...item } };
  }

  reserve(sku, qty, opts = {}) {
    const item = this.items.get(sku);
    if (!item) return { ok: false, error: 'SKU_NOT_FOUND' };
    if (qty <= 0) return { ok: false, error: 'INVALID_QTY' };
    const available = item.stock - item.reserved;
    if (available < qty) return { ok: false, error: 'INSUFFICIENT_AVAILABLE', available };
    const kcheck = this._checkKey(opts.idempotencyKey);
    if (kcheck.duplicate) return { ok: false, error: 'DUPLICATE_KEY' };
    item.reserved += qty;
    item.version += 1;
    this._audit('reserve', sku, qty, opts.idempotencyKey, true);
    return { ok: true, item: { ...item } };
  }

  releaseReservation(sku, qty, opts = {}) {
    const item = this.items.get(sku);
    if (!item) return { ok: false, error: 'SKU_NOT_FOUND' };
    if (qty <= 0 || qty > item.reserved) return { ok: false, error: 'INVALID_RELEASE_QTY' };
    const kcheck = this._checkKey(opts.idempotencyKey);
    if (kcheck.duplicate) return { ok: false, error: 'DUPLICATE_KEY' };
    item.reserved -= qty;
    item.version += 1;
    this._audit('release', sku, -qty, opts.idempotencyKey, true);
    return { ok: true, item: { ...item } };
  }

  transfer(fromSku, toSku, qty, opts = {}) {
    const fromItem = this.items.get(fromSku);
    const toItem = this.items.get(toSku);
    if (!fromItem || !toItem) return { ok: false, error: 'SKU_NOT_FOUND' };
    if (qty <= 0) return { ok: false, error: 'INVALID_QTY' };
    const available = fromItem.stock - fromItem.reserved;
    if (available < qty) return { ok: false, error: 'INSUFFICIENT_AVAILABLE', available };
    const kcheck = this._checkKey(opts.idempotencyKey);
    if (kcheck.duplicate) return { ok: false, error: 'DUPLICATE_KEY' };
    fromItem.stock -= qty;
    fromItem.version += 1;
    toItem.stock += qty;
    toItem.version += 1;
    this._audit('transfer_out', fromSku, -qty, opts.idempotencyKey, true);
    this._audit('transfer_in', toSku, qty, opts.idempotencyKey, true);
    return { ok: true, from: { ...fromItem }, to: { ...toItem } };
  }

  adjustStock(sku, qty, expectedVersion, opts = {}) {
    const item = this.items.get(sku);
    if (!item) return { ok: false, error: 'SKU_NOT_FOUND' };
    if (expectedVersion !== undefined && expectedVersion !== item.version)
      return { ok: false, error: 'VERSION_MISMATCH', expected: expectedVersion, actual: item.version };
    const kcheck = this._checkKey(opts.idempotencyKey);
    if (kcheck.duplicate) return { ok: false, error: 'DUPLICATE_KEY' };
    item.stock += qty;
    item.version += 1;
    this._audit('adjust', sku, qty, opts.idempotencyKey, true);
    return { ok: true, item: { ...item } };
  }

  _audit(op, sku, delta, key, success) {
    this.audit.push({ seq: ++this.seq, op, sku, delta, key: key || null, ts: this._now(), success });
  }

  getStock() { return [...this.items.values()].map(i => ({ ...i })); }
  getAudit(sku) { return sku ? this.audit.filter(a => a.sku === sku) : [...this.audit]; }

  exportData() {
    return {
      items: [...this.items.values()].map(i => ({ ...i })),
      usedKeys: [...this.usedKeys],
      audit: [...this.audit],
      exportedAt: this._now()
    };
  }

  importData(data) {
    this.items.clear();
    for (const i of data.items) this.items.set(i.sku, { ...i });
    this.usedKeys = new Set(data.usedKeys || []);
    this.audit = [...(data.audit || [])];
    this.seq = this.audit.length;
    return { ok: true, count: this.items.size };
  }

  reset() {
    this.items.clear();
    this.audit = [];
    this.usedKeys.clear();
    this.seq = 0;
  }
}

function result(name, passed, details) {
  return { name, passed, details: details || '', elapsedMs: 0 };
}

function fail(name, err) {
  return { name, passed: false, details: String(err), elapsedMs: 0 };
}

async function scenario_create_item(inv) {
  inv.reset();
  const r = inv.createItem('SKU-001', 'Test Widget');
  if (!r.ok) return fail('create_item_returns_item', r.error);
  if (r.item.sku !== 'SKU-001' || r.item.stock !== 0)
    return fail('create_item_returns_item', 'Item data mismatch');
  return result('create_item_returns_item', true, 'SKU-001 created, stock=0');
}

async function scenario_seed_samples(inv) {
  inv.reset();
  const skus = ['SKU-A', 'SKU-B', 'SKU-C', 'SKU-D', 'SKU-E'];
  for (const s of skus) {
    const r = inv.createItem(s, 'Item ' + s);
    if (!r.ok) return fail('seed_creates_5_sample_items', r.error + ' for ' + s);
  }
  if (inv.items.size !== 5) return fail('seed_creates_5_sample_items', 'Expected 5, got ' + inv.items.size);
  return result('seed_creates_5_sample_items', true, '5 items seeded');
}

async function scenario_inbound(inv) {
  inv.reset();
  inv.createItem('SKU-X', 'X');
  const r = inv.inbound('SKU-X', 10);
  if (!r.ok) return fail('inbound_increases_stock', r.error);
  if (r.item.stock !== 10) return fail('inbound_increases_stock', 'Expected 10, got ' + r.item.stock);
  return result('inbound_increases_stock', true, 'Stock 0->10');
}

async function scenario_outbound(inv) {
  inv.reset();
  inv.createItem('SKU-Y', 'Y');
  inv.inbound('SKU-Y', 20);
  const r = inv.outbound('SKU-Y', 8);
  if (!r.ok) return fail('outbound_decreases_stock', r.error);
  if (r.item.stock !== 12) return fail('outbound_decreases_stock', 'Expected 12, got ' + r.item.stock);
  return result('outbound_decreases_stock', true, 'Stock 20->12');
}

async function scenario_outbound_rejects(inv) {
  inv.reset();
  inv.createItem('SKU-Z', 'Z');
  inv.inbound('SKU-Z', 5);
  inv.reserve('SKU-Z', 3);
  const r = inv.outbound('SKU-Z', 4);
  if (r.ok) return fail('outbound_rejects_negative_available', 'Should have rejected');
  if (r.error !== 'INSUFFICIENT_AVAILABLE')
    return fail('outbound_rejects_negative_available', 'Wrong error: ' + r.error);
  return result('outbound_rejects_negative_available', true, 'Rejected outbound=4 when available=2');
}

async function scenario_reserve(inv) {
  inv.reset();
  inv.createItem('SKU-R', 'R');
  inv.inbound('SKU-R', 100);
  const r = inv.reserve('SKU-R', 30);
  if (!r.ok) return fail('reserve_stock_succeeds', r.error);
  if (r.item.reserved !== 30) return fail('reserve_stock_succeeds', 'Expected reserved=30');
  return result('reserve_stock_succeeds', true, 'Reserved 30, available=70');
}

async function scenario_release(inv) {
  inv.reset();
  inv.createItem('SKU-RR', 'RR');
  inv.inbound('SKU-RR', 50);
  inv.reserve('SKU-RR', 20);
  const r = inv.releaseReservation('SKU-RR', 10);
  if (!r.ok) return fail('release_reservation_restores_available', r.error);
  if (r.item.reserved !== 10) return fail('release_reservation_restores_available', 'Expected reserved=10');
  if (r.item.stock - r.item.reserved !== 40)
    return fail('release_reservation_restores_available', 'Expected available=40');
  return result('release_reservation_restores_available', true, 'Released 10, available=40');
}

async function scenario_transfer(inv) {
  inv.reset();
  inv.createItem('SKU-SRC', 'Source');
  inv.createItem('SKU-DST', 'Dest');
  inv.inbound('SKU-SRC', 30);
  const r = inv.transfer('SKU-SRC', 'SKU-DST', 10);
  if (!r.ok) return fail('transfer_moves_stock_between_skus', r.error);
  if (r.from.stock !== 20 || r.to.stock !== 10)
    return fail('transfer_moves_stock_between_skus', 'Stock mismatch');
  return result('transfer_moves_stock_between_skus', true, 'SRC 30->20, DST 0->10');
}

async function scenario_idempotency(inv) {
  inv.reset();
  inv.createItem('SKU-ID', 'Idem');
  const key = randomUUID();
  const r1 = inv.inbound('SKU-ID', 10, { idempotencyKey: key });
  if (!r1.ok) return fail('duplicate_idempotency_key_does_not_double_apply', 'First failed: ' + r1.error);
  const r2 = inv.inbound('SKU-ID', 10, { idempotencyKey: key });
  if (r2.ok) return fail('duplicate_idempotency_key_does_not_double_apply', 'Should reject duplicate');
  const item = inv.items.get('SKU-ID');
  if (item.stock !== 10) return fail('duplicate_idempotency_key_does_not_double_apply', 'Stock doubled: ' + item.stock);
  return result('duplicate_idempotency_key_does_not_double_apply', true, 'Stock=10, dup key rejected');
}

async function scenario_stale_version(inv) {
  inv.reset();
  inv.createItem('SKU-V', 'Versioned');
  inv.inbound('SKU-V', 5);
  const r = inv.adjustStock('SKU-V', 2, 0);
  if (r.ok) return fail('stale_version_update_rejected', 'Should reject stale v0');
  if (r.error !== 'VERSION_MISMATCH')
    return fail('stale_version_update_rejected', 'Wrong error: ' + r.error);
  const r2 = inv.adjustStock('SKU-V', 2, 1);
  if (!r2.ok) return fail('stale_version_update_rejected', 'Correct v1 should work: ' + r2.error);
  return result('stale_version_update_rejected', true, 'Stale v0 rejected, v1 accepted');
}

async function scenario_export_import(inv) {
  inv.reset();
  inv.createItem('SKU-E1', 'Export1');
  inv.createItem('SKU-E2', 'Export2');
  inv.inbound('SKU-E1', 10);
  inv.inbound('SKU-E2', 20);
  inv.reserve('SKU-E1', 3);
  const key = randomUUID();
  inv.inbound('SKU-E1', 5, { idempotencyKey: key });

  const exported = inv.exportData();
  const inv2 = new InventorySystem();
  inv2.importData(exported);

  if (inv2.items.size !== 2) return fail('export_import_roundtrip', 'Item count mismatch');
  const e1 = inv2.items.get('SKU-E1');
  if (e1.stock !== 15 || e1.reserved !== 3)
    return fail('export_import_roundtrip', 'Data mismatch');
  const dup = inv2.inbound('SKU-E1', 5, { idempotencyKey: key });
  if (dup.ok) return fail('export_import_roundtrip', 'Dup key should still reject');
  if (inv2.audit.length !== exported.audit.length)
    return fail('export_import_roundtrip', 'Audit length mismatch');
  return result('export_import_roundtrip', true, 'Roundtrip faithful');
}

async function scenario_audit_events(inv) {
  inv.reset();
  inv.createItem('SKU-Ad', 'Audited');
  inv.inbound('SKU-Ad', 50);
  inv.reserve('SKU-Ad', 15);
  inv.outbound('SKU-Ad', 5);
  inv.releaseReservation('SKU-Ad', 5);
  inv.adjustStock('SKU-Ad', -3, 4);

  const audit = inv.getAudit('SKU-Ad');
  if (audit.length < 5) return fail('audit_events_recorded_for_adjustments', 'Expected >=5, got ' + audit.length);
  const ops = audit.map(a => a.op);
  if (!ops.includes('inbound') || !ops.includes('reserve') || !ops.includes('outbound') ||
      !ops.includes('release') || !ops.includes('adjust'))
    return fail('audit_events_recorded_for_adjustments', 'Missing ops: ' + ops.join(','));
  return result('audit_events_recorded_for_adjustments', true, audit.length + ' audit events');
}

const SCENARIOS = [
  scenario_create_item,
  scenario_seed_samples,
  scenario_inbound,
  scenario_outbound,
  scenario_outbound_rejects,
  scenario_reserve,
  scenario_release,
  scenario_transfer,
  scenario_idempotency,
  scenario_stale_version,
  scenario_export_import,
  scenario_audit_events,
];

async function runScenarios() {
  const inv = new InventorySystem();
  const results = [];
  for (const fn of SCENARIOS) {
    const start = Date.now();
    let r;
    try { r = await fn(inv); } catch (e) { r = fail(fn.name || 'unknown', e); }
    r.elapsedMs = Date.now() - start;
    results.push(r);
  }
  return results;
}

module.exports = { runScenarios, InventorySystem, SCENARIOS };
