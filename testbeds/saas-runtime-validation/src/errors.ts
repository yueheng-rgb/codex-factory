export function ok<T>(data: T) { return { ok: true, data }; }
export function err(code: string, message: string, statusCode: number) {
  return { body: { ok: false, error: { code, message } }, statusCode };
}
