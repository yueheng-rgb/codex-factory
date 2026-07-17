/**
 * 权限模块
 * 真实项目需从 JWT token 解析角色，并在每个 API handler 中校验。
 */

export type Role = "admin" | "user";

export interface PermissionCheck {
  action: "read" | "create" | "update" | "delete" | "manage";
  resource: string;
}

const ROLE_PERMISSIONS: Record<Role, PermissionCheck[]> = {
  admin: [
    { action: "read", resource: "*" },
    { action: "create", resource: "*" },
    { action: "update", resource: "*" },
    { action: "delete", resource: "*" },
    { action: "manage", resource: "*" },
  ],
  user: [
    { action: "read", resource: "records" },
    { action: "read", resource: "dashboard" },
  ],
};

/**
 * 检查角色是否拥有指定权限。
 */
export function hasPermission(
  role: Role,
  action: PermissionCheck["action"],
  resource: string
): boolean {
  const perms = ROLE_PERMISSIONS[role] || [];
  return perms.some(
    (p) =>
      (p.resource === "*" || p.resource === resource) &&
      (p.action === action || p.action === "manage")
  );
}

/**
 * 要求管理员权限，否则返回 403。
 */
export function requireAdmin(role: Role): { allowed: boolean; error?: Response } {
  if (role !== "admin") {
    return {
      allowed: false,
      error: Response.json(
        { ok: false, error: { code: "FORBIDDEN", message: "需要管理员权限" } },
        { status: 403 }
      ),
    };
  }
  return { allowed: true };
}
