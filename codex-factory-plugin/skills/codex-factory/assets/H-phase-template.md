# H-Phase Specification Template

> **Category**: phase-templates | **Stability**: stable | **Phase Type**: H (Hardening/Governance)
>
> Use this template to create a new H-phase specification. Copy, fill all sections, remove no sections.

---

## H-Phase Metadata

| Field | Value |
|-------|-------|
| **Phase ID** | H??—replace with actual phase number |
| **Parent Phase** | REQUIRED—must be completed and verified |
| **Phase Type** | H (Hardening / Governance) |
| **Owner Agent Role** | H?-Builder |
| **Scope** | Governance, hardening, policy, infrastructure |
| **Start Condition** | Parent phase closure + verifier PASS |
| **Evidence Hierarchy** | Verifier result > Transcript > Registry entry > Progress event > Summary |

---

## Preflight Checklist

Before any H-phase work begins, the Main Agent MUST confirm:

- [ ] Parent phase `CLOSURE.json` exists and is parseable
- [ ] Parent phase verifier result shows `"status": "PASS"` for all P0 checks
- [ ] No stale agents from parent phase (all agents: `completed`, `failed`, or `closed`)
- [ ] Session rotation handoff is current (`session-rotation-handoff.json` verified)
- [ ] `factoryctl verify` returns clean (no unmet floors, no negative gaps)
- [ ] All core schemas validate (policy JSONs, contract JSONs, evidence JSONs)
- [ ] `SCORING_SYSTEM_GATE.md` acknowledged by Main Agent in transcript

**Blocking Rule**: If any preflight item is unmet, the phase MUST NOT start. Record the blocking reason in `PREFLIGHT_FAILURE.md` and request parent phase repair.

---

## Artifact Checklist

Every H-phase MUST produce the following artifacts. Mark each as `REQUIRED` or `NOT_APPLICABLE` with justification.

| Artifact | Required? | Justification |
|----------|-----------|---------------|
| `CLOSURE.json` — machine-readable closure document | REQUIRED | |
| `VERIFIER_RESULT.json` — verifier output (all P0/P1/P2 checks) | REQUIRED | |
| `NEGATIVE_CONTROL_REPORT.json` — negative control execution results | REQUIRED | |
| `session-rotation-handoff.json` — handoff for next session | REQUIRED | |
| `PHASE_SPECIFICATION.md` — this phase spec (completed) | REQUIRED | |
| `ARTIFACT_CHECKLIST.json` — machine-readable artifact inventory | REQUIRED | |
| `COMPLEXITY_FLOORS.json` — complexity floor verification | CONDITIONAL—if complexity floors apply | |
| Policy documents (if governance phase) | CONDITIONAL—describe if applicable | |
| Schema documents (if schema phase) | CONDITIONAL—describe if applicable | |

---

## Verifier Requirements

### P0 Checks (BLOCKING — must all PASS)

These checks block phase completion. Failure at P0 = phase cannot close.

1. **Preflight Verifier**: All preflight items confirmed before work starts
2. **Artifact Completeness**: All required artifacts present, parseable, non-empty
3. **Parent Phase Integrity**: Parent phase artifacts intact, unmodified
4. **Boundary Compliance**: No BOUNDARY.md rule violated
5. **Evidence Integrity**: All evidence claims backed by verifier result or transcript, no summary-as-evidence
6. **Scoring Gate**: No scoring system used as PASS/FAIL gate (per SCORING_SYSTEM_GATE.md)
7. **Negative Control Completion**: All negative controls executed, results recorded
8. **No Stale Agents**: All agents in terminal state (`completed`, `failed`, or `closed`)

### P1 Checks (SHOULD PASS — failures documented with rationale)

1. **Transcript Completeness**: All agent actions have corresponding transcript entries
2. **Registry Consistency**: Agent registry matches actual agent states
3. **Progress Event Coverage**: Progress events cover all significant state transitions
4. **Schema Validation**: All produced artifacts validate against their schemas
5. **Cross-Reference Integrity**: All internal references resolve correctly

### P2 Checks (NICE TO HAVE — non-blocking observations)

1. **Documentation Quality**: All docs have clear headings, no placeholder text
2. **Diagnostic Coverage**: Diagnosis reports cover all anomaly categories
3. **Future-Proofing**: Artifact format compatible with next phase expectations

---

## Negative Control Requirements

Every H-phase MUST include negative controls that test:

1. **Preflight Failure**: What happens when preflight is intentionally broken?
   - Expected: Phase refuses to start, `PREFLIGHT_FAILURE.md` generated
2. **Artifact Missing**: What happens when a required artifact is removed?
   - Expected: Verifier catches the gap, reports P0 failure
3. **Scoring Substitution**: What happens when a scoring metric is used as a gate?
   - Expected: Verifier rejects (per SCORING_SYSTEM_GATE.md)
4. **Summary-as-Evidence**: What happens when a compressed summary replaces primary evidence?
   - Expected: Verifier flags evidence integrity violation
5. **Manual PASS**: What happens when a human manually marks a check as PASS without verifier run?
   - Expected: System rejects manual PASS, demands verifier JSON

Each negative control MUST:
- Name the scenario
- Describe the break step
- Record the expected behavior
- Record the actual behavior
- State whether actual matches expected
- Be included in `NEGATIVE_CONTROL_REPORT.json`

---

## Closure Criteria

### REQUIRED FOR CLOSURE

1. **Verifier PASS**: All P0 checks `"status": "PASS"` in `VERIFIER_RESULT.json`
2. **Negative Controls Complete**: All negative controls executed, all expected behaviors confirmed
3. **Artifact Completeness**: All required artifacts present, parseable, validated
4. **Session Rotation Handoff**: `session-rotation-handoff.json` generated and verified
5. **CLOSURE.json Generated**: Machine-readable closure with:
   - `phaseId`, `closureTimestamp`, `verifierRef`, `negativeControlRef`
   - `allowedNextPhase` (list of valid next phases)
   - `unresolvedCaveats` (P1/P2 items deferred)
   - `closedBy` (Main Agent role)
6. **No Unmet Floors**: All complexity floors met (if applicable)
7. **No Negative Gaps**: All negative control gaps resolved
8. **No Stale Agents**: All agents terminal

### FORBIDDEN FOR CLOSURE

- ❌ Manual PASS verdict (all PASS must be verifier-generated)
- ❌ `expectedClass`-only verdict (must include actual evidence)
- ❌ Generic FAIL without specific check reference
- ❌ Scoring system as gate (per SCORING_SYSTEM_GATE.md)
- ❌ Compressed summary as primary evidence
- ❌ Closure with unmet P0 items caveated as "acceptable"
- ❌ Closure with stale agents still `in_progress`

---

## Evidence Rules

Per `BOUNDARY.md` evidence hierarchy:

| Evidence Level | Acceptable as Primary? | Notes |
|---------------|----------------------|-------|
| Verifier result | ✅ Yes | Machine-readable, binary check |
| Transcript | ✅ Yes (corroborating) | Must reference specific entries |
| Registry entry | ⚠️ Supplementary | Only for state tracking claims |
| Progress event | ⚠️ Supplementary | Only for timeline claims |
| Summary | ❌ No | Untrusted unless backed by verifier |

---

## P0/P1/P2 Policy

Per `policies/` decision policies:

- **P0**: BLOCKING. Phase cannot close if any P0 check fails.
- **P1**: DOCUMENTED. P1 failures must be documented in `CLOSURE.json` under `unresolvedCaveats`. Main Agent may close if all P0 pass and P1 failures have rationale.
- **P2**: OBSERVED. Non-blocking. Recorded but do not prevent closure.

Hard floors (complexity, evidence) cannot be caveated below their threshold. A P0 floor failure is absolute.

---

## Verifier JSON Requirement

All PASS verdicts MUST reference a verifier JSON output. No manual PASS.

The verifier JSON MUST contain:
```json
{
  "verifierId": "string",
  "phaseId": "string",
  "runTimestamp": "ISO8601",
  "checks": [
    {
      "checkId": "string",
      "priority": "P0|P1|P2",
      "status": "PASS|FAIL",
      "evidenceRef": "string (file path or transcript location)",
      "actualValue": "string",
      "expectedValue": "string"
    }
  ],
  "summary": {
    "p0Passed": "number",
    "p0Failed": "number",
    "p1Passed": "number",
    "p1Failed": "number",
    "p2Passed": "number",
    "p2Failed": "number",
    "overallVerdict": "PASS|FAIL"
  },
  "nativeGenerated": true,
  "generatedBy": "string (agent role)"
}
```
