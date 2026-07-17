/**
 * ??????Mock ???
 * ??????? JWT verify ? session check?
 *
 * ?? token ??????????????? token ? userId ???
 * ?? ????????? token ???????
 * ?? role ??????? MOCK_USERS ???
 */

import type { FastifyRequest, FastifyReply } from "fastify";
import { errorBody, statusFromCode } from "../utils/api-response.js";

declare module "fastify" {
  interface FastifyRequest {
    currentUser?: {
      id: string;
      username: string;
      role: "admin" | "user";
      displayName: string;
    };
  }
}

// ===== ??? token ? userId ?? =====

const TOKEN_MAP: Record<string, string> = {
  "mock-token-user": "u-002",
  "mock-token-admin": "u-001",
};

export async function authMiddleware(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  const authHeader = request.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    const body = errorBody("UNAUTHORIZED", "????");
    return reply.status(statusFromCode("UNAUTHORIZED")).send(body);
  }

  const token = authHeader.slice(7);

  // ??? token ?? ? ??? token ????
  const userId = TOKEN_MAP[token];
  if (!userId) {
    const body = errorBody("UNAUTHORIZED", "Token ??????");
    return reply.status(statusFromCode("UNAUTHORIZED")).send(body);
  }

  // ? mock ???????role ??????
  const { MOCK_USERS } = await import("../db/mock-db.js");
  const user = MOCK_USERS.find((u) => u.id === userId);

  if (!user) {
    const body = errorBody("UNAUTHORIZED", "?????");
    return reply.status(statusFromCode("UNAUTHORIZED")).send(body);
  }

  request.currentUser = {
    id: user.id,
    username: user.username,
    role: user.role,
    displayName: user.displayName,
  };
}

export async function adminMiddleware(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  if (!request.currentUser || request.currentUser.role !== "admin") {
    const body = errorBody("FORBIDDEN", "???????");
    return reply.status(statusFromCode("FORBIDDEN")).send(body);
  }
}
