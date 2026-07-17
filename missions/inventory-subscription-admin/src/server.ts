// Mission Server — Inventory Subscription Admin
// Expert Packs: admin-system, ecommerce, saas-tool
import Fastify from "fastify";
import { reset } from "./db/store.js";
import * as auth from "./services/auth.service.js";
import * as product from "./services/product.service.js";
import * as tenantSvc from "./services/tenant.service.js";

const app = Fastify({ logger: false });
reset();

function uid(req: any) { return (req.headers["x-user-id"] as string) || null; }

app.get("/health", async () => ({ status:"ok", mission:"inventory-subscription-admin", packs:["admin-system","ecommerce","saas-tool"] }));
app.get("/ready", async () => ({ ready: true, store:"in-memory" }));

// Auth routes
app.get("/admin/users/:id", async (req, rep) => {
  const a = auth.authenticate(uid(req)); if ("error" in a) { rep.code(a.statusCode); return a; } return a.data;
});
app.patch("/admin/users/:id/role", async (req, rep) => {
  const r = auth.changeRole(uid(req), (req.params as any).id, (req.body as any).role);
  if ("error" in r) { rep.code(r.statusCode); return r; } return r.data;
});

// Product routes
app.post("/admin/products", async (req, rep) => {
  const r = product.createProduct(uid(req), req.body as any);
  if ("error" in r) { rep.code(r.statusCode); return r; } return r.data;
});
app.patch("/admin/products/:id/price", async (req, rep) => {
  const r = product.updatePrice(uid(req), (req.params as any).id, (req.body as any).price);
  if ("error" in r) { rep.code(r.statusCode); return r; } return r.data;
});
app.patch("/admin/products/:id/status", async (req, rep) => {
  const token = (req.headers["x-confirmation-token"] as string) || undefined;
  const r = product.changeStatus(uid(req), (req.params as any).id, (req.body as any).status, token);
  if ("error" in r) { rep.code(r.statusCode); return r; } return r.data;
});
app.post("/admin/products/:id/inventory", async (req, rep) => {
  const body = req.body as any;
  const r = product.adjustInventory(uid(req), (req.params as any).id, body.delta, body.reason || "api");
  if ("error" in r) { rep.code(r.statusCode); return r; } return r.data;
});

// Tenant routes
app.get("/admin/tenants/:id", async (req, rep) => {
  const r = tenantSvc.getTenant(uid(req), (req.params as any).id);
  if ("error" in r) { rep.code(r.statusCode); return r; } return r.data;
});
app.post("/admin/tenants/:id/quota", async (req, rep) => {
  const r = tenantSvc.checkQuota((req.params as any).id, (req.body as any).amount);
  if ("error" in r) { rep.code(r.statusCode); return r; } return r.data;
});
app.patch("/admin/tenants/:id/subscription", async (req, rep) => {
  const r = tenantSvc.updateSubscription(uid(req), (req.params as any).id, (req.body as any).status);
  if ("error" in r) { rep.code(r.statusCode); return r; } return r.data;
});

// Audit
app.get("/admin/audit", async (req, rep) => {
  const a = auth.checkPerm(uid(req), "audit:read");
  if ("error" in a) { rep.code(a.statusCode); return a; }
  const { auditLog } = await import("./db/store.js");
  return auditLog;
});

const PORT = parseInt(process.env.PORT || "3300");
app.listen({ port: PORT }, () => console.log(`Mission server on port ${PORT}`));
export { app };
