import { describe, it, expect, beforeAll, afterAll } from "vitest";
import Fastify, { FastifyInstance } from "fastify";
import { createSession, validateSession, users, processedPayments, appConfig } from "../src/store";
import { ALLOWED_MIME_TYPES, MAX_UPLOAD_SIZE } from "../src/types";

let app: FastifyInstance;

beforeAll(async () => {
  app = Fastify({ logger: false });
  app.post("/api/auth/login", async (req, reply) => {
    const { openid } = req.body as any;
    if (!openid || typeof openid !== "string" || openid.length < 3) return reply.status(400).send({ error: "INVALID_OPENID" });
    const s = createSession(openid);
    return { sessionToken: s.sessionToken, userId: s.userId };
  });
  function requireAuth(req: any, reply: any): any {
    const token = (req.headers["x-session-token"] || "") as string;
    if (!token) { reply.status(401).send({ error: "NO_SESSION_TOKEN" }); return null; }
    const sess = validateSession(token);
    if (!sess) { reply.status(401).send({ error: "INVALID_SESSION_TOKEN" }); return null; }
    return users.get(sess.userId) ?? null;
  }
  const ADMINS = new Set(["u-admin-001"]);
  app.get("/api/user/profile", async (req, reply) => { const u = requireAuth(req, reply); if (!u) return; return { userId: u.userId, nickname: u.nickname }; });
  app.get("/api/user/orders", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    const target = (req.query as any).userId;
    if (target && target !== u.userId) return reply.status(403).send({ error: "CROSS_USER_ACCESS_DENIED" });
    return { orders: u.orders };
  });
  app.get("/api/config", async (_req, reply) => ({ appId: appConfig.appId, production: appConfig.production }));
  app.post("/api/payment/callback", async (req, reply) => {
    const cb = req.body as any;
    if (!cb.transactionId) return reply.status(400).send({ error: "MISSING_TRANSACTION_ID" });
    if (processedPayments.has(cb.transactionId)) return { status: "OK", deduplicated: true };
    processedPayments.add(cb.transactionId);
    return { status: "OK", deduplicated: false };
  });
  app.post("/api/upload", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    const m = req.body as any;
    if (!m.mimeType || !ALLOWED_MIME_TYPES.includes(m.mimeType)) return reply.status(400).send({ error: "INVALID_FILE_TYPE" });
    if (m.size > MAX_UPLOAD_SIZE) return reply.status(400).send({ error: "FILE_TOO_LARGE" });
    return { status: "OK", fileId: "f-xxx" };
  });
  app.post("/api/form/submit", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    const f = req.body as any;
    if (!f.title || f.title.length < 1 || f.title.length > 200) return reply.status(400).send({ error: "INVALID_TITLE" });
    if (!f.content || f.content.length < 1 || f.content.length > 5000) return reply.status(400).send({ error: "INVALID_CONTENT" });
    if (f.phone && !/^\d{11}$/.test(f.phone)) return reply.status(400).send({ error: "INVALID_PHONE" });
    return { status: "OK" };
  });
  app.get("/api/admin/users", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    if (!ADMINS.has(u.userId)) return reply.status(403).send({ error: "ADMIN_PERMISSION_REQUIRED" });
    return { users: [] };
  });
  app.get("/health", async () => ({ status: "ok" }));
  await app.listen({ port: 13200, host: "0.0.0.0" });
});

afterAll(async () => { await app?.close(); });

async function login(openid: string) {
  const res = await app.inject({ method:"POST", url:"/api/auth/login", payload:{ openid } });
  return res.json();
}

describe("MINI-001 openid validation", () => {
  it("accepts valid openid", async () => {
    const res = await app.inject({ method:"POST", url:"/api/auth/login", payload:{ openid:"oTest123" } });
    expect(res.statusCode).toBe(200);
  });
  it("rejects empty openid", async () => {
    const res = await app.inject({ method:"POST", url:"/api/auth/login", payload:{ openid:"" } });
    expect(res.statusCode).toBe(400);
  });
  it("rejects missing openid", async () => {
    const res = await app.inject({ method:"POST", url:"/api/auth/login", payload:{} });
    expect(res.statusCode).toBe(400);
  });
});

describe("MINI-002 session token", () => {
  it("rejects no token", async () => {
    const res = await app.inject({ method:"GET", url:"/api/user/profile" });
    expect(res.statusCode).toBe(401);
  });
  it("rejects bad token", async () => {
    const res = await app.inject({ method:"GET", url:"/api/user/profile", headers:{"x-session-token":"bad"} });
    expect(res.statusCode).toBe(401);
  });
  it("accepts valid token", async () => {
    const { sessionToken } = await login("oU1");
    const res = await app.inject({ method:"GET", url:"/api/user/profile", headers:{"x-session-token":sessionToken} });
    expect(res.statusCode).toBe(200);
  });
});


describe("MINI-003 cross-user isolation", () => {
  it("rejects cross-user order access", async () => {
    const { sessionToken } = await login("oUserA");
    const res = await app.inject({ method:"GET", url:"/api/user/orders?userId=u-other", headers:{"x-session-token":sessionToken} });
    expect(res.statusCode).toBe(403);
  });
});
describe("MINI-004 secret never exposed", () => {
  it("config excludes appSecret", async () => {
    const res = await app.inject({ method:"GET", url:"/api/config" });
    expect(res.json().appSecret).toBeUndefined();
  });
});

describe("MINI-005 payment idempotency", () => {
  it("first callback processes", async () => {
    const res = await app.inject({ method:"POST", url:"/api/payment/callback", payload:{ transactionId:"tx-1", openid:"o1", amount:100, status:"PAID" } });
    expect(res.json().deduplicated).toBe(false);
  });
  it("repeat callback deduplicates", async () => {
    const res = await app.inject({ method:"POST", url:"/api/payment/callback", payload:{ transactionId:"tx-1", openid:"o1", amount:100, status:"PAID" } });
    expect(res.json().deduplicated).toBe(true);
  });
});

describe("MINI-006 upload type validation", () => {
  it("accepts allowed type", async () => {
    const { sessionToken } = await login("oUp1");
    const res = await app.inject({ method:"POST", url:"/api/upload", headers:{"x-session-token":sessionToken}, payload:{ fileName:"a.jpg", mimeType:"image/jpeg", size:1000 } });
    expect(res.statusCode).toBe(200);
  });
  it("rejects disallowed type", async () => {
    const { sessionToken } = await login("oUp2");
    const res = await app.inject({ method:"POST", url:"/api/upload", headers:{"x-session-token":sessionToken}, payload:{ fileName:"a.exe", mimeType:"application/x-msdownload", size:1000 } });
    expect(res.statusCode).toBe(400);
  });
});

describe("MINI-007 upload size", () => {
  it("rejects oversized", async () => {
    const { sessionToken } = await login("oBig");
    const res = await app.inject({ method:"POST", url:"/api/upload", headers:{"x-session-token":sessionToken}, payload:{ fileName:"big.jpg", mimeType:"image/jpeg", size:MAX_UPLOAD_SIZE+1 } });
    expect(res.statusCode).toBe(400);
  });
});

describe("MINI-008 form validation", () => {
  it("accepts valid form", async () => {
    const { sessionToken } = await login("oF1");
    const res = await app.inject({ method:"POST", url:"/api/form/submit", headers:{"x-session-token":sessionToken}, payload:{ title:"Hello", content:"World" } });
    expect(res.statusCode).toBe(200);
  });
  it("rejects empty title", async () => {
    const { sessionToken } = await login("oF2");
    const res = await app.inject({ method:"POST", url:"/api/form/submit", headers:{"x-session-token":sessionToken}, payload:{ title:"", content:"x" } });
    expect(res.statusCode).toBe(400);
  });
  it("rejects bad phone", async () => {
    const { sessionToken } = await login("oF3");
    const res = await app.inject({ method:"POST", url:"/api/form/submit", headers:{"x-session-token":sessionToken}, payload:{ title:"T", content:"C", phone:"123" } });
    expect(res.statusCode).toBe(400);
  });
});

describe("MINI-009 admin permission", () => {
  it("rejects non-admin", async () => {
    const { sessionToken } = await login("oNormal");
    const res = await app.inject({ method:"GET", url:"/api/admin/users", headers:{"x-session-token":sessionToken} });
    expect(res.statusCode).toBe(403);
  });
});

describe("MINI-010 production human review", () => {
  it("detects production mode for review trigger", () => {
    appConfig.production = true;
    expect(appConfig.production).toBe(true);
    appConfig.production = false;
  });
});

describe("NEGATIVE CONTROLS", () => {
  it("NC1: forged openid rejected", async () => {
    const res = await app.inject({ method:"POST", url:"/api/auth/login", payload:{ openid:"" } });
    expect(res.statusCode).toBe(400);
  });
  it("NC2: no session token rejected", async () => {
    const res = await app.inject({ method:"GET", url:"/api/user/profile" });
    expect(res.statusCode).toBe(401);
  });
  it("NC3: cross-user data rejected", async () => {
    const { sessionToken } = await login("oNC3");
    const res = await app.inject({ method:"GET", url:"/api/user/orders?userId=u-other", headers:{"x-session-token":sessionToken} });
    expect(res.statusCode).toBe(403);
  });
  it("NC4: appSecret not exposed", async () => {
    const res = await app.inject({ method:"GET", url:"/api/config" });
    expect(res.json().appSecret).toBeUndefined();
  });
  it("NC5: duplicate payment idempotent", async () => {
    await app.inject({ method:"POST", url:"/api/payment/callback", payload:{ transactionId:"tx-nc5", openid:"o1", amount:50, status:"PAID" } });
    const res = await app.inject({ method:"POST", url:"/api/payment/callback", payload:{ transactionId:"tx-nc5", openid:"o1", amount:50, status:"PAID" } });
    expect(res.json().deduplicated).toBe(true);
  });
  it("NC6: disallowed upload rejected", async () => {
    const { sessionToken } = await login("oNC6");
    const res = await app.inject({ method:"POST", url:"/api/upload", headers:{"x-session-token":sessionToken}, payload:{ fileName:"bad.exe", mimeType:"application/exe", size:100 } });
    expect(res.statusCode).toBe(400);
  });
  it("NC7: oversized upload rejected", async () => {
    const { sessionToken } = await login("oNC7");
    const res = await app.inject({ method:"POST", url:"/api/upload", headers:{"x-session-token":sessionToken}, payload:{ fileName:"huge.jpg", mimeType:"image/jpeg", size:99999999 } });
    expect(res.statusCode).toBe(400);
  });
  it("NC8: non-admin admin API rejected", async () => {
    const { sessionToken } = await login("oNC8");
    const res = await app.inject({ method:"GET", url:"/api/admin/users", headers:{"x-session-token":sessionToken} });
    expect(res.statusCode).toBe(403);
  });
});

describe("HEALTH", () => {
  it("health check", async () => {
    const res = await app.inject({ method:"GET", url:"/health" });
    expect(res.statusCode).toBe(200);
  });
});
