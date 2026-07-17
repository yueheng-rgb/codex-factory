import { tenants, users, gid } from "../db/store.js";
import { UserRole, WorkspaceStatus } from "../types.js";

// SaaS Pack Invariants enforced:
//   tenant_data_isolation, user_cannot_access_other_tenant_data,
//   deleted_workspace_cannot_generate

export function createTenant(name: string): { id: string; name: string } {
  const t = { id: gid("ten"), name, status: "ACTIVE" as WorkspaceStatus, createdAt: new Date().toISOString() };
  tenants.set(t.id, t);
  return t;
}

export function createUser(email: string, role: UserRole, tenantId: string): { id: string } | { error: string } {
  if (!tenants.has(tenantId)) return { error: "NOT_FOUND: Tenant not found" };
  // INVARIANT: deleted_workspace_cannot_generate (cannot add users to deleted workspace)
  if (tenants.get(tenantId)!.status === "DELETED") return { error: "WORKSPACE_DELETED: Cannot add users to deleted workspace" };
  const u = { id: gid("usr"), email, role, tenantId };
  users.set(u.id, u);
  return { id: u.id };
}

// INVARIANT: tenant_data_isolation — data access must be scoped to tenant
// INVARIANT: user_cannot_access_other_tenant_data — cross-tenant access blocked
export function getUserTenant(userId: string): string | null {
  const u = users.get(userId);
  return u ? u.tenantId : null;
}

export function assertTenantAccess(userId: string, targetTenantId: string): { error: string } | null {
  const userTenant = getUserTenant(userId);
  if (!userTenant) return { error: "NOT_FOUND: User not found" };
  if (userTenant !== targetTenantId) return { error: "CROSS_TENANT_ACCESS: User cannot access other tenant data" };
  return null;
}

export function assertWorkspaceActive(tenantId: string): { error: string } | null {
  const t = tenants.get(tenantId);
  if (!t) return { error: "NOT_FOUND: Tenant not found" };
  if (t.status === "DELETED") return { error: "WORKSPACE_DELETED: Deleted workspace cannot generate" };
  return null;
}

export function getUser(userId: string) { return users.get(userId) ?? null; }
export function getTenant(tenantId: string) { return tenants.get(tenantId) ?? null; }

export function deleteWorkspace(tenantId: string): { error: string } | null {
  const t = tenants.get(tenantId);
  if (!t) return { error: "NOT_FOUND: Tenant not found" };
  t.status = "DELETED";
  tenants.set(tenantId, t);
  return null;
}
