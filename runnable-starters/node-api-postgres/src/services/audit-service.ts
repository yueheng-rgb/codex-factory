/**
 * ???????????
 * ??????????????????
 */

import type { AuditLogEntry } from "../types/index.js";
import { mockAuditLogs } from "../db/mock-db.js";
import type { PaginatedResult, PaginationParams } from "../types/index.js";
import { paginate } from "../utils/pagination.js";

/**
 * ??????
 */
export function log(
  userId: string,
  action: string,
  targetType: string,
  targetId: string,
  detail: string
): AuditLogEntry {
  const entry: AuditLogEntry = {
    id: `audit-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
    actorId: userId,
    action,
    targetType,
    targetId,
    result: "success",
    detail,
    createdAt: new Date().toISOString(),
  };

  mockAuditLogs.push(entry);
  return entry;
}

/**
 * ??????????
 * ?? ? admin ??????
 */
export function listAuditLogs(
  pagination: PaginationParams,
  filters?: { userId?: string; action?: string; targetType?: string }
): PaginatedResult<AuditLogEntry> {
  let filtered = [...mockAuditLogs];

  if (filters?.userId) {
    filtered = filtered.filter((l) => l.actorId === filters.userId);
  }
  if (filters?.action) {
    filtered = filtered.filter((l) => l.action === filters.action);
  }
  if (filters?.targetType) {
    filtered = filtered.filter((l) => l.targetType === filters.targetType);
  }

  // ?????
  filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  const total = filtered.length;
  const start = (pagination.page - 1) * pagination.pageSize;
  const items = filtered.slice(start, start + pagination.pageSize);

  return paginate(items, total, pagination.page, pagination.pageSize);
}
