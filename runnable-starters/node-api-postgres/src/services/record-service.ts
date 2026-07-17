/**
 * 业务记录服务层
 * 封装业务逻辑，不直接操作数据存储。
 */

import type { BusinessRecord, RecordStatus } from "../types/index.js";
import * as recordRepo from "../repositories/record-repository.js";
import * as auditService from "./audit-service.js";
import { validateFields } from "../utils/validation.js";

export interface CreateRecordInput {
  title: string;
  description: string;
}

export interface UpdateRecordInput {
  status?: RecordStatus;
  remark?: string;
}

const VALID_STATUSES: RecordStatus[] = ["pending", "in_progress", "completed", "cancelled"];

/**
 * 创建业务记录
 */
export function createRecord(
  input: CreateRecordInput,
  userId: string,
  userName: string
): { data?: BusinessRecord; error?: { code: string; message: string; details?: Array<{ field: string; message: string }> } } {
  // 服务端校验
  const validation = validateFields([
    { field: "title", value: input.title, rules: [{ required: true, minLength: 2, maxLength: 200 }] },
    { field: "description", value: input.description, rules: [{ required: true, minLength: 2, maxLength: 2000 }] },
  ]);

  if (!validation.valid) {
    return {
      error: { code: "VALIDATION_ERROR", message: "输入校验失败", details: validation.errors },
    };
  }

  const record = recordRepo.create(input.title, input.description, userId, userName);

  // 写入审计日志占位
  auditService.log(userId, "CREATE", "record", record.id, "Record created");

  return { data: record };
}

/**
 * 获取记录列表（分页、搜索、筛选）
 */
export function listRecords(params: {
  page: number;
  pageSize: number;
  search?: string;
  status?: string;
}) {
  return recordRepo.list(params);
}

/**
 * 获取单条记录
 */
export function getRecord(id: string): BusinessRecord | null {
  return recordRepo.getById(id);
}

/**
 * 更新记录
 */
export function updateRecord(
  id: string,
  input: UpdateRecordInput,
  userId: string
): { data?: BusinessRecord; error?: { code: string; message: string } } {
  const existing = recordRepo.getById(id);
  if (!existing) {
    return { error: { code: "NOT_FOUND", message: "记录不存在" } };
  }

  // 校验状态枚举
  if (input.status && !VALID_STATUSES.includes(input.status)) {
    return { error: { code: "VALIDATION_ERROR", message: `无效的状态值: ${input.status}` } };
  }

  const updated = recordRepo.update(id, input);
  if (!updated) {
    return { error: { code: "NOT_FOUND", message: "记录不存在" } };
  }

  // 写入审计日志占位
  auditService.log(userId, "UPDATE", "record", id, `Updated: ${JSON.stringify(input)}`);

  return { data: updated };
}

/**
 * 执行业务动作（状态流转 + 幂等占位）
 */
export function performAction(
  id: string,
  action: string,
  userId: string,
  idempotencyKey?: string
): { data?: BusinessRecord; error?: { code: string; message: string }; cached?: boolean } {
  const existing = recordRepo.getById(id);
  if (!existing) {
    return { error: { code: "NOT_FOUND", message: "记录不存在" } };
  }

  // ?? 幂等检查占位（真实项目用数据库唯一约束）
  // const cached = checkIdempotency(idempotencyKey);
  // if (cached) return { data: cached as BusinessRecord, cached: true };

  // 示例状态流转规则
  const transitions: Record<RecordStatus, Partial<Record<"approve" | "complete" | "cancel", RecordStatus>>> = {
    pending: { approve: "in_progress", cancel: "cancelled" },
    in_progress: { complete: "completed", cancel: "cancelled" },
    completed: {},
    cancelled: {},
  };

  const targetStatus = (transitions[existing.status] as Record<string, RecordStatus>)?.[action];
  if (!targetStatus) {
    return {
      error: {
        code: "VALIDATION_ERROR",
        message: `不允许对状态 "${existing.status}" 执行 "${action}" 操作`,
      },
    };
  }

  const updated = recordRepo.update(id, { status: targetStatus });
  if (!updated) {
    return { error: { code: "NOT_FOUND", message: "记录不存在" } };
  }

  // 写入审计日志占位
  auditService.log(userId, action.toUpperCase(), "record", id, `Action "${action}" performed`);

  return { data: updated };
}
