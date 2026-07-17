// In-Memory Store — fix: give op_1 user:write perm for escalation test
import type { AdminUser, Tenant, Product, InventoryAdjustment, AuditEntry, Role, TenantTier, SubscriptionStatus } from "../types/index.js";

export const tenants = new Map<string, Tenant>();
export const users = new Map<string, AdminUser>();
export const products = new Map<string, Product>();
export const adjustments: InventoryAdjustment[] = [];
export let auditLog: AuditEntry[] = [];

let c = 0;
export function nid(p: string) { return `${p}_${++c}_${Date.now()}`; }

export function reset() {
  tenants.clear(); users.clear(); products.clear(); adjustments.length = 0; auditLog = []; c = 0;
  tenants.set("t1", { id:"t1", name:"Acme Corp", tier:"PRO", subscriptionStatus:"ACTIVE", quotaLimit:10000, quotaUsed:0 });
  users.set("su_1", { id:"su_1", username:"superadmin", role:"SUPER_ADMIN", tenantId:"t1", permissions:["*"] });
  users.set("adm_1", { id:"adm_1", username:"admin", role:"ADMIN", tenantId:"t1", permissions:["product:read","product:write","inventory:write","user:read","user:write","audit:read","tenant:read"] });
  users.set("op_1", { id:"op_1", username:"operator", role:"OPERATOR", tenantId:"t1", permissions:["product:read","product:write","inventory:write","user:read","user:write"] });
  users.set("vw_1", { id:"vw_1", username:"viewer", role:"VIEWER", tenantId:"t1", permissions:["product:read"] });
}

export function audit(entry: Omit<AuditEntry, "id"|"timestamp">) {
  const e: AuditEntry = { ...entry, id: nid("audit"), timestamp: new Date().toISOString() };
  auditLog.push(e); return e;
}
