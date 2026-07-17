# Integrity Check Policy

**Policy ID**: `INTEG-CHK-001`
**Version**: 0.5.0-candidate
**Status**: PROTOCOL_DRAFT
**Scope**: All multi-agent large-project runs
**Owner**: Integrity Checker (execution), Main Agent (escalation recipient)

---

## 1. Purpose

This policy defines what the Integrity Checker audits, how often, what evidence is required, escalation triggers, and PASS/FAIL criteria. The Integrity Checker is the final audit layer — it catches deception, drift, stale agents, missing evidence, spawn failures, and Main Agent fallback contamination.

---

## 2. Audit Scope

The Integrity Checker audits the following categories:

### 2.1 Deception Detection

| Check ID | What Is Checked | Evidence Required |
|----------|----------------|-------------------|
| `IC-DEC-01` | Worker output tampering | SHA256 comparison of handoff vs. build artifacts |
| `IC-DEC-02` | Falsified progress reports | Cross-reference progress-report.json with file timestamps |
| `IC-DEC-03` | Phantom handoffs (handoff claiming work not done) | Diff handoff fileList against actual repository state |
| `IC-DEC-04` | Drift injection disguised as legitimate output | Compare against drift-injection-fixture patterns |

### 2.2 Drift Detection

| Check ID | What Is Checked | Evidence Required |
|----------|----------------|-------------------|
| `IC-DRF-01` | Module boundary violations | Cross-reference all written files against capsule ownedScope |
| `IC-DRF-02` | API contract drift | Compare actual API signatures against Architect baseline |
| `IC-DRF-03` | Dependency graph drift | Rebuild dependency graph from actual imports vs declared deps |
| `IC-DRF-04` | Shared type duplication | Scan for duplicate type definitions across modules |

### 2.3 Stale Agent Detection

| Check ID | What Is Checked | Evidence Required |
|----------|----------------|-------------------|
| `IC-STL-01` | Agent inactive beyond timeout | Compare last activity timestamp against session timeout |
| `IC-STL-02` | Agent producing no output in cycle | Check if expectedOutputs delivered within cycle window |
| `IC-STL-03` | Agent in zombie state (spawned but never reported) | Cross-reference spawn-decisions.json with progress reports |

### 2.4 Missing Evidence Detection

| Check ID | What Is Checked | Evidence Required |
|----------|----------------|-------------------|
| `IC-EVD-01` | Missing handoff file | Check handoffRequirements.fileList completeness |
| `IC-EVD-02` | Missing SHA256 hash | Every handoff file must have sha256 in handoffRequirements |
| `IC-EVD-03` | Missing transcript reference | handoffRequirements.transcriptRef must be non-empty |
| `IC-EVD-04` | Missing contract checklist | handoffRequirements.contractChecklist must be complete |

### 2.5 Spawn Failure Hiding

| Check ID | What Is Checked | Evidence Required |
|----------|----------------|-------------------|
| `IC-SPN-01` | Spawn attempt with no capsule validation | validate-capsule.ps1 result must precede spawn |
| `IC-SPN-02` | Spawned agent never produced output | Cross-reference spawn timestamp with first progress report |
| `IC-SPN-03` | Spawn silently failed (no error logged) | Check spawn log for error entries |

### 2.6 Main Agent Fallback Contamination

| Check ID | What Is Checked | Evidence Required |
|----------|----------------|-------------------|
| `IC-MAF-01` | Main Agent wrote into worker owned scope | Check all files in worker scope for Main Agent authorship |
| `IC-MAF-02` | Main Agent bypassed Integrator merge | Check merge history for non-Integrator merges |
| `IC-MAF-03` | Main Agent modified worker capsule post-spawn | Compare capsule hash at spawn vs. at close |

---

## 3. Check Frequency

| Check Type | Frequency | Trigger |
|-----------|-----------|---------|
| Full audit | Every integration cycle | After all handoffs received, before Verifier gate |
| Spot check | Every worker handoff | On each handoff receipt by Integrator |
| Deception sweep | Every close receipt | On each close-receipt generation |
| Drift sweep | Every merge attempt | Before Integrator executes merge |
| Stale agent sweep | Every 30 minutes | Timer-based during active run |

---

## 4. Evidence Requirements Per Check

Every Integrity Checker audit must produce:

```json
{
  "checkId": "IC-DEC-01",
  "checkType": "DECEPTION",
  "targetAgentId": "builder-1",
  "evidenceBasis": [
    {
      "evidenceType": "SHA256_COMPARISON",
      "expectedHash": "a1b2c3d4...",
      "observedHash": "a1b2c3d4...",
      "match": true
    }
  ],
  "passFail": "PASS",
  "notes": "No tampering detected"
}
```

Every FAIL must additionally include:
- `failureReason`: Human-readable explanation
- `escalationLevel`: `WARNING`, `BLOCKING`, or `CRITICAL`
- `recommendedAction`: What the Main Agent should do

---

## 5. Escalation Triggers

| Trigger | Escalation Level | Action |
|---------|-----------------|--------|
| Any `IC-DEC-*` FAIL | **CRITICAL** | Quarantine all worker artifacts, freeze merge, notify Main Agent immediately |
| Any `IC-DRF-*` FAIL at CRITICAL severity | **BLOCKING** | Block merge, notify Integrator and Architect |
| Any `IC-DRF-*` FAIL at HIGH severity | **WARNING** | Flag in Verifier gate, allow merge with documented acceptance |
| Any `IC-STL-*` FAIL | **WARNING** | Notify Main Agent, check if respawn needed |
| Any `IC-EVD-*` FAIL | **BLOCKING** | Reject handoff, request worker resubmit with complete evidence |
| Any `IC-SPN-*` FAIL | **CRITICAL** | Audit entire spawn pipeline, possible Main Agent procedure error |
| Any `IC-MAF-*` FAIL | **CRITICAL** | Halt run, Main Agent must not write worker scope; full audit required |

---

## 6. PASS/FAIL Criteria

### PASS Criteria

| Check Type | PASS Condition |
|-----------|---------------|
| Deception | All SHA256 hashes match; all progress reports consistent with file timestamps; no phantom handoffs |
| Drift | No CRITICAL or HIGH drift violations; MEDIUM violations documented and accepted |
| Stale Agents | All spawned agents active and producing output within cycle |
| Missing Evidence | All handoff files present with valid SHA256, transcript ref, and contract checklist |
| Spawn Failures | All spawns preceded by capsule validation; all spawned agents produced output |
| Main Agent Fallback | No Main Agent writes in worker scope; all merges done by Integrator |

### FAIL Criteria

| Check Type | FAIL Condition |
|-----------|---------------|
| Deception | Any SHA256 mismatch, timestamp inconsistency, or phantom handoff |
| Drift | Any CRITICAL drift or unremediated HIGH drift |
| Stale Agents | Any agent inactive beyond timeout with no progress |
| Missing Evidence | Any required handoff file, hash, transcript, or checklist missing |
| Spawn Failures | Any spawn without capsule validation or with zero output |
| Main Agent Fallback | Any Main Agent contamination in worker scope |

---

## 7. Integrity Check Result Format

Every full audit produces `integrity-check-result.json`:

```json
{
  "auditId": "IC-AUDIT-20260626-001",
  "auditTimestamp": "2026-06-26T14:30:00+08:00",
  "runId": "factory-agent-1-protocol-pack-simulation",
  "overallResult": "PASS" | "FAIL",
  "checks": [ /* array of check results */ ],
  "escalations": [ /* array of escalation entries */ ],
  "driftInjectionDetected": true | false,
  "deceptionDetected": true | false,
  "staleAgentsDetected": true | false,
  "missingEvidenceDetected": true | false,
  "spawnFailuresDetected": true | false,
  "mainAgentFallbackDetected": true | false
}
```

---

## 8. Drift Injection Detection (Special Requirement)

The Integrity Checker MUST be able to detect at least ONE injected drift or deception artifact. The `drift-injection-fixture.json` provides test patterns:

- Injected file outside declared owned scope
- SHA256 mismatch in handoff fileList
- Missing transcript reference
- Phantom file claim in progress report

The Integrity Checker must cross-reference all artifacts against declared scopes and hashes. At least one injection must trigger a FAIL.

---

*End of Integrity Check Policy*
