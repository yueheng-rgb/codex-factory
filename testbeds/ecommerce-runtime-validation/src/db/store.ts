import { Product, Order, InventoryAudit, PaymentCallback } from "../types.js";

// In-memory stores for runtime validation testbed
// NOT production — data lost on restart

export const products = new Map<string, Product>();
export const orders = new Map<string, Order>();
export const auditLog: InventoryAudit[] = [];
export const processedPayments = new Set<string>(); // For idempotency check

let nextId = 1;
export function generateId(prefix: string): string {
  return `${prefix}-${nextId++}-${Date.now()}`;
}

export function resetStores(): void {
  products.clear();
  orders.clear();
  auditLog.length = 0;
  processedPayments.clear();
  nextId = 1;
}
