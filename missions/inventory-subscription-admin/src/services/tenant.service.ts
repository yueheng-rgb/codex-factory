// Tenant & Subscription Service — SaaS Tool Pack
// Invariants: tenant_data_isolation, subscription_status_controls_access, usage_quota_non_negative, quota_decrement_must_be_atomic

import type { AdminUser } from "../types/index.js";
import { tenants, audit } from "../db/store.js";
import { checkPerm } from "./auth.service.js";
import { err, ok } from "../errors/index.js";
import { ERR } from "../types/index.js";

export function getTenant(uid: string | null, tenantId: string) {
  const a = checkPerm(uid, "tenant:read");
  if ("error" in a) return a;
  const u = a.data as AdminUser;
  if (u.tenantId !== tenantId && u.role !== "SUPER_ADMIN") return err(ERR.TENANT_ISOLATION, "Cannot access other tenant data", 403);
  const t = tenants.get(tenantId);
  return t ? ok(t) : err("NOT_FOUND", "Tenant not found", 404);
}

export function checkQuota(tenantId: string, amount: number) {
  const t = tenants.get(tenantId);
  if (!t) return err("NOT_FOUND", "Tenant not found", 404);
  if (t.subscriptionStatus !== "ACTIVE") return err(ERR.SUBSCRIPTION_EXPIRED, "Subscription not active");
  if (amount < 0) return err(ERR.QUOTA_EXCEEDED, "Quota amount must be non-negative");
  if (t.quotaUsed + amount > t.quotaLimit) return err(ERR.QUOTA_EXCEEDED, `Quota exceeded: ${t.quotaUsed}/${t.quotaLimit} + ${amount}`);
  t.quotaUsed += amount; tenants.set(tenantId, t);
  audit({ actorId:"system", action:"QUOTA_CONSUMED", targetType:"tenant", targetId:tenantId, details:`${amount} consumed, ${t.quotaUsed}/${t.quotaLimit}`, tenantId });
  return ok({ remaining: t.quotaLimit - t.quotaUsed, used: t.quotaUsed, limit: t.quotaLimit });
}

export function updateSubscription(uid: string | null, tenantId: string, status: string) {
  const a = checkPerm(uid, "tenant:read");
  if ("error" in a) return a;
  const u = a.data as AdminUser;
  if (u.role !== "SUPER_ADMIN") return err(ERR.PROTECTED_FIELD, "Only SUPER_ADMIN can change subscriptions", 403);
  const t = tenants.get(tenantId);
  if (!t) return err("NOT_FOUND", "Tenant not found", 404);
  t.subscriptionStatus = status as any; tenants.set(tenantId, t);
  audit({ actorId:u.id, action:"SUBSCRIPTION_CHANGED", targetType:"tenant", targetId:tenantId, details:`Status -> ${status}`, tenantId });
  return ok(t);
}
