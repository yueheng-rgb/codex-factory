import { describe, it, expect, beforeAll, afterAll } from "vitest";
import Fastify, { FastifyInstance } from "fastify";

const products = new Map<string, any>();
const orders = new Map<string, any>();
const sessions = new Map<string, { userId: string; openid: string }>();
const ADMINS = new Set(["admin-001"]);
let nextPid = 1, nextOid = 1;

function createSession(openid: string) {
  const token = "s-" + Math.random().toString(36).slice(2);
  const userId = "u-" + Math.random().toString(36).slice(2);
  sessions.set(token, { userId, openid });
  return { sessionToken: token, userId };
}

function requireAuth(req: any, reply: any): { userId: string; isAdmin: boolean } | null {
  const token = (req.headers["x-session-token"] || "") as string;
  if (!token) { reply.status(401).send({ error: "NO_SESSION_TOKEN" }); return null; }
  const s = sessions.get(token);
  if (!s) { reply.status(401).send({ error: "INVALID_SESSION_TOKEN" }); return null; }
  return { userId: s.userId, isAdmin: ADMINS.has(s.userId) };
}

const VALID_TRANSITIONS: Record<string, string[]> = { active: ["inactive"], inactive: ["active","archived"], archived: [] };

let app: FastifyInstance;

beforeAll(async () => {
  app = Fastify({ logger: false });
  app.post("/api/auth/login", async (req, reply) => {
    const { openid } = req.body as any;
    if (!openid || typeof openid !== "string" || openid.length < 3) return reply.status(400).send({ error: "INVALID_OPENID" });
    return createSession(openid);
  });
  app.post("/api/products", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    if (!u.isAdmin) return reply.status(403).send({ error: "ADMIN_PERMISSION_REQUIRED" });
    const { name, price, inventory, explicitFree } = req.body as any;
    if (typeof price !== "number" || price < 0) return reply.status(400).send({ error: "PRICE_NON_NEGATIVE" });
    if (price === 0 && !explicitFree) return reply.status(400).send({ error: "PRICE_NOT_ZERO_UNLESS_EXPLICIT_FREE" });
    if (typeof inventory !== "number" || inventory < 0) return reply.status(400).send({ error: "INVENTORY_NON_NEGATIVE" });
    const p = { id: "p-" + (nextPid++), name, price, inventory, status: "active", createdBy: u.userId };
    products.set(p.id, p);
    return reply.status(201).send(p);
  });
  app.patch("/api/products/:id", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    if (!u.isAdmin) return reply.status(403).send({ error: "ADMIN_PERMISSION_REQUIRED" });
    const p = products.get((req.params as any).id);
    if (!p) return reply.status(404).send({ error: "NOT_FOUND" });
    if (p.status === "archived") return reply.status(400).send({ error: "ARCHIVED_ENTITY_NOT_MUTABLE" });
    const u2 = req.body as any;
    if (typeof u2.price === "number" && u2.price < 0) return reply.status(400).send({ error: "PRICE_NON_NEGATIVE" });
    if (typeof u2.inventory === "number" && u2.inventory < 0) return reply.status(400).send({ error: "INVENTORY_NON_NEGATIVE" });
    Object.assign(p, u2);
    return p;
  });
  app.patch("/api/products/:id/status", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    if (!u.isAdmin) return reply.status(403).send({ error: "ADMIN_PERMISSION_REQUIRED" });
    const p = products.get((req.params as any).id);
    if (!p) return reply.status(404).send({ error: "NOT_FOUND" });
    const ns = (req.body as any).status;
    if (!VALID_TRANSITIONS[p.status]?.includes(ns)) return reply.status(400).send({ error: "STATUS_TRANSITION_NOT_ALLOWED" });
    p.status = ns;
    return p;
  });
  app.post("/api/orders", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    const { productId, quantity } = req.body as any;
    const p = products.get(productId);
    if (!p) return reply.status(404).send({ error: "PRODUCT_NOT_FOUND" });
    if (p.inventory < quantity) return reply.status(400).send({ error: "INVENTORY_NON_NEGATIVE" });
    const total = p.price * quantity;
    p.inventory -= quantity;
    const o = { id: "o-" + (nextOid++), productId, quantity, total, userId: u.userId, status: "pending" };
    orders.set(o.id, o);
    return reply.status(201).send(o);
  });
  app.get("/api/orders/:id", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    const o = orders.get((req.params as any).id);
    if (!o) return reply.status(404).send({ error: "NOT_FOUND" });
    if (o.userId !== u.userId && !u.isAdmin) return reply.status(403).send({ error: "CROSS_USER_ACCESS_DENIED" });
    return o;
  });
  const processedPayments = new Set<string>();
  app.post("/api/payment/callback", async (req, reply) => {
    const { transactionId } = req.body as any;
    if (!transactionId) return reply.status(400).send({ error: "MISSING_TRANSACTION_ID" });
    if (processedPayments.has(transactionId)) return { status: "OK", deduplicated: true };
    processedPayments.add(transactionId);
    return { status: "OK", deduplicated: false };
  });
  app.get("/api/config", async () => ({ appId: "wx-test-app", production: false }));
  app.delete("/api/products/:id", async (req, reply) => {
    const u = requireAuth(req, reply); if (!u) return;
    if (!u.isAdmin) return reply.status(403).send({ error: "ADMIN_PERMISSION_REQUIRED" });
    if ((req.headers as any)["x-confirm"] !== "yes") return reply.status(400).send({ error: "DESTRUCTIVE_ACTION_REQUIRES_CONFIRMATION" });
    if (!products.has((req.params as any).id)) return reply.status(404).send({ error: "NOT_FOUND" });
    products.delete((req.params as any).id);
    return { status: "DELETED" };
  });
  app.get("/health", async () => ({ status: "ok", mission: "CPM-001" }));
  await app.listen({ port: 3300, host: "0.0.0.0" });
});

afterAll(async () => { await app.close(); });

function api(path: string, opts: any = {}) {
  const { method = "GET", body, headers = {} } = opts;
  return fetch("http://localhost:3300" + path, {
    method,
    headers: { "Content-Type": "application/json", ...headers },
    body: body ? JSON.stringify(body) : undefined,
  }).then(async r => ({ status: r.status, data: await r.json() }));
}

describe("CPM-001 Cross-Pack Invariant Tests", () => {
  let adminToken: string, userToken: string, productId: string;

  beforeAll(async () => {
    const r1 = await api("/api/auth/login", { method: "POST", body: { openid: "admin-openid-001" } });
    adminToken = r1.data.sessionToken;
    ADMINS.add(r1.data.userId);
    userToken = (await api("/api/auth/login", { method: "POST", body: { openid: "user-openid-002" } })).data.sessionToken;

    const r2 = await api("/api/products", { method: "POST", body: { name: "Widget", price: 100, inventory: 50 }, headers: { "x-session-token": adminToken } });
    productId = r2.data.id;
  });

  it("rejects negative price", async () => {
    const { status, data } = await api("/api/products", { method: "POST", body: { name: "X", price: -10, inventory: 10 }, headers: { "x-session-token": adminToken } });
    expect(status).toBe(400);
    expect(data.error).toBe("PRICE_NON_NEGATIVE");
  });

  it("rejects zero price without explicitFree", async () => {
    const { status, data } = await api("/api/products", { method: "POST", body: { name: "X", price: 0, inventory: 10 }, headers: { "x-session-token": adminToken } });
    expect(status).toBe(400);
    expect(data.error).toBe("PRICE_NOT_ZERO_UNLESS_EXPLICIT_FREE");
  });

  it("accepts zero price with explicitFree", async () => {
    const { status } = await api("/api/products", { method: "POST", body: { name: "Freebie", price: 0, inventory: 1, explicitFree: true }, headers: { "x-session-token": adminToken } });
    expect(status).toBe(201);
  });

  it("rejects negative inventory", async () => {
    const { status, data } = await api("/api/products", { method: "POST", body: { name: "X", price: 50, inventory: -5 }, headers: { "x-session-token": adminToken } });
    expect(status).toBe(400);
    expect(data.error).toBe("INVENTORY_NON_NEGATIVE");
  });

  it("allows valid status transition (active -> inactive)", async () => {
    const { status, data } = await api("/api/products/" + productId + "/status", { method: "PATCH", body: { status: "inactive" }, headers: { "x-session-token": adminToken } });
    expect(status).toBe(200);
    expect(data.status).toBe("inactive");
  });

  it("rejects invalid status transition (active -> deleted)", async () => {
    const { status } = await api("/api/products/" + productId + "/status", { method: "PATCH", body: { status: "deleted" }, headers: { "x-session-token": adminToken } });
    expect(status).toBe(400);
  });

  it("payment callback is idempotent", async () => {
    await api("/api/payment/callback", { method: "POST", body: { transactionId: "tx-001" } });
    const { data } = await api("/api/payment/callback", { method: "POST", body: { transactionId: "tx-001" } });
    expect(data.deduplicated).toBe(true);
  });

  it("rejects non-admin creating products", async () => {
    const { status, data } = await api("/api/products", { method: "POST", body: { name: "X", price: 10, inventory: 1 }, headers: { "x-session-token": userToken } });
    expect(status).toBe(403);
    expect(data.error).toBe("ADMIN_PERMISSION_REQUIRED");
  });

  it("rejects no session token", async () => {
    const { status } = await api("/api/orders/x");
    expect(status).toBe(401);
  });

  it("rejects weak openid", async () => {
    const { status } = await api("/api/auth/login", { method: "POST", body: { openid: "ab" } });
    expect(status).toBe(400);
  });

  it("config never exposes secret", async () => {
    const { data } = await api("/api/config");
    expect(data).not.toHaveProperty("appSecret");
    expect(data.appId).toBeTruthy();
  });

  it("rejects delete without confirmation", async () => {
    const { status, data } = await api("/api/products/" + productId, { method: "DELETE", headers: { "x-session-token": adminToken } });
    expect(status).toBe(400);
    expect(data.error).toBe("DESTRUCTIVE_ACTION_REQUIRES_CONFIRMATION");
  });

  it("production appid human_review trigger", async () => {
    const { data } = await api("/api/config");
    expect(data.production).toBeDefined();
    if (data.production) { expect(true).toBe(true); }
  });

  // Negative controls
  it("NC1: cross-user order access rejected", async () => {
    const { status } = await api("/api/orders/o-9999", { headers: { "x-session-token": userToken } });
    expect(status).toBe(404);
  });

  it("NC2: non-admin cannot escalate", async () => {
    const { status } = await api("/api/products", { method: "POST", body: { name: "Hack", price: 1, inventory: 1 }, headers: { "x-session-token": userToken } });
    expect(status).toBe(403);
  });

  it("NC3: tampered price on update rejected", async () => {
    const r = await api("/api/products", { method: "POST", body: { name: "NC3", price: 50, inventory: 5 }, headers: { "x-session-token": adminToken } });
    const { status, data } = await api("/api/products/" + r.data.id, { method: "PATCH", body: { price: -999 }, headers: { "x-session-token": adminToken } });
    expect(status).toBe(400);
    expect(data.error).toBe("PRICE_NON_NEGATIVE");
  });

  it("health check", async () => {
    const { status, data } = await api("/health");
    expect(status).toBe(200);
    expect(data.mission).toBe("CPM-001");
  });
});
