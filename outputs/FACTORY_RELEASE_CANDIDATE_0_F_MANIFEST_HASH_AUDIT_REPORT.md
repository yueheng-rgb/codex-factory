# FACTORY-RELEASE-CANDIDATE-0 — Section F: Manifest and Hash Audit Report

**Phase:** FACTORY-RELEASE-CANDIDATE-0
**Section:** F
**Generated:** 2026-06-28T20:35:00+08:00
**Status:** COMPLETE

---

## 1. Package Identity

| Field | Value |
|---|---|
| Package Name | codex-factory-core-v0.9.0-pre-RC0.zip |
| Location | outputs/codex-factory-core-v0.9.0-pre-RC0.zip |
| SHA256 | A058FD67A02B13AAB010040905FA1D471050F9CB7A4A07EB3C5B9C5DB9240EF6 |
| SHA File | outputs/codex-factory-core-v0.9.0-pre-RC0.zip.sha256 |
| Total Entries | 2755 |
| Size | 3,278 KB (3.2 MB) |
| Artifact Type | RELEASE_CANDIDATE |

## 2. SHA256 Verification

| Check | Result |
|---|---|
| SHA file exists | YES |
| Computed SHA matches stored SHA | YES |
| SHA256 algorithm | SHA256 |

## 3. Key File Audit

| File | Status |
|---|---|
| AGENTS.md | FOUND |
| GLOBAL_CODEX_RULES.md | FOUND |
| APP_TYPE_ROUTER.md | FOUND |
| STACK_DECISION_GUIDE.md | FOUND |
| scripts/factoryctl.ps1 | FOUND |
| factory-release/RC_BOUNDARY.md | FOUND |
| factory-release/RC_CRITERIA.md | FOUND |
| factory-release/RC0_METADATA.json | FOUND |
| governance/factory-ab/verifier-factory-ab-1-result.json | FOUND |
| governance/factory-build/verifier-factory-build-pack-staging-p8-result.json | FOUND |
| governance/factory-release/verifier-factory-release-readiness-0-result.json | FOUND |
| factory-build-mode/memory-quality/ | FOUND |
| factory-resource-pack/ | FOUND |

## 4. Forbidden Content Audit

| Pattern | Status | Notes |
|---|---|---|
| Real projects (ecommerce, bigdata) | CLEAN | Excluded |
| Working copies (fresh-install) | CLEAN | Excluded |
| Old student packages | CLEAN | Excluded |
| Trial/harness/runs | CLEAN | Excluded |
| node_modules | CLEAN | Excluded |
| Release ZIPs inside RC | CLEAN | Excluded from outputs |
| Real .env secrets | CLEAN | Only .env.example templates in starters |
| Native Build Pro artifacts | CLEAN | Excluded |

## 5. Module Distribution

| Top-Level Directory | Type | Status |
|---|---|---|
| AGENTS.md + rules | CORE | Included |
| blueprints/ | CORE | Included |
| codex-factory-plugin/ | EXPERIMENTAL | Included (with caveats) |
| factory-ab/ | CORE | Included |
| factory-build-mode/ | CORE | Included (contains memory-quality) |
| factory-context-space/ | CORE | Included |
| factory-diagnostic-pack/ | CORE | Included |
| factory-release/ | CORE | Included |
| factory-resource-pack/ | CORE | Included |
| governance/ | CORE | Included |
| outputs/ | CORE (reports only) | Included (ZIPs excluded) |
| prompts/ | CORE | Included |
| runnable-starters/ | CORE | Included |
| schemas/ | CORE | Included |
| scripts/ | CORE | Included |
| skills/ | CORE | Included |
| src/ | CORE | Included |
| starters/ | CORE | Included |
| templates/ | CORE | Included |

## 6. Manifest File

Created: `outputs/RC0_MANIFEST.json` (full entry listing)

**Section F verdict: COMPLETE**
