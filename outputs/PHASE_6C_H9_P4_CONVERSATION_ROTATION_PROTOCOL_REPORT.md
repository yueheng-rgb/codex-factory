# Phase 6C-H9-P4: Conversation Rotation and Compression Resume Protocol

**Report ID:** PHASE_6C_H9_P4_CONVERSATION_ROTATION_PROTOCOL
**Status:** PASS
**Date:** 2026-06-22
**Codex Factory Version:** Phase 6C

---

## Purpose

Establishes a Factory-level protocol that prevents stale-context continuation after repeated compression, agent-limit interruption, or window handoff.

---

## Deliverables

| # | File | Type | Status |
|---|------|------|--------|
| 1 | `governance/harness-readiness/conversation-rotation-policy.json` | Policy definition | Created |
| 2 | `scripts/harness-readiness/create-resume-capsule.ps1` | Capsule creator | Created |
| 3 | `scripts/harness-readiness/verify-resume-capsule.ps1` | Capsule verifier | Created |
| 4 | `scripts/harness-readiness/verify-new-window-readiness.ps1` | New-window verifier | Created |
| 5 | `outputs/PHASE_6C_H9_P4_CONVERSATION_ROTATION_PROTOCOL_REPORT.md` | This report | Created |

---

## Protocol Rules

### Rotation Triggers (Must Stop)

1. **compressionCount >= 2** — main agent must stop; cannot continue in same window
2. **Agent limit hit** — pending workers cannot be dispatched; stop and handoff
3. **Phase regression** — closed phase re-executed; stop and quarantine
4. **Context compression during active run** — resumeAllowed=false until capsule verified

### New Window Requirements

New window must not continue until `verify-new-window-readiness.ps1` passes.

New window must read:
- `current-phase-lock.json`
- `quarantined-runs.json`
- latest trusted report
- latest active run status
- `allowedNextPhase`
- known caveats
- forbidden closed phases

### Resume Capsule (Required Fields)

- `currentTrustedPhase`
- `allowedNextPhase`
- `activeRunId`
- `activeRunStatus`
- `lastTrustedReports[]`
- `quarantinedRuns[]`
- `openCaveats[]`
- `forbiddenActions[]`
- `requiredNextAction`
- `evidencePaths[]`
- `compressionCount`
- `handoffCreatedAt`

### Verifier Failure Conditions

| Condition | Classification |
|-----------|---------------|
| Resume capsule missing | FAIL_MISSING_EVIDENCE |
| allowedNextPhase mismatches phase lock | FAIL_CONTRACT_DRIFT |
| Old closed phase requested | FAIL_CONTRACT_DRIFT |
| DRY18-B starts before DRY18-A-P2 PASS | FAIL_CONTRACT_DRIFT |
| Quarantined run used as source | FAIL_CONTRACT_DRIFT |
| compressionCount >= 2, no new window handoff | FAIL_CONTRACT_DRIFT |
| PASS claim lacks evidence path | FAIL_MISSING_EVIDENCE |

---

## Verification

### create-resume-capsule.ps1

- Path: `scripts/harness-readiness/create-resume-capsule.ps1`
- Accepts: `-RunDir`, `-CompressionCount`
- Outputs: `{RunDir}/resume-capsule.json`

### verify-resume-capsule.ps1

- Path: `scripts/harness-readiness/verify-resume-capsule.ps1`
- Accepts: `-CapsulePath`
- Exit code: 0 = PASS, 1 = FAIL

### verify-new-window-readiness.ps1

- Path: `scripts/harness-readiness/verify-new-window-readiness.ps1`
- Accepts: `-ResumeCapsulePath` (optional if not resume-blocked)
- Exit code: 0 = PASS, 1 = FAIL

---

## Current State

| Field | Value |
|-------|-------|
| Current trusted phase | H9-P3 |
| Allowed next phase | DRY18-A-clean-start |
| Active run status | CLEAN_START_AUTHORIZED |
| Quarantined runs | 1 (dry18-mini-incident-response-ops-app) |
| DRY18-A-P2 PASS | Confirmed |
| DRY18-B status | Not started |
| compressionCount threshold | 2 |

---

## Confirmations

- compressionCount >= 2 requires new window: **Confirmed**
- New window cannot continue without verified capsule: **Confirmed**
- No final ZIP created: **Confirmed**
- DRY18-B not started: **Confirmed**
- DRY18-A-P2 PASS recorded: **Confirmed**

---

## Caveats

None.

---

**Final Status: PASS**
