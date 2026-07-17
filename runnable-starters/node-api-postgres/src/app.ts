/**
 * Fastify App 工厂
 * 注册所有 routes、middleware、错误处理。
 * 不直接 listen — server.ts 负责启动。
 *
 * ?? 使用 app.register() 创建 scoped plugin，确保 addHook 不泄漏到其他路由。
 */

import Fastify from "fastify";
import { registerErrorHandler } from "./middleware/error-handler.js";
import { registerRequestLogger } from "./middleware/request-logger.js";
import { healthRoutes } from "./routes/health.js";
import { authRoutes } from "./routes/auth-placeholder.js";
import { recordRoutes } from "./routes/records.js";
import { adminRoutes } from "./routes/admin.js";

export function buildApp() {
  const app = Fastify({
    logger: false,
  });

  // ====== 全局中间件 ======
  registerErrorHandler(app);
  registerRequestLogger(app);

  // ====== 公开路由（无需认证） ======
  healthRoutes(app);
  authRoutes(app);

  // ====== 需认证路由（scoped plugin，hook 不泄漏） ======
  app.register(async (scoped) => {
    recordRoutes(scoped);
  });

  // ====== Admin 路由（scoped plugin，需认证 + admin 权限） ======
  app.register(async (scoped) => {
    adminRoutes(scoped);
  });

    // Catch-all 404 for unified error format
  app.setNotFoundHandler(async (_request, reply) => {
    return reply.status(404).send({ ok: false, error: { code: 'NOT_FOUND', message: 'Route not found' } });
  });

  return app;
}