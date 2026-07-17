// Mini Inventory Admin — API Routes
import type { FastifyInstance } from "fastify";
import * as svc from "../services/inventory.service.js";
import { success, error, statusFromCode } from "../errors.js";

export function registerRoutes(app: FastifyInstance): void {
  // Health
  app.get("/health", async () => success({ status: "ok", service: "mini-inventory-admin" }));

  // GET /api/items
  app.get("/api/items", async (request) => {
    const q = request.query as Record<string, string>;
    const page = Math.max(1, parseInt(q.page || "1", 10) || 1);
    const pageSize = Math.min(100, Math.max(1, parseInt(q.pageSize || "20", 10) || 20));
    const result = svc.listItems({ page, pageSize, search: q.search, category: q.category, status: q.status });
    return success(result);
  });

  // GET /api/items/:id
  app.get("/api/items/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = svc.getItem(id);
    if (!item) return reply.status(404).send(error("NOT_FOUND", `Item "${id}" not found`));
    return success(item);
  });

  // POST /api/items
  app.post("/api/items", async (request, reply) => {
    const result = svc.createItem((request.body || {}) as Record<string, unknown>);
    if (result.error) return reply.status(statusFromCode(result.error.code)).send(error(result.error.code, result.error.message, result.error.details));
    return reply.status(201).send(success(result.data!));
  });

  // PATCH /api/items/:id
  app.patch("/api/items/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const result = svc.updateItem(id, (request.body || {}) as Record<string, unknown>);
    if (result.error) return reply.status(statusFromCode(result.error.code)).send(error(result.error.code, result.error.message, result.error.details));
    return success(result.data!);
  });

  // PATCH /api/items/:id/status
  app.patch("/api/items/:id/status", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = (request.body || {}) as { status?: string };
    if (!body.status) return reply.status(400).send(error("VALIDATION_ERROR", "status is required"));
    const result = svc.updateItemStatus(id, body.status);
    if (result.error) return reply.status(statusFromCode(result.error.code)).send(error(result.error.code, result.error.message));
    return success(result.data!);
  });

  // POST /api/items/:id/inventory
  app.post("/api/items/:id/inventory", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = (request.body || {}) as { delta?: number };
    if (body.delta === undefined) return reply.status(400).send(error("VALIDATION_ERROR", "delta is required"));
    const result = svc.adjustInventory(id, body.delta);
    if (result.error) return reply.status(statusFromCode(result.error.code)).send(error(result.error.code, result.error.message));
    return success(result.data!);
  });

  // DELETE /api/items/:id (blocked — destructive_action_requires_confirmation)
  app.delete("/api/items/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const result = svc.deleteItem(id);
    return reply.status(statusFromCode(result.error!.code)).send(error(result.error!.code, result.error!.message));
  });
}
