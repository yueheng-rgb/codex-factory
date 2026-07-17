// SaaS Runtime Validation Testbed — Test Suite
// Covers: 14 saas-tool invariants + 8 negative controls
// Source: governance/expert-packs/saas-tool/saas-tool-pack.json v1.0.0

import { describe, it, expect, beforeEach } from "vitest";
import { createTenant, createUser, assertTenantAccess, assertWorkspaceActive, deleteWorkspace } from "../src/services/tenant.service.js";
import { createSubscription, assertSubscriptionActive, assertCanGenerate, decrementQuota, changePlan } from "../src/services/subscription.service.js";
import { generate, getGenerationHistory, createApiKey, listApiKeys, storeProviderKey, getProviderKeyRedacted, processBillingEvent, checkRateLimit } from "../src/services/generation.service.js";
import { resetAll, tenants, users, subscriptions } from "../src/db/store.js";

beforeEach(() => resetAll());

function setupTenant(name = "Acme") {
  const t = createTenant(name);
  return t;
}
function setupUser(email = "a@t.com", role = "ADMIN" as const, tenantId: string) {
  createUser(email, role, tenantId);
  // Return the user ID we can use (generated internally)
  const u = Array.from(users.values()).find(u => u.tenantId === tenantId)!;
  return u;
}
function setupSub(tenantId: string, plan = "pro", quota = 1000) {
  createSubscription(tenantId, plan, quota);
}

// ============================================================
// TENANT ISOLATION INVARIANTS (3: tenant_data_isolation, user_cannot_access_other_tenant_data, deleted_workspace_cannot_generate)
// ============================================================

describe("Invariant: tenant_data_isolation", () => {
  it("allows user to access own tenant data", () => {
    const t = setupTenant();
    const u = setupUser("a@t.com", "ADMIN", t.id);
    const r = assertTenantAccess(u.id, t.id);
    expect(r).toBeNull();
  });
});

describe("Invariant: user_cannot_access_other_tenant_data", () => {
  it("blocks cross-tenant data access", () => {
    const t1 = setupTenant("A");
    const t2 = setupTenant("B");
    const u = setupUser("a@t.com", "ADMIN", t1.id);
    const r = assertTenantAccess(u.id, t2.id);
    expect(r).not.toBeNull();
    expect(r!.error).toContain("CROSS_TENANT_ACCESS");
  });
});

describe("Invariant: deleted_workspace_cannot_generate", () => {
  it("blocks generation on deleted workspace", () => {
    const t = setupTenant();
    setupSub(t.id);
    deleteWorkspace(t.id);
    const r = assertWorkspaceActive(t.id);
    expect(r).not.toBeNull();
    expect(r!.error).toContain("WORKSPACE_DELETED");
  });
  it("allows generation on active workspace", () => {
    const t = setupTenant();
    const r = assertWorkspaceActive(t.id);
    expect(r).toBeNull();
  });
});

// ============================================================
// SUBSCRIPTION INVARIANTS (2: subscription_status_controls_access, expired_subscription_cannot_generate)
// ============================================================

describe("Invariant: subscription_status_controls_access", () => {
  it("allows access with active subscription", () => {
    const t = setupTenant();
    setupSub(t.id);
    const r = assertSubscriptionActive(t.id);
    expect(r).toBeNull();
  });
});

describe("Invariant: expired_subscription_cannot_generate", () => {
  it("blocks generation with expired subscription", () => {
    const t = setupTenant();
    createSubscription(t.id, "pro", 100);
    const sub = Array.from(subscriptions.values())[0];
    sub.expiresAt = new Date(Date.now() - 86400000).toISOString(); // yesterday
    subscriptions.set(sub.id, sub);
    const r = assertCanGenerate(t.id);
    expect(r).not.toBeNull();
    expect(r!.error).toContain("SUBSCRIPTION_EXPIRED");
  });
});

// ============================================================
// QUOTA INVARIANTS (2: usage_quota_non_negative, quota_decrement_must_be_atomic)
// ============================================================

describe("Invariant: usage_quota_non_negative", () => {
  it("allows valid quota decrement", () => {
    const t = setupTenant();
    setupSub(t.id, "pro", 100);
    const r = decrementQuota(t.id, 30);
    expect("remaining" in r).toBe(true);
    expect((r as any).remaining).toBe(70);
  });
  it("rejects decrement exceeding quota", () => {
    const t = setupTenant();
    setupSub(t.id, "pro", 10);
    const r = decrementQuota(t.id, 50);
    expect("error" in r && r.error.includes("QUOTA_EXCEEDED")).toBe(true);
  });
});

describe("Invariant: quota_decrement_must_be_atomic", () => {
  it("prevents negative quota after decrement", () => {
    const t = setupTenant();
    setupSub(t.id, "pro", 5);
    // Exact remaining — should pass
    const r1 = decrementQuota(t.id, 5);
    expect("remaining" in r1).toBe(true);
    // Next decrement should fail
    const r2 = decrementQuota(t.id, 1);
    expect("error" in r2 && r2.error.includes("QUOTA_EXCEEDED")).toBe(true);
  });
});

// ============================================================
// GENERATION INVARIANTS (2: generation_cost_must_be_recorded, generation_history_belongs_to_tenant)
// ============================================================

describe("Invariant: generation_cost_must_be_recorded", () => {
  it("records cost on generation", () => {
    const t = setupTenant();
    setupUser("a@t.com", "ADMIN", t.id);
    const u = Array.from(users.values())[0];
    const r = generate({ tenantId: t.id, userId: u.id, model: "gpt-4", prompt: "Hello world" });
    expect("id" in r).toBe(true);
    expect((r as any).cost).toBeGreaterThan(0);
    expect((r as any).tokenCount).toBeGreaterThan(0);
  });
});

describe("Invariant: generation_history_belongs_to_tenant", () => {
  it("returns only tenant-scoped generation history", () => {
    const t1 = setupTenant("A");
    const t2 = setupTenant("B");
    setupUser("a@t.com", "ADMIN", t1.id);
    const u1 = Array.from(users.values()).find(u => u.tenantId === t1.id)!;
    setupUser("b@t.com", "ADMIN", t2.id);
    const u2 = Array.from(users.values()).find(u => u.tenantId === t2.id)!;
    generate({ tenantId: t1.id, userId: u1.id, model: "m", prompt: "A" });
    generate({ tenantId: t2.id, userId: u2.id, model: "m", prompt: "B" });
    const h1 = getGenerationHistory(t1.id);
    expect(h1.length).toBe(1);
    expect(h1[0].prompt).toBe("A");
    const h2 = getGenerationHistory(t2.id);
    expect(h2.length).toBe(1);
    expect(h2[0].prompt).toBe("B");
  });
});

// ============================================================
// API KEY INVARIANTS (2: api_key_never_exposed_to_client, provider_key_server_side_only)
// ============================================================

describe("Invariant: api_key_never_exposed_to_client", () => {
  it("returns masked key, never full key", () => {
    const t = setupTenant();
    const k = createApiKey(t.id, "openai");
    expect(k.key).toBeDefined(); // Full key exists in store
    expect(k.key).toMatch(/^sk-/);
    const listed = listApiKeys(t.id);
    expect(listed.length).toBe(1);
    // CRITICAL: listed keys must NOT have the "key" field
    expect((listed[0] as any).key).toBeUndefined();
    expect(listed[0].maskedKey).toMatch(/^sk-\.\.\./);
  });
});

describe("Invariant: provider_key_server_side_only", () => {
  it("never exposes provider key to client", () => {
    storeProviderKey("openai", "sk-pro-real-secret");
    const r = getProviderKeyRedacted();
    expect(r.present).toBe(true);
    expect(r.value).toBe("***REDACTED***");
    expect(r.value).not.toContain("sk-pro");
  });
});

// ============================================================
// BILLING WEBHOOK + RATE LIMIT INVARIANTS (2)
// ============================================================

describe("Invariant: billing_webhook_idempotency_required", () => {
  it("processes webhook once, skips duplicate", () => {
    const r1 = processBillingEvent("evt-1", "t1");
    expect("processed" in r1 && r1.processed === true).toBe(true);
    const r2 = processBillingEvent("evt-1", "t1");
    expect("processed" in r2 && (r2 as any).processed === false).toBe(true); // idempotent
  });
});

describe("Invariant: rate_limit_enforced_per_user_or_tenant", () => {
  it("allows requests under limit", () => {
    const r = checkRateLimit("user-1");
    expect(r.allowed).toBe(true);
    expect(r.remaining).toBe(99);
  });
  it("blocks requests over limit", () => {
    for (let i = 0; i < 100; i++) checkRateLimit("user-2");
    const r = checkRateLimit("user-2");
    expect(r.allowed).toBe(false);
    expect(r.remaining).toBe(0);
  });
});

// ============================================================
// ADMIN PERMISSION INVARIANT (1)
// ============================================================

describe("Invariant: admin_required_for_plan_change", () => {
  it("allows ADMIN to change plan", () => {
    const t = setupTenant();
    setupSub(t.id);
    const u = setupUser("admin@t.com", "ADMIN", t.id);
    const r = changePlan(t.id, "enterprise", 5000, u.id);
    expect(r).toBeNull();
  });
  it("rejects MEMBER from changing plan", () => {
    const t = setupTenant();
    setupSub(t.id);
    const u = setupUser("member@t.com", "MEMBER", t.id);
    const r = changePlan(t.id, "enterprise", 5000, u.id);
    expect(r).not.toBeNull();
    expect(r!.error).toContain("FORBIDDEN_PLAN_CHANGE");
  });
});

// ============================================================
// NEGATIVE CONTROLS (8)
// ============================================================

describe("Negative Control 1: cross-tenant data access — BLOCKED", () => {
  it("rejects accessing other tenant data", () => {
    const t1 = setupTenant("A"); const t2 = setupTenant("B");
    const u = setupUser("a@t.com", "ADMIN", t1.id);
    expect(assertTenantAccess(u.id, t2.id)!.error).toContain("CROSS_TENANT_ACCESS");
  });
});

describe("Negative Control 2: expired subscription generates — BLOCKED", () => {
  it("rejects generation on expired sub", () => {
    const t = setupTenant(); setupSub(t.id);
    const sub = Array.from(subscriptions.values())[0];
    sub.status = "EXPIRED"; subscriptions.set(sub.id, sub);
    expect(assertCanGenerate(t.id)!.error).toContain("SUBSCRIPTION_INACTIVE");
  });
});

describe("Negative Control 3: quota goes negative — BLOCKED", () => {
  it("rejects decrement beyond quota", () => {
    const t = setupTenant(); setupSub(t.id, "pro", 5);
    expect("error" in decrementQuota(t.id, 20)).toBe(true);
  });
});

describe("Negative Control 4: generation without cost recording — IMPOSSIBLE", () => {
  it("always records cost on generation", () => {
    const t = setupTenant();
    const u = setupUser("a@t.com", "ADMIN", t.id);
    const r = generate({ tenantId: t.id, userId: u.id, model: "m", prompt: "test" });
    expect((r as any).cost).toBeGreaterThan(0);
  });
});

describe("Negative Control 5: API key returned to client — REDACTED", () => {
  it("never exposes full API key to client", () => {
    const t = setupTenant(); createApiKey(t.id, "openai");
    const listed = listApiKeys(t.id);
    listed.forEach(k => { expect((k as any).key).toBeUndefined(); expect(k.maskedKey).toMatch(/^sk-\.\.\./); });
  });
});

describe("Negative Control 6: provider key in client response — REDACTED", () => {
  it("provider key is never in any response", () => {
    storeProviderKey("openai", "sk-real-secret-key");
    const r = getProviderKeyRedacted();
    expect(r.value).not.toContain("sk-real");
  });
});

describe("Negative Control 7: duplicate billing webhook — IDEMPOTENT", () => {
  it("processes event only once", () => {
    expect((processBillingEvent("evt-x", "t1") as any).processed).toBe(true);
    expect((processBillingEvent("evt-x", "t1") as any).processed).toBe(false);
  });
});

describe("Negative Control 8: non-admin changes plan — BLOCKED", () => {
  it("rejects MEMBER plan change", () => {
    const t = setupTenant(); setupSub(t.id);
    const u = setupUser("m@t.com", "MEMBER", t.id);
    expect(changePlan(t.id, "pro", 100, u.id)!.error).toContain("FORBIDDEN_PLAN_CHANGE");
  });
});

// ============================================================
// EDGE CASES
// ============================================================

describe("Edge cases", () => {
  it("rejects user creation on deleted workspace", () => {
    const t = setupTenant(); deleteWorkspace(t.id);
    const r = createUser("x@t.com", "ADMIN", t.id);
    expect("error" in r && r.error.includes("WORKSPACE_DELETED")).toBe(true);
  });
});
