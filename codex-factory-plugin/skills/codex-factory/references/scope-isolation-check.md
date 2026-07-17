# Verifier Module: scope-isolation-check

## Metadata
- **Verifier ID**: `scope-isolation-check`
- **Version**: 1.0.0
- **Phase**: H18
- **Category**: boundary-enforcement
- **Priority**: P0 (Hard Floor)
- **nativeGenerated**: true

## Purpose
Enforce worker scope boundaries. Detect cross-scope writes where one worker modifies files owned by another worker. Protect integrator-only files from unauthorized modification. Validate that every file modification is attributable to the owning worker.

## Target Gate
`SCOPE_ISOLATION_INTACT`

## Evidence Source
- **Primary**: Worker contracts — `scope.ownedFiles`, `scope.ownedDirectories`, `scope.forbiddenFiles`, `scope.forbiddenDirectories`
- **Secondary**: Filesystem audit — file modification timestamps and owning agent correlation
- **Tertiary**: `AGENT_REGISTRY.json` — agent session windows
- **Quaternary**: Git blame or filesystem metadata for modification attribution

## Definitions
- **Owned Scope**: Files and directories a worker is exclusively authorized to modify.
- **Forbidden Scope**: Files and directories a worker must never modify.
- **Cross-Scope Write**: A modification made by an agent to a file outside its owned scope.
- **Integrator-Only File**: A file that only the integrator role may modify (e.g., merge artifacts, phase-close records).
- **Orphaned Modification**: A file modification with no attributable agent session.

## Check Logic

### Step 1: Build Ownership Map
For each worker contract:
- Map `file → owningAgentId` for all `scope.ownedFiles`.
- Map `directory → owningAgentId` for all `scope.ownedDirectories`.
- Map `file → forbiddenFor[agentIds]` for all `scope.forbiddenFiles`.
- Map `directory → forbiddenFor[agentIds]` for all `scope.forbiddenDirectories`.

### Step 2: Collect Modification Records
For each file in the resource pack:
- Get last modification timestamp.
- Correlate with agent session windows from `AGENT_REGISTRY.json`.
- Determine `modifyingAgentId`.

### Step 3: Detect Violations
For each modification:
```
ownerMatch      = modifyingAgentId == owningAgentId
forbiddenTouch  = modifyingAgentId in forbiddenFor[file]
orphaned        = modifyingAgentId is null (no agent session covers timestamp)
crossScope      = (owningAgentId exists) AND NOT ownerMatch AND NOT orphaned

violation = forbiddenTouch OR (crossScope AND NOT orphaned)
```

### Step 4: Classify Violations
- `forbiddenTouch` → **FAIL: FORBIDDEN_SCOPE_VIOLATION** (P0)
- `crossScope` with known owner → **FAIL: CROSS_SCOPE_WRITE** (P0)
- `orphaned` with no session coverage → **FAIL: ORPHANED_MODIFICATION** (P0)
- Integrator-only file modified by non-integrator → **FAIL: INTEGRATOR_SCOPE_VIOLATION** (P0)

### Step 5: Special Protections
- **Integrator-only files**: `MANIFEST.json`, phase-close records, merge artifacts — only integrator role may modify.
- **Verifier artifacts**: Verifier output files — verifier role is read-only for source; writes only to designated output paths.
- **Registry files**: `AGENT_REGISTRY.json`, `AGENT_PROGRESS.jsonl` — only the agent-tracking subsystem may append.

## PASS Criteria
- Every file modification is attributable to the owning worker agent.
- Zero forbidden scope violations.
- Zero cross-scope writes.
- Zero orphaned modifications.
- All integrator-only files untouched by non-integrator agents.

## FAIL Criteria
| Failure Mode | Priority | Description |
|---|---|---|
| `CROSS_SCOPE_WRITE` | P0 | Agent modified a file owned by another agent. |
| `FORBIDDEN_SCOPE_VIOLATION` | P0 | Agent modified a file explicitly forbidden in its contract. |
| `ORPHANED_MODIFICATION` | P0 | File modified with no attributable agent session. |
| `INTEGRATOR_SCOPE_VIOLATION` | P0 | Non-integrator modified an integrator-only file. |
| `MAIN_AGENT_UNDECLARED_FALLBACK` | P0 | Main Agent modified worker scope without declared fallback. |
| `OWNERSHIP_CONFLICT` | P1 | Two contracts claim ownership of the same file. |
| `UNOWNED_FILE_MODIFIED` | P2 | File in resource pack has no owning agent but was modified. |

## Machine-Readable Output Format
```json
{
  "verifierName": "scope-isolation-check",
  "targetGate": "SCOPE_ISOLATION_INTACT",
  "executedAt": "2026-06-24T12:00:00.000+08:00",
  "outcome": "PASS|FAIL",
  "ownershipMap": {
    "fileCount": 45,
    "ownedFileCount": 42,
    "unownedFileCount": 3
  },
  "violations": [
    {
      "file": "path/to/violated-file.json",
      "owningAgentId": "H18-Builder-02",
      "modifyingAgentId": "H18-Builder-01",
      "violationType": "CROSS_SCOPE_WRITE",
      "modificationTimestamp": "2026-06-24T11:30:00.000+08:00",
      "priority": "P0"
    }
  ],
  "orphanedModifications": [],
  "integratorViolations": [],
  "summary": {
    "totalFiles": 45,
    "violations": 0,
    "orphaned": 0,
    "crossScope": 0,
    "forbidden": 0,
    "integrator": 0
  },
  "evidenceRefs": [
    "path/to/worker-contracts/*.json",
    "path/to/AGENT_REGISTRY.json"
  ]
}
```

## False Positive Risks
1. **Shared utility files**: Some files may be legitimately shared across workers (e.g., shared schema files). Mitigation: Shared files must be declared in `allowedImports` with explicit cross-worker permission.
2. **Integrator merge writes**: Integrator writes to worker-owned files during merge are legitimate. Mitigation: Integrator role has elevated write permission; filter integrator writes from cross-scope detection.
3. **Post-phase archival writes**: Files modified after phase close for archival purposes. Mitigation: Only check modifications within the active phase window.
4. **Timestamp granularity**: Filesystem timestamp granularity may not distinguish two rapid modifications. Mitigation: Use SHA256 comparison as secondary check; if content unchanged, modification may be benign.

## Dependencies
- `worker-contract.schema.json` — scope definitions
- `agent-spawn-failure-policy.json` — undeclared fallback rules
- `AGENT_REGISTRY.json` — session windows

## Integration
Invoked by `factoryctl verify --gate SCOPE_ISOLATION_INTACT`. Runs automatically during phase-close preflight. Cannot be skipped.
