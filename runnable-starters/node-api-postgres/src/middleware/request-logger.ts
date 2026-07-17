/**
 * 请求日志中间件（占位）
 * 真实项目接入结构化日志系统（如 pino/winston）。
 */

import type { FastifyInstance } from "fastify";

export function registerRequestLogger(app: FastifyInstance): void {
  app.addHook("onRequest", async (request) => {
    // 占位：记录请求信息
    // 真实项目替换为结构化日志
    console.log(`[REQ] ${request.method} ${request.url}`);
  });

  app.addHook("onResponse", async (request, reply) => {
    console.log(`[RES] ${request.method} ${request.url} ${reply.statusCode}`);
  });
}
