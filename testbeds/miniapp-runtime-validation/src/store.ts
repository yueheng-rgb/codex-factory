import { MiniappSession, UserData, PaymentCallback } from "./types";
export const sessions = new Map<string, MiniappSession>();
export const users = new Map<string, UserData>();
export const processedPayments = new Set<string>();
export const appConfig: { appId: string; appSecret: string; production: boolean } = {
  appId: "wx-test-appid-xxxx",
  appSecret: "test-secret-do-not-expose",
  production: false
};
export function createSession(openid: string): MiniappSession {
  const token = "sess-" + Math.random().toString(36).slice(2);
  const userId = "u-" + openid;
  const s: MiniappSession = { openid, sessionToken: token, userId };
  sessions.set(token, s);
  if (!users.has(userId)) users.set(userId, { userId, nickname: "用户"+userId.slice(-4), avatar: "", orders: [] });
  return s;
}
export function validateSession(token: string): MiniappSession | null {
  return sessions.get(token) ?? null;
}
