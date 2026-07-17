// Admin System Runtime Validation — Fastify Server
// Source: governance/expert-packs/admin-system/admin-system-pack.json v1.0.0

import Fastify from "fastify";
import { resetStores } from "./db/store.js";
import * as auth from "./services/auth.service.js";
import * as resource from "./services/resource.service.js";
import * as batch from "./services/batch.service.js";
import * as exportSvc from "./services/export.service.js";
import * as importSvc from "./services/import.service.js";

const app = Fastify({ logger: false });

resetStores();

function getUserId(req: any): string | null {
  return (req.headers["x-user-id"] as string) || null;
}

// Health check
app.get("/health", async () => ({ status: "ok", pack: "admin-system" }));

// === USER / AUTH ROUTES ===
app.get("/admin/users", async (req, reply) => {
  const page = parseInt((req.query as any).page || "1");
  const pageSize = parseInt((req.query as any).pageSize || "20");
  const result = auth.listUsers(getUserId(req), page, pageSize);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

app.get("/admin/users/:id", async (req, reply) => {
  const result = auth.getUserById(getUserId(req), (req.params as any).id);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

app.patch("/admin/users/:id/role", async (req, reply) => {
  const result = auth.changeUserRole(getUserId(req), (req.params as any).id, (req.body as any).role);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

// === RESOURCE ROUTES ===
app.post("/admin/resources", async (req, reply) => {
  const result = resource.createResource(getUserId(req), req.body as any);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

app.get("/admin/resources", async (req, reply) => {
  const q = req.query as any;
  const result = resource.listResources(
    getUserId(req),
    parseInt(q.page || "1"),
    parseInt(q.pageSize || "20"),
    q.includeDeleted === "true",
    q.search,
    q.searchField
  );
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

app.get("/admin/resources/:id", async (req, reply) => {
  const result = resource.getResource(getUserId(req), (req.params as any).id);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

app.patch("/admin/resources/:id", async (req, reply) => {
  const token = (req.headers["x-confirmation-token"] as string) || undefined;
  const result = resource.updateResource(getUserId(req), (req.params as any).id, req.body as any, token);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

app.patch("/admin/resources/:id/status", async (req, reply) => {
  const token = (req.headers["x-confirmation-token"] as string) || undefined;
  const result = resource.changeResourceStatus(getUserId(req), (req.params as any).id, (req.body as any).status, token);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

app.delete("/admin/resources/:id", async (req, reply) => {
  const token = (req.headers["x-confirmation-token"] as string) || undefined;
  const result = resource.deleteResource(getUserId(req), (req.params as any).id, token);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

// === BATCH ROUTES ===
app.post("/admin/batch-delete", async (req, reply) => {
  const result = batch.batchDelete(getUserId(req), req.body as any);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

app.post("/admin/batch-update-status", async (req, reply) => {
  const { newStatus, ...batchReq } = req.body as any;
  const result = batch.batchUpdateStatus(getUserId(req), batchReq, newStatus);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

// === EXPORT ROUTE ===
app.post("/admin/export", async (req, reply) => {
  const result = exportSvc.exportResources(getUserId(req), req.body as any);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

// === IMPORT ROUTE ===
app.post("/admin/import", async (req, reply) => {
  const { rows } = req.body as any;
  const result = importSvc.importResources(getUserId(req), rows);
  if ("error" in result) { reply.code(result.statusCode); return result; }
  return result.data;
});

// === AUDIT ROUTE ===
app.get("/admin/audit-log", async (req, reply) => {
  const authResult = auth.checkRolePermission(getUserId(req), "audit:read");
  if ("error" in authResult) { reply.code(authResult.statusCode); return authResult; }
  const { getAuditLogEntries } = await import("./db/store.js");
  return getAuditLogEntries();
});

const PORT = parseInt(process.env.PORT || "3200");
app.listen({ port: PORT }, () => {
  console.log(`Admin System Runtime Validation server on port ${PORT}`);
});

export { app };
