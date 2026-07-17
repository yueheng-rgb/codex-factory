# RC-USER-REVIEW-0 — Section B: Package Inventory Report

**Phase:** RC-USER-REVIEW-0
**Section:** B
**Generated:** 2026-06-28T21:00:00+08:00
**Status:** COMPLETE

---

## 1. Package Overview

| Field | Value |
|---|---|
| Package | `codex-factory-core-v0.9.0-pre-RC0.zip` |
| Total Entries | 2,755 |
| Uncompressed Size | 13,693 KB (13.4 MB) |
| Compressed Size | 3,278 KB (3.2 MB) |
| Compression Ratio | 4.2:1 |

## 2. Module Breakdown (by size)

| Module | Files | Uncompressed | % of Total | Type |
|---|---|---|---|---|
| governance/ | 1,074 | 7,875 KB | 57.5% | CORE |
| outputs/ | 729 | 1,930 KB | 14.1% | CORE (reports) |
| scripts/ | 276 | 1,719 KB | 12.5% | CORE |
| factory-context-space/ | 173 | 877 KB | 6.4% | CORE |
| codex-factory-plugin/ | 75 | 307 KB | 2.2% | EXPERIMENTAL |
| factory-resource-pack/ | 61 | 303 KB | 2.2% | CORE |
| runnable-starters/ | 167 | 248 KB | 1.8% | CORE |
| factory-build-mode/ | 115 | 189 KB | 1.4% | CORE |
| factory-diagnostic-pack/ | 20 | 73 KB | 0.5% | CORE |
| (root files) | 7 | 59 KB | 0.4% | CORE |
| skills/ | 9 | 24 KB | 0.2% | CORE |
| prompts/ | 11 | 22 KB | 0.2% | CORE |
| Other (6 modules) | 38 | 68 KB | 0.5% | CORE |

## 3. Growth Analysis

### Why 3.2 MB / 2,755 entries?

1. **governance/ (57.5%)** — Largest contributor. Contains ~1,074 JSON/MD governance artifacts from all factory phases (AB trials, build staging, release readiness, contracts, diagnosis, etc.). Each phase creates 10-20 small JSON+Mardown files.

2. **outputs/ (14.1%)** — 729 report files (.md) from all phases. Excluded from ZIP: all `.zip` files.

3. **scripts/ (12.5%)** — 276 PowerShell/JS/Python scripts for verification, packaging, diagnostics.

4. **factory-context-space/ (6.4%)** — 173 context space policy and packet files.

5. **codex-factory-plugin/ (2.2%)** — Experimental plugin with skills, MCP, automation.

### Is this expected?

**YES.** The factory is documentation-heavy by design. Each phase produces governance artifacts (JSON) and human-readable reports (Markdown). The compressed size (3.2 MB) is modest — roughly a single high-res photo.

### Unusual directories?

- **governance/contracts/** — Contains dry-run and harness contract files (expected)
- **governance/context-space/** — Contains context packet definitions (expected)
- **runnable-starters/** — 167 files, compressed to 248 KB. Template starter projects (expected)

## 4. Root Junk Check

| Check | Result |
|---|---|
| Root files count | 7 (all known-good) |
| Root junk (.tsx, .py, flag files) | ABSENT |
| Release ZIPs at root | ABSENT |
| Random test artifacts | ABSENT |

✅ Root is clean — only AGENTS.md, GLOBAL_CODEX_RULES.md, APP_TYPE_ROUTER.md, STACK_DECISION_GUIDE.md, EXTERNAL_SKILLS_RESEARCH.md, README.md, RUN_CODEX_APP_FACTORY.md

## 5. Key Files Presence

| File | Module | Status |
|---|---|---|
| `AGENTS.md` | (root) | ✓ |
| `scripts/factoryctl.ps1` | scripts/ | ✓ |
| `factory-release/RC_BOUNDARY.md` | factory-release/ | ✓ |
| `factory-release/RC0_METADATA.json` | factory-release/ | ✓ |
| `factory-build-mode/memory-quality/` | factory-build-mode/ | ✓ |
| `governance/factory-ab/verifier-factory-ab-1-result.json` | governance/ | ✓ |
| `governance/factory-build/verifier-factory-build-pack-staging-p8-result.json` | governance/ | ✓ |

**Section B verdict: COMPLETE**
