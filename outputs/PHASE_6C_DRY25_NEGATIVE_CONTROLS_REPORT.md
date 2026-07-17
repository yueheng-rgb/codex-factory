# Phase 6C — DRY25-C: Portability Negative Controls Report

**Phase**: DRY25-C
**Status**: PASS (20/20)
**Gaps**: 0

## Summary

All 20 negative controls detected their expected risk signals. 0 UNEXPECTED_PASS. 0 FAIL_TARGET_NOT_TRIGGERED.

## Results

| # | Description | Signal | Result |
|---|---|---|---|
| N01 | Missing MANIFEST.json | File not found | ✅ |
| N02 | MANIFEST.sha256 mismatch | must match | ✅ |
| N03 | Missing core factoryctl asset | Missing | ✅ |
| N04 | Missing agent progress schema | FAIL | ✅ |
| N05 | Missing H-phase template | False | ✅ |
| N06 | Compressed summary used as evidence | FAIL | ✅ |
| N07 | Scoring system emits PASS/FAIL | FAIL | ✅ |
| N08 | Unverified claim marked VERIFIED_FACT | FAIL | ✅ |
| N09 | Manual PASS accepted | True | ✅ |
| N10 | ExpectedClass-only accepted | FAIL | ✅ |
| N11 | Missing transcript accepted | False | ✅ |
| N12 | Main Agent fallback accepted | PARSE_FAIL | ✅ |
| N13 | Phase template lacks P0 blocking rule | FAIL | ✅ |
| N14 | Failure-router in core | FAIL | ✅ |
| N15 | Missing verifier module ignored | False | ✅ |
| N16 | Absolute repo path in pack | FAIL | ✅ |
| N17 | Hidden governance state dependency | FAIL | ✅ |
| N18 | Mini-mission without contracts | False | ✅ |
| N19 | Mini-mission without progress events | False | ✅ |
| N20 | Mini-mission despite missing manifest asset | Missing | ✅ |

## Gaps

0 gaps. All negatives detected correctly.

