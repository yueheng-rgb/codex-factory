// Auth Service — Admin System Pack
// Invariants: admin_required_for_admin_routes, role_permission_must_be_enforced, ordinary_admin_cannot_escalate_role, audit_log_required_for_sensitive_actions, protected_fields_cannot_be_modified_without_permission

import type { AdminUser, Role } from "../types/index.js";
import { users, audit, tenants } from "../db/store.js";
import { err, ok } from "../errors/index.js";
import { ERR } from "../types/index.js";

export function authenticate(uid: string | null) {
  if (!uid) return err(ERR.UNAUTHORIZED, "Authentication required", 401);
  const u = users.get(uid);
  if (!u) return err(ERR.UNAUTHORIZED, "Invalid user", 401);
  // SaaS invariant: tenant must be active
  const t = tenants.get(u.tenantId);
  if (t && t.subscriptionStatus === "EXPIRED") return err(ERR.SUBSCRIPTION_EXPIRED, "Tenant subscription expired", 403);
  return ok(u);
}

export function checkPerm(uid: string | null, perm: string) {
  const a = authenticate(uid);
  if ("error" in a) return a;
  const u = a.data as AdminUser;
  if (u.role === "SUPER_ADMIN" || u.permissions.includes("*")) return ok(u);
  if (!u.permissions.includes(perm)) {
    audit({ actorId:u.id, action:"PERMISSION_DENIED", targetType:"permission", targetId:perm, details:`${u.username} lacks ${perm}`, tenantId:u.tenantId });
    return err(ERR.FORBIDDEN, `Permission denied: ${perm}`, 403);
  }
  return ok(u);
}

const RANKS: Record<Role,number> = { SUPER_ADMIN:4, ADMIN:3, OPERATOR:2, VIEWER:1 };

export function changeRole(actorId: string | null, targetId: string, newRole: Role) {
  const a = checkPerm(actorId, "user:write");
  if ("error" in a) return a;
  const actor = a.data as AdminUser;
  const target = users.get(targetId);
  if (!target) return err("NOT_FOUND", "User not found", 404);
  // Tenant isolation
  if (actor.tenantId !== target.tenantId) return err(ERR.TENANT_ISOLATION, "Cross-tenant user modification forbidden", 403);
  if (actor.role !== "SUPER_ADMIN" && RANKS[newRole] > RANKS[actor.role]) {
    audit({ actorId:actor.id, action:"ROLE_ESCALATION_BLOCKED", targetType:"user", targetId, details:`${actor.username} tried ${newRole}`, tenantId:actor.tenantId });
    return err(ERR.ROLE_ESCALATION, `Cannot escalate to ${newRole}`, 403);
  }
  target.role = newRole; users.set(targetId, target);
  audit({ actorId:actor.id, action:"ROLE_CHANGED", targetType:"user", targetId, details:`Role -> ${newRole}`, tenantId:actor.tenantId });
  return ok(target);
}
