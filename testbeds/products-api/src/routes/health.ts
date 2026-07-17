/**
 * GET /health
 */
import type { FastifyInstance } from "fastify";
import { success } from "../utils/api-response.js";

export async function healthRoutes(app: FastifyInstance): Promise<void> {
  app.get("/health", async (_request, reply) => {
    return reply.send(success({ status: "ok", service: "products-api-testbed" }));
  });
}