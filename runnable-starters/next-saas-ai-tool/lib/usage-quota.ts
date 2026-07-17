/**
 * User Quota Management - Daily Reset
 * Each user gets 3 free generations per day.
 * Uses globalThis for shared state across Next.js route modules.
 * Real project MUST use database transactions for quota operations.
 */

export interface UserQuota {
  userId: string;
  dailyLimit: number;
  usedToday: number;
  total: number;
  used: number;
  lastResetDate: string;
}

const globalKey = "__saas_usage_quota__";
function getStore(): Map<string, UserQuota> {
  if (!(globalThis as any)[globalKey]) {
    (globalThis as any)[globalKey] = new Map<string, UserQuota>();
  }
  return (globalThis as any)[globalKey];
}

function todayStr(): string {
  return new Date().toISOString().slice(0, 10);
}

export function getQuota(userId: string): UserQuota {
  const today = todayStr();
  const store = getStore();
  if (!store.has(userId)) {
    store.set(userId, { userId, dailyLimit: 3, usedToday: 0, total: 3, used: 0, lastResetDate: today });
  }
  const quota = store.get(userId)!;
  if (quota.lastResetDate !== today) {
    quota.usedToday = 0;
    quota.lastResetDate = today;
  }
  quota.total = quota.dailyLimit;
  quota.used = quota.usedToday;
  return quota;
}

export function tryDeductQuota(userId: string): boolean {
  const quota = getQuota(userId);
  if (quota.usedToday >= quota.dailyLimit) return false;
  quota.usedToday++;
  quota.used = quota.usedToday;
  return true;
}

export function restoreQuota(userId: string): void {
  const quota = getQuota(userId);
  if (quota.usedToday > 0) {
    quota.usedToday--;
    quota.used = quota.usedToday;
  }
}

export function getRemaining(userId: string): number {
  const quota = getQuota(userId);
  return Math.max(0, quota.dailyLimit - quota.usedToday);
}

export function resetMockQuota(): void {
  (globalThis as any)[globalKey] = new Map();
}