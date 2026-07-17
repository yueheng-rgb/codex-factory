/**
 * Records Routes
 * 
 * GET    /records          — 列表（分页 + 搜索 + 筛选）
 * GET    /records/:id      — 详情
 * POST   /records          — 创建
 * PATCH  /records/:id      — 更新
 * POST   /records/:id/action — 业务动作（状态流转 + 幂等占位）
 */

import type { FastifyInstance } from "fastify";
import { success, errorBody, statusFromCode } from "../utils/api-response.js";
import { parsePagination } from "../utils/pagination.js";
import { authMiddleware } from "../middleware/auth.js";
import * as recordService from "../services/record-service.js";

export async function recordRoutes(app: FastifyInstance): Promise<void> {
  // 所有 records 路由需要登录
  app.addHook("onRequest", authMiddleware);

  // GET /records — 列表
  app.get("/records", async (request, reply) => {
    const query = request.query as {
      page?: string;
      pageSize?: string;
      search?: string;
      status?: string;
    };

    const { page, pageSize } = parsePagination(query);
    const result = recordService.listRecords({
      page,
      pageSize, search: query.search || undefined,
      status: query.status || undefined,
    });

    return reply.send(success(result.items, {
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
      totalPages: result.totalPages,
    }));
  });

  // GET /records/:id — 详情
  app.get("/records/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const record = recordService.getRecord(id);

    if (!record) {
      const err = errorBody("NOT_FOUND", "记录不存在");
      return reply.status(statusFromCode("NOT_FOUND")).send(err);
    }

    return reply.send(success(record));
  });

  // POST /records — 创建
  app.post("/records", async (request, reply) => {
    const body = request.body as { title?: string; description?: string } | undefined;
    const userId = request.currentUser!.id;
    const userName = request.currentUser!.displayName;

    if (!body || typeof body !== "object") {
      const err = errorBody("VALIDATION_ERROR", "请提供 title 和 description");
      return reply.status(statusFromCode("VALIDATION_ERROR")).send(err);
    }

    const result = recordService.createRecord(
      { title: body.title || "", description: body.description || "" },
      userId,
      userName
    );

    if (result.error) {
      return reply.status(statusFromCode(result.error.code)).send(errorBody(
        result.error.code,
        result.error.message,
        result.error.details
      ));
    }

    return reply.status(201).send(success(result.data!));
  });

  // PATCH /records/:id — 更新
  app.patch("/records/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = request.body as { status?: string; remark?: string } | undefined;
    const userId = request.currentUser!.id;

    const result = recordService.updateRecord(id, {
      status: body?.status as import("../types/index.js").RecordStatus | undefined,
      remark: body?.remark,
    }, userId);

    if (result.error) {
      return reply.status(statusFromCode(result.error.code)).send(errorBody(
        result.error.code,
        result.error.message
      ));
    }

    return reply.send(success(result.data!));
  });

  // POST /records/:id/action — 业务动作（状态流转 + 幂等占位）
  app.post("/records/:id/action", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = request.body as { action?: string; idempotencyKey?: string } | undefined;
    const userId = request.currentUser!.id;

    if (!body || !body.action) {
      const err = errorBody("VALIDATION_ERROR", "请指定 action");
      return reply.status(statusFromCode("VALIDATION_ERROR")).send(err);
    }

    const result = recordService.performAction(
      id,
      body.action,
      userId,
      body.idempotencyKey
    );

    if (result.error) {
      return reply.status(statusFromCode(result.error.code)).send(errorBody(
        result.error.code,
        result.error.message
      ));
    }

    return reply.send(success(result.data!));
  });
}
