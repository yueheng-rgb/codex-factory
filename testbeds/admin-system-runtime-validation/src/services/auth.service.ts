// Admin System Runtime Validation — Auth Service
// Enforces: admin_required_for_admin_routes, role_permission_must_be_enforced, ordinary_admin_cannot_escalate_role

import type { AdminUser, Role } from "../types.js";
import { users, addAuditEntry } from "../db/store.js";
import { errorResponse, okResponse } from "../errors.js";
import { ERROR_CODES } from "../types.js";

export function authenticate(userId: string): AdminUser | null {
  return users.get(userId) ?? null;
}

export function checkPermission(user: AdminUser, requiredPermission: string): boolean {
  if (user.role === "SUPER_ADMIN") return true;
  if (user.permissions.includes("*")) return true;
  return user.permissions.includes(requiredPermission);
}

export function checkAdminRoute(userId: string | null) {
  if (!userId) return errorResponse(ERROR_CODES.UNAUTHORIZED, "Admin authentication required", 401);
  const user = authenticate(userId);
  if (!user) return errorResponse(ERROR_CODES.UNAUTHORIZED, "Invalid admin user", 401);
  return okResponse(user);
}

export function checkRolePermission(userId: string | null, requiredPermission: string) {
  const auth = checkAdminRoute(userId);
  if ("error" in auth) return auth;
  const user = auth.data as AdminUser;
  if (!checkPermission(user, requiredPermission)) {
    addAuditEntry({
      actorId: user.id, actorRole: user.role,
      action: "PERMISSION_DENIED", targetType: "permission", targetId: requiredPermission,
      details: `User ${user.username} (${user.role}) attempted action requiring ${requiredPermission}`,
      result: "REJECTED"
    });
    return errorResponse(ERROR_CODES.FORBIDDEN, `Permission denied: ${requiredPermission}`, 403);
  }
  addAuditEntry({
    actorId: user.id, actorRole: user.role,
    action: "PERMISSION_CHECK_PASSED", targetType: "permission", targetId: requiredPermission,
    details: `User ${user.username} (${user.role}) passed check for ${requiredPermission}`,
    result: "SUCCESS"
  });
  return okResponse(user);
}

const ROLE_HIERARCHY: Record<Role, number> = { SUPER_ADMIN: 4, ADMIN: 3, OPERATOR: 2, VIEWER: 1 };

export function changeUserRole(actorId: string, targetUserId: string, newRole: Role) {
  const auth = checkRolePermission(actorId, "user:write");
  if ("error" in auth) return auth;
  const actor = auth.data as AdminUser;

  const target = users.get(targetUserId);
  if (!target) return errorResponse("NOT_FOUND", "Target user not found", 404);

  // Invariant: ordinary_admin_cannot_escalate_role
  if (actor.role !== "SUPER_ADMIN") {
    if (ROLE_HIERARCHY[newRole] > ROLE_HIERARCHY[actor.role]) {
      addAuditEntry({
        actorId: actor.id, actorRole: actor.role,
        action: "ROLE_ESCALATION_ATTEMPTED", targetType: "user", targetId: targetUserId,
        details: `${actor.username} (${actor.role}) attempted to escalate ${target.username} to ${newRole}`,
        result: "REJECTED"
      });
      return errorResponse(ERROR_CODES.ROLE_ESCALATION_BLOCKED,
        `Cannot escalate to ${newRole} from role ${actor.role}`, 403);
    }
  }

  const oldRole = target.role;
  target.role = newRole;
  users.set(targetUserId, target);

  addAuditEntry({
    actorId: actor.id, actorRole: actor.role,
    action: "ROLE_CHANGED", targetType: "user", targetId: targetUserId,
    details: `Role changed from ${oldRole} to ${newRole} by ${actor.username}`,
    result: "SUCCESS"
  });

  return okResponse(target);
}

export function getUserById(requestorId: string | null, userId: string) {
  const auth = checkRolePermission(requestorId, "user:read");
  if ("error" in auth) return auth;
  const user = users.get(userId);
  if (!user) return errorResponse("NOT_FOUND", "User not found", 404);
  return okResponse(user);
}

export function listUsers(requestorId: string | null, page: number = 1, pageSize: number = 20) {
  const auth = checkRolePermission(requestorId, "user:read");
  if ("error" in auth) return auth;

  // Invariant: pagination_limit_enforced
  const maxPageSize = 100;
  const effectivePageSize = Math.min(pageSize, maxPageSize);
  if (pageSize > maxPageSize) {
    return errorResponse(ERROR_CODES.PAGINATION_LIMIT_EXCEEDED,
      `Page size ${pageSize} exceeds maximum ${maxPageSize}`, 400);
  }

  const allUsers = Array.from(users.values());
  const total = allUsers.length;
  const start = (page - 1) * effectivePageSize;
  const paged = allUsers.slice(start, start + effectivePageSize);

  return okResponse({ items: paged, total, page, pageSize: effectivePageSize });
}
