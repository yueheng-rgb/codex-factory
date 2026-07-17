# H18-A0 / Legacy Capability Inventory Report

**Phase**: H18-A0 | **Date**: 2026-06-24 | **Type**: RESEARCH_AND_INVENTORY
**Total Capabilities Found**: 26

---

## Executive Summary

Scanned 24 packages, 48 scripts, 53 outputs, and harness infrastructure. Found **3 scoring systems** — ALL classified as risky for CORE packaging. H18 resource pack must enforce **verifier-based gating only**, not score-based gating.

---

## Disposition Summary

| Disposition | Count | Items |
|---|---|---|
| CORE_PACKAGED | 3 | factoryctl.ps1, agent-registry-progress-scripts, handoff-generation-scripts |
| OPTIONAL_PACKAGED | 4 | evidence-collector, snapshot-manager, project-scaffolding, legacy-negative-controls |
| REFERENCE_ARCHIVED | 12 | risk-classifier, verify-gate, diagnosis-engine-core, phase-gate, scope-guard, task-queue, dep-scheduler, legacy-verifier-scripts, state-management-scripts, governance-diagnosis-jsons, legacy-build-scripts, harness-infrastructure |
| DEPRECATED_NOT_PACKAGED | 7 | drift-severity-scoring, evidence-classification-scoring, diagnosis-reporter, agent-lifecycle, contract-engine, dry23-integration-hub, integration-hub-old |
| EXCLUDED_RISKY | 1 | failure-router |

---

## Scoring System Findings

### 1. risk-classifier (DRY23-A)
- 18 RiskType signals, 4 severity levels (LOW/MEDIUM/HIGH/CRITICAL)
- **Risk**: Scores could replace transcript/verifier evidence. HIGH severity could mask P0 blocking issues.
- **Risk**: Evaluator may produce HIGH confidence for post-hoc reconstructed evidence.
- **No negative controls** test scoring accuracy.
- **Verdict**: REFERENCE_ARCHIVED — signal taxonomy is useful reference; enforcement must remain verifier-based.

### 2. drift-severity-scoring (DRY23-A)
- DriftSeverity (None/Minor/Major/Critical) with rank weights + staleness score thresholds.
- Arbitrary weight scale (0-3), hardcoded thresholds.
- **Replaced by**: DRY24 architecture-drift-detector (rule-based DriftPreventionPolicy).
- **Verdict**: DEPRECATED_NOT_PACKAGED.

### 3. evidence-classification-scoring (DRY23-A)
- ClassificationScore with native/reconstructed numerical weights.
- Heuristic-based (zero sha256, size, path hints) — fragile.
- **Replaced by**: DRY24 nativeGenerated:true boolean marker.
- **Verdict**: DEPRECATED_NOT_PACKAGED.

---

## Scoring System Risk Assessment

| Risk | risk-classifier | drift-severity | evidence-classification |
|---|---|---|---|
| Score replaces evidence | YES | No | YES |
| High score masks P0 | YES | YES | No |
| Score downgrades hard floor | YES | No | No |
| Score from Codex self-report | YES | No | No |
| Has negative controls | NO | No | No |

**ALL 3 EXCLUDED FROM CORE.**

---

## CORE Packaged (3 items)

| Capability | Category | Why Core |
|---|---|---|
| factoryctl.ps1 | factoryctl | Operational entrypoint; loss = control plane unavailable |
| agent-registry-progress-scripts | agent_management | Native agent registration and progress tracking |
| handoff-generation-scripts | session_rotation | Session rotation handoff generation and verification |

---

## OPTIONAL Packaged (4 items)

| Capability | Category | Note |
|---|---|---|
| evidence-collector | evidence_management | Audit evidence bundling; needs verification gate |
| snapshot-manager | evidence_management | State snapshot lifecycle; retention policy needs definition |
| project-scaffolding | bootstrap | Starter template; needs factory-specific expansion |
| legacy-negative-controls | negative_control | Fixture template; needs DRY24 risk taxonomy alignment |

---

## EXCLUDED (1 item)

| Capability | Reason |
|---|---|
| failure-router | Automated retry/quarantine/downgrade decisions without verifier oversight. SeverityAssessor could downgrade blocking failures. |

---

## H18 Resource Pack Impact

### Recommended Design Changes
1. **Add SCORING_SYSTEM_GATE** to H18 manifest: no core module may emit PASS/FAIL based on computed score.
2. **All gating must be verifier-based** (binary check, not weighted score).
3. **Legacy harness infrastructure** should be archived as reference, not packaged as operational.
4. **Deprecated modules** should be documented with replacement paths in H18 migration guide.

### H18 Main Implementation Recommendations
- **Pack as CORE**: factoryctl.ps1 + agent scripts + handoff scripts
- **Pack as OPTIONAL**: evidence-collector, snapshot-manager, scaffolding, negative fixtures
- **Archive as REFERENCE**: 12 items (risk-classifier taxonomy, verify-gate patterns, etc.)
- **Deprecate with docs**: 7 items (all superseded by DRY24 equivalents)
- **Exclude**: failure-router (risky auto-decisions)
- **Do NOT include any score-based gating in CORE modules**

---

## Next Step

Proceed to **H18 main implementation** with the above inventory as manifest guidance. Core pack: 3 operational modules. Optional: 4 modules. All scoring systems excluded from core.