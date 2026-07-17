# Scoring System Negative Fixture Template

## Metadata
- **Template Version**: 1.0.0
- **Phase**: H18
- **Category**: negative-fixture
- **Target Gate**: SCORING_SYSTEM_GATE
- **nativeGenerated**: true

## Purpose
This template is specifically for creating negative control scenarios that test the SCORING_SYSTEM_GATE. These fixtures inject score-based PASS verdicts and verify that the gating system correctly blocks them.

The SCORING_SYSTEM_GATE rule states: **No core module may emit PASS/FAIL based on a computed score. All gating must be verifier-based and evidence-backed.**

---

## Risk Model

Scoring systems can fail in these specific ways:

| Risk | Description | Fixture Should Test |
|---|---|---|
| Score replaces evidence | A score of 0.9 is treated as equivalent to verifier PASS | Inject score-based verdict, verify gate blocks |
| High score masks P0 | A high aggregate score hides a P0 failure | Inject P0 failure with high overall score |
| Score downgrades hard floor | A score is used to caveat a hard floor failure | Inject hard floor failure with caveat score |
| Score from self-report | Codex self-reports a score without verification | Inject self-reported score as evidence |
| Score without negative control | Scoring system has no negative fixtures testing accuracy | The fixtures themselves address this gap |

---

## Fixture Patterns

### Pattern A: Direct Score-Based PASS

**Scenario**: A verifier result JSON uses a `score` field to derive a PASS outcome.

**Fault Injection**:
```json
{
  "verifierName": "score-based-verifier",
  "targetGate": "HARD_FLOOR_MET",
  "outcome": "PASS",
  "score": 0.85,
  "note": "Score exceeds threshold, therefore PASS"
}
```

**Expected Gate Trigger**: SCORING_SYSTEM_GATE → SCORE_BASED_VERDICT (P0)

**Verifier Confirmation**: `no-generic-fail-check` must detect `score` field and flag as SCORE_BASED_VERDICT.

---

### Pattern B: High Score Masking P0 Failure

**Scenario**: An aggregate score of 0.92 is reported, but one sub-check is a P0 hard floor failure. The high score masks the failure.

**Fault Injection**:
```json
{
  "aggregateScore": 0.92,
  "subChecks": [
    { "gate": "HARD_FLOOR_MET", "outcome": "FAIL", "priority": "P0" },
    { "gate": "PARENT_PHASE_MATCH", "outcome": "PASS" },
    { "gate": "SCOPE_ISOLATION_INTACT", "outcome": "PASS" }
  ],
  "overallOutcome": "PASS",
  "note": "Aggregate score 0.92 > 0.80 threshold, overall PASS despite P0 failure"
}
```

**Expected Gate Trigger**: SCORING_SYSTEM_GATE → SCORE_MASKED_P0_FAILURE (P0)

---

### Pattern C: Score Used to Caveat Hard Floor

**Scenario**: A hard floor failure is downgraded to CAVEAT because a severity score is below threshold.

**Fault Injection**:
```json
{
  "verifierName": "hard-floor-check",
  "targetGate": "HARD_FLOOR_MET",
  "outcome": "CAVEAT",
  "actualFiles": 2,
  "minFiles": 3,
  "severityScore": 0.3,
  "note": "Severity score 0.3 < 0.5, downgraded to CAVEAT from FAIL"
}
```

**Expected Gate Trigger**: SCORING_SYSTEM_GATE → HARD_FLOOR_CAVEAT_BY_SCORE (P0)

**Key Rule Violated**: Hard floors cannot be caveated below threshold. No `decision-priority-policy.json` caveat downgrade is allowed for P0.

---

### Pattern D: Self-Reported Score as Evidence

**Scenario**: A Codex agent self-reports a quality score that is treated as verifier evidence.

**Fault Injection**:
```json
{
  "source": "codex-self-report",
  "qualityScore": 0.95,
  "selfAssessment": "Codex assesses this work as 95% complete and correct",
  "treatedAs": "PASS",
  "note": "No independent verifier result exists"
}
```

**Expected Gate Trigger**: SCORING_SYSTEM_GATE → SELF_REPORT_SCORE_AS_EVIDENCE (P0)

**Key Rule Violated**: Evidence hierarchy: Codex self-report is prohibited as primary evidence.

---

## Fixture Definition Template (JSON)

```json
{
  "id": "nc-scoring-gate-XXX",
  "targetGate": "SCORING_SYSTEM_GATE",
  "expectedRiskSignal": "DESCRIPTION_OF_RISK",
  "expectedFailureClass": "P0",
  "faultManifest": {
    "description": "DETAILED_FAULT_DESCRIPTION",
    "injectedArtifact": "negative-fixtures/artifacts/FILENAME.json",
    "violationType": "VIOLATION_TYPE",
    "expectedDetection": "HOW_VERIFIER_DETECTS",
    "falsifiesClaim": "WHAT_CLAIM_IS_FALSIFIED"
  },
  "expectedFailureMode": "SPECIFIC_FAILURE_MODE",
  "mustNotProduce": ["PASS", "CAVEAT"],
  "allowedSecondaryGates": [],
  "executionEvidencePath": "negative-fixtures/transcripts/nc-scoring-gate-XXX.txt",
  "executionEvidenceFormat": "plaintext",
  "expectedEvidenceContent": [
    "SCORING_SYSTEM_GATE triggered",
    "SPECIFIC_FAILURE_MODE",
    "outcome: FAIL"
  ],
  "forbiddenEvidenceContent": [
    "UNEXPECTED_PASS",
    "outcome: PASS"
  ],
  "verifierConfirmationRequired": true,
  "verifierModule": "negative-control-check",
  "confirmationCriteria": [
    "Fixture execution recorded in AGENT_PROGRESS.jsonl as negative_control_executed",
    "SCORING_SYSTEM_GATE triggered with correct failure mode",
    "Outcome is FAIL, not PASS",
    "Failure class is P0"
  ]
}
```

---

## Machine-Readable Execution Result Format

```json
{
  "fixtureId": "nc-scoring-gate-XXX",
  "executedAt": "2026-06-24T12:00:00.000+08:00",
  "fixturePattern": "PATTERN_NAME",
  "injectedFault": {
    "artifact": "negative-fixtures/artifacts/FILENAME.json",
    "violation": "VIOLATION_TYPE",
    "scoreValue": 0.85,
    "description": "Injected score-based PASS verdict"
  },
  "verifierResult": {
    "verifierName": "no-generic-fail-check",
    "targetGate": "SCORING_SYSTEM_GATE",
    "outcome": "FAIL",
    "failureMode": "SCORE_BASED_VERDICT",
    "priority": "P0"
  },
  "fixtureResult": {
    "expectedOutcome": "FAIL",
    "actualOutcome": "FAIL",
    "targetGateTriggered": true,
    "correctFailureMode": true,
    "unexpectedPass": false,
    "scoreCorrectlyBlocked": true,
    "overallResult": "PASS"
  }
}
```

---

## Minimum Required Fixtures for SCORING_SYSTEM_GATE

To achieve adequate negative coverage, the following fixtures are the minimum set:

| Fixture ID | Pattern | What It Tests |
|---|---|---|
| `nc-scoring-gate-001` | Direct Score-Based PASS | Score field in verdict triggers gate |
| `nc-scoring-gate-002` | High Score Masking P0 | Aggregate score hides P0 failure |
| `nc-scoring-gate-003` | Score Caveats Hard Floor | Score downgrades P0 to CAVEAT |
| `nc-scoring-gate-004` | Self-Reported Score | Self-reported score treated as evidence |

All four must be executed and pass their negative control checks for SCORING_SYSTEM_GATE coverage to be considered complete.

---

## Validation Checklist

- [ ] Fixture ID follows `nc-scoring-gate-NNN` convention
- [ ] `targetGate` is `SCORING_SYSTEM_GATE`
- [ ] `expectedFailureClass` is `P0`
- [ ] `faultManifest.violationType` is a recognized scoring violation
- [ ] `mustNotProduce` includes both `PASS` and `CAVEAT`
- [ ] Inject artifact is a valid JSON file with a `score` field
- [ ] Execution evidence path is unique and writable
- [ ] All four minimum fixtures are present
- [ ] Each fixture conforms to `negative-fixture-schema.json`

---

## References
- `SCORING_SYSTEM_GATE.md` — the scoring system gate rule
- `negative-fixture-template.md` — general negative fixture template
- `negative-fixture-schema.json` — JSON schema for fixture definitions
- `verifier-modules/no-generic-fail-check.md` — verifier that detects score-based verdicts
- `verifier-modules/negative-control-check.md` — verifier that validates negative controls
- `policies/decision-priority-policy.json` — P0 classification and no-caveat-downgrade rule
- `policies/evidence-acceptance-policy.json` — evidence hierarchy and prohibited evidence
