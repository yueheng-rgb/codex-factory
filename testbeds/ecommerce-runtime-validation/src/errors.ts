import { ApiResponse } from "../types.js";

export function success<T>(data: T): ApiResponse<T> {
  return { ok: true, data };
}

export function error(code: string, message: string, statusCode: number) {
  return {
    body: { ok: false, error: { code, message } } as ApiResponse,
    statusCode
  };
}
