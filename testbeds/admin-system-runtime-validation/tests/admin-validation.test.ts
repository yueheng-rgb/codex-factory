// Admin System Runtime Validation — Comprehensive Test Suite
// Covers: 13 admin-system invariants + 8 negative controls
// Source: governance/expert-packs/admin-system/admin-system-pack.json v1.0.0

import { describe, it, expect, beforeEach } from "vitest";
import { resetStores, resources, users, auditLog } from "../src/db/store.js";
import * as auth from "../src/services/auth.service.js";
import * as resource from "../src/services/resource.service.js";
import * as batchSvc from "../src/services/batch.service.js";
import * as exportSvc from "../src/services/export.service.js";
import * as importSvc from "../src/services/import.service.js";
import { ERROR_CODES } from "../src/types.js";

beforeEach(() => { resetStores(); });

// ============================================================
// INVARIANT 1: admin_required_for_admin_routes
// ============================================================
describe("Invariant 1: admin_required_for_admin_routes", () => {
  it("rejects unauthenticated access to admin route", () => {
    const r = auth.checkAdminRoute(null);
    expect("error" in r && r.error === ERROR_CODES.UNAUTHORIZED).toBe(true);
  });
  it("rejects invalid user ID on admin route", () => {
    const r = auth.checkAdminRoute("nonexistent");
    expect("error" in r && r.error === ERROR_CODES.UNAUTHORIZED).toBe(true);
  });
  it("allows valid admin user on admin route", () => {
    const r = auth.checkAdminRoute("su_1");
    expect("error" in r).toBe(false);
    expect((r as any).data.role).toBe("SUPER_ADMIN");
  });
});

// ============================================================
// INVARIANT 2: role_permission_must_be_enforced
// ============================================================
describe("Invariant 2: role_permission_must_be_enforced", () => {
  it("allows admin with correct permission", () => {
    const r = auth.checkRolePermission("adm_1", "resource:read");
    expect("error" in r).toBe(false);
  });
  it("rejects viewer without resource:write permission", () => {
    const r = auth.checkRolePermission("vw_1", "resource:write");
    expect("error" in r && r.error === ERROR_CODES.FORBIDDEN).toBe(true);
  });
  it("rejects operator without resource:delete permission", () => {
    const r = auth.checkRolePermission("op_1", "resource:delete");
    expect("error" in r && r.error === ERROR_CODES.FORBIDDEN).toBe(true);
  });
  it("allows SUPER_ADMIN all permissions (*)", () => {
    const r = auth.checkRolePermission("su_1", "any:random:perm");
    expect("error" in r).toBe(false);
  });
});

// ============================================================
// INVARIANT 3: ordinary_admin_cannot_escalate_role
// ============================================================
describe("Invariant 3: ordinary_admin_cannot_escalate_role", () => {
  it("allows SUPER_ADMIN to escalate any role", () => {
    const r = auth.changeUserRole("su_1", "vw_1", "ADMIN");
    expect("error" in r).toBe(false);
    expect((r as any).data.role).toBe("ADMIN");
  });
  it("rejects ADMIN escalating to SUPER_ADMIN", () => {
    const r = auth.changeUserRole("adm_1", "adm_1", "SUPER_ADMIN");
    expect("error" in r && r.error === ERROR_CODES.ROLE_ESCALATION_BLOCKED).toBe(true);
  });
  it("rejects OPERATOR escalating anyone to ADMIN", () => {
    const r = auth.changeUserRole("op_1", "vw_1", "ADMIN");
    expect("error" in r && r.error === ERROR_CODES.ROLE_ESCALATION_BLOCKED).toBe(true);
  });
  it("allows ADMIN to demote to lower role", () => {
    const r = auth.changeUserRole("adm_1", "op_1", "VIEWER");
    expect("error" in r).toBe(false);
    expect((r as any).data.role).toBe("VIEWER");
  });
});

// ============================================================
// INVARIANT 4: destructive_action_requires_confirmation
// ============================================================
describe("Invariant 4: destructive_action_requires_confirmation", () => {
  it("rejects delete without confirmation token", () => {
    const created = resource.createResource("adm_1", { name: "Test", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    const r = resource.deleteResource("adm_1", rid);
    expect("error" in r && r.error === ERROR_CODES.CONFIRMATION_REQUIRED).toBe(true);
  });
  it("allows delete with correct confirmation token", () => {
    const created = resource.createResource("adm_1", { name: "Test", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    const r = resource.deleteResource("adm_1", rid, `confirm-delete-${rid}`);
    expect("error" in r).toBe(false);
    expect((r as any).data.status).toBe("DELETED");
  });
  it("rejects delete with wrong confirmation token", () => {
    const created = resource.createResource("adm_1", { name: "Test", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    const r = resource.deleteResource("adm_1", rid, "wrong-token");
    expect("error" in r && r.error === ERROR_CODES.CONFIRMATION_REQUIRED).toBe(true);
  });
});

// ============================================================
// INVARIANT 5: deleted_record_not_listed_by_default
// ============================================================
describe("Invariant 5: deleted_record_not_listed_by_default", () => {
  it("does not list deleted resources by default", () => {
    const created = resource.createResource("adm_1", { name: "Keep", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    resource.deleteResource("adm_1", rid, `confirm-delete-${rid}`);

    const list = resource.listResources("adm_1");
    const items = (list as any).data.items;
    expect(items.every((r: any) => r.id !== rid)).toBe(true);
  });
  it("lists deleted resources when includeDeleted=true", () => {
    const created = resource.createResource("adm_1", { name: "Gone", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    resource.deleteResource("adm_1", rid, `confirm-delete-${rid}`);

    const list = resource.listResources("adm_1", 1, 20, true);
    const items = (list as any).data.items;
    expect(items.some((r: any) => r.id === rid)).toBe(true);
  });
});

// ============================================================
// INVARIANT 6: status_transition_allowed
// ============================================================
describe("Invariant 6: status_transition_allowed", () => {
  it("allows DRAFT -> ACTIVE", () => {
    const created = resource.createResource("adm_1", { name: "Test", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    const r = resource.changeResourceStatus("adm_1", rid, "ACTIVE");
    expect("error" in r).toBe(false);
  });
  it("rejects DRAFT -> ARCHIVED (invalid transition)", () => {
    const created = resource.createResource("adm_1", { name: "Test", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    const r = resource.changeResourceStatus("adm_1", rid, "ARCHIVED");
    expect("error" in r && r.error === ERROR_CODES.INVALID_STATUS_TRANSITION).toBe(true);
  });
  it("rejects DELETED -> ACTIVE (deleted cannot transition)", () => {
    const created = resource.createResource("adm_1", { name: "Test", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    resource.deleteResource("adm_1", rid, `confirm-delete-${rid}`);
    const r = resource.changeResourceStatus("adm_1", rid, "ACTIVE");
    expect("error" in r).toBe(true);
  });
});

// ============================================================
// INVARIANT 7: protected_fields_cannot_be_modified_without_permission
// ============================================================
describe("Invariant 7: protected_fields_cannot_be_modified_without_permission", () => {
  it("allows SUPER_ADMIN to modify protectedData", () => {
    const created = resource.createResource("adm_1", { name: "Sec", description: "", protectedData: "old" });
    const rid = (created as any).data.id;
    const r = resource.updateResource("su_1", rid, { protectedData: "new" });
    expect("error" in r).toBe(false);
    expect((r as any).data.protectedData).toBe("new");
  });
  it("rejects OPERATOR from modifying protectedData", () => {
    const created = resource.createResource("adm_1", { name: "Sec", description: "", protectedData: "old" });
    const rid = (created as any).data.id;
    const r = resource.updateResource("op_1", rid, { protectedData: "hacked" });
    expect("error" in r && r.error === ERROR_CODES.PROTECTED_FIELD).toBe(true);
  });
});

// ============================================================
// INVARIANT 8: batch_operation_must_be_scoped
// ============================================================
describe("Invariant 8: batch_operation_must_be_scoped", () => {
  it("rejects batch delete with no filter and no IDs", () => {
    const r = batchSvc.batchDelete("adm_1", { maxAffected: 10, confirmationToken: "batch-confirm-test" });
    expect("error" in r && r.error === ERROR_CODES.BATCH_SCOPE_EXCEEDED).toBe(true);
  });
  it("rejects batch delete exceeding hard limit", () => {
    const r = batchSvc.batchDelete("adm_1", { ids: ["res_1"], maxAffected: 2000, confirmationToken: "batch-confirm-test" });
    expect("error" in r && r.error === ERROR_CODES.BATCH_SCOPE_EXCEEDED).toBe(true);
  });
  it("requires confirmation token for batch delete", () => {
    const r = batchSvc.batchDelete("adm_1", { ids: ["res_1"], maxAffected: 10 });
    expect("error" in r && r.error === ERROR_CODES.CONFIRMATION_REQUIRED).toBe(true);
  });
  it("allows scoped batch delete with IDs and confirmation", () => {
    const c1 = resource.createResource("adm_1", { name: "A", description: "", protectedData: "" });
    const c2 = resource.createResource("adm_1", { name: "B", description: "", protectedData: "" });
    const ids = [(c1 as any).data.id, (c2 as any).data.id];
    const r = batchSvc.batchDelete("adm_1", { ids, maxAffected: 10, confirmationToken: "batch-confirm-cleanup" });
    expect("error" in r).toBe(false);
    expect((r as any).data.affectedCount).toBe(2);
  });
});

// ============================================================
// INVARIANT 9: audit_log_required_for_sensitive_actions
// ============================================================
describe("Invariant 9: audit_log_required_for_sensitive_actions", () => {
  it("creates audit log on resource creation", () => {
    const before = auditLog.length;
    resource.createResource("adm_1", { name: "Audited", description: "", protectedData: "" });
    expect(auditLog.length).toBeGreaterThan(before);
    expect(auditLog.some(e => e.action === "RESOURCE_CREATED")).toBe(true);
  });
  it("creates audit log on delete", () => {
    const created = resource.createResource("adm_1", { name: "ToDelete", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    const before = auditLog.length;
    resource.deleteResource("adm_1", rid, `confirm-delete-${rid}`);
    expect(auditLog.some(e => e.action === "RESOURCE_STATUS_CHANGED" && e.targetId === rid)).toBe(true);
  });
  it("creates audit log on role change", () => {
    const before = auditLog.length;
    auth.changeUserRole("su_1", "vw_1", "OPERATOR");
    expect(auditLog.some(e => e.action === "ROLE_CHANGED")).toBe(true);
  });
  it("creates audit log on permission denied", () => {
    auth.checkRolePermission("vw_1", "resource:write");
    expect(auditLog.some(e => e.action === "PERMISSION_DENIED")).toBe(true);
  });
  it("creates audit log on export", () => {
    exportSvc.exportResources("adm_1", { format: "json", fields: ["name", "status"] });
    expect(auditLog.some(e => e.action === "EXPORT")).toBe(true);
  });
  it("creates audit log on import", () => {
    importSvc.importResources("su_1", [{ name: "Imported" }]);
    expect(auditLog.some(e => e.action === "IMPORT")).toBe(true);
  });
});

// ============================================================
// INVARIANT 10: export_requires_permission
// ============================================================
describe("Invariant 10: export_requires_permission", () => {
  it("allows export for user with export:read", () => {
    const r = exportSvc.exportResources("adm_1", { format: "json", fields: ["name", "status"] });
    expect("error" in r).toBe(false);
    expect((r as any).data.count).toBeGreaterThanOrEqual(0);
  });
  it("rejects export for operator without export:read", () => {
    const r = exportSvc.exportResources("op_1", { format: "json", fields: ["name"] });
    expect("error" in r && r.error === ERROR_CODES.EXPORT_PERMISSION_REQUIRED).toBe(true);
  });
  it("rejects export with invalid fields", () => {
    const r = exportSvc.exportResources("adm_1", { format: "json", fields: ["name", "password"] });
    expect("error" in r && r.error === ERROR_CODES.SEARCH_FILTER_INVALID).toBe(true);
  });
});

// ============================================================
// INVARIANT 11: import_requires_validation
// ============================================================
describe("Invariant 11: import_requires_validation", () => {
  it("allows valid import by SUPER_ADMIN", () => {
    const r = importSvc.importResources("su_1", [{ name: "Valid Item", description: "desc" }]);
    expect("error" in r).toBe(false);
    expect((r as any).data.created).toBe(1);
  });
  it("rejects import with missing name", () => {
    const r = importSvc.importResources("su_1", [{ description: "no name" }]);
    expect("error" in r && r.error === ERROR_CODES.IMPORT_VALIDATION_FAILED).toBe(true);
  });
  it("rejects import with unknown fields", () => {
    const r = importSvc.importResources("su_1", [{ name: "X", secretCode: 123 }]);
    expect("error" in r && r.error === ERROR_CODES.IMPORT_VALIDATION_FAILED).toBe(true);
  });
  it("rejects import by non-admin user", () => {
    const r = importSvc.importResources("op_1", [{ name: "X" }]);
    expect("error" in r && r.error === ERROR_CODES.PROTECTED_FIELD).toBe(true);
  });
});

// ============================================================
// INVARIANT 12: pagination_limit_enforced
// ============================================================
describe("Invariant 12: pagination_limit_enforced", () => {
  it("rejects page size exceeding max limit", () => {
    const r = resource.listResources("adm_1", 1, 200);
    expect("error" in r && r.error === ERROR_CODES.PAGINATION_LIMIT_EXCEEDED).toBe(true);
  });
  it("allows page size within limit", () => {
    const r = resource.listResources("adm_1", 1, 50);
    expect("error" in r).toBe(false);
  });
  it("caps at max when pageSize is exactly 100", () => {
    const r = resource.listResources("adm_1", 1, 100);
    expect("error" in r).toBe(false);
  });
});

// ============================================================
// INVARIANT 13: search_filter_must_be_whitelisted
// ============================================================
describe("Invariant 13: search_filter_must_be_whitelisted", () => {
  it("rejects search on non-whitelisted field", () => {
    const r = resource.listResources("adm_1", 1, 20, false, "test", "protectedData");
    expect("error" in r && r.error === ERROR_CODES.SEARCH_FILTER_INVALID).toBe(true);
  });
  it("allows search on whitelisted field (name)", () => {
    resource.createResource("adm_1", { name: "SearchTarget", description: "", protectedData: "" });
    const r = resource.listResources("adm_1", 1, 20, false, "Search", "name");
    expect("error" in r).toBe(false);
    expect((r as any).data.items.length).toBe(1);
  });
});

// ============================================================
// NEGATIVE CONTROLS (8)
// ============================================================

describe("Negative Control 1: unauthenticated access to admin route — BLOCKED", () => {
  it("returns UNAUTHORIZED for null user on resource list", () => {
    const r = resource.listResources(null);
    expect("error" in r && r.error === ERROR_CODES.UNAUTHORIZED).toBe(true);
  });
  it("returns UNAUTHORIZED for null user on export", () => {
    const r = exportSvc.exportResources(null, { format: "json", fields: ["name"] });
    expect("error" in r).toBe(true);
  });
});

describe("Negative Control 2: viewer accessing forbidden resource — BLOCKED", () => {
  it("rejects viewer from writing resources", () => {
    const r = resource.createResource("vw_1", { name: "Nope", description: "", protectedData: "" });
    expect("error" in r && r.error === ERROR_CODES.FORBIDDEN).toBe(true);
  });
});

describe("Negative Control 3: operator escalating to SUPER_ADMIN — BLOCKED", () => {
  it("rejects operator escalating self", () => {
    const r = auth.changeUserRole("op_1", "op_1", "SUPER_ADMIN");
    expect("error" in r && r.error === ERROR_CODES.ROLE_ESCALATION_BLOCKED).toBe(true);
  });
});

describe("Negative Control 4: delete without confirmation — BLOCKED", () => {
  it("rejects delete without confirmation token", () => {
    const created = resource.createResource("adm_1", { name: "Safe", description: "", protectedData: "" });
    const r = resource.deleteResource("adm_1", (created as any).data.id);
    expect("error" in r && r.error === ERROR_CODES.CONFIRMATION_REQUIRED).toBe(true);
  });
});

describe("Negative Control 5: batch operation exceeds scope — BLOCKED", () => {
  it("rejects batch delete with no scope", () => {
    const r = batchSvc.batchDelete("adm_1", { maxAffected: 10, confirmationToken: "batch-confirm-x" });
    expect("error" in r && r.error === ERROR_CODES.BATCH_SCOPE_EXCEEDED).toBe(true);
  });
});

describe("Negative Control 6: sensitive action without audit log — IMPOSSIBLE", () => {
  it("always creates audit log on resource creation", () => {
    const before = auditLog.length;
    resource.createResource("adm_1", { name: "Check", description: "", protectedData: "" });
    expect(auditLog.length).toBeGreaterThan(before);
  });
  it("always creates audit log on status change", () => {
    const created = resource.createResource("adm_1", { name: "Check", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    const before = auditLog.length;
    resource.changeResourceStatus("adm_1", rid, "ACTIVE");
    expect(auditLog.length).toBeGreaterThan(before);
  });
});

describe("Negative Control 7: export without permission — BLOCKED", () => {
  it("rejects operator export", () => {
    const r = exportSvc.exportResources("op_1", { format: "csv", fields: ["name"] });
    expect("error" in r && r.error === ERROR_CODES.EXPORT_PERMISSION_REQUIRED).toBe(true);
  });
});

describe("Negative Control 8: import with invalid fields — BLOCKED", () => {
  it("rejects import with unknown column", () => {
    const r = importSvc.importResources("su_1", [{ name: "X", forbiddenColumn: "evil" }]);
    expect("error" in r && r.error === ERROR_CODES.IMPORT_VALIDATION_FAILED).toBe(true);
  });
  it("rejects import with empty name", () => {
    const r = importSvc.importResources("su_1", [{ name: "" }]);
    expect("error" in r).toBe(true);
  });
});

// ============================================================
// EDGE CASES
// ============================================================
describe("Edge cases", () => {
  it("rejects access to deleted resource", () => {
    const created = resource.createResource("adm_1", { name: "Gone", description: "", protectedData: "" });
    const rid = (created as any).data.id;
    resource.deleteResource("adm_1", rid, `confirm-delete-${rid}`);
    const r = resource.getResource("adm_1", rid);
    expect("error" in r).toBe(true);
  });
  it("rejects status change on non-existent resource", () => {
    const r = resource.changeResourceStatus("adm_1", "nonexistent", "ACTIVE");
    expect("error" in r).toBe(true);
  });
  it("rejects batch status update with empty IDs", () => {
    const r = batchSvc.batchUpdateStatus("adm_1", { ids: [], maxAffected: 10, confirmationToken: "x" }, "ACTIVE");
    expect("error" in r && r.error === ERROR_CODES.BATCH_SCOPE_EXCEEDED).toBe(true);
  });
  it("lists resources with correct pagination", () => {
    for (let i = 0; i < 5; i++) {
      resource.createResource("adm_1", { name: `Item${i}`, description: "", protectedData: "" });
    }
    const r = resource.listResources("adm_1", 1, 3);
    expect((r as any).data.items.length).toBe(3);
    expect((r as any).data.total).toBe(5);
  });
});
