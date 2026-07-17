/**
 * ????????Mock ???
 * ??????? Prisma/Drizzle ????? + bcrypt?
 *
 * ?? ??? token ???????????????
 * ?? ??? userId + timestamp ?????
 */

import type { MockUser } from "../types/index.js";
import { MOCK_USERS } from "../db/mock-db.js";

// ?????? token ??
const TOKEN_MAP: Record<string, string> = {
  "u-001": "mock-token-admin",
  "u-002": "mock-token-user",
};

export function findByUsername(username: string): MockUser | null {
  return MOCK_USERS.find((u) => u.username === username) || null;
}

export function findById(id: string): MockUser | null {
  return MOCK_USERS.find((u) => u.id === id) || null;
}

export function mockLogin(username: string, password: string): {
  token: string;
  user: Omit<MockUser, "password">;
} | null {
  const user = findByUsername(username);
  if (!user || user.password !== password) return null;

  const { password: _, ...safe } = user;
  // ???????????? token
  const token = TOKEN_MAP[user.id] || `mock-token-fallback-${Date.now()}`;
  return { token, user: safe };
}
