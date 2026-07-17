# Verifier Module: negative-control-check

## Metadata
- **Verifier ID**: `negative-control-check`
- **Version**: 1.0.0
- **Phase**: H18
- **Category**: safety-gate
- **Priority**: P0 (Hard Floor)
- **nativeGenerated**: true

## Purpose
Verify that all negative control fixtures have been executed, all target gates were triggered as expected, and there are no unexpected passes or undetected failures. Ensures the gating system correctly rejects what it should reject.

## Target Gate
`NEGATIVE_CONTROLS_VALID`

## Evidence Source
- **Primary**: Negative fixture definition files (`negative-fixture-schema.json` conformant)
- **Secondary**: Negative fixture execution transcripts
- **Tertiary**: Verifier results triggered by negative controls
- **Quaternary**: `AGENT_PROGRESS.jsonl` — `negative_control_executed` events

## Definitions
- **Negative Fixture**: A deliberately crafted scenario designed to trigger a specific failure gate.
- **Expected Failure Class**: The failure classification (P0/P1/P2) the negative control is designed to produce.
- **Target Gate**: The specific verifier gate the negative control aims to trigger.
- **Unexpected Pass**: A negative fixture that produced PASS when it should have produced FAIL — indicates a broken gate.
- **Fail Target Not Triggered**: A negative fixture that did not trigger the specific target gate — indicates gate bypass.

## Check Logic

### Step 1: Inventory Negative Fixtures
For each negative fixture definition:
- Read `id`, `targetGate`, `expectedFailureClass`, `faultManifest`.
- Record as `expectedFixtures[]`.

### Step 2: Collect Execution Results
For each executed negative fixture:
- Find corresponding `negative_control_executed` events in `AGENT_PROGRESS.jsonl`.
- Find corresponding verifier results triggered by the negative control.
- Record `executedFixtures[]` with actual outcome and triggered gates.

### Step 3: Compare Expected vs Actual
For each fixture:
```
executed       = fixture.id in executedFixtures
correctGate    = fixture.targetGate in triggeredGates
correctClass   = actualFailureClass matches expectedFailureClass
notUnexpectedPass = actualOutcome != "PASS"

result = executed AND correctGate AND correctClass AND notUnexpectedPass
```

### Step 4: Classify Gaps
- Fixture defined but not executed → **FAIL: NEGATIVE_FIXTURE_NOT_EXECUTED** (P1)
- Fixture executed but wrong gate triggered → **FAIL: WRONG_GATE_TRIGGERED** (P0)
- Fixture executed but produced PASS → **FAIL: UNEXPECTED_PASS** (P0)
- Fixture executed but FAIL_TARGET_NOT_TRIGGERED → **FAIL: FAIL_TARGET_NOT_TRIGGERED** (P0)
- Fixture executed and correct → **PASS**

### Step 5: Aggregate
- All fixtures executed with correct outcomes → **PASS**
- Any UNEXPECTED_PASS or FAIL_TARGET_NOT_TRIGGERED → **FAIL (P0)**
- Any NEGATIVE_FIXTURE_NOT_EXECUTED → **FAIL (P1)**

## PASS Criteria
- All defined negative fixtures have been executed.
- All executed fixtures triggered their target gate.
- All executed fixtures produced FAIL with correct failure class.
- Zero UNEXPECTED_PASS outcomes.
- Zero FAIL_TARGET_NOT_TRIGGERED outcomes.

## FAIL Criteria
| Failure Mode | Priority | Description |
|---|---|---|
| `UNEXPECTED_PASS` | P0 | Negative fixture produced PASS instead of FAIL. Gate is broken. |
| `FAIL_TARGET_NOT_TRIGGERED` | P0 | Negative fixture did not trigger the specific target gate. Possible gate bypass. |
| `WRONG_GATE_TRIGGERED` | P0 | Negative fixture triggered a different gate than expected. Gate routing error. |
| `NEGATIVE_FIXTURE_NOT_EXECUTED` | P1 | Defined negative fixture was not executed. Missing coverage. |
| `INSUFFICIENT_NEGATIVE_COVERAGE` | P1 | Fewer than minimum required negative fixtures executed. |
| `FIXTURE_EXECUTION_ERROR` | P1 | Negative fixture execution itself failed (not the gate, but the fixture setup). |

## Machine-Readable Output Format
```json
{
  "verifierName": "negative-control-check",
  "targetGate": "NEGATIVE_CONTROLS_VALID",
  "executedAt": "2026-06-24T12:00:00.000+08:00",
  "outcome": "PASS|FAIL",
  "fixtureResults": [
    {
      "fixtureId": "nc-scoring-gate-001",
      "targetGate": "SCORING_SYSTEM_GATE",
      "expectedFailureClass": "P0",
      "executed": true,
      "triggeredGate": "SCORING_SYSTEM_GATE",
      "actualOutcome": "FAIL",
      "actualFailureClass": "P0",
      "correctGate": true,
      "correctClass": true,
      "unexpectedPass": false,
      "result": "PASS"
    }
  ],
  "summary": {
    "totalDefined": 5,
    "totalExecuted": 5,
    "passed": 4,
    "failed": 1,
    "unexpectedPasses": 0,
    "failTargetNotTriggered": 0,
    "notExecuted": 0
  },
  "evidenceRefs": [
    "path/to/negative-fixtures/*.json",
    "path/to/AGENT_PROGRESS.jsonl"
  ]
}
```

## False Positive Risks
1. **Fixture execution ordering**: A negative fixture may depend on state set by a prior fixture. If execution order differs, wrong gate may trigger. Mitigation: Each fixture should be self-contained and reset state.
2. **Overlapping gate triggers**: A fixture designed for GATE_A may also validly trigger GATE_B. Mitigation: Fixture definitions must specify primary target gate and allowed secondary gates.
3. **Transient failures in fixture setup**: If fixture setup fails (not the gate check), it's a fixture execution error, not a gate failure. Mitigation: Distinguish fixture execution errors from gate outcomes.

## Dependencies
- `negative-fixture-schema.json` — fixture definition format
- `negative-fixture-template.md` — fixture creation template
- `scoring-system-negative-fixture-template.md` — scoring-specific template
- `decision-priority-policy.json` — failure class definitions

## Integration
Invoked by `factoryctl verify --gate NEGATIVE_CONTROLS_VALID`. Must be run after all negative fixtures are executed and before phase-close.
