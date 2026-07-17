# RC-USER-REVIEW-0 — Section A: Scope Lock Report

**Phase:** RC-USER-REVIEW-0
**Section:** A
**Generated:** 2026-06-28T21:00:00+08:00
**Status:** COMPLETE

---

## 1. RC0 Status at Review Entry

| Field | Value |
|---|---|
| Package | `outputs/codex-factory-core-v0.9.0-pre-RC0.zip` |
| SHA256 | `A058FD67A02B13AAB010040905FA1D471050F9CB7A4A07EB3C5B9C5DB9240EF6` (verified) |
| Size | 3,278 KB (3.2 MB), 2,755 entries |
| artifactType | RELEASE_CANDIDATE |
| RC-0 verifier | 45/45 PASS |
| v0.5 | BLOCKED |

## 2. Scope: What This Phase IS

- **User inspection** of RC0 package contents, structure, and metadata
- **Acceptance decision** — whether RC0 is suitable for next phase
- **Blocker awareness** — confirm user understands what remains
- **Option selection** — user chooses next step

## 3. Scope: What This Phase IS NOT

- ❌ NOT a release — RC0 remains a candidate
- ❌ NOT v0.5 — v0.5 is still BLOCKED
- ❌ NOT package modification — no changes to RC0 ZIP
- ❌ NOT production deployment
- ❌ NOT blocker resolution — all 4 blockers preserved

## 4. Forbidden Actions During Review

| Action | Status |
|---|---|
| Modify RC0 package | FORBIDDEN |
| Set releaseAllowed=true | FORBIDDEN |
| Set v05Package=true | FORBIDDEN |
| Set finalRelease=true | FORBIDDEN |
| Claim production readiness | FORBIDDEN |
| Claim Factory superiority | FORBIDDEN |
| Deploy to server | FORBIDDEN |
| Access production database | FORBIDDEN |
| Print real secrets | FORBIDDEN |

## 5. Review Prerequisites Confirmed

- [x] RC-0 verifier PASS (45/45)
- [x] RC package intact (SHA match)
- [x] All flags preserved (releaseAllowed=false, etc.)
- [x] All 4 blockers still active
- [x] v0.5 still BLOCKED

**Section A verdict: SCOPE_LOCKED**
