/**
 * Admin Routes???????
 *
 * GET /admin/audit-logs ? ???????? admin ???
 */

import type { FastifyInstance } from "fastify";
import { success, errorBody, statusFromCode } from "../utils/api-response.js";
import { parsePagination } from "../utils/pagination.js";
import { authMiddleware, adminMiddleware } from "../middleware/auth.js";
import * as auditService from "../services/audit-service.js";

export async function adminRoutes(app: FastifyInstance): Promise<void> {
  // ?? admin ?????? + admin ??
  app.addHook("onRequest", authMiddleware);
  app.addHook("onRequest", adminMiddleware);

  // GET /admin/audit-logs ? ??????
  app.get("/admin/audit-logs", async (request, reply) => {
    const query = request.query as {
      page?: string;
      limit?: string;
      pageSize?: string;
      userId?: string;
      action?: string;
      targetType?: string;
    };

    const { page, pageSize } = parsePagination(query);
    const result = auditService.listAuditLogs(
      { page, pageSize },
      {
        userId: query.userId,
        action: query.action,
        targetType: query.targetType,
      }
    );

    return reply.send(success(result.items, {
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
      totalPages: result.totalPages,
    }));
  });
}
