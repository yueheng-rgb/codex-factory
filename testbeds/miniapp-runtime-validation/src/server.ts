import Fastify from "fastify";
import { createSession, validateSession, users, processedPayments, appConfig } from "./store";
import { UserData, FormSubmission, PaymentCallback, UploadMeta, ALLOWED_MIME_TYPES, MAX_UPLOAD_SIZE } from "./types";

const app = Fastify({ logger: false });

// MINI-001: openid must be validated server-side
app.post("/api/auth/login", async (req, reply) => {
  const { openid } = req.body as any;
  if (!openid || typeof openid !== "string" || openid.length < 3) {
    return reply.status(400).send({ error: "INVALID_OPENID", message: "openid must be validated server-side" });
  }
  const session = createSession(openid);
  return { sessionToken: session.sessionToken, userId: session.userId };
});

// MINI-002: session token required for user actions
function requireAuth(req: any, reply: any): UserData | null {
  const token = (req.headers["x-session-token"] || req.headers.authorization?.replace("Bearer ","")) as string;
  if (!token) { reply.status(401).send({ error: "NO_SESSION_TOKEN" }); return null; }
  const sess = validateSession(token);
  if (!sess) { reply.status(401).send({ error: "INVALID_SESSION_TOKEN" }); return null; }
  return users.get(sess.userId) ?? null;
}

// MINI-003: user cannot access other user data
app.get("/api/user/profile", async (req, reply) => {
  const user = requireAuth(req, reply);
  if (!user) return;
  return { userId: user.userId, nickname: user.nickname, avatar: user.avatar };
});

app.get("/api/user/orders", async (req, reply) => {
  const user = requireAuth(req, reply);
  if (!user) return;
  // Only return own orders — cross-user check in tests
  const targetUserId = (req.query as any).userId;
  if (targetUserId && targetUserId !== user.userId) {
    return reply.status(403).send({ error: "CROSS_USER_ACCESS_DENIED" });
  }
  return { orders: user.orders };
});

// MINI-004: miniapp secret never exposed to client
app.get("/api/config", async (_req, reply) => {
  // Only return appId, NEVER appSecret
  return { appId: appConfig.appId, production: appConfig.production };
});

// MINI-005: payment callback must be idempotent
app.post("/api/payment/callback", async (req, reply) => {
  const cb = req.body as PaymentCallback;
  if (!cb.transactionId) return reply.status(400).send({ error: "MISSING_TRANSACTION_ID" });
  if (processedPayments.has(cb.transactionId)) {
    return { status: "OK", deduplicated: true };
  }
  processedPayments.add(cb.transactionId);
  return { status: "OK", deduplicated: false };
});

// MINI-006: upload file type must be validated
app.post("/api/upload", async (req, reply) => {
  const user = requireAuth(req, reply);
  if (!user) return;
  const meta = req.body as UploadMeta;
  if (!meta.mimeType || !ALLOWED_MIME_TYPES.includes(meta.mimeType)) {
    return reply.status(400).send({ error: "INVALID_FILE_TYPE", allowed: ALLOWED_MIME_TYPES });
  }
  // MINI-007: upload size limit
  if (meta.size > MAX_UPLOAD_SIZE) {
    return reply.status(400).send({ error: "FILE_TOO_LARGE", maxSize: MAX_UPLOAD_SIZE });
  }
  return { status: "OK", fileId: "f-" + Math.random().toString(36).slice(2) };
});

// MINI-008: form input must be validated
app.post("/api/form/submit", async (req, reply) => {
  const user = requireAuth(req, reply);
  if (!user) return;
  const form = req.body as FormSubmission;
  if (!form.title || form.title.length < 1 || form.title.length > 200) {
    return reply.status(400).send({ error: "INVALID_TITLE" });
  }
  if (!form.content || form.content.length < 1 || form.content.length > 5000) {
    return reply.status(400).send({ error: "INVALID_CONTENT" });
  }
  if (form.phone && !/^\d{11}$/.test(form.phone)) {
    return reply.status(400).send({ error: "INVALID_PHONE" });
  }
  return { status: "OK", submissionId: "sub-" + Math.random().toString(36).slice(2) };
});

// MINI-009: admin API requires permission
const ADMINS = new Set(["admin-001"]);
app.get("/api/admin/users", async (req, reply) => {
  const user = requireAuth(req, reply);
  if (!user) return;
  if (!ADMINS.has(user.userId)) {
    return reply.status(403).send({ error: "ADMIN_PERMISSION_REQUIRED" });
  }
  return { users: Array.from(users.values()).map(u => ({ userId: u.userId, nickname: u.nickname })) };
});

// Health check
app.get("/health", async () => ({ status: "ok", pack: "miniapp-runtime-validation" }));

app.listen({ port: 3200, host: "0.0.0.0" }).then(() => console.log("MINIAPP TESTBED :3200")).catch(console.error);
export { app };
