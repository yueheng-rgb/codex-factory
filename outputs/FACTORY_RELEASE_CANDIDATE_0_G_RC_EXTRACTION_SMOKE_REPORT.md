# FACTORY-RELEASE-CANDIDATE-0 — Section G: RC Extraction Smoke Report

**Phase:** FACTORY-RELEASE-CANDIDATE-0
**Section:** G
**Generated:** 2026-06-28T20:36:00+08:00
**Status:** COMPLETE

---

## 1. Extraction Result

| Check | Result |
|---|---|
| Extraction from ZIP | SUCCESS |
| Target directory | %TEMP%/rc0-extraction-smoke |
| Extraction errors | None |

## 2. Structure Verification

| Expected Path | Type | Status |
|---|---|---|
| AGENTS.md | File | OK |
| scripts/factoryctl.ps1 | File | OK |
| factory-release/RC_BOUNDARY.md | File | OK |
| factory-release/RC0_METADATA.json | File | OK |
| governance/ | Directory | OK |
| factory-resource-pack/ | Directory | OK |
| factory-build-mode/ | Directory | OK |
| blueprints/ | Directory | OK |
| starters/ | Directory | OK |
| skills/ | Directory | OK |
| prompts/ | Directory | OK |
| schemas/ | Directory | OK |
| templates/ | Directory | OK |
| runnable-starters/ | Directory | OK |
| outputs/ | Directory | OK |

## 3. RC Metadata Flag Verification

| Flag | Expected | Actual | OK |
|---|---|---|---|
| artifactType | RELEASE_CANDIDATE | RELEASE_CANDIDATE | ✓ |
| isRelease | false | False | ✓ |
| isV05 | false | False | ✓ |
| rcCandidate | true | True | ✓ |
| releaseAllowed | false | False | ✓ |
| v05Package | false | False | ✓ |
| finalRelease | false | False | ✓ |

## 4. Extraction Counts

| Metric | Value |
|---|---|
| Files extracted | 2735 |
| Directories | 227 |

## 5. Forbidden Content Check

| Pattern | Status |
|---|---|
| ecommerce_homework | CLEAN |
| bigdata_homework | CLEAN |
| habit-tracker-* | CLEAN |
| fresh-install-target* | CLEAN |
| node_modules | CLEAN |
| runs | CLEAN |
| trials | CLEAN |
| harness | CLEAN |
| benchmark | CLEAN |

**Section G verdict: PASS**
