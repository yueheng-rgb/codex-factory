// ============================================================================
// CPM-004 Cross-Pack Invariant Test Harness
// Packs: cpp-memory-safety (7 CRITICAL) + admin-system/miniapp (13 invariants)
// Date: 2026-07-12 | Worker A 閳?Test Harness
// ============================================================================

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import fastify, { FastifyInstance } from "fastify";

import {
  ALLOWED_MIME_TYPES,
  DISALLOWED_EXTENSIONS,
  UPLOAD_SIZE_LIMIT,
} from "../src/types";

// ============================================================================
// Fastify mock server 閳?port 3400
// ============================================================================

let app: FastifyInstance;

/** Pre-seeded admin token for test sessions. */
const ADMIN_TOKEN = "cpm004-admin-token-2026";
/** Non-admin (viewer) token. */
const VIEWER_TOKEN = "cpm004-viewer-token-2026";

beforeAll(async () => {
  app = fastify({ logger: false });

  // ---- Health check ----
  app.get("/health", async () => ({ status: "ok", mission: "CPM-004" }));

  // ---- Admin dashboard (admin-only route) ----
  app.get("/admin/dashboard", async (req, reply) => {
    const auth = req.headers["authorization"] as string | undefined;
    if (!auth || auth !== `Bearer ${ADMIN_TOKEN}`) {
      reply.status(403);
      return { error: "FORBIDDEN", detail: "Admin role required" };
    }
    return { dashboard: "CPM-004 admin panel", uptime: process.uptime() };
  });

  // ---- File upload endpoint ----
  app.post("/admin/upload", async (req, reply) => {
    const auth = req.headers["authorization"] as string | undefined;
    if (!auth || auth !== `Bearer ${ADMIN_TOKEN}`) {
      reply.status(403);
      return { error: "FORBIDDEN", detail: "Admin role required for upload" };
    }

    const contentType = req.headers["content-type"] as string | undefined;
    if (!contentType || !contentType.startsWith("application/json")) {
      reply.status(400);
      return { error: "BAD_REQUEST", detail: "Expected application/json" };
    }

    // Simulate parsing form fields from a JSON body for test simplicity
    const body = req.body as {
      filename?: string;
      mimeType?: string;
      sizeBytes?: number;
    };

    if (!body || !body.filename || !body.mimeType) {
      reply.status(400);
      return {
        error: "BAD_REQUEST",
        detail: "filename and mimeType are required",
      };
    }

    // --- invariant: upload_file_type_must_be_validated ---
    const allowed = ALLOWED_MIME_TYPES as readonly string[];
    if (!allowed.includes(body.mimeType)) {
      reply.status(415);
      return {
        error: "UNSUPPORTED_MEDIA_TYPE",
        detail: `File type '${body.mimeType}' is not allowed. Permitted: ${allowed.join(", ")}`,
      };
    }

    // Also reject by disallowed extension
    const ext = body.filename.slice(body.filename.lastIndexOf(".")).toLowerCase();
    const disallowed = DISALLOWED_EXTENSIONS as readonly string[];
    if (disallowed.includes(ext)) {
      reply.status(415);
      return {
        error: "UNSUPPORTED_MEDIA_TYPE",
        detail: `File extension '${ext}' is not allowed`,
      };
    }

    // --- invariant: upload_size_limit_enforced ---
    const size = body.sizeBytes ?? 0;
    if (size > UPLOAD_SIZE_LIMIT) {
      reply.status(413);
      return {
        error: "PAYLOAD_TOO_LARGE",
        detail: `Upload size ${size} exceeds limit of ${UPLOAD_SIZE_LIMIT} bytes`,
      };
    }

    return {
      ok: true,
      recordCount: 42,
      warnings: [] as string[],
      elapsedMs: 12,
      contentHash: "sha256:cpm004-mock-hash",
    };
  });

  // ---- Destructive action endpoint ----
  app.delete("/admin/resource/:id", async (req, reply) => {
    const auth = req.headers["authorization"] as string | undefined;
    if (!auth || auth !== `Bearer ${ADMIN_TOKEN}`) {
      reply.status(403);
      return { error: "FORBIDDEN", detail: "Admin role required" };
    }

    const { id } = req.params as { id: string };
    const body = req.body as { confirm?: boolean } | undefined;

    // --- invariant: destructive_action_requires_confirmation ---
    if (!body || body.confirm !== true) {
      reply.status(400);
      return {
        error: "CONFIRMATION_REQUIRED",
        detail: `Destructive action on resource '${id}' requires explicit confirmation`,
      };
    }

    return { ok: true, deleted: id };
  });

  await app.listen({ port: 3400 });
});

afterAll(async () => {
  if (app) await app.close();
});

// ============================================================================
// Helper: fetch wrapper
// ============================================================================

const BASE = "http://127.0.0.1:3400";

async function api(
  method: string,
  path: string,
  opts?: { token?: string; body?: unknown; contentType?: string }
): Promise<{ status: number; data: unknown }> {
  const headers: Record<string, string> = {};
  if (opts?.token) headers["authorization"] = `Bearer ${opts.token}`;
  if (opts?.contentType) headers["content-type"] = opts.contentType;
  else if (opts?.body !== undefined)
    headers["content-type"] = "application/json";

  const init: RequestInit = { method, headers };
  if (opts?.body !== undefined) init.body = JSON.stringify(opts.body);

  const res = await fetch(`${BASE}${path}`, init);
  const data = await res.json();
  return { status: res.status, data };
}

// ============================================================================
// Group A: cpp-memory-safety 閳?Concept-level invariant guards
// ============================================================================

/** Simulated bounded buffer mirroring the C++ invariant. */
class BoundedBuffer {
  private buf: Uint8Array;
  constructor(size: number) {
    this.buf = new Uint8Array(size);
  }
  read(offset: number, length: number): Uint8Array | null {
    // invariant: buffer_bounds_must_be_checked
    if (offset < 0 || offset + length > this.buf.length) return null;
    return this.buf.slice(offset, offset + length);
  }
  write(offset: number, data: Uint8Array): boolean {
    if (offset < 0 || offset + data.length > this.buf.length) return false;
    this.buf.set(data, offset);
    return true;
  }
}

/** Simulated file parser that must respect a bounded input size. */
class BoundedFileParser {
  /** Maximum bytes the parser will ever consume from input. */
  static readonly MAX_INPUT = 1024 * 1024; // 1 MiB
  parse(raw: Uint8Array, limit: number = BoundedFileParser.MAX_INPUT): { records: number; truncated: boolean } {
    // invariant: file_parser_must_be_bounded
    const slice = raw.length > limit ? raw.slice(0, limit) : raw;
    const records = Math.min(slice.length, 1000); // arbitrary tokenizer
    return { records, truncated: raw.length > limit };
  }
}

/** Simulated native function that must guard against null dereference. */
function safeNativeParse(ptr: Uint8Array | null): { ok: boolean; len: number } {
  // invariant: null_pointer_dereference_must_be_prevented
  if (ptr === null) return { ok: false, len: 0 };
  return { ok: true, len: ptr.length };
}

/** Check that a sanitizer toolchain requirement document / config exists. */
interface SanitizerConfig {
  enabled: boolean;
  tools: string[]; // e.g. ["AddressSanitizer", "UndefinedBehaviorSanitizer"]
  ciGate: boolean; // CI must fail on sanitizer violation
}
function validateSanitizerConfig(cfg: SanitizerConfig): boolean {
  // invariant: sanitizer_toolchain_integration_required
  return cfg.enabled && cfg.tools.length > 0 && cfg.ciGate;
}

// ============================================================================
// TESTS
// ============================================================================

describe("CPM-004 Cross-Pack Invariant Tests", () => {
  // --------------------------------------------------------------------------
  // 1. Health check
  // --------------------------------------------------------------------------
  it("health check 閳?server is running on port 3400", async () => {
    const { status, data } = await api("GET", "/health");
    expect(status).toBe(200);
    expect((data as Record<string, unknown>).status).toBe("ok");
    expect((data as Record<string, unknown>).mission).toBe("CPM-004");
  });

  // --------------------------------------------------------------------------
  // 2. admin_required_for_admin_routes
  // --------------------------------------------------------------------------
  it("admin_required_for_admin_routes 閳?rejects unauthenticated requests", async () => {
    const { status, data } = await api("GET", "/admin/dashboard");
    expect(status).toBe(403);
    expect((data as Record<string, unknown>).error).toBe("FORBIDDEN");
  });

  it("admin_required_for_admin_routes 閳?rejects non-admin (viewer) tokens", async () => {
    const { status, data } = await api("GET", "/admin/dashboard", {
      token: VIEWER_TOKEN,
    });
    expect(status).toBe(403);
    expect((data as Record<string, unknown>).error).toBe("FORBIDDEN");
  });

  it("admin_required_for_admin_routes 閳?permits admin tokens", async () => {
    const { status, data } = await api("GET", "/admin/dashboard", {
      token: ADMIN_TOKEN,
    });
    expect(status).toBe(200);
    expect((data as Record<string, unknown>).dashboard).toContain("CPM-004");
  });

  // --------------------------------------------------------------------------
  // 3. upload_file_type_must_be_validated
  // --------------------------------------------------------------------------
  it("upload_file_type_must_be_validated 閳?accepts allowed MIME types (csv)", async () => {
    const { status, data } = await api("POST", "/admin/upload", {
      token: ADMIN_TOKEN,
      contentType: "application/json",
      body: { filename: "data.csv", mimeType: "text/csv", sizeBytes: 1024 },
    });
    expect(status).toBe(200);
    expect((data as Record<string, unknown>).ok).toBe(true);
  });

  it("upload_file_type_must_be_validated 閳?accepts allowed MIME types (json)", async () => {
    const { status, data } = await api("POST", "/admin/upload", {
      token: ADMIN_TOKEN,
      contentType: "application/json",
      body: { filename: "data.json", mimeType: "application/json", sizeBytes: 512 },
    });
    expect(status).toBe(200);
    expect((data as Record<string, unknown>).ok).toBe(true);
  });

  // --------------------------------------------------------------------------
  // 4. upload_size_limit_enforced
  // --------------------------------------------------------------------------
  it("upload_size_limit_enforced 閳?rejects payload exceeding 5 MiB", async () => {
    const { status, data } = await api("POST", "/admin/upload", {
      token: ADMIN_TOKEN,
      contentType: "application/json",
      body: {
        filename: "big.csv",
        mimeType: "text/csv",
        sizeBytes: UPLOAD_SIZE_LIMIT + 1,
      },
    });
    expect(status).toBe(413);
    expect((data as Record<string, unknown>).error).toBe("PAYLOAD_TOO_LARGE");
  });

  it("upload_size_limit_enforced 閳?permits upload at exactly limit boundary", async () => {
    const { status, data } = await api("POST", "/admin/upload", {
      token: ADMIN_TOKEN,
      contentType: "application/json",
      body: {
        filename: "exact.csv",
        mimeType: "text/csv",
        sizeBytes: UPLOAD_SIZE_LIMIT,
      },
    });
    expect(status).toBe(200);
    expect((data as Record<string, unknown>).ok).toBe(true);
  });

  // --------------------------------------------------------------------------
  // 5. destructive_action_requires_confirmation
  // --------------------------------------------------------------------------
  it("destructive_action_requires_confirmation 閳?rejects DELETE without confirm flag", async () => {
    const { status, data } = await api("DELETE", "/admin/resource/r-001", {
      token: ADMIN_TOKEN,
      body: {},
    });
    expect(status).toBe(400);
    expect((data as Record<string, unknown>).error).toBe("CONFIRMATION_REQUIRED");
  });

  it("destructive_action_requires_confirmation 閳?permits DELETE with explicit confirm", async () => {
    const { status, data } = await api("DELETE", "/admin/resource/r-001", {
      token: ADMIN_TOKEN,
      body: { confirm: true },
    });
    expect(status).toBe(200);
    expect((data as Record<string, unknown>).ok).toBe(true);
    expect((data as Record<string, unknown>).deleted).toBe("r-001");
  });

  // --------------------------------------------------------------------------
  // 6. Negative controls
  // --------------------------------------------------------------------------
  it("NEGATIVE: oversized upload returns 413 (not 500 or 200)", async () => {
    const { status } = await api("POST", "/admin/upload", {
      token: ADMIN_TOKEN,
      contentType: "application/json",
      body: {
        filename: "huge.csv",
        mimeType: "text/csv",
        sizeBytes: 100 * 1024 * 1024, // 100 MiB
      },
    });
    expect(status).toBe(413);
  });

  it("NEGATIVE: disallowed file type (.exe) returns 415", async () => {
    const { status, data } = await api("POST", "/admin/upload", {
      token: ADMIN_TOKEN,
      contentType: "application/json",
      body: {
        filename: "malware.exe",
        mimeType: "application/x-msdownload",
        sizeBytes: 4096,
      },
    });
    expect(status).toBe(415);
    expect((data as Record<string, unknown>).error).toBe("UNSUPPORTED_MEDIA_TYPE");
  });

  it("NEGATIVE: non-admin viewer cannot upload files", async () => {
    const { status, data } = await api("POST", "/admin/upload", {
      token: VIEWER_TOKEN,
      contentType: "application/json",
      body: {
        filename: "data.csv",
        mimeType: "text/csv",
        sizeBytes: 1024,
      },
    });
    expect(status).toBe(403);
    expect((data as Record<string, unknown>).error).toBe("FORBIDDEN");
  });

  // --------------------------------------------------------------------------
  // 7. cpp-memory-safety: buffer_bounds_must_be_checked (concept-level)
  // --------------------------------------------------------------------------
  it("buffer_bounds_must_be_checked 閳?read within bounds succeeds", () => {
    const buf = new BoundedBuffer(64);
    const data = new Uint8Array([1, 2, 3]);
    expect(buf.write(0, data)).toBe(true);
    expect(buf.read(0, 3)).toEqual(data);
  });

  it("buffer_bounds_must_be_checked 閳?read beyond bounds returns null", () => {
    const buf = new BoundedBuffer(64);
    expect(buf.read(60, 10)).toBeNull(); // 60 + 10 > 64
    expect(buf.read(-1, 1)).toBeNull();  // negative offset
    expect(buf.read(0, 65)).toBeNull();  // length exceeds size
  });

  it("buffer_bounds_must_be_checked 閳?write beyond bounds returns false", () => {
    const buf = new BoundedBuffer(64);
    const big = new Uint8Array(128);
    expect(buf.write(0, big)).toBe(false);
    expect(buf.write(63, new Uint8Array([1, 2]))).toBe(false);
  });

  // --------------------------------------------------------------------------
  // 8. cpp-memory-safety: file_parser_must_be_bounded (concept-level)
  // --------------------------------------------------------------------------
  it("file_parser_must_be_bounded 閳?small input fits within limit", () => {
    const parser = new BoundedFileParser();
    const small = new Uint8Array(500);
    const result = parser.parse(small);
    expect(result.truncated).toBe(false);
    expect(result.records).toBe(500);
  });

  it("file_parser_must_be_bounded 閳?oversized input is truncated", () => {
    const parser = new BoundedFileParser();
    const huge = new Uint8Array(BoundedFileParser.MAX_INPUT + 1024);
    const result = parser.parse(huge);
    expect(result.truncated).toBe(true);
    expect(result.records).toBeLessThanOrEqual(1000);
  });

  // --------------------------------------------------------------------------
  // 9. cpp-memory-safety: null_pointer_dereference_must_be_prevented (concept-level)
  // --------------------------------------------------------------------------
  it("null_pointer_dereference_must_be_prevented 閳?returns error on null input", () => {
    const result = safeNativeParse(null);
    expect(result.ok).toBe(false);
    expect(result.len).toBe(0);
  });

  it("null_pointer_dereference_must_be_prevented 閳?succeeds on valid pointer", () => {
    const data = new Uint8Array([0xca, 0xfe, 0xba, 0xbe]);
    const result = safeNativeParse(data);
    expect(result.ok).toBe(true);
    expect(result.len).toBe(4);
  });

  // --------------------------------------------------------------------------
  // 10. cpp-memory-safety: sanitizer_toolchain_integration_required (concept-level)
  // --------------------------------------------------------------------------
  it("sanitizer_toolchain_integration_required 閳?valid config passes gate", () => {
    const cfg: SanitizerConfig = {
      enabled: true,
      tools: ["AddressSanitizer", "UndefinedBehaviorSanitizer"],
      ciGate: true,
    };
    expect(validateSanitizerConfig(cfg)).toBe(true);
  });

  it("sanitizer_toolchain_integration_required 閳?disabled config fails gate", () => {
    expect(validateSanitizerConfig({ enabled: false, tools: ["AddressSanitizer"], ciGate: true })).toBe(false);
    expect(validateSanitizerConfig({ enabled: true, tools: [], ciGate: true })).toBe(false);
    expect(validateSanitizerConfig({ enabled: true, tools: ["AddressSanitizer"], ciGate: false })).toBe(false);
  });
});

