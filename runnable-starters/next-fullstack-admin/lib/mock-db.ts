/**
 * Mock 数据库
 * 提供内存中的数据存储，模拟数据库操作。
 * 真实项目必须替换为 PostgreSQL + Prisma/Drizzle。
 */

export interface BusinessRecord {
  id: string;
  title: string;
  description: string;
  status: "pending" | "active" | "completed" | "archived" | "cancelled";
  priority: "low" | "medium" | "high";
  createdBy: string;
  createdAt: string;
  updatedAt: string;
  remark?: string;
}

/** 初始 mock 数据 */
const initialRecords: BusinessRecord[] = [
  {
    id: "rec-001",
    title: "示例记录一",
    description: "这是一条处于待处理状态的示例业务记录。",
    status: "pending",
    priority: "high",
    createdBy: "u-001",
    createdAt: "2026-01-15T08:00:00Z",
    updatedAt: "2026-01-15T08:00:00Z",
  },
  {
    id: "rec-002",
    title: "示例记录二",
    description: "这是一条处于活跃状态的示例业务记录。",
    status: "active",
    priority: "medium",
    createdBy: "u-001",
    createdAt: "2026-01-16T10:30:00Z",
    updatedAt: "2026-01-16T14:20:00Z",
  },
  {
    id: "rec-003",
    title: "示例记录三",
    description: "这是一条已完成的示例业务记录。",
    status: "completed",
    priority: "low",
    createdBy: "u-002",
    createdAt: "2026-01-10T09:00:00Z",
    updatedAt: "2026-01-12T16:00:00Z",
    remark: "已完成，无后续问题",
  },
];

// 使用闭包保存可变状态
let store = [...initialRecords];
let nextId = 4;

export function getAllRecords(): BusinessRecord[] {
  return [...store];
}

export function getRecordById(id: string): BusinessRecord | undefined {
  return store.find((r) => r.id === id);
}

export function createRecord(
  data: Omit<BusinessRecord, "id" | "createdAt" | "updatedAt">
): BusinessRecord {
  const now = new Date().toISOString();
  const record: BusinessRecord = {
    ...data,
    id: `rec-${String(nextId++).padStart(3, "0")}`,
    createdAt: now,
    updatedAt: now,
  };
  store.push(record);
  return record;
}

export function updateRecord(
  id: string,
  data: Partial<Omit<BusinessRecord, "id" | "createdAt">>
): BusinessRecord | null {
  const idx = store.findIndex((r) => r.id === id);
  if (idx === -1) return null;
  store[idx] = {
    ...store[idx],
    ...data,
    updatedAt: new Date().toISOString(),
  };
  return store[idx];
}

export function deleteRecord(id: string): boolean {
  const idx = store.findIndex((r) => r.id === id);
  if (idx === -1) return false;
  store.splice(idx, 1);
  return true;
}

/** 重置 mock 数据（供测试使用） */
export function resetMockDB(): void {
  store = [...initialRecords];
  nextId = 4;
}
