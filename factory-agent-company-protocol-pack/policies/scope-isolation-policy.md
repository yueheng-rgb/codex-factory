# Scope Isolation Policy

**Policy ID**: `SCOPE-ISO-001`
**Version**: 0.5.0-candidate
**Status**: PROTOCOL_DRAFT
**Scope**: All multi-agent large-project runs
**Owner**: Main Agent (enforcement), Integrator (detection)

---

## 1. Purpose

This policy defines what each agent role may and may not access, write, or modify. Scope isolation prevents cross-contamination, unauthorized writes, and merge conflicts in multi-agent runs.

---

## 2. Owned Scope Definition

Every worker agent has an **owned scope** — the set of files, directories, and modules it is authorized to write.

Owned scope is declared in the worker capsule JSON under `ownedScope`:

```json
{
  "ownedScope": [
    "src/modules/auth/",
    "src/modules/auth/tests/",
    "src/shared/types/auth.d.ts"
  ]
}
```

### Rules
- Owned scopes MUST be non-overlapping across workers.
- A worker may read but NEVER write files outside its owned scope.
- Owned scope is frozen at spawn time. No runtime expansion.

---

## 3. Forbidden Scope Definition

Every worker agent has a **forbidden scope** — files it must never access.

Forbidden scope is declared under `forbiddenScope`:

```json
{
  "forbiddenScope": [
    "src/modules/payments/",
    "src/modules/admin/",
    "config/secrets/",
    "*.env*"
  ]
}
```

### Rules
- Forbidden scope includes ALL other worker owned scopes by default.
- Secrets, config, and environment files are forbidden to all workers.
- Integrator merge scripts are forbidden to all workers.

---

## 4. Cross-Scope Write Detection

### Detection Mechanism

The Integrator checks every handoff for cross-scope writes:

1. Compare `filesWritten` from handoff against worker's `ownedScope`.
2. Any file outside owned scope → **contamination event**.
3. Contamination is classified as `NON_BLOCKING_REPAIRED` or `BLOCKING_UNREPAIRED`.

### Contamination Classification

| Classification | Definition | Action |
|---------------|-----------|--------|
| `NON_BLOCKING_REPAIRED` | Integrator successfully reverted cross-scope writes before merge | Log, continue, flag in reviewer report |
| `BLOCKING_UNREPAIRED` | Cross-scope write cannot be cleanly reverted or caused cascading issues | Quarantine worker, escalate to Main Agent |

---

## 5. Role-Based Access Matrix

| Role | Owned Scope | Write Permission | Read Permission | Merge Permission |
|------|-------------|-----------------|-----------------|-----------------|
| **Main Agent** | Orchestration only | Orchestration dir only | Full read | No (delegates to Integrator) |
| **Architect** | Design artifacts | Design docs only | Full read | No |
| **Builder** | Assigned module(s) | Owned scope only | Full read except secrets | No |
| **Integrator** | Merge workspace | Merge workspace only | Full read | **YES — sole merge owner** |
| **Reviewer** | Review reports | Review reports only | **Readonly** | No |
| **Verifier** | Gate results | Gate results only | **Readonly** | No |
| **Integrity Checker** | Audit reports | Audit reports only | **Readonly** | No |

---

## 6. Integrator: Sole Merge Owner

The Integrator is the **only** role authorized to merge worker outputs into the main branch.

- No worker may merge its own code.
- No worker may merge another worker's code.
- Main Agent does NOT merge — only coordinates.
- All merges produce an `integration-result.json`.

---

## 7. Verifier and Integrity Checker: Readonly

The Verifier and Integrity Checker are **strictly readonly** roles:

- They produce reports and gate decisions.
- They NEVER modify source code, handoffs, or capsules.
- If they detect an issue, they escalate — they do NOT fix.
- Readonly violation is itself a `BLOCKING_UNREPAIRED` contamination event.

---

## 8. Scope Violation Escalation Path

```
Cross-scope write detected
    |
    v
Integrator classifies
    |
    +-- NON_BLOCKING_REPAIRED
    |       |
    |       v
    |   Integrator reverts, logs in integration-result.json
    |       |
    |       v
    |   Reviewer flags in quality gap report
    |       |
    |       v
    |   Continue merge
    |
    +-- BLOCKING_UNREPAIRED
            |
            v
        Worker capsule → quarantined
        Handoff → rejected
        Main Agent notified
        Architect reviews scope boundaries
        Root cause analysis required before respawn
```

---

## 9. Prevention Rules

1. Capsule `ownedScope` MUST be validated before spawn (`validate-capsule.ps1`).
2. Capsule `forbiddenScope` MUST include all other worker owned scopes.
3. `forkContext` MUST be `false` — workers operate in shared context, not forks.
4. Worker handoffs MUST list every file written with full path.
5. Integrator MUST run cross-scope check on every handoff before merge.

---

## 10. Evidence Requirements

Every scope violation event must record:

| Field | Required |
|-------|----------|
| `violationType` | `NON_BLOCKING_REPAIRED` or `BLOCKING_UNREPAIRED` |
| `workerCapsuleId` | Yes |
| `offendingFile` | Full path |
| `ownedScope` | The worker's declared owned scope |
| `violationScope` | The scope the file actually belongs to |
| `detectedBy` | `Integrator` |
| `detectedAt` | ISO 8601 |
| `resolution` | `REVERTED`, `QUARANTINED`, or `PENDING` |

---

*End of Scope Isolation Policy*
