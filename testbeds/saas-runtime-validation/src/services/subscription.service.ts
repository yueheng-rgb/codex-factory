import { subscriptions, gid, users } from "../db/store.js";
import { UserRole } from "../types.js";

// SaaS Pack Invariants enforced:
//   subscription_status_controls_access, expired_subscription_cannot_generate,
//   usage_quota_non_negative, quota_decrement_must_be_atomic,
//   admin_required_for_plan_change

export function createSubscription(tenantId: string, plan: string, quotaTotal: number): { id: string } {
  const s = { id: gid("sub"), tenantId, plan, status: "ACTIVE" as const, quotaTotal, quotaRemaining: quotaTotal, expiresAt: new Date(Date.now() + 30*86400000).toISOString() };
  subscriptions.set(s.id, s);
  return { id: s.id };
}

export function getSubscription(tenantId: string) {
  return Array.from(subscriptions.values()).find(s => s.tenantId === tenantId) ?? null;
}

// INVARIANT: subscription_status_controls_access
export function assertSubscriptionActive(tenantId: string): { error: string } | null {
  const sub = getSubscription(tenantId);
  if (!sub) return { error: "NO_SUBSCRIPTION: Tenant has no subscription" };
  if (sub.status !== "ACTIVE") return { error: "SUBSCRIPTION_INACTIVE: Subscription is not active" };
  return null;
}

// INVARIANT: expired_subscription_cannot_generate
export function assertCanGenerate(tenantId: string): { error: string } | null {
  const access = assertSubscriptionActive(tenantId);
  if (access) return access;
  const sub = getSubscription(tenantId)!;
  if (new Date(sub.expiresAt) < new Date()) {
    sub.status = "EXPIRED";
    subscriptions.set(sub.id, sub);
    return { error: "SUBSCRIPTION_EXPIRED: Subscription has expired" };
  }
  return null;
}

// INVARIANT: usage_quota_non_negative
// INVARIANT: quota_decrement_must_be_atomic (simulated atomic with check-then-set)
export function decrementQuota(tenantId: string, amount: number): { remaining: number } | { error: string } {
  const sub = getSubscription(tenantId);
  if (!sub) return { error: "NO_SUBSCRIPTION: Tenant has no subscription" };
  if (sub.quotaRemaining < amount) return { error: "QUOTA_EXCEEDED: Insufficient quota remaining" };
  // Atomic decrement: check THEN set (in real DB: UPDATE ... WHERE quota_remaining >= amount)
  const newRemaining = sub.quotaRemaining - amount;
  if (newRemaining < 0) return { error: "QUOTA_NEGATIVE: Quota would become negative" };
  sub.quotaRemaining = newRemaining;
  subscriptions.set(sub.id, sub);
  return { remaining: newRemaining };
}

// INVARIANT: admin_required_for_plan_change
export function changePlan(tenantId: string, newPlan: string, newQuota: number, userId: string): { error: string } | null {
  const user = users.get(userId);
  if (!user) return { error: "NOT_FOUND: User not found" };
  if (user.tenantId !== tenantId) return { error: "CROSS_TENANT_ACCESS" };
  if (user.role !== "ADMIN") return { error: "FORBIDDEN_PLAN_CHANGE: Only ADMIN can change subscription plan" };
  const sub = getSubscription(tenantId);
  if (!sub) return { error: "NO_SUBSCRIPTION" };
  sub.plan = newPlan;
  sub.quotaTotal = newQuota;
  sub.quotaRemaining = newQuota;
  subscriptions.set(sub.id, sub);
  return null;
}
