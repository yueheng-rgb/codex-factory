# FACTORY-AGENT-2 Preflight Reconciliation Report

**Generated**: 2026-06-26T03:00:00+08:00  
**Phase**: FACTORY-AGENT-2 / Worker Capsule + Reporting Runtime Hardening  
**Preflight Result**: PASS_WITH_GAPS — proceed to AGENT-2 implementation

---

## Parent Phase Verification

| Check | Result |
|---|---|
| FACTORY-AGENT-1 PASS | ✅ PASS (52/52 verifier, 36/36 negatives) |
| Protocol pack directory | ✅ exists — 47 files |
| Role docs (7 roles) | ✅ all exist |
| Schemas (4) | ✅ all exist |
| Simulation artifacts (15) | ✅ all exist |
| v0.4 release ZIP unchanged | ✅ SHA256 confirmed |
| Old FINAL package unchanged | ✅ confirmed |
| No new ZIP created | ✅ confirmed |
| No benchmark started | ✅ confirmed |
| No v0.5 package | ✅ confirmed |
| 10-role model not restored | ✅ confirmed (archived) |

---

## AGENT-1 Caveat Reconciliation: `check-agent-protocol-integrity.ps1`

**Question**: AGENT-1 spec requested `check-agent-protocol-integrity.ps1`, but completion summary highlighted `validate-capsule.ps1`.

**Search result**: `check-agent-protocol-integrity.ps1` does **NOT** exist anywhere in the repo.

**Classification**: **Category 3** — runtime integrity script is missing and must be created in this phase.

**Resolution**: AGENT-2 will create `factory-agent-company-protocol-pack/runtime/scripts/check-agent-protocol-integrity.ps1` as a combined protocol integrity suite.

---

## Runtime Gap Analysis

| Runtime Capability | Exists? | Schema? | Policy? | Needs Runtime? |
|---|---|---|---|---|
| Anti-deception checking | ❌ | N/A | ✅ policy | ✅ YES |
| Capsule validation | ✅ partial | ✅ | ✅ | ✅ UPGRADE |
| Progress report validation | ❌ | ✅ | ✅ | ✅ YES |
| Status report validation | ❌ | ✅ | ✅ | ✅ YES |
| Handoff validation | ❌ | ✅ | ✅ | ✅ YES |
| Close receipt validation | ❌ | ✅ | ✅ | ✅ YES |
| Scope isolation checking | ❌ | N/A | ✅ policy | ✅ YES |
| Evidence integrity checking | ❌ | N/A | ✅ policy | ✅ YES |
| Combined protocol integrity suite | ❌ | N/A | N/A | ✅ YES |

### Existing `validate-capsule.ps1` Assessment

**Current checks (9 fields)**: capsuleId, ownedScope, forbiddenScope, forkContext, expectedOutputs, handoffRequirements.fileList, .sha256, .transcriptRef, .contractChecklist

**Missing checks (13 fields)**: phase, role (validation against known roles), allowedImports, forbiddenImports, requiredEvidence, closeConditions, antiDeceptionChecks, escalationTriggers, assignedBy, assignedAt, contractVersion, capsuleId pattern, expectedOutputs structured object validation

**Verdict**: Needs upgrade to full schema coverage in AGENT-2.

---

## Existing Assets

### Schemas (4)
- `worker-capsule.schema.json` — 22 required fields
- `worker-reporting.schema.json` — PROGRESS/BLOCKER/STATUS types
- `worker-handoff.schema.json` — SHA256, contract checklist, transcript
- `close-receipt.schema.json` — COMPLETED/FAILED/STALE/REPLACED

### Fixtures (5 from AGENT-1)
- Valid capsule, invalid capsule (no-scope), valid close receipt, valid handoff, drift injection

### Simulation (15 artifacts from AGENT-1)
- 2 builder capsules, progress report, blocker report, 2 handoffs, 2 close receipts, integration result, integrity check, reviewer, verifier, spawn decisions, task graph, manifest

---

## Open Caveats

1. AGENT-1 requested `check-agent-protocol-integrity.ps1` — resolved by including it in AGENT-2 scope
2. Existing `validate-capsule.ps1` covers 9/22 required capsule schema fields — must be upgraded
3. All 4 schemas exist but no runtime validators consume them — AGENT-2 will bridge this gap

---

## Recommendation

**Proceed to AGENT-2 implementation.** All blockers are zero. Gaps are well-defined and within AGENT-2 scope. Parent chain is clean.
