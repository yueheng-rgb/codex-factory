# FACTORY-V04-PREP: v0.4 Draft Resource Pack Report

**Status:** COMPLETED — 32/32 Verifier PASS  
**Draft Location:** actory-resource-pack-v0.4-draft/  
**Generated:** 2026-06-25T20:22:00+08:00

---

## Draft Contents

| Layer | Files | Status |
|---|---|---|
| **core/** | 11 | Factory Lite Core (default) |
| **review/** | 2 | Reviewer checklist (optional) |
| **optional-3role/** | 4 | 3-role model (optional) |
| **context-recovery-deferred/** | 2 | Deferred modules |
| **archive/** | 2 | Archived 10-role model |
| **benchmarks/** | 1 | Benchmark evidence |
| **scripts/** | 3 | Validation + smoke test |
| **schemas/** | 1 | Schema index |
| **docs/** | 1 | Documentation index |
| **Top-level** | 6 | README, INSTALL, USAGE, etc. |

## Validation

- **Structure validation:** 0 errors
- **Smoke test:** 5/5 checks passed
- **Manifest:** SHA256 per file, 31 files indexed

## Key Design Decisions

1. **Default = Factory Lite Core** — no roles, Manual Router + POR, ~200ms overhead
2. **Optional 3-role** — Architect/Builder/Reviewer for projects with auth/RBAC
3. **10-role archived** — preserved for reference, not active
4. **Page Router limits to 5 pages** — prevents context bloat
5. **Evidence hierarchy enforced** — process artifacts ≠ product quality

## Recommended Next

User review, then one of:
- **FACTORY-EVAL-10** — Second benchmark using v0.4 draft
- **FACTORY-V04-P1** — Draft repair if issues found
- **FACTORY-V04-RELEASE-PREP** — only with explicit user confirmation
