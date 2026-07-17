// Admin System Runtime Validation — Resource Service
// Enforces: deleted_record_not_listed_by_default, status_transition_allowed,
//           protected_fields_cannot_be_modified_without_permission,
//           destructive_action_requires_confirmation, audit_log_required_for_sensitive_actions

import type { AdminResource, ResourceStatus, ConfirmationToken } from "../types.js";
import { resources, nextId, addAuditEntry } from "../db/store.js";
import { checkRolePermission } from "./auth.service.js";
import { errorResponse, okResponse } from "../errors.js";
import { ERROR_CODES, ALLOWED_STATUS_TRANSITIONS } from "../types.js";

export function createResource(userId: string | null, data: { name: string; description: string; protectedData: string }) {
  const auth = checkRolePermission(userId, "resource:write");
  if ("error" in auth) return auth;
  const user = auth.data as any;

  const now = new Date().toISOString();
  const resource: AdminResource = {
    id: nextId("res"),
    name: data.name,
    description: data.description,
    status: "DRAFT",
    protectedData: data.protectedData,
    createdBy: user.id,
    createdAt: now,
    updatedAt: now,
    deletedAt: null
  };
  resources.set(resource.id, resource);

  addAuditEntry({
    actorId: user.id, actorRole: user.role,
    action: "RESOURCE_CREATED", targetType: "resource", targetId: resource.id,
    details: `Created resource "${resource.name}"`,
    result: "SUCCESS"
  });

  return okResponse(resource);
}

export function getResource(userId: string | null, resourceId: string) {
  const auth = checkRolePermission(userId, "resource:read");
  if ("error" in auth) return auth;

  const resource = resources.get(resourceId);
  if (!resource) return errorResponse("NOT_FOUND", "Resource not found", 404);

  // Invariant: deleted_record_not_listed_by_default
  if (resource.deletedAt !== null) {
    return errorResponse("NOT_FOUND", "Resource has been deleted", 404);
  }

  return okResponse(resource);
}

export function listResources(userId: string | null,
  page: number = 1, pageSize: number = 20,
  includeDeleted: boolean = false,
  search?: string, searchField?: string
) {
  const auth = checkRolePermission(userId, "resource:read");
  if ("error" in auth) return auth;

  // Invariant: pagination_limit_enforced
  const maxPageSize = 100;
  const effectivePageSize = Math.min(pageSize, maxPageSize);
  if (pageSize > maxPageSize) {
    return errorResponse(ERROR_CODES.PAGINATION_LIMIT_EXCEEDED,
      `Page size ${pageSize} exceeds max ${maxPageSize}`, 400);
  }

  // Invariant: search_filter_must_be_whitelisted
  const ALLOWED_SEARCH_FIELDS = ["name", "description", "status"];
  if (search && searchField && !ALLOWED_SEARCH_FIELDS.includes(searchField)) {
    return errorResponse(ERROR_CODES.SEARCH_FILTER_INVALID,
      `Search field "${searchField}" is not allowed. Allowed: ${ALLOWED_SEARCH_FIELDS.join(", ")}`, 400);
  }

  let allResources = Array.from(resources.values());

  // Soft delete filtering
  if (!includeDeleted) {
    allResources = allResources.filter(r => r.deletedAt === null);
  }

  // Search filter
  if (search && searchField) {
    const lowerSearch = search.toLowerCase();
    allResources = allResources.filter(r => {
      const val = (r as any)[searchField];
      return typeof val === "string" && val.toLowerCase().includes(lowerSearch);
    });
  }

  const total = allResources.length;
  const start = (page - 1) * effectivePageSize;
  const paged = allResources.slice(start, start + effectivePageSize);

  return okResponse({ items: paged, total, page, pageSize: effectivePageSize });
}

export function updateResource(userId: string | null, resourceId: string,
  updates: Partial<Pick<AdminResource, "name" | "description" | "protectedData">>,
  confirmationToken?: ConfirmationToken
) {
  const auth = checkRolePermission(userId, "resource:write");
  if ("error" in auth) return auth;
  const user = auth.data as any;

  const resource = resources.get(resourceId);
  if (!resource) return errorResponse("NOT_FOUND", "Resource not found", 404);
  if (resource.deletedAt !== null) return errorResponse("NOT_FOUND", "Resource deleted", 404);

  // Invariant: protected_fields_cannot_be_modified_without_permission
  if (updates.protectedData !== undefined && user.role !== "SUPER_ADMIN" && user.role !== "ADMIN") {
    return errorResponse(ERROR_CODES.PROTECTED_FIELD,
      "Cannot modify protected fields without ADMIN or SUPER_ADMIN role", 403);
  }

  // Invariant: destructive_action_requires_confirmation (for status=DELETED changes handled in deleteResource)
  Object.assign(resource, updates, { updatedAt: new Date().toISOString() });
  resources.set(resourceId, resource);

  addAuditEntry({
    actorId: user.id, actorRole: user.role,
    action: "RESOURCE_UPDATED", targetType: "resource", targetId: resourceId,
    details: `Updated fields: ${Object.keys(updates).join(", ")}`,
    result: "SUCCESS"
  });

  return okResponse(resource);
}

export function changeResourceStatus(userId: string | null, resourceId: string,
  newStatus: ResourceStatus, confirmationToken?: ConfirmationToken
) {
  const auth = checkRolePermission(userId, "resource:write");
  if ("error" in auth) return auth;
  const user = auth.data as any;

  const resource = resources.get(resourceId);
  if (!resource) return errorResponse("NOT_FOUND", "Resource not found", 404);
  if (resource.deletedAt !== null) return errorResponse("NOT_FOUND", "Resource deleted", 404);

  // Invariant: status_transition_allowed
  const allowedNext = ALLOWED_STATUS_TRANSITIONS[resource.status];
  if (!allowedNext.includes(newStatus)) {
    return errorResponse(ERROR_CODES.INVALID_STATUS_TRANSITION,
      `Cannot transition from ${resource.status} to ${newStatus}. Allowed: ${allowedNext.join(", ")}`, 400);
  }

  // Invariant: destructive_action_requires_confirmation for DELETED status
  if (newStatus === "DELETED") {
    if (!confirmationToken || confirmationToken !== `confirm-delete-${resourceId}`) {
      return errorResponse(ERROR_CODES.CONFIRMATION_REQUIRED,
        "Destructive action requires confirmation token", 400);
    }
  }

  const oldStatus = resource.status;
  resource.status = newStatus;
  if (newStatus === "DELETED") {
    resource.deletedAt = new Date().toISOString();
  }
  resource.updatedAt = new Date().toISOString();
  resources.set(resourceId, resource);

  addAuditEntry({
    actorId: user.id, actorRole: user.role,
    action: "RESOURCE_STATUS_CHANGED", targetType: "resource", targetId: resourceId,
    details: `Status changed from ${oldStatus} to ${newStatus}`,
    result: "SUCCESS"
  });

  return okResponse(resource);
}

export function deleteResource(userId: string | null, resourceId: string, confirmationToken?: ConfirmationToken) {
  // Invariant: destructive_action_requires_confirmation
  if (!confirmationToken || confirmationToken !== `confirm-delete-${resourceId}`) {
    return errorResponse(ERROR_CODES.CONFIRMATION_REQUIRED,
      "Destructive action requires confirmation token. Use confirm-delete-<resourceId>", 400);
  }

  return changeResourceStatus(userId, resourceId, "DELETED", confirmationToken);
}
