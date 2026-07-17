# Negative Fixture Template

## Metadata
- **Template Version**: 1.0.0
- **Phase**: H18
- **Category**: negative-fixture
- **nativeGenerated**: true

## Purpose
This template defines the standard format for creating negative control scenarios in the Factory resource pack. Negative fixtures are deliberately crafted inputs designed to trigger specific verifier gates. They validate that the gating system correctly rejects what it should reject.

Use this template when creating a new negative fixture definition. Copy, fill in all sections, and save as a JSON file conforming to `negative-fixture-schema.json`.

---

## Fixture Definition Structure

### 1. Identity
```yaml
id: "nc-{gate-short-name}-{sequence}"       # e.g., nc-scoring-gate-001
targetGate: "GATE_NAME"                      # The verifier gate this fixture targets
expectedRiskSignal: "DESCRIPTION"            # What risk this fixture simulates
expectedFailureClass: "P0|P1|P2"            # Expected failure priority level
```

### 2. Fault Manifest
Describe the deliberate fault injected into the system. Be specific about what is wrong and why it should trigger the target gate.

```yaml
faultManifest:
  description: >
    Detailed description of the injected fault.
    Include: what artifact is affected, what rule is violated,
    what the expected detection mechanism is.
  injectedArtifact: "path/to/affected-artifact.json"
  violationType: "TYPE_OF_VIOLATION"
  expectedDetection: "How the verifier should detect this fault"
  falsifiesClaim: "What claim or invariant this fault falsifies"
```

### 3. Expected Failure Detail
```yaml
expectedFailure:
  targetGate: "GATE_NAME"
  expectedOutcome: "FAIL"
  expectedFailureMode: "SPECIFIC_FAILURE_MODE_ENUM_VALUE"
  expectedPriority: "P0|P1|P2"
  mustNotProduce: ["PASS", "CAVEAT"]
  allowedSecondaryGates: []                  # Other gates that may also fire (not errors)
```

### 4. Execution Evidence
```yaml
executionEvidence:
  path: "path/to/negative-fixture-execution/{fixture-id}-transcript.txt"
  format: "plaintext|json"
  expectedContent:
    - "Expected log line or JSON field indicating gate triggered"
    - "Expected verifier output excerpt"
  forbiddenContent:
    - "UNEXPECTED_PASS"
    - "PASS"
```

### 5. Verifier Confirmation
```yaml
verifierConfirmation:
  required: true
  verifierModule: "negative-control-check"
  confirmationCriteria:
    - "Fixture execution recorded in AGENT_PROGRESS.jsonl as negative_control_executed"
    - "Target gate triggered with correct failure mode"
    - "Outcome is FAIL, not PASS"
    - "Failure class matches expectedFailureClass"
```

---

## Machine-Readable Result Format

Every negative fixture execution must produce a machine-readable result:

```json
{
  "fixtureId": "nc-{gate}-{seq}",
  "executedAt": "2026-06-24T12:00:00.000+08:00",
  "injectedFault": {
    "artifact": "path/to/artifact",
    "violation": "TYPE",
    "description": "What was injected"
  },
  "verifierResult": {
    "verifierName": "name-of-verifier",
    "targetGate": "GATE_NAME",
    "outcome": "FAIL",
    "failureMode": "SPECIFIC_FAILURE_MODE",
    "priority": "P0"
  },
  "fixtureResult": {
    "expectedOutcome": "FAIL",
    "actualOutcome": "FAIL",
    "targetGateTriggered": true,
    "correctFailureMode": true,
    "unexpectedPass": false,
    "overallResult": "PASS"
  }
}
```

---

## Creation Checklist

Before submitting a new negative fixture, verify:

- [ ] `id` is unique and follows naming convention `nc-{gate}-{seq}`
- [ ] `targetGate` references a real verifier gate defined in `verifier-modules/`
- [ ] `faultManifest` describes a specific, reproducible fault
- [ ] `expectedFailureMode` matches an enum value from the target verifier's FAIL criteria
- [ ] `mustNotProduce` includes "PASS"
- [ ] `executionEvidence.path` is a valid, writable path
- [ ] `verifierConfirmation.required` is true
- [ ] Fixture conforms to `negative-fixture-schema.json`
- [ ] Fixture is self-contained (does not depend on other fixtures' state)
- [ ] Fixture resets any state it modifies

---

## Anti-Patterns (Do NOT Do)

| Anti-Pattern | Why Wrong | Correct Approach |
|---|---|---|
| Fixture expects PASS | Negative controls must produce FAIL | Design a fault that should trigger FAIL |
| Fixture depends on prior fixture state | Execution order independence required | Reset state at start of fixture |
| Fixture target is not a real gate | Cannot validate a non-existent gate | Reference gates from verifier-modules/ |
| Fixture modifies production artifacts | Fixtures must be isolated | Use copies or temporary artifacts |
| No execution transcript | Evidence chain incomplete | Always produce transcript |
| `verifierConfirmation: false` | Unconfirmed negative is useless | Always require verifier confirmation |

---

## Example: Scoring System Gate Negative Fixture

```yaml
id: "nc-scoring-gate-001"
targetGate: "SCORING_SYSTEM_GATE"
expectedRiskSignal: "Score-based PASS substituted for verifier evidence"
expectedFailureClass: "P0"
faultManifest:
  description: >
    Inject a verifier result JSON that uses a computed score (0.85)
    to produce a PASS verdict instead of a binary verifier check.
    This should trigger SCORING_SYSTEM_GATE because score-based
    verdicts are prohibited.
  injectedArtifact: "negative-fixtures/artifacts/score-based-pass.json"
  violationType: "SCORE_BASED_VERDICT"
  expectedDetection: "no-generic-fail-check verifier detects score field in verdict"
  falsifiesClaim: "All PASS verdicts are backed by verifier results"
expectedFailure:
  targetGate: "SCORING_SYSTEM_GATE"
  expectedOutcome: "FAIL"
  expectedFailureMode: "SCORE_BASED_VERDICT"
  expectedPriority: "P0"
  mustNotProduce: ["PASS"]
executionEvidence:
  path: "negative-fixtures/transcripts/nc-scoring-gate-001.txt"
  format: "plaintext"
  expectedContent:
    - "SCORING_SYSTEM_GATE triggered"
    - "SCORE_BASED_VERDICT"
    - "outcome: FAIL"
  forbiddenContent:
    - "UNEXPECTED_PASS"
verifierConfirmation:
  required: true
  verifierModule: "negative-control-check"
```

---

## References
- `negative-fixture-schema.json` — JSON schema for fixture definitions
- `scoring-system-negative-fixture-template.md` — scoring-specific template
- `verifier-modules/negative-control-check.md` — verifier that validates negative controls
- `SCORING_SYSTEM_GATE.md` — the scoring system gate rule
