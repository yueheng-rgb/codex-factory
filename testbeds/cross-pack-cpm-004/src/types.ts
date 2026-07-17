// ============================================================================
// CPM-004 Cross-Pack Invariant Types
// Packs: cpp-memory-safety, admin-system/miniapp
// ============================================================================

/** File upload request payload. */
export interface UploadRequest {
  /** File name including extension */
  filename: string;
  /** MIME type asserted by the client */
  mimeType: string;
  /** Raw file size in bytes */
  sizeBytes: number;
  /** Base64-encoded file content */
  payload: string;
  /** Authenticated session token */
  token: string;
}

/** Result returned by the native parser after processing an upload. */
export interface ParseResult {
  /** Whether parsing succeeded */
  ok: boolean;
  /** Number of records / lines parsed */
  recordCount: number;
  /** Any diagnostic warnings (e.g. truncated rows) */
  warnings: string[];
  /** Fatal error message when ok === false */
  error?: string;
  /** Parser runtime in milliseconds */
  elapsedMs: number;
  /** Hash of parsed content for integrity verification */
  contentHash: string;
}

/** Admin session validated by the server-side auth middleware. */
export interface AdminSession {
  /** Unique session identifier */
  sessionId: string;
  /** User ID bound to the session */
  userId: string;
  /** Role — only "admin" permits admin-route access */
  role: "admin" | "editor" | "viewer";
  /** Session expiry as ISO-8601 */
  expiresAt: string;
  /** Upload size cap in bytes for this session */
  uploadLimitBytes: number;
}

// ---------------------------------------------------------------------------
// Internal helper types for the test harness
// ---------------------------------------------------------------------------

/** Categories of permitted upload types under admin-system invariants. */
export const ALLOWED_MIME_TYPES = [
  "text/csv",
  "application/json",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
] as const;

/** Maximum upload size (5 MiB) enforced by admin-system. */
export const UPLOAD_SIZE_LIMIT = 5 * 1024 * 1024;

/** Disallowed file extension category for negative tests. */
export const DISALLOWED_EXTENSIONS = [
  ".exe",
  ".bat",
  ".sh",
  ".dll",
  ".so",
] as const;
