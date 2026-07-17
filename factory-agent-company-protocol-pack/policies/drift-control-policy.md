# Drift Control Policy

**Policy ID**: `DRIFT-CTRL-001`
**Version**: 0.5.0-candidate
**Status**: PROTOCOL_DRAFT
**Scope**: All multi-agent large-project runs
**Owner**: Integrator Lead

---

## 1. Purpose

This policy defines how architecture drift is detected, classified, escalated, and resolved in multi-agent Factory runs. Drift is any divergence between the approved architecture baseline and the artifacts produced by worker agents.

---

## 2. Drift Categories

### 2.1 Module Boundary Violations

| Code | Description | Severity |
|------|-------------|----------|
| `DRIFT-MB-01` | Worker writes into another worker's owned scope | CRITICAL |
| `DRIFT-MB-02` | Worker imports from another module without declared dependency | HIGH |
| `DRIFT-MB-03` | Worker exposes internal implementation as public API | MEDIUM |

### 2.2 API Contract Changes

| Code | Description | Severity |
|------|-------------|----------|
| `DRIFT-API-01` | Breaking change to an agreed interface signature | CRITICAL |
| `DRIFT-API-02` | Adding undocumented parameters to a public function | HIGH |
| `DRIFT-API-03` | Changing return type without contract update | HIGH |
| `DRIFT-API-04` | Introducing new required fields without version bump | MEDIUM |

### 2.3 Dependency Graph Drift

| Code | Description | Severity |
|------|-------------|----------|
| `DRIFT-DEP-01` | Circular dependency introduced between modules | CRITICAL |
| `DRIFT-DEP-02` | Worker adds undeclared external dependency | HIGH |
| `DRIFT-DEP-03` | Implicit dependency via shared mutable state | HIGH |

### 2.4 Shared Type Duplication

| Code | Description | Severity |
|------|-------------|----------|
| `DRIFT-TYPE-01` | Two workers define identical but divergent types | HIGH |
| `DRIFT-TYPE-02` | Worker redefines a shared type locally instead of importing | MEDIUM |
| `DRIFT-TYPE-03` | Shared type modified without cross-worker synchronization | HIGH |

---

## 3. Severity Classification

| Severity | Definition | Response SLA |
|----------|-----------|--------------|
| **CRITICAL** | Makes the system unmergeable or breaks core contracts | Quarantine immediately |
| **HIGH** | Introduces hidden coupling or future merge conflicts | Flag in next review cycle |
| **MEDIUM** | Reduces maintainability but not immediately blocking | Log for sprint retrospective |

---

## 4. Drift Prevention Rules

1. **Pre-flight capsule validation**: Every worker capsule MUST pass `validate-capsule.ps1` before spawn.
2. **Scope declaration**: Every worker MUST declare `ownedScope` and `forbiddenScope` in capsule JSON.
3. **Contract freeze**: Once Architect publishes API contracts, no worker may modify them unilaterally.
4. **Dependency registration**: All cross-module dependencies must be declared in `task-graph.json` before spawn.
5. **Type registry**: Shared types live in a single `shared/` package; workers import, never redefine.

---

## 5. Drift Detection Pipeline

```
[Architect Baseline]
       |
       v
[Worker Capsule] --> [validate-capsule.ps1] --> PASS/FAIL
       |
       v
[Build Artifacts] --> [Integrator diff check] --> DRIFT?
       |                                              |
       v                                              v
[Reviewer audit]                              [Quarantine / Escalate]
       |
       v
[Verifier gate] --> DRIFT_FREE / DRIFT_DETECTED
       |
       v
[Integrity Checker final sweep]
```

---

## 6. When Drift Is Detected

### 6.1 Quarantine (CRITICAL)

- Worker artifacts are moved to `_quarantine/` directory.
- Worker capsule is flagged with `driftStatus: "QUARANTINED"`.
- Integrator notifies Main Agent within 5 minutes.
- Worker is NOT respawned until root cause is diagnosed.

### 6.2 Escalate (HIGH)

- Drift is recorded in `integration-result.json` with evidence snapshot.
- Integrator flags for Reviewer attention in next cycle.
- Worker may continue if drift is non-breaking.

### 6.3 Repair (MEDIUM)

- Logged in `reviewer-result.json` as a quality observation.
- Addressed in next refinement pass.
- Does not block merge.

---

## 7. Drift Evidence Requirements

Every drift detection must include:

| Field | Required | Example |
|-------|----------|---------|
| `driftCode` | Yes | `DRIFT-MB-01` |
| `detectedBy` | Yes | `Integrator` |
| `detectedAt` | Yes | ISO 8601 timestamp |
| `workerCapsuleId` | Yes | `builder-1-capsule` |
| `affectedModule` | Yes | `auth-module` |
| `baselineRef` | Yes | SHA256 of original contract |
| `observedRef` | Yes | SHA256 of drifted artifact |
| `diff` | Yes | Path to diff file |
| `severity` | Yes | `CRITICAL` |
| `resolution` | No | `QUARANTINED`, `REPAIRED`, `ACCEPTED` |

---

## 8. Escalation Path

```
Worker Drift
    |
    v
Integrator detects
    |
    +-- CRITICAL --> Quarantine --> Main Agent notified --> Architect reviews
    |
    +-- HIGH     --> Reviewer flag --> Next cycle audit --> Repair or accept
    |
    +-- MEDIUM   --> Log only --> Retrospective
```

---

## 9. Policy Compliance

- Every integration cycle MUST run full drift detection.
- Verifier MUST confirm `DRIFT_FREE` before merge gate passes.
- Integrity Checker MUST audit all quarantine decisions for false positives.
- Drift policy violations are recorded in `integrity-check-result.json`.

---

*End of Drift Control Policy*
