// Product & Inventory Service — Ecommerce Pack
// Invariants: price_non_negative, inventory_non_negative, stock_delta_must_be_audited, archived_product_not_sellable, admin_required_for_price_change, destructive_action_requires_confirmation, status_transition_allowed

import type { AdminUser, ProductStatus } from "../types/index.js";
import { products, adjustments, audit, nid, tenants } from "../db/store.js";
import { checkPerm } from "./auth.service.js";
import { err, ok } from "../errors/index.js";
import { ERR, ALLOWED_STATUS } from "../types/index.js";

export function createProduct(uid: string | null, data: { name: string; price: number; inventory: number; tenantId: string }) {
  const a = checkPerm(uid, "product:write");
  if ("error" in a) return a;
  const u = a.data as AdminUser;
  if (u.tenantId !== data.tenantId) return err(ERR.TENANT_ISOLATION, "Cannot create product for other tenant", 403);
  if (data.price < 0) return err(ERR.PRICE_NEGATIVE, "Price must be non-negative");
  if (data.inventory < 0) return err(ERR.INVENTORY_NEGATIVE, "Inventory must be non-negative");
  const now = new Date().toISOString();
  const p = { id: nid("prod"), name: data.name, price: data.price, isFree: data.price === 0, inventory: data.inventory, status: "DRAFT" as ProductStatus, tenantId: data.tenantId, createdBy: u.id, createdAt: now, updatedAt: now, deletedAt: null as string | null };
  products.set(p.id, p);
  audit({ actorId:u.id, action:"PRODUCT_CREATED", targetType:"product", targetId:p.id, details: `Created ${p.name}`, tenantId:u.tenantId });
  return ok(p);
}

export function adjustInventory(uid: string | null, productId: string, delta: number, reason: string) {
  const a = checkPerm(uid, "inventory:write");
  if ("error" in a) return a;
  const u = a.data as AdminUser;
  const p = products.get(productId);
  if (!p || p.deletedAt) return err("NOT_FOUND", "Product not found", 404);
  if (u.tenantId !== p.tenantId) return err(ERR.TENANT_ISOLATION, "Cross-tenant inventory forbidden", 403);
  if (p.status === "ARCHIVED") return err(ERR.STALE_DATA, "Archived product not sellable");
  if (p.inventory + delta < 0) return err(ERR.INVENTORY_NEGATIVE, `Inventory would go negative: ${p.inventory} + ${delta}`);
  p.inventory += delta; p.updatedAt = new Date().toISOString(); products.set(productId, p);
  const adj = { productId, delta, reason, operatorId: u.id, timestamp: new Date().toISOString() };
  adjustments.push(adj);
  audit({ actorId:u.id, action:"INVENTORY_ADJUSTED", targetType:"product", targetId:productId, details:`${delta>0?"+":""}${delta} — ${reason}`, tenantId:u.tenantId });
  return ok(p);
}

export function updatePrice(uid: string | null, productId: string, newPrice: number) {
  const a = checkPerm(uid, "product:write");
  if ("error" in a) return a;
  const u = a.data as AdminUser;
  if (u.role !== "SUPER_ADMIN" && u.role !== "ADMIN") return err(ERR.PROTECTED_FIELD, "Only ADMIN+ can change prices", 403);
  const p = products.get(productId);
  if (!p || p.deletedAt) return err("NOT_FOUND", "Product not found", 404);
  if (newPrice < 0) return err(ERR.PRICE_NEGATIVE, "Price must be non-negative");
  p.price = newPrice; p.isFree = newPrice === 0; p.updatedAt = new Date().toISOString(); products.set(productId, p);
  audit({ actorId:u.id, action:"PRICE_CHANGED", targetType:"product", targetId:productId, details:`Price -> ${newPrice}`, tenantId:u.tenantId });
  return ok(p);
}

export function changeStatus(uid: string | null, productId: string, newStatus: ProductStatus, token?: string) {
  const a = checkPerm(uid, "product:write");
  if ("error" in a) return a;
  const u = a.data as AdminUser;
  const p = products.get(productId);
  if (!p || p.deletedAt) return err("NOT_FOUND", "Product not found", 404);
  if (!ALLOWED_STATUS[p.status].includes(newStatus)) return err(ERR.INVALID_STATUS, `Cannot transition ${p.status} -> ${newStatus}`);
  if (newStatus === "DELETED" && token !== `confirm-delete-${productId}`) return err(ERR.CONFIRMATION, "Destructive action requires confirmation token");
  p.status = newStatus;
  if (newStatus === "DELETED") p.deletedAt = new Date().toISOString();
  p.updatedAt = new Date().toISOString(); products.set(productId, p);
  audit({ actorId:u.id, action:"STATUS_CHANGED", targetType:"product", targetId:productId, details:`${p.status} -> ${newStatus}`, tenantId:u.tenantId });
  return ok(p);
}
