# Verifier Module: parent-phase-check

## Metadata
- **Verifier ID**: `parent-phase-check`
- **Version**: 1.0.0
- **Phase**: H18
- **Category**: structural-integrity
- **Priority**: P0 (Hard Floor)
- **nativeGenerated**: true

## Purpose
Verify that each worker contract's declared phase matches the expected parent phase for its scope. Detect phase mismatches that indicate contract drift or incorrect retroactive attribution.

## Target Gate
`PARENT_PHASE_MATCH`

## Evidence Source
- **Primary**: Worker contract JSON (`worker-contract.schema.json`)
- **Secondary**: `AGENT_PROGRESS.jsonl` — phase timeline events
- **Tertiary**: `AGENT_REGISTRY.json` — spawn records with phase attribution

## Check Logic

### Step 1: Extract Declared Phase
For each worker contract in scope:
- Read `contract.phase` value.
- Record as `declaredPhase`.

### Step 2: Derive Expected Phase
- If contract has `generatedBy` field referencing a known phase-defining script (e.g., `H18 Builder`), derive expected phase from script metadata.
- If contract is in a phase-scoped directory (e.g., `factory-resource-pack/` is H18), derive expected phase from directory context.
- If phase is explicitly declared in `AGENT_PROGRESS.jsonl` with matching `agentId`, use that as expected phase.

### Step 3: Compare
- `declaredPhase === expectedPhase` → **tentative PASS**
- `declaredPhase !== expectedPhase` → **FAIL: PARENT_PHASE_MISMATCH**

### Step 4: Cross-Validate with Timeline
- Check `AGENT_PROGRESS.jsonl` for `phase_started` and `phase_completed` events for `expectedPhase`.
- If contract `generatedAt` falls outside `[phase_started.timestamp, phase_completed.timestamp]`:
  - Contract may be retroactive → check `retroactive` and `reconstructedFrom` fields.
  - If `retroactive: true` and phase mismatch exists, downgrade to **CAVEAT: RETROACTIVE_PHASE_DECLARED** (P2).
  - If `retroactive: false` and phase mismatch exists, **FAIL: PHASE_TIMELINE_VIOLATION** (P0).

## PASS Criteria
- `declaredPhase` matches `expectedPhase` exactly.
- Contract `generatedAt` falls within phase timeline window (if retroactive, this constraint is relaxed to CAVEAT).
- No contradictory phase attribution found in registry or progress events.

## FAIL Criteria
| Failure Mode | Priority | Description |
|---|---|---|
| `PARENT_PHASE_MISMATCH` | P0 | Declared phase does not match expected phase. |
| `PHASE_TIMELINE_VIOLATION` | P0 | Non-retroactive contract generated at timestamp outside phase window. |
| `CONFLICTING_PHASE_ATTRIBUTION` | P1 | Agent registry and contract disagree on phase. |
| `MISSING_PHASE_DECLARATION` | P1 | Contract has no phase field. |

## CAVEAT Criteria
| Caveat | Priority | Description |
|---|---|---|
| `RETROACTIVE_PHASE_DECLARED` | P2 | Phase mismatch but contract is retroactive; nativeGenerated must be false. |

## Machine-Readable Output Format
```json
{
  "verifierName": "parent-phase-check",
  "targetGate": "PARENT_PHASE_MATCH",
  "executedAt": "2026-06-24T12:00:00.000+08:00",
  "outcome": "PASS|FAIL|CAVEAT",
  "checks": [
    {
      "contractPath": "path/to/worker-contract.json",
      "agentId": "H18-Builder-01",
      "declaredPhase": "H18",
      "expectedPhase": "H18",
      "phaseMatch": true,
      "inTimelineWindow": true,
      "retroactive": false,
      "result": "PASS"
    }
  ],
  "evidenceRefs": [
    "path/to/worker-contract.json",
    "path/to/AGENT_PROGRESS.jsonl",
    "path/to/AGENT_REGISTRY.json"
  ],
  "summary": "3 contracts checked: 3 PASS, 0 FAIL, 0 CAVEAT"
}
```

## False Positive Risks
1. **Multi-phase agents**: An agent legitimately spanning two phases may have a contract that references the earlier phase. Mitigation: Check `AGENT_PROGRESS.jsonl` for multi-phase span; if confirmed, accept the declared phase.
2. **Phase naming conventions**: If phase naming changes mid-Factory (e.g., "H13-D" vs "H13"), exact string match may fail. Mitigation: Maintain a phase alias map.
3. **Retroactive contract with correct phase**: A retroactive contract may have the correct phase but `generatedAt` outside the window. Mitigation: Always check `retroactive` flag before flagging timeline violation.

## Dependencies
- `worker-contract.schema.json` — contract format definition
- `evidence-entry.schema.json` — evidence integrity validation
- `AGENT_PROGRESS.jsonl` — phase timeline source

## Integration
This verifier is invoked during `factoryctl verify --gate PARENT_PHASE_MATCH` and automatically during `factoryctl phase-close` preflight checks.
