// Admin System Runtime Validation — Batch Service
// Enforces: batch_operation_must_be_scoped, destructive_action_requires_confirmation, audit_log_required_for_sensitive_actions

import type { BatchOperationRequest, BatchOperationResult } from "../types.js";
import { resources, addAuditEntry } from "../db/store.js";
import { checkRolePermission } from "./auth.service.js";
import { errorResponse, okResponse } from "../errors.js";
import { ERROR_CODES } from "../types.js";

const HARD_LIMIT = 1000;

export function batchDelete(userId: string | null, request: BatchOperationRequest) {
  const auth = checkRolePermission(userId, "resource:delete");
  if ("error" in auth) return auth;
  const user = auth.data as any;

  // Invariant: destructive_action_requires_confirmation
  if (!request.confirmationToken || !request.confirmationToken.startsWith("batch-confirm-")) {
    return errorResponse(ERROR_CODES.CONFIRMATION_REQUIRED,
      "Batch destructive action requires confirmation token: batch-confirm-<reason>", 400);
  }

  // Invariant: batch_operation_must_be_scoped
  if (!request.filter && !request.ids) {
    return errorResponse(ERROR_CODES.BATCH_SCOPE_EXCEEDED,
      "Batch operation must specify filter or IDs — cannot delete all", 400);
  }

  if (request.maxAffected > HARD_LIMIT) {
    return errorResponse(ERROR_CODES.BATCH_SCOPE_EXCEEDED,
      `Batch maxAffected ${request.maxAffected} exceeds hard limit ${HARD_LIMIT}`, 400);
  }

  const result: BatchOperationResult = { affectedCount: 0, errors: [] };
  const now = new Date().toISOString();

  if (request.ids) {
    for (const id of request.ids) {
      const r = resources.get(id);
      if (!r || r.deletedAt !== null) { result.errors.push(`Resource ${id} not found or already deleted`); continue; }
      r.status = "DELETED";
      r.deletedAt = now;
      r.updatedAt = now;
      resources.set(id, r);
      result.affectedCount++;
    }
  } else if (request.filter) {
    const { field, value } = request.filter;
    const ALLOWED_FILTERS = ["status", "createdBy", "name"];
    if (!ALLOWED_FILTERS.includes(field)) {
      return errorResponse(ERROR_CODES.SEARCH_FILTER_INVALID,
        `Filter field "${field}" not allowed. Allowed: ${ALLOWED_FILTERS.join(", ")}`, 400);
    }
    let count = 0;
    for (const [id, r] of resources) {
      if (count >= request.maxAffected) break;
      if (r.deletedAt !== null) continue;
      if ((r as any)[field] === value) {
        r.status = "DELETED";
        r.deletedAt = now;
        r.updatedAt = now;
        resources.set(id, r);
        result.affectedCount++;
        count++;
      }
    }
  }

  addAuditEntry({
    actorId: user.id, actorRole: user.role,
    action: "BATCH_DELETE", targetType: "resource", targetId: "batch",
    details: `Batch deleted ${result.affectedCount} resources. Errors: ${result.errors.length}. Token: ${request.confirmationToken}`,
    result: result.errors.length === 0 ? "SUCCESS" : "REJECTED"
  });

  return okResponse(result);
}

export function batchUpdateStatus(userId: string | null, request: BatchOperationRequest, newStatus: string) {
  const auth = checkRolePermission(userId, "resource:write");
  if ("error" in auth) return auth;
  const user = auth.data as any;

  if (!request.ids || request.ids.length === 0) {
    return errorResponse(ERROR_CODES.BATCH_SCOPE_EXCEEDED,
      "Batch status update must specify resource IDs", 400);
  }

  if (request.maxAffected > HARD_LIMIT) {
    return errorResponse(ERROR_CODES.BATCH_SCOPE_EXCEEDED,
      `Batch maxAffected ${request.maxAffected} exceeds hard limit ${HARD_LIMIT}`, 400);
  }

  const result: BatchOperationResult = { affectedCount: 0, errors: [] };
  for (const id of request.ids) {
    const r = resources.get(id);
    if (!r || r.deletedAt !== null) { result.errors.push(`Resource ${id} not found`); continue; }
    // Simplified: allow batch status change to ACTIVE/SUSPENDED only
    if (!["ACTIVE", "SUSPENDED"].includes(newStatus)) {
      result.errors.push(`Batch status ${newStatus} not allowed for batch update`);
      continue;
    }
    r.status = newStatus as any;
    r.updatedAt = new Date().toISOString();
    resources.set(id, r);
    result.affectedCount++;
  }

  addAuditEntry({
    actorId: user.id, actorRole: user.role,
    action: "BATCH_STATUS_UPDATE", targetType: "resource", targetId: "batch",
    details: `Batch updated ${result.affectedCount} resources to ${newStatus}`,
    result: result.errors.length === 0 ? "SUCCESS" : "REJECTED"
  });

  return okResponse(result);
}
