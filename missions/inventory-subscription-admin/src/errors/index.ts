// Unified error helpers
export function err(code: string, msg: string, status = 400) { return { error: code, message: msg, statusCode: status }; }
export function ok<T>(data: T) { return { success: true, data }; }
