# R2.3-U Design: Secure File Upload Endpoint for factory-skill-live-trial

**Phase:** R2.3-U Step 3  
**Based on:** Evidence Pack FACTORY_R2_3_U_EVIDENCE_PACK.json (13 sources)  
**Key source:** fastify/fastify-multipart (official GitHub plugin)

---

## Adopted Approach

Use `@fastify/multipart` — the official Fastify multipart plugin. It provides streaming-based file upload with built-in size limits, file type access, and async iteration.

**Stack:**
- **Framework:** Fastify 4.x (already in project)
- **Plugin:** `@fastify/multipart` (official, maintained by Fastify team)
- **Validation:** Magic-byte detection via `file-type` package + extension whitelist
- **Storage:** Local filesystem, outside web root, with sanitized filenames
- **Security:** Helmet headers, rate limiting, CORS configured

## Rejected Alternatives

| Alternative | Reason Rejected |
|---|---|
| `busboy` directly | Lower-level; @fastify/multipart wraps it with Fastify integration |
| `multer` | Express-specific, not Fastify-native |
| Cloud storage (S3, etc.) | Local-first project; cloud deferred per factory policy |
| Base64 in JSON body | Inefficient for files > 1MB; not REST-idiomatic |

## Source-Backed Reasons

1. **Source:** `github.com/fastify/fastify-multipart` → Official Fastify plugin, actively maintained, Fastify team recommendation
2. **Source:** `fastify.dev/docs` (implied by plugin ecosystem) → Fastify plugins follow Fastify encapsulation pattern; `@fastify/multipart` registers a decorator
3. **Factory constraint:** local-first → no cloud upload; files stored locally

## Design Spec

### Endpoint

```
POST /api/upload
Content-Type: multipart/form-data

Fields: file (required, single file)
Response: 201 { ok: true, filename, size, type, url }
```

### Security Controls

| Control | Implementation |
|---|---|
| File size limit | 5MB per file (configurable) |
| Type validation | Whitelist: image/png, image/jpeg, image/webp, application/pdf, text/plain |
| Magic byte check | `file-type` package verifies actual type, not just extension |
| Filename sanitization | UUID prefix + sanitized original name |
| Storage location | `./uploads/` (gitignored, outside src/) |
| Rate limiting | 10 uploads/min per IP |
| Error handling | 400 on invalid type, 413 on too large, 500 on disk error |

### Implementation Plan

1. Install `@fastify/multipart` and `file-type`
2. Register plugin with limits: `{ limits: { fileSize: 5 * 1024 * 1024 } }`
3. Add `POST /api/upload` route
4. Stream file to disk with UUID filename
5. Validate type via magic bytes
6. Return file metadata
7. Add test: valid upload, invalid type, too large, no file

### Risks

| Risk | Mitigation |
|---|---|
| Disk exhaustion | Size limit + monitoring |
| Path traversal in filename | Sanitize + UUID prefix |
| Zip bomb | Size limit handles this |
| Concurrent writes | UUID filename prevents collision |

### Rollback / Simplification

If `@fastify/multipart` has issues, fall back to raw `busboy` with manual Fastify integration.

---

**Evidence Pack used:** outputs/FACTORY_R2_3_U_EVIDENCE_PACK.json  
**Designer agent:** ARCH-001 (simulated)  
**Implementer agent:** IMPL-BE-001 (read-only access to EP)
