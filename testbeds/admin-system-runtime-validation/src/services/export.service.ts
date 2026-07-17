// Admin System Runtime Validation — Export Service
// Enforces: export_requires_permission, audit_log_required_for_sensitive_actions

import type { ExportRequest } from "../types.js";
import { resources, addAuditEntry } from "../db/store.js";
import { checkRolePermission } from "./auth.service.js";
import { errorResponse, okResponse } from "../errors.js";
import { ERROR_CODES } from "../types.js";

export function exportResources(userId: string | null, request: ExportRequest) {
  const auth = checkRolePermission(userId, "export:read");
  if ("error" in auth) {
    // Specific check: if the user lacks export permission
    const authCheck = checkRolePermission(userId, "resource:read"); // can they at least read?
    if ("error" in authCheck) return auth; // no read at all
    return errorResponse(ERROR_CODES.EXPORT_PERMISSION_REQUIRED,
      "Export operation requires export:read permission", 403);
  }
  const user = auth.data as any;

  const allResources = Array.from(resources.values())
    .filter(r => r.deletedAt === null);

  const ALLOWED_EXPORT_FIELDS = ["id", "name", "description", "status", "createdBy", "createdAt", "updatedAt"];
  const invalidFields = request.fields.filter(f => !ALLOWED_EXPORT_FIELDS.includes(f));
  if (invalidFields.length > 0) {
    return errorResponse(ERROR_CODES.SEARCH_FILTER_INVALID,
      `Invalid export fields: ${invalidFields.join(", ")}. Allowed: ${ALLOWED_EXPORT_FIELDS.join(", ")}`, 400);
  }

  const exported = allResources.map(r => {
    const obj: Record<string, any> = {};
    for (const f of request.fields) obj[f] = (r as any)[f];
    return obj;
  });

  addAuditEntry({
    actorId: user.id, actorRole: user.role,
    action: "EXPORT", targetType: "resource", targetId: "export",
    details: `Exported ${exported.length} resources in ${request.format}. Fields: ${request.fields.join(", ")}`,
    result: "SUCCESS"
  });

  return okResponse({ format: request.format, count: exported.length, data: exported });
}
