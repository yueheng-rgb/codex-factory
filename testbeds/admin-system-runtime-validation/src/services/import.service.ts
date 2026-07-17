// Admin System Runtime Validation — Import Service
// Enforces: import_requires_validation, protected_fields_cannot_be_modified_without_permission

import { resources, nextId, addAuditEntry } from "../db/store.js";
import { checkRolePermission } from "./auth.service.js";
import { errorResponse, okResponse } from "../errors.js";
import { ERROR_CODES } from "../types.js";

export function importResources(userId: string | null, rows: Record<string, any>[]) {
  // Requires resource:write AND SUPER_ADMIN or ADMIN (import is sensitive)
  const auth = checkRolePermission(userId, "resource:write");
  if ("error" in auth) return auth;
  const user = auth.data as any;

  if (user.role !== "SUPER_ADMIN" && user.role !== "ADMIN") {
    return errorResponse(ERROR_CODES.PROTECTED_FIELD,
      "Import requires ADMIN or SUPER_ADMIN role", 403);
  }

  const errors: string[] = [];
  const created: string[] = [];
  const now = new Date().toISOString();

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const lineLabel = `Row ${i + 1}`;

    // Invariant: import_requires_validation
    if (!row.name || typeof row.name !== "string" || row.name.trim().length === 0) {
      errors.push(`${lineLabel}: name is required and must be a non-empty string`);
      continue;
    }

    // Reject protected fields in import unless SUPER_ADMIN
    if (row.protectedData !== undefined && user.role !== "SUPER_ADMIN") {
      errors.push(`${lineLabel}: protectedData cannot be set via import by non-SUPER_ADMIN`);
      continue;
    }

    // Reject unknown/invalid fields
    const ALLOWED_FIELDS = ["name", "description", "status"];
    const unknownFields = Object.keys(row).filter(k => !ALLOWED_FIELDS.includes(k) && k !== "protectedData");
    if (unknownFields.length > 0) {
      errors.push(`${lineLabel}: unknown fields: ${unknownFields.join(", ")}`);
      continue;
    }

    const resource = {
      id: nextId("imp"),
      name: row.name.trim(),
      description: row.description || "",
      status: (row.status || "DRAFT") as any,
      protectedData: row.protectedData || "",
      createdBy: user.id,
      createdAt: now,
      updatedAt: now,
      deletedAt: null as string | null
    };
    resources.set(resource.id, resource);
    created.push(resource.id);
  }

  addAuditEntry({
    actorId: user.id, actorRole: user.role,
    action: "IMPORT", targetType: "resource", targetId: "import",
    details: `Imported ${created.length} resources. Errors: ${errors.length}. ${errors.slice(0, 3).join("; ")}`,
    result: errors.length === 0 ? "SUCCESS" : "REJECTED"
  });

  if (errors.length > 0) {
    return errorResponse(ERROR_CODES.IMPORT_VALIDATION_FAILED,
      `Import validation failed: ${errors.length} errors. First: ${errors[0]}`, 400);
  }

  return okResponse({ created: created.length, ids: created });
}
