/**
 * Unified API response helpers
 */

export interface ApiSuccess<T = unknown> {
  ok: true;
  data: T;
  meta?: { page: number; pageSize: number; total: number; totalPages: number };
}

export interface ApiError {
  ok: false;
  error: { code: string; message: string; details?: Array<{ field: string; message: string }> };
}

export type ApiResponse<T = unknown> = ApiSuccess<T> | ApiError;

export function success<T>(data: T, meta?: ApiSuccess["meta"]): ApiSuccess<T> {
  return meta ? { ok: true, data, meta } : { ok: true, data };
}

export function errorBody(code: string, message: string, details?: ApiError["error"]["details"]): ApiError {
  return { ok: false, error: { code, message, ...(details ? { details } : {}) } };
}

export function statusFromCode(code: string): number {
  switch (code) {
    case "VALIDATION_ERROR": return 400;
    case "UNAUTHORIZED": return 401;
    case "FORBIDDEN": return 403;
    case "NOT_FOUND": return 404;
    case "CONFLICT": return 409;
    default: return 500;
  }
}