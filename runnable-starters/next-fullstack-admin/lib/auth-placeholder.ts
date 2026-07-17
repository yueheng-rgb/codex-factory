/**
 * 认证占位模块
 * 当前使用 mock 用户数据，真实项目需替换为 JWT / NextAuth / better-auth。
 */

export interface MockUser {
  id: string;
  username: string;
  password: string;   // ⚠️ 明文仅用于 mock，真实项目用 bcrypt
  role: "admin" | "user";
  displayName: string;
}

export const MOCK_USERS: MockUser[] = [
  {
    id: "u-001",
    username: "admin",
    password: "admin123",
    role: "admin",
    displayName: "管理员",
  },
  {
    id: "u-002",
    username: "user",
    password: "user123",
    role: "user",
    displayName: "普通用户",
  },
];

/**
 * Mock 登录验证。
 * 真实项目需替换为 bcrypt.compare + JWT sign。
 */
export function mockLogin(username: string, password: string): {
  token: string;
  user: Omit<MockUser, "password">;
} | null {
  const user = MOCK_USERS.find(
    (u) => u.username === username && u.password === password
  );
  if (!user) return null;

  const { password: _, ...safe } = user;
  return {
    token: `mock-token-${user.id}-${Date.now()}`,
    user: safe,
  };
}

/**
 * Mock token 验证。
 * 真实项目需替换为 JWT verify。
 */
export function mockVerifyToken(token: string): Omit<MockUser, "password"> | null {
  if (!token || !token.startsWith("mock-token-")) return null;
  const userId = token.split("-")[2];
  const user = MOCK_USERS.find((u) => u.id === userId);
  if (!user) return null;
  const { password: _, ...safe } = user;
  return safe;
}
