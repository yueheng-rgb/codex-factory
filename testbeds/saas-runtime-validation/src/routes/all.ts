import { FastifyInstance } from "fastify";
import { createTenant, createUser, assertTenantAccess, assertWorkspaceActive, deleteWorkspace, getUserTenant } from "../services/tenant.service.js";
import { createSubscription, getSubscription, assertCanGenerate, decrementQuota, changePlan } from "../services/subscription.service.js";
import { generate, getGenerationHistory, createApiKey, listApiKeys, storeProviderKey, getProviderKeyRedacted, processBillingEvent, checkRateLimit } from "../services/generation.service.js";
import { users } from "../db/store.js";

function getUserId(req: any): string { return req.headers["x-user-id"] || "anon"; }

export function registerSaaSRoutes(app: FastifyInstance): void {
  app.get("/health", async () => ({ ok: true, data: { service: "saas-runtime-validation", version: "1.0.0" } }));

  // Tenant
  app.post("/api/tenants", async (req) => { const t = createTenant((req.body as any).name || "default"); return { ok: true, data: t }; });
  app.post("/api/tenants/:id/delete", async (req) => { const e = deleteWorkspace((req.params as any).id); if (e) return { ok: false, error: { code: e.error.split(":")[0], message: e.error.split(": ")[1] || e.error } }; return { ok: true }; });

  // User
  app.post("/api/users", async (req) => {
    const b = req.body as any;
    const r = createUser(b.email || "test@test.com", b.role || "MEMBER", b.tenantId);
    if ("error" in r) return { ok: false, error: { code: r.error.split(":")[0], message: r.error.split(": ")[1] || r.error } };
    return { ok: true, data: r };
  });

  // Subscription
  app.post("/api/subscriptions", async (req) => {
    const b = req.body as any;
    const r = createSubscription(b.tenantId, b.plan || "free", b.quotaTotal || 1000);
    return { ok: true, data: r };
  });
  app.post("/api/subscriptions/change-plan", async (req, reply) => {
    const b = req.body as any;
    const r = changePlan(b.tenantId, b.plan, b.quota, getUserId(req));
    if (r) { reply.code(403); return { ok: false, error: { code: r.error.split(":")[0], message: r.error.split(": ")[1] || r.error } }; }
    return { ok: true };
  });

  // Generation (with rate limit + quota + subscription gate)
  app.post("/api/generate", async (req, reply) => {
    const userId = getUserId(req);
    const b = req.body as any;

    // Rate limit check
    const rl = checkRateLimit(userId);
    if (!rl.allowed) { reply.code(429); return { ok: false, error: { code: "RATE_LIMITED", message: "Rate limit exceeded" } }; }

    // Tenant access check
    const tenantErr = assertTenantAccess(userId, b.tenantId);
    if (tenantErr) { reply.code(403); return { ok: false, error: { code: tenantErr.error.split(":")[0], message: tenantErr.error.split(": ")[1] } }; }

    // Workspace active check
    const wsErr = assertWorkspaceActive(b.tenantId);
    if (wsErr) { reply.code(403); return { ok: false, error: { code: wsErr.error.split(":")[0], message: wsErr.error.split(": ")[1] } }; }

    // Subscription gate
    const subErr = assertCanGenerate(b.tenantId);
    if (subErr) { reply.code(402); return { ok: false, error: { code: subErr.error.split(":")[0], message: subErr.error.split(": ")[1] } }; }

    // Quota decrement
    const quotaResult = decrementQuota(b.tenantId, 10);
    if ("error" in quotaResult) { reply.code(400); return { ok: false, error: { code: quotaResult.error.split(":")[0], message: quotaResult.error.split(": ")[1] } }; }

    const result = generate({ tenantId: b.tenantId, userId, model: b.model || "test-model", prompt: b.prompt || "test" });
    return { ok: true, data: { ...result, remainingQuota: (quotaResult as any).remaining } };
  });

  // Generation history
  app.get("/api/generations/:tenantId", async (req, reply) => {
    const { tenantId } = req.params as any;
    const userId = getUserId(req);
    const tenantErr = assertTenantAccess(userId, tenantId);
    if (tenantErr) { reply.code(403); return { ok: false, error: { code: tenantErr.error.split(":")[0], message: tenantErr.error.split(": ")[1] } }; }
    return { ok: true, data: getGenerationHistory(tenantId) };
  });

  // API Keys (SAFE — masked, never exposes full key)
  app.post("/api/api-keys", async (req) => {
    const b = req.body as any;
    const key = createApiKey(b.tenantId, b.provider || "openai");
    // NEVER return the full key — only masked + id
    return { ok: true, data: { id: key.id, maskedKey: key.maskedKey, provider: key.provider } };
  });
  app.get("/api/api-keys/:tenantId", async (req) => {
    return { ok: true, data: listApiKeys((req.params as any).tenantId) };
  });

  // Provider key (server-side only, NEVER exposed)
  app.post("/api/provider-key", async () => {
    storeProviderKey("openai", "sk-pro-very-secret-real-key-12345");
    return { ok: true, data: getProviderKeyRedacted() };
  });

  // Billing webhook
  app.post("/api/billing-webhook", async (req) => {
    const b = req.body as any;
    const r = processBillingEvent(b.eventId, b.tenantId);
    return { ok: true, data: r };
  });
}
