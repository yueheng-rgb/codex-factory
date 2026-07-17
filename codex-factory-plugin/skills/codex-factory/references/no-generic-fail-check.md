# Verifier Module: no-generic-fail-check

## Metadata
- **Verifier ID**: `no-generic-fail-check`
- **Version**: 1.0.0
- **Phase**: H18
- **Category**: verdict-integrity
- **Priority**: P0 (Hard Floor)
- **nativeGenerated**: true

## Purpose
Detect and reject generic FAIL verdicts that do not reference a specific target gate. Enforce that every FAIL verdict names a concrete gate and is backed by a verifier result. Prohibit expectedClass-only, manual PASS-only, and preclassified-only verdicts.

## Target Gate
`NO_GENERIC_FAIL`

## Evidence Source
- **Primary**: All verifier result JSON files in scope
- **Secondary**: `AGENT_PROGRESS.jsonl` — verifier_fail events
- **Tertiary**: Phase-close report — aggregated verdicts

## Definitions
- **Generic FAIL**: A FAIL verdict with no `targetGate` field, or with a non-specific value like "generic", "misc", "other".
- **ExpectedClass-Only**: A FAIL verdict that only declares `expectedFailureClass` without naming a `targetGate`.
- **Manual PASS-Only**: A PASS verdict with no verifier result backing it (no `verifierName`, no `evidenceRefs`).
- **Preclassified-Only**: A verdict whose outcome was determined by a pre-existing classification rather than an active verifier check.

## Prohibited Verdict Patterns

| Pattern | Example | Why Prohibited |
|---|---|---|
| No `targetGate` | `{"outcome": "FAIL"}` | Cannot determine what failed. |
| Generic `targetGate` | `{"targetGate": "generic"}` | No specific gate to remediate. |
| `expectedClass` without gate | `{"expectedFailureClass": "P0"}` | No verifier gate named. |
| `manual` verdict | `{"outcome": "PASS", "source": "manual"}` | No automated evidence. |
| `preclassified` verdict | `{"outcome": "FAIL", "preclassified": true}` | Bypasses verifier. |
| Score-based verdict | `{"score": 0.3, "outcome": "FAIL"}` | SCORING_SYSTEM_GATE violation. |

## Check Logic

### Step 1: Collect All Verdicts
Scan all verifier result JSON files, AGENT_PROGRESS.jsonl verifier events, and the phase-close report for verdict objects.

### Step 2: Validate Each Verdict
For each verdict:
```
hasTargetGate       = verdict.targetGate is present AND non-empty AND not in ["generic", "misc", "other", "unknown"]
hasVerifierName     = verdict.verifierName is present (for PASS/FAIL)
hasEvidenceRefs     = verdict.evidenceRefs is non-empty array
notExpectedClassOnly = NOT (verdict has expectedFailureClass AND missing targetGate)
notManualOnly       = verdict.source != "manual"
notPreclassified    = verdict.preclassified is falsy
notScoreBased       = verdict.score is undefined

valid = hasTargetGate AND hasVerifierName AND hasEvidenceRefs AND notExpectedClassOnly AND notManualOnly AND notPreclassified AND notScoreBased
```

### Step 3: Classify Invalid Verdicts
- Missing targetGate → **FAIL: GENERIC_FAIL_NO_TARGET_GATE** (P0)
- Generic targetGate → **FAIL: GENERIC_FAIL_NON_SPECIFIC_GATE** (P0)
- ExpectedClass-only → **FAIL: EXPECTED_CLASS_ONLY** (P0)
- Manual-only → **FAIL: MANUAL_PASS_ONLY** (P0)
- Preclassified-only → **FAIL: PRECLASSIFIED_ONLY** (P0)
- Score-based → **FAIL: SCORE_BASED_VERDICT** (P0)

### Step 4: Aggregate
- All verdicts valid → **PASS**
- Any invalid verdict → **FAIL**

## PASS Criteria
- Every FAIL verdict names a specific, non-generic target gate.
- Every PASS verdict is backed by a verifier result with verifierName and evidenceRefs.
- Zero expectedClass-only verdicts.
- Zero manual-only verdicts.
- Zero preclassified-only verdicts.
- Zero score-based verdicts.

## FAIL Criteria
| Failure Mode | Priority | Description |
|---|---|---|
| `GENERIC_FAIL_NO_TARGET_GATE` | P0 | FAIL verdict with no targetGate field. |
| `GENERIC_FAIL_NON_SPECIFIC_GATE` | P0 | FAIL verdict with generic targetGate value. |
| `EXPECTED_CLASS_ONLY` | P0 | FAIL verdict with expectedFailureClass but no targetGate. |
| `MANUAL_PASS_ONLY` | P0 | PASS verdict with no verifier backing. |
| `PRECLASSIFIED_ONLY` | P0 | Verdict determined by preclassification, not active check. |
| `SCORE_BASED_VERDICT` | P0 | Verdict derived from computed score (SCORING_SYSTEM_GATE). |

## Machine-Readable Output Format
```json
{
  "verifierName": "no-generic-fail-check",
  "targetGate": "NO_GENERIC_FAIL",
  "executedAt": "2026-06-24T12:00:00.000+08:00",
  "outcome": "PASS|FAIL",
  "verdictsChecked": 12,
  "invalidVerdicts": [
    {
      "source": "path/to/verifier-result.json",
      "verdict": {
        "outcome": "FAIL",
        "expectedFailureClass": "P0"
      },
      "violation": "EXPECTED_CLASS_ONLY",
      "detail": "Verdict has expectedFailureClass but no targetGate."
    }
  ],
  "violationCounts": {
    "GENERIC_FAIL_NO_TARGET_GATE": 0,
    "GENERIC_FAIL_NON_SPECIFIC_GATE": 0,
    "EXPECTED_CLASS_ONLY": 1,
    "MANUAL_PASS_ONLY": 0,
    "PRECLASSIFIED_ONLY": 0,
    "SCORE_BASED_VERDICT": 0
  },
  "summary": "12 verdicts checked: 1 invalid (EXPECTED_CLASS_ONLY). FAIL.",
  "evidenceRefs": [
    "path/to/verifier-results/*.json",
    "path/to/AGENT_PROGRESS.jsonl"
  ]
}
```

## False Positive Risks
1. **Verdicts in progress**: A verdict being composed may temporarily lack targetGate. Mitigation: Only check finalized verdicts (those with `outcome` set and `finalized: true`).
2. **Legacy verdict format**: Older phases may have used different verdict formats. Mitigation: Apply this check only to H18+ phases; legacy verdicts are excluded.
3. **Caveat verdicts**: CAVEAT verdicts may have different field requirements than PASS/FAIL. Mitigation: This check applies to PASS and FAIL only; CAVEAT verdicts have relaxed requirements.

## Dependencies
- `evidence-acceptance-policy.json` — verdict evidence requirements
- `SCORING_SYSTEM_GATE.md` — score-based verdict prohibition
- `decision-priority-policy.json` — failure classification

## Integration
Invoked by `factoryctl verify --gate NO_GENERIC_FAIL`. Runs automatically during phase-close preflight. Cannot be skipped.
