# FACTORY-RELEASE-CANDIDATE-0 — Section E: RC Package Creation and SHA256 Report

**Phase:** FACTORY-RELEASE-CANDIDATE-0
**Section:** E
**Generated:** 2026-06-28T20:31:00+08:00
**Status:** COMPLETE

---

## 1. Package Identity

| Field | Value |
|---|---|
| Package Name | codex-factory-core-v0.9.0-pre-RC0.zip |
| Location | outputs/codex-factory-core-v0.9.0-pre-RC0.zip |
| SHA256 | 5726F2E782D9A9EF11CD80A5933B417A3BC64E442B54F86157DBB3BFB39CC3DC |
| SHA File | outputs/codex-factory-core-v0.9.0-pre-RC0.zip.sha256 |
| File Count | 2848 |
| Size | 5,168 KB (5.05 MB) |
| Artifact Type | RELEASE_CANDIDATE |

## 2. Build Configuration

| Setting | Value |
|---|---|
| Build Mode | Build Lite |
| Source | Current project state (P8 staging) |
| Excluded Dirs | 36 excluded directories |
| Build Script | scripts/factory-release-candidate-0-package.ps1 |

## 3. Exclusions Applied

Real projects (6): ecommerce_homework, ecommerce_runb, bigdata_homework, habit-tracker-*, tiny-typescript-service

Working copies (6): fresh-install-target*, i-test-target, harness-control

Trial/Harness (6): runs, trials, harness, blind-test-results, benchmark-results, benchmark

Old packages (8): final-package*, packages, factory-resource-pack-v0.4-*, factory-resource-pack-v0.9.0-pre-staging

Infrastructure (4): node_modules, .codex-factory, external-conversation-space, workspace

Misc (6): targets, release-candidate, factory-diagnostic-pack-v1.1.0-audit-bundle-staging, factory-agent-company-protocol-pack

## 4. Verification

- [x] Package file exists
- [x] SHA256 file exists
- [x] SHA256 matches package
- [x] No forbidden content in exclusion review
- [x] File count reasonable (2848)

**Section E verdict: COMPLETE**
