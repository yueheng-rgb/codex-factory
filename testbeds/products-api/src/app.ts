/**
 * Fastify App factory for Products API testbed
 */
import Fastify from "fastify";
import { registerErrorHandler } from "./middleware/error-handler.js";
import { healthRoutes } from "./routes/health.js";
import { productRoutes } from "./routes/products.js";

export function buildApp() {
  const app = Fastify({ logger: false });

  registerErrorHandler(app);
  healthRoutes(app);
  productRoutes(app);

  // Catch-all 404
  app.setNotFoundHandler(async (_request, reply) => {
    return reply.status(404).send({ ok: false, error: { code: "NOT_FOUND", message: "Route not found" } });
  });

  return app;
}