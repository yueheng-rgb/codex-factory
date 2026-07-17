/**
 * Mock Session Management — Cookie-based Auth
 * Uses HttpOnly cookies to store opaque session tokens.
 * Real project: replace with JWT / NextAuth / better-auth.
 */

import { cookies } from "next/headers";
import { MOCK_USERS, type MockUser } from "./auth-placeholder";

const SESSION_COOKIE = "mock_session";
const TOKEN_MAP = new Map<string, string>(); // opaque_token -> userId (server-side only)

/**
 * Generate a cryptographically opaque session token.
 * Real project: use JWT with proper signing.
 */
function generateToken(): string {
  const bytes = new Uint8Array(32);
  if (typeof crypto !== "undefined" && crypto.getRandomValues) {
    crypto.getRandomValues(bytes);
  } else {
    for (let i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
  }
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * Create a session: generate token, map to userId, store in server-side map.
 * Sets an HttpOnly, SameSite=Lax cookie.
 */
export async function createSession(userId: string): Promise<string> {
  const token = generateToken();
  TOKEN_MAP.set(token, userId);

  const cookieStore = cookies();
  (cookieStore as any).set(SESSION_COOKIE, token, {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 24, // 24 hours
  });

  return token;
}

/**
 * Destroy the session by removing the cookie and clearing the token map.
 */
export async function destroySession(): Promise<void> {
  const cookieStore = cookies();
  const token = (cookieStore as any).get(SESSION_COOKIE)?.value;
  if (token) {
    TOKEN_MAP.delete(token);
  }
  (cookieStore as any).set(SESSION_COOKIE, "", {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    maxAge: 0, // delete immediately
  });
}

/**
 * Get the current user from the session cookie.
 * Returns null if no valid session exists.
 */
export async function getSessionUser(): Promise<Omit<MockUser, "password"> | null> {
  const cookieStore = cookies();
  const token = (cookieStore as any).get(SESSION_COOKIE)?.value;
  if (!token) return null;

  const userId = TOKEN_MAP.get(token);
  if (!userId) return null;

  const user = MOCK_USERS.find((u) => u.id === userId);
  if (!user) return null;

  const { password: _, ...safe } = user;
  return safe;
}

/**
 * Require an authenticated user. Returns the user or throws.
 * Use this as a middleware guard in API routes.
 */
export async function requireMockUser(): Promise<Omit<MockUser, "password">> {
  const user = await getSessionUser();
  if (!user) {
    throw new Error("UNAUTHORIZED");
  }
  return user;
}