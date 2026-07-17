// Admin System Runtime Validation — Unified Error Helpers

export function errorResponse(code: string, message: string, statusCode: number = 400) {
  return { error: code, message, statusCode };
}

export function okResponse<T>(data: T) {
  return { success: true, data };
}
