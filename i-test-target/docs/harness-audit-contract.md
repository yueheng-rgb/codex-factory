# Harness Audit Contract

## Audit Bundle Structure
```
outputs/phase6c-XX-final-audit-bundle.zip
outputs/phase6c-XX-final-audit-bundle.zip.meta.json
```

## ZIP Contents
- Final report (does NOT contain ZIP's own SHA256)
- SHA256SUMS.txt (relative paths, not basenames)
- All command stdout/stderr/exitCode files
- RUN_STATE.jsonl with complete hash chain
- TASKS.json with attempt history
- ACCEPTANCE.json with status fields
- CONTROL_PLANE_LOCK.json
- RELEASE_MANIFEST.json
- Validation evidence
- Integration evidence

## Sidecar Meta
```json
{
  "phase": "Phase 6C-XX",
  "bundlePath": "...",
  "sizeBytes": 0,
  "entryCount": 0,
  "sha256": "...",
  "createdAt": "..."
}
```

## Audit Rules
1. ZIP must contain all referenced evidence
2. SHA256SUMS must use relative paths (no basename-only)
3. Final report must not contain ZIP's own SHA256 (self-reference)
4. Sidecar meta must be external to ZIP
5. Stderr must be captured even if empty (0B file)
6. Reports must not claim untested capabilities
7. Phase status (PASS/PARTIAL/FAIL) must be honest
