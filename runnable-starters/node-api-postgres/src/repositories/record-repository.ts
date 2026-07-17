/**
 * 业务记录数据访问层（Mock 实现）
 * 真实项目替换为 Prisma/Drizzle 数据库操作。
 */

import type { BusinessRecord, RecordStatus } from "../types/index.js";
import type { PaginatedResult } from "../types/index.js";
import { mockRecords } from "../db/mock-db.js";
import { paginate } from "../utils/pagination.js";

export function create(
  title: string,
  description: string,
  createdBy: string, createdByName: string
): BusinessRecord {
  const record: BusinessRecord = {
    id: `rec-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
    title,
    description,
    status: "pending",
    remark: "",
    createdBy,
    createdByName,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  mockRecords.push(record);
  return record;
}

export function getById(id: string): BusinessRecord | null {
  return mockRecords.find((r) => r.id === id) || null;
}

export function list(params: {
  page: number;
  pageSize: number;
  search?: string;
  status?: string;
}): PaginatedResult<BusinessRecord> {
  let filtered = [...mockRecords];

  if (params.search) {
    const keyword = params.search.toLowerCase();
    filtered = filtered.filter(
      (r) =>
        r.title.toLowerCase().includes(keyword) ||
        r.description.toLowerCase().includes(keyword)
    );
  }

  if (params.status) {
    filtered = filtered.filter((r) => r.status === params.status);
  }

  // 按时间倒序
  filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  const total = filtered.length;
  const start = (params.page - 1) * params.pageSize;
  const items = filtered.slice(start, start + params.pageSize);

  return paginate(items, total, params.page, params.pageSize);
}

export function update(
  id: string,
  input: { status?: RecordStatus; remark?: string }
): BusinessRecord | null {
  const idx = mockRecords.findIndex((r) => r.id === id);
  if (idx === -1) return null;

  const existing = mockRecords[idx];
  const updated: BusinessRecord = {
    ...existing,
    ...(input.status ? { status: input.status } : {}),
    ...(input.remark !== undefined ? { remark: input.remark } : {}),
    updatedAt: new Date().toISOString(),
  };

  mockRecords[idx] = updated;
  return updated;
}

export function remove(id: string): boolean {
  const idx = mockRecords.findIndex((r) => r.id === id);
  if (idx === -1) return false;
  mockRecords.splice(idx, 1);
  return true;
}
