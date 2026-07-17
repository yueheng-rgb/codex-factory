/**
 * Mock Authentication
 * Uses mock user data. Real project: replace with JWT / NextAuth / better-auth.
 */

export interface MockUser {
  id: string;
  username: string;
  password: string;   // ⚠️ plaintext only for mock; real project uses bcrypt
  role: "admin" | "user";
  displayName: string;
}

export const MOCK_USERS: MockUser[] = [
  {
    id: "u-001",
    username: "admin",
    password: "admin123",
    role: "admin",
    displayName: "Admin",
  },
  {
    id: "u-002",
    username: "user",
    password: "user123",
    role: "user",
    displayName: "Demo User",
  },
];

/**
 * Mock login validation.
 * Real project: bcrypt.compare + JWT sign.
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
 * Mock token verification.
 * Real project: JWT verify.
 */
export function mockVerifyToken(token: string): Omit<MockUser, "password"> | null {
  if (!token || !token.startsWith("mock-token-")) return null;
  const userId = token.split("-")[2];
  const user = MOCK_USERS.find((u) => u.id === userId);
  if (!user) return null;
  const { password: _, ...safe } = user;
  return safe;
}