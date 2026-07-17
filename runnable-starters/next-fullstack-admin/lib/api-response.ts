/**
 * 统一 API 响应格式
 * 所有 API route handler 必须使用此模块构建响应。
 */

export interface ApiSuccess<T = unknown> {
  ok: true;
  data: T;
  meta?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface ApiError {
  ok: false;
  error: {
    code: string;
    message: string;
    details?: Array<{ field: string; message: string }>;
  };
}

export type ApiResponse<T = unknown> = ApiSuccess<T> | ApiError;

export function success<T>(data: T, meta?: ApiSuccess["meta"]): ApiSuccess<T> {
  const resp: ApiSuccess<T> = { ok: true, data };
  if (meta) resp.meta = meta;
  return resp;
}

export function error(
  code: string,
  message: string,
  details?: ApiError["error"]["details"],
  status?: number
): { body: ApiError; status: number } {
  return {
    body: { ok: false, error: { code, message, ...(details ? { details } : {}) } },
    status: status ?? statusFromCode(code),
  };
}

function statusFromCode(code: string): number {
  switch (code) {
    case "VALIDATION_ERROR": return 400;
    case "UNAUTHORIZED": return 401;
    case "FORBIDDEN": return 403;
    case "NOT_FOUND": return 404;
    case "CONFLICT": return 409;
    default: return 500;
  }
}

/** 从 ApiError response 提取 NextResponse 所需的 status */
export function errorResponse(
  code: string,
  message: string,
  details?: ApiError["error"]["details"]
): Response {
  const { body, status } = error(code, message, details);
  return Response.json(body, { status });
}
