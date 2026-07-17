# FACTORY-V04-P1: v0.4 Reframe + Quality Gap Repair — Complete Report

**Phase**: FACTORY-V04-P1  
**Date**: 2026-06-25T22:20:48+08:00  
**Status**: COMPLETE  

## Summary

v0.4 Factory Lite Core has been reframed from "universal quality improver" to **"process integrity layer with conditional quality benefits"** based on two-benchmark evidence (EVAL-8 + EVAL-13).

## What Changed

### New Positioning
- **From**: "v0.4 improves product quality" (implicit universal claim)
- **To**: "v0.4 is a PROCESS INTEGRITY LAYER. Product quality improvement is CONDITIONAL, NOT GUARANTEED."

### New Documents
- POSITIONING.md — Honest framing of what v0.4 IS and IS NOT
- EVIDENCE_BASIS.md — Updated with EVAL-13 INCONCLUSIVE caveat
- docs/WHEN_TO_USE_FACTORY_LITE.md — Recommended scenarios
- docs/WHEN_NOT_TO_USE_FACTORY.md — Anti-patterns
- docs/COMMON_FAILURE_MODES.md — 5 common failure modes

### New Mechanisms
- core/quality-gap-trigger-policy.json — 5 quality-gap triggers (QG01-QG05)
- eview/quality-gap-reviewer-checklist.json — Reviewer P1 with 5 dimensions (RV01-RV05)

### Repaired Mechanisms
- context-recovery-deferred/multi-agent-escalation-policy.json — Tier 0.5 (Reviewer) added, escalation rules defined
- MANIFEST.json — New positioning, evidence, forbidden claims

### Evidence Reconciliation
- EVAL-8 positive (+8) preserved
- EVAL-13 INCONCLUSIVE preserved
- 8 supported claims, 7 unsupported, 5 inconclusive

## Quality Gap Triggers

| Trigger | Detection | Action |
|---------|-----------|--------|
| QG01 | UI depth risk | Reviewer |
| QG02 | Documentation risk | Reviewer |
| QG03 | Test quality risk | Reviewer |
| QG04 | Domain correctness risk | Reviewer |
| QG05 | API completeness risk | Reviewer |

**Escalation**: Reviewer → 3-role only when QG01+QG04 both fire OR Reviewer recommends MAJOR_GAPS.

## Verification

- Verifier: **21/21 PASS**
- Negative controls: **26/26 PASS, 0 gaps**
- Smoke tests: **5/5 scenarios PASS**
- No release ZIPs | No FINAL modification | v0.4 remains DRAFT_NOT_RELEASED

## Recommended Next Phase

User review, then choose:
1. **FACTORY-EVAL-14** — Test 3-role Reviewer model against quality gaps
2. **FACTORY-EVAL-15** — Third benchmark for more robust evidence
3. **FACTORY-V04-RELEASE-PREP** — Only if user accepts process-integrity positioning
