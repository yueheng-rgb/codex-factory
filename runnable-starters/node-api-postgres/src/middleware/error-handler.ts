/**
 * 全局错误处理中间件
 * 捕获未处理的异常，返回统一错误格式。
 */

import type { FastifyInstance, FastifyError } from "fastify";
import { errorBody } from "../utils/api-response.js";

export function registerErrorHandler(app: FastifyInstance): void {
  app.setErrorHandler((error: FastifyError, _request, reply) => {
    console.error(`[ERROR] ${error.message}`, error.stack);

    const statusCode = error.statusCode || 500;
    const code =
      statusCode === 400
        ? "VALIDATION_ERROR"
        : statusCode === 401
          ? "UNAUTHORIZED"
          : statusCode === 403
            ? "FORBIDDEN"
            : statusCode === 404
              ? "NOT_FOUND"
              : "INTERNAL_ERROR";

    const body = errorBody(code, error.message || "服务器内部错误");
    return reply.status(statusCode).send(body);
  });
}