// Mini Inventory Admin ¡ª Inventory Service with Business Invariants
import type { Item, ItemStatus, PaginatedResult } from "../types.js";
import { PROTECTED_FIELDS, VALID_STATUS_TRANSITIONS } from "../types.js";
import * as store from "../db/store.js";

interface ServiceResult<T> {
  data?: T;
  error?: { code: string; message: string; details?: Record<string, unknown> };
}

// ============================================
// Business Invariants
// ============================================

function checkPriceInvariant(price: number, explicitFree: boolean): string | null {
  // invariant: price_non_negative
  if (price < 0) return "Price must be non-negative (price_non_negative)";
  // invariant: price_not_zero_unless_explicit_free
  if (price === 0 && !explicitFree) return "Price cannot be zero unless explicitFree is set (price_not_zero_unless_explicit_free)";
  return null;
}

function checkInventoryInvariant(inventory: number): string | null {
  // invariant: inventory_non_negative
  if (inventory < 0) return "Inventory must be non-negative (inventory_non_negative)";
  return null;
}

function checkStatusTransition(current: ItemStatus, next: ItemStatus): string | null {
  // invariant: status_transition_allowed
  const allowed = VALID_STATUS_TRANSITIONS[current];
  if (!allowed?.includes(next)) {
    return `Status transition from ${current} to ${next} is not allowed (status_transition_allowed)`;
  }
  return null;
}

function checkArchivedNotMutable(status: ItemStatus): string | null {
  // invariant: archived_entity_not_mutable
  if (status === "ARCHIVED") return "Archived items cannot be modified (archived_entity_not_mutable)";
  return null;
}

function checkProtectedFields(body: Record<string, unknown>): string | null {
  // invariant: user_cannot_modify_protected_fields
  const blocked = PROTECTED_FIELDS.filter(f => f in body);
  if (blocked.length > 0) {
    return `Cannot modify protected fields: ${blocked.join(", ")} (user_cannot_modify_protected_fields)`;
  }
  return null;
}

// ============================================
// Service Methods
// ============================================

export function listItems(params: {
  page: number;
  pageSize: number;
  search?: string;
  category?: string;
  status?: string;
}): PaginatedResult<Item> {
  let all = store.getAll();
  if (params.search) {
    const q = params.search.toLowerCase();
    all = all.filter(i => i.name.toLowerCase().includes(q) || i.description.toLowerCase().includes(q));
  }
  if (params.category) all = all.filter(i => i.category === params.category);
  if (params.status) all = all.filter(i => i.status === params.status);

  const total = all.length;
  const totalPages = Math.ceil(total / params.pageSize);
  const start = (params.page - 1) * params.pageSize;
  const items = all.slice(start, start + params.pageSize);

  return { items, page: params.page, pageSize: params.pageSize, total, totalPages };
}

export function getItem(id: string): Item | undefined {
  return store.getById(id);
}

export function createItem(body: Record<string, unknown>): ServiceResult<Item> {
  const protectedCheck = checkProtectedFields(body);
  if (protectedCheck) return { error: { code: "VALIDATION_ERROR", message: protectedCheck } };

  const name = String(body.name || "").trim();
  if (!name) return { error: { code: "VALIDATION_ERROR", message: "name is required" } };

  const price = body.price !== undefined ? Number(body.price) : 0;
  const explicitFree = Boolean(body.explicitFree);
  const priceCheck = checkPriceInvariant(price, explicitFree);
  if (priceCheck) return { error: { code: "BUSINESS_RULE_VIOLATION", message: priceCheck } };

  const inventory = body.inventory !== undefined ? Number(body.inventory) : 0;
  const invCheck = checkInventoryInvariant(inventory);
  if (invCheck) return { error: { code: "BUSINESS_RULE_VIOLATION", message: invCheck } };

  const status = (body.status as ItemStatus) || "DRAFT";
  if (!["DRAFT", "ACTIVE", "DISCONTINUED", "ARCHIVED"].includes(status)) {
    return { error: { code: "VALIDATION_ERROR", message: `Invalid status: ${status}` } };
  }

  const now = new Date().toISOString();
  const item: Item = {
    id: store.generateId(),
    name,
    description: String(body.description || ""),
    price,
    explicitFree,
    inventory,
    category: String(body.category || "general"),
    status,
    createdAt: now,
    updatedAt: now,
  };

  store.insert(item);
  return { data: item };
}

export function updateItem(id: string, body: Record<string, unknown>): ServiceResult<Item> {
  const existing = store.getById(id);
  if (!existing) return { error: { code: "NOT_FOUND", message: `Item "${id}" not found` } };

  const archivedCheck = checkArchivedNotMutable(existing.status);
  if (archivedCheck) return { error: { code: "BUSINESS_RULE_VIOLATION", message: archivedCheck } };

  const protectedCheck = checkProtectedFields(body);
  if (protectedCheck) return { error: { code: "VALIDATION_ERROR", message: protectedCheck } };

  if ("price" in body) {
    const price = Number(body.price);
    const explicitFree = "explicitFree" in body ? Boolean(body.explicitFree) : existing.explicitFree;
    const priceCheck = checkPriceInvariant(price, explicitFree);
    if (priceCheck) return { error: { code: "BUSINESS_RULE_VIOLATION", message: priceCheck } };
  }

  if ("inventory" in body) {
    const invCheck = checkInventoryInvariant(Number(body.inventory));
    if (invCheck) return { error: { code: "BUSINESS_RULE_VIOLATION", message: invCheck } };
  }

  const updated = store.update(id, body);
  return { data: updated! };
}

export function updateItemStatus(id: string, newStatus: string): ServiceResult<Item> {
  const existing = store.getById(id);
  if (!existing) return { error: { code: "NOT_FOUND", message: `Item "${id}" not found` } };

  const transitionCheck = checkStatusTransition(existing.status, newStatus as ItemStatus);
  if (transitionCheck) return { error: { code: "BUSINESS_RULE_VIOLATION", message: transitionCheck } };

  const updated = store.update(id, { status: newStatus as ItemStatus });
  return { data: updated! };
}

export function adjustInventory(id: string, delta: number): ServiceResult<Item> {
  const existing = store.getById(id);
  if (!existing) return { error: { code: "NOT_FOUND", message: `Item "${id}" not found` } };

  const archivedCheck = checkArchivedNotMutable(existing.status);
  if (archivedCheck) return { error: { code: "BUSINESS_RULE_VIOLATION", message: archivedCheck } };

  const newInventory = existing.inventory + delta;
  const invCheck = checkInventoryInvariant(newInventory);
  if (invCheck) return { error: { code: "BUSINESS_RULE_VIOLATION", message: invCheck } };

  const updated = store.update(id, { inventory: newInventory });
  return { data: updated! };
}

export function deleteItem(id: string): ServiceResult<void> {
  const existing = store.getById(id);
  if (!existing) return { error: { code: "NOT_FOUND", message: `Item "${id}" not found` } };
  // destructive_action_requires_confirmation: only soft-archive, never hard delete
  return { error: { code: "BUSINESS_RULE_VIOLATION", message: "Hard delete not allowed; archive the item instead (destructive_action_requires_confirmation)" } };
}
