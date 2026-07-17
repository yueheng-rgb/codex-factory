/**
 * 幂等 Key 管理
 * 防止用户重复提交同一请求。
 * 真实项目使用数据库唯一约束 + INSERT ON CONFLICT。
 */

const idempotencyStore = new Map<string, { result: unknown; createdAt: number }>();

export function checkIdempotency(key: string): unknown | null {
  const entry = idempotencyStore.get(key);
  if (entry) return entry.result;
  return null;
}

export function saveIdempotency(key: string, result: unknown): void {
  idempotencyStore.set(key, { result, createdAt: Date.now() });
}

export function cleanExpiredIdempotency(maxAgeMs: number = 3600000): void {
  const now = Date.now();
  for (const [key, entry] of idempotencyStore) {
    if (now - entry.createdAt > maxAgeMs) idempotencyStore.delete(key);
  }
}
