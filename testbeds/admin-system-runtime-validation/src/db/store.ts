// Admin System Runtime Validation — In-Memory Store
// Source: governance/expert-packs/admin-system/admin-system-pack.json v1.0.0

import type { AdminUser, AdminResource, AuditLogEntry, Role } from "../types.js";

export const users: Map<string, AdminUser> = new Map();
export const resources: Map<string, AdminResource> = new Map();
export let auditLog: AuditLogEntry[] = [];

let idCounter = 0;
export function nextId(prefix: string): string { return `${prefix}_${++idCounter}_${Date.now()}`; }

export function resetStores() {
  users.clear();
  resources.clear();
  auditLog = [];
  idCounter = 0;
  seedUsers();
}

function seedUsers() {
  users.set("su_1", {
    id: "su_1", username: "superadmin", role: "SUPER_ADMIN",
    permissions: ["*"], createdAt: new Date().toISOString()
  });
  users.set("adm_1", {
    id: "adm_1", username: "admin", role: "ADMIN",
    permissions: ["resource:read", "resource:write", "resource:delete", "user:read", "user:write", "audit:read", "export:read"],
    createdAt: new Date().toISOString()
  });
  users.set("op_1", {
    id: "op_1", username: "operator", role: "OPERATOR",
    permissions: ["resource:read", "resource:write", "user:read", "user:write"],
    createdAt: new Date().toISOString()
  });
  users.set("vw_1", {
    id: "vw_1", username: "viewer", role: "VIEWER",
    permissions: ["resource:read"],
    createdAt: new Date().toISOString()
  });
}

export function addAuditEntry(entry: Omit<AuditLogEntry, "id" | "timestamp">) {
  const e: AuditLogEntry = { ...entry, id: nextId("audit"), timestamp: new Date().toISOString() };
  auditLog.push(e);
  return e;
}

export function getAuditLogEntries(filter?: { actorId?: string; action?: string; targetId?: string }): AuditLogEntry[] {
  let results = auditLog;
  if (filter?.actorId) results = results.filter(e => e.actorId === filter.actorId);
  if (filter?.action) results = results.filter(e => e.action === filter.action);
  if (filter?.targetId) results = results.filter(e => e.targetId === filter.targetId);
  return results;
}
