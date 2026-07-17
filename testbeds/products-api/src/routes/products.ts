/**
 * Products CRUD routes
 *
 * GET    /api/products           ！ list (paginated, searchable, filterable)
 * GET    /api/products/:id       ！ get by id
 * POST   /api/products           ！ create
 * PATCH  /api/products/:id       ！ update
 * PATCH  /api/products/:id/status ！ status transition
 */
import type { FastifyInstance } from "fastify";
import { success, errorBody, statusFromCode } from "../utils/api-response.js";
import * as productService from "../services/product-service.js";

export async function productRoutes(app: FastifyInstance): Promise<void> {
  // GET /api/products
  app.get("/api/products", async (request, reply) => {
    const q = request.query as { page?: string; pageSize?: string; search?: string; category?: string; status?: string };
    const page = Math.max(1, parseInt(q.page || "1", 10) || 1);
    const pageSize = Math.min(100, Math.max(1, parseInt(q.pageSize || "20", 10) || 20));
    const result = productService.listProducts({ page, pageSize, search: q.search, category: q.category, status: q.status });
    return reply.send(success(result.items, { page: result.page, pageSize: result.pageSize, total: result.total, totalPages: result.totalPages }));
  });

  // GET /api/products/:id
  app.get("/api/products/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const product = productService.getProduct(id);
    if (!product) return reply.status(404).send(errorBody("NOT_FOUND", `Product "${id}" not found`));
    return reply.send(success(product));
  });

  // POST /api/products
  app.post("/api/products", async (request, reply) => {
    const result = productService.createProduct((request.body || {}) as Record<string, unknown>);
    if (result.error) return reply.status(statusFromCode(result.error.code)).send(errorBody(result.error.code, result.error.message, result.error.details));
    return reply.status(201).send(success(result.data!));
  });

  // PATCH /api/products/:id
  app.patch("/api/products/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const result = productService.updateProduct(id, (request.body || {}) as Record<string, unknown>);
    if (result.error) return reply.status(statusFromCode(result.error.code)).send(errorBody(result.error.code, result.error.message, result.error.details));
    return reply.send(success(result.data!));
  });

  // PATCH /api/products/:id/status
  app.patch("/api/products/:id/status", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = (request.body || {}) as { status?: string };
    if (!body.status) return reply.status(400).send(errorBody("VALIDATION_ERROR", "status is required"));
    const result = productService.updateProductStatus(id, body.status);
    if (result.error) return reply.status(statusFromCode(result.error.code)).send(errorBody(result.error.code, result.error.message));
    return reply.send(success(result.data!));
  });
}