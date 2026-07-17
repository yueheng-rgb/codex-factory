/**
 * Idempotency Key Management
 * Clients MUST send Idempotency-Key header (crypto.randomUUID()) per logical operation.
 * Server scopes by userId + operation + rawKey.
 *
 * Rules:
 * - Same userId + operation + key + same payload = return cached result (no double-deduct)
 * - Same userId + operation + key + different payload = 409 IDEMPOTENCY_CONFLICT
 * - Different users with same raw key = independent (scoped by userId)
 *
 * Uses globalThis for shared state across Next.js route modules.
 * Real project: database unique constraint + INSERT ON CONFLICT.
 */

interface IdempotencyEntry {
  result: unknown;
  createdAt: number;
  fingerprint: string;
}

const globalKey = "__saas_idempotency__";
function getStore(): Map<string, IdempotencyEntry> {
  if (!(globalThis as any)[globalKey]) {
    (globalThis as any)[globalKey] = new Map<string, IdempotencyEntry>();
  }
  return (globalThis as any)[globalKey];
}

function buildStoreKey(userId: string, operation: string, rawKey: string): string {
  return `${userId}::${operation}::${rawKey}`;
}

/**
 * Check if idempotency key has already been processed for this user+operation.
 * Returns { hit: true, result } if cached, { hit: true, conflict: true } if conflict, { hit: false } otherwise.
 */
export function checkIdempotency(
  userId: string,
  operation: string,
  rawKey: string,
  currentFingerprint: string
): { hit: boolean; conflict?: boolean; result?: unknown } {
  const storeKey = buildStoreKey(userId, operation, rawKey);
  const entry = getStore().get(storeKey);
  if (!entry) return { hit: false };

  if (entry.fingerprint === currentFingerprint) {
    return { hit: true, result: entry.result };
  }
  return { hit: true, conflict: true };
}

/**
 * Save idempotency entry with fingerprint.
 */
export function saveIdempotency(
  userId: string,
  operation: string,
  rawKey: string,
  result: unknown,
  fingerprint: string
): void {
  const storeKey = buildStoreKey(userId, operation, rawKey);
  getStore().set(storeKey, { result, createdAt: Date.now(), fingerprint });
}

/**
 * Clean expired idempotency records.
 */
export function cleanExpiredIdempotency(maxAgeMs: number = 3600000): void {
  const store = getStore();
  const now = Date.now();
  for (const [key, entry] of store) {
    if (now - entry.createdAt > maxAgeMs) store.delete(key);
  }
}
