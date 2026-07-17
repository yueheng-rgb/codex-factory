import { FastifyInstance } from "fastify";
import { createProduct, getProduct, listProducts, updateProduct } from "../services/product.service.js";
import { adjustInventory, getAuditLog } from "../services/inventory.service.js";
import { UserRole } from "../types.js";

function getRole(request: { headers: Record<string, string | undefined> }): UserRole {
  return (request.headers["x-user-role"] as UserRole) || "USER";
}
function getUserId(request: { headers: Record<string, string | undefined> }): string {
  return request.headers["x-user-id"] || "anon";
}

export function registerProductRoutes(app: FastifyInstance): void {
  app.get("/api/products", async (request) => {
    const query = request.query as { page?: string; pageSize?: string };
    const page = parseInt(query.page || "1");
    const pageSize = parseInt(query.pageSize || "20");
    return { ok: true, data: listProducts(page, pageSize) };
  });

  app.get("/api/products/:id", async (request) => {
    const { id } = request.params as { id: string };
    const product = getProduct(id);
    if (!product) return { statusCode: 404, ...{ ok: false, error: { code: "NOT_FOUND", message: "Product not found" } } };
    return { ok: true, data: product };
  });

  app.post("/api/products", async (request, reply) => {
    const body = request.body as Record<string, unknown>;
    const result = createProduct(body as any, getUserId(request));
    if ("error" in result) {
      const [code, ...msg] = result.error.split(": ");
      reply.code(400);
      return { ok: false, error: { code, message: msg.join(": ") } };
    }
    reply.code(201);
    return { ok: true, data: result };
  });

  app.patch("/api/products/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = request.body as Record<string, unknown>;
    const role = getRole(request);
    // INVARIANT: admin_required_for_price_change (checked inside updateProduct)
    const result = updateProduct(id, body as any, getUserId(request), role);
    if ("error" in result) {
      const [code, ...msg] = result.error.split(": ");
      const statusCode = code === "FORBIDDEN_PRICE_CHANGE" ? 403 : 400;
      reply.code(statusCode);
      return { ok: false, error: { code, message: msg.join(": ") } };
    }
    return { ok: true, data: result };
  });

  app.post("/api/products/:id/inventory", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = request.body as { delta: number; reason: string };
    const result = adjustInventory(id, body.delta ?? 0, getUserId(request), body.reason || "manual");
    if ("error" in result) {
      const [code, ...msg] = result.error.split(": ");
      reply.code(400);
      return { ok: false, error: { code, message: msg.join(": ") } };
    }
    return { ok: true, data: result };
  });

  app.get("/api/audit-log", async (request) => {
    const query = request.query as { productId?: string };
    return { ok: true, data: getAuditLog(query.productId) };
  });
}
