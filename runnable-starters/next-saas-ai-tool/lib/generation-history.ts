/**
 * Mock Generation History
 * Uses globalThis to share state across Next.js route modules.
 * Real project: replace with database queries.
 */

export interface HistoryRecord {
  id: string;
  userId: string;
  prompt: string;
  topic?: string;
  style?: string;
  content: string;
  model: string;
  status: "success" | "failed";
  createdAt: string;
}

const globalKey = "__saas_generation_history__";
function getStore(): HistoryRecord[] {
  if (!(globalThis as any)[globalKey]) {
    (globalThis as any)[globalKey] = [];
  }
  return (globalThis as any)[globalKey];
}

export function addHistory(record: HistoryRecord): void {
  getStore().unshift(record);
}

export function getHistory(
  userId: string,
  page: number = 1,
  pageSize: number = 20
): { items: HistoryRecord[]; total: number; page: number; pageSize: number; totalPages: number } {
  const records = getStore();
  const userRecords = records.filter((r) => r.userId === userId);
  const total = userRecords.length;
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const items = userRecords.slice((page - 1) * pageSize, page * pageSize);
  return { items, total, page, pageSize, totalPages };
}

export function resetMockHistory(): void {
  (globalThis as any)[globalKey] = [];
}