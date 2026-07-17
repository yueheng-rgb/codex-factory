/**
 * Global error handler ¡ª unified error format
 */
import type { FastifyInstance, FastifyError } from "fastify";
import { errorBody } from "../utils/api-response.js";

export function registerErrorHandler(app: FastifyInstance): void {
  app.setErrorHandler((error: FastifyError, _request, reply) => {
    const statusCode = error.statusCode || 500;
    const code =
      statusCode === 400 ? "VALIDATION_ERROR"
      : statusCode === 401 ? "UNAUTHORIZED"
      : statusCode === 403 ? "FORBIDDEN"
      : statusCode === 404 ? "NOT_FOUND"
      : "INTERNAL_ERROR";
    return reply.status(statusCode).send(errorBody(code, error.message || "Internal server error"));
  });
}