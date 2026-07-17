import { products, auditLog, generateId } from "../db/store.js";
import { InventoryAudit } from "../types.js";

// Ecommerce Pack Invariants enforced:
//   inventory_non_negative, stock_delta_must_be_audited

export function adjustInventory(
  productId: string, delta: number, operatorId: string, reason: string
): { newQuantity: number; audit: InventoryAudit } | { error: string } {
  const product = products.get(productId);
  if (!product) return { error: "NOT_FOUND: Product not found" };

  const newQuantity = product.inventory + delta;

  // INVARIANT: inventory_non_negative
  if (newQuantity < 0) {
    return { error: "INVENTORY_NEGATIVE: Inventory cannot be negative" };
  }

  const audit: InventoryAudit = {
    id: generateId("audit"),
    productId,
    previousQuantity: product.inventory,
    newQuantity,
    delta,
    operatorId,
    reason,
    timestamp: new Date().toISOString()
  };

  // INVARIANT: stock_delta_must_be_audited
  auditLog.push(audit);

  product.inventory = newQuantity;
  product.updatedAt = new Date().toISOString();
  products.set(productId, product);

  return { newQuantity, audit };
}

export function getAuditLog(productId?: string): InventoryAudit[] {
  if (productId) {
    return auditLog.filter(a => a.productId === productId);
  }
  return [...auditLog];
}
