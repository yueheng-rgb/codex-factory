/**
 * POST /auth/login — Mock 登录
 * 真实项目替换为 JWT + bcrypt + refresh token。
 */

import type { FastifyInstance } from "fastify";
import { success, errorBody, statusFromCode } from "../utils/api-response.js";
import { mockLogin } from "../repositories/user-repository.js";
import { validateFields } from "../utils/validation.js";

export async function authRoutes(app: FastifyInstance): Promise<void> {
  app.post("/auth/login", async (request, reply) => {
    const body = request.body as { username?: string; password?: string } | undefined;

    if (!body || typeof body !== "object") {
      const err = errorBody("VALIDATION_ERROR", "请提供用户名和密码");
      return reply.status(statusFromCode("VALIDATION_ERROR")).send(err);
    }

    // 服务端校验
    const validation = validateFields([
      { field: "username", value: body.username, rules: [{ required: true, message: "请输入用户名" }] },
      { field: "password", value: body.password, rules: [{ required: true, message: "请输入密码" }] },
    ]);

    if (!validation.valid) {
      const err = errorBody("VALIDATION_ERROR", "输入校验失败", validation.errors);
      return reply.status(statusFromCode("VALIDATION_ERROR")).send(err);
    }

    const result = mockLogin(body.username!, body.password!);

    if (!result) {
      const err = errorBody("UNAUTHORIZED", "用户名或密码错误");
      return reply.status(statusFromCode("UNAUTHORIZED")).send(err);
    }

    return reply.send(success(result));
  });
}
