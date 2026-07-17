/**
 * Records 业务模块
 * 封装 BusinessRecord 的查询、筛选、分页逻辑。
 */

import type { BusinessRecord } from "./mock-db";
import { getAllRecords, getRecordById, createRecord, updateRecord, deleteRecord } from "./mock-db";

export interface RecordsQuery {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
  priority?: string;
}

export interface PaginatedResult {
  items: BusinessRecord[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export function queryRecords(q: RecordsQuery): PaginatedResult {
  let records = getAllRecords();

  // 搜索
  if (q.search) {
    const s = q.search.toLowerCase();
    records = records.filter(
      (r) =>
        r.title.toLowerCase().includes(s) ||
        r.description.toLowerCase().includes(s)
    );
  }

  // 状态筛选
  if (q.status) {
    records = records.filter((r) => r.status === q.status);
  }

  // 优先级筛选
  if (q.priority) {
    records = records.filter((r) => r.priority === q.priority);
  }

  // 按更新时间倒序
  records.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());

  // 分页
  const page = Math.max(1, q.page ?? 1);
  const limit = Math.min(100, Math.max(1, q.limit ?? 20));
  const total = records.length;
  const totalPages = Math.ceil(total / limit);
  const items = records.slice((page - 1) * limit, page * limit);

  return { items, page, limit, total, totalPages };
}

export { getRecordById, createRecord, updateRecord, deleteRecord };
