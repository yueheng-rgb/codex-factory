import { generations, apiKeys, providerKeys, processedEvents, gid } from "../db/store.js";
import { GenerationRequest, GenerationResult, ApiKey } from "../types.js";

// SaaS Pack Invariants enforced:
//   generation_cost_must_be_recorded, generation_history_belongs_to_tenant,
//   api_key_never_exposed_to_client, provider_key_server_side_only,
//   billing_webhook_idempotency_required, rate_limit_enforced_per_user_or_tenant

// --- GENERATION ---

// INVARIANT: generation_cost_must_be_recorded
export function generate(req: GenerationRequest): GenerationResult | { error: string } {
  // Simulated AI generation
  const tokenCount = req.prompt.length + 20;
  const costPerToken = 0.0001;
  const cost = Math.round(tokenCount * costPerToken * 10000) / 10000;

  const result: GenerationResult = {
    id: gid("gen"),
    tenantId: req.tenantId,
    userId: req.userId,
    model: req.model,
    prompt: req.prompt,
    output: `Generated response for: ${req.prompt.slice(0, 50)}`,
    tokenCount,
    cost,
    createdAt: new Date().toISOString()
  };
  generations.set(result.id, result);
  return result;
}

// INVARIANT: generation_history_belongs_to_tenant
export function getGenerationHistory(tenantId: string): GenerationResult[] {
  return Array.from(generations.values()).filter(g => g.tenantId === tenantId);
}

// --- API KEYS ---

// INVARIANT: api_key_never_exposed_to_client
export function createApiKey(tenantId: string, provider: string): ApiKey {
  const rawKey = `sk-${gid("key")}-${Math.random().toString(36).slice(2)}`;
  const key: ApiKey = {
    id: gid("apk"),
    tenantId,
    key: rawKey,              // FULL key — NEVER returned to client
    maskedKey: `sk-...${rawKey.slice(-4)}`,  // MASKED — safe for client
    provider,
    createdAt: new Date().toISOString()
  };
  apiKeys.set(key.id, key);
  return key;
}

// Returns SAFE representation — masked key only
export function listApiKeys(tenantId: string): Omit<ApiKey, "key">[] {
  return Array.from(apiKeys.values())
    .filter(k => k.tenantId === tenantId)
    .map(({ key, ...safe }) => safe);
}

// INVARIANT: provider_key_server_side_only
export function storeProviderKey(provider: string, apiKey: string): void {
  providerKeys.set(provider, apiKey); // NEVER exposed through any API
}

export function hasProviderKey(provider: string): boolean {
  return providerKeys.has(provider);
}

// CONFIRM: provider key is NEVER in any response
export function getProviderKeyRedacted(): { present: boolean; value: string } {
  return { present: true, value: "***REDACTED***" };
}

// --- BILLING WEBHOOK ---

// INVARIANT: billing_webhook_idempotency_required
export function processBillingEvent(eventId: string, tenantId: string): { processed: boolean } | { error: string } {
  if (processedEvents.has(eventId)) {
    return { processed: false }; // Idempotent — already processed
  }
  processedEvents.add(eventId);
  // In real system: update subscription, add credits, etc.
  return { processed: true };
}

// --- RATE LIMITING ---

// INVARIANT: rate_limit_enforced_per_user_or_tenant (simulated via quota gate)
const requestCounts = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 100;
const RATE_WINDOW_MS = 60000;

export function checkRateLimit(key: string): { allowed: boolean; remaining: number } {
  const now = Date.now();
  const entry = requestCounts.get(key);
  if (!entry || now > entry.resetAt) {
    requestCounts.set(key, { count: 1, resetAt: now + RATE_WINDOW_MS });
    return { allowed: true, remaining: RATE_LIMIT - 1 };
  }
  if (entry.count >= RATE_LIMIT) {
    return { allowed: false, remaining: 0 };
  }
  entry.count++;
  return { allowed: true, remaining: RATE_LIMIT - entry.count };
}
