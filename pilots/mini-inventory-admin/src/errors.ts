// Mini Inventory Admin — Unified Error Format
import type { ApiError, ApiResponse } from "./types.js";

export function success<T>(data: T): ApiResponse<T> {
  return { ok: true, data };
}

export function error(code: string, message: string, details?: Record<string, unknown>): ApiResponse<never> {
  return { ok: false, error: { code, message, details } };
}

export function statusFromCode(code: string): number {
  const map: Record<string, number> = {
    VALIDATION_ERROR: 400,
    NOT_FOUND: 404,
    CONFLICT: 409,
    BUSINESS_RULE_VIOLATION: 422,
    INTERNAL_ERROR: 500,
  };
  return map[code] ?? 400;
}
