# DRY-Phase Specification Template

> **Category**: phase-templates | **Stability**: stable | **Phase Type**: DRY (Delivery / Mission)
>
> Use this template to create a new DRY-phase specification. Copy, fill all sections, remove no sections.

---

## DRY-Phase Metadata

| Field | Value |
|-------|-------|
| **Phase ID** | DRY??—replace with actual phase number |
| **Parent Phase** | REQUIRED—must be completed and verified |
| **Phase Type** | DRY (Delivery / Mission) |
| **Owner Agent Role** | DRY?-Builder |
| **Scope** | Product delivery, feature completion, mission execution |
| **Start Condition** | Parent phase closure + verifier PASS + factoryctl verify clean |
| **Evidence Hierarchy** | Verifier result > Transcript > Registry entry > Progress event > Summary |

---

## Positive Mission Requirements

### Core Deliverables

List every deliverable the phase MUST produce. Each deliverable must be VERIFIABLE (binary: exists/does-not-exist, passes/does-not-pass).

| ID | Deliverable | Verification Method | Priority |
|----|------------|-------------------|----------|
| D-01 | (describe deliverable) | (how to verify it exists and works) | P0 |
| D-02 | (describe deliverable) | (how to verify it exists and works) | P0 |
| ... | ... | ... | ... |

### Feature Completeness

List every feature that must be implemented. Each feature must have an acceptance test.

| ID | Feature | Acceptance Criteria | Priority |
|----|---------|-------------------|----------|
| F-01 | (describe feature) | (binary acceptance criteria) | P0 |
| F-02 | (describe feature) | (binary acceptance criteria) | P0 |
| ... | ... | ... | ... |

### Integration Requirements

List all integration points that must be validated.

| ID | Integration | Validation Method | Priority |
|----|------------|-----------------|----------|
| I-01 | (describe integration) | (how to validate) | P0 |
| ... | ... | ... | ... |

---

## Negative Controls

Every DRY-phase MUST include negative controls that test failure modes. These prevent false closure.

### Required Negative Controls

1. **Deliverable Missing**: Remove a core deliverable — verifier must catch it
2. **Feature Regression**: Break a delivered feature — acceptance test must fail
3. **Integration Break**: Sever an integration point — validation must fail
4. **Evidence Corruption**: Corrupt a verifier result — system must reject
5. **Empty Artifact**: Replace a deliverable with empty file — verifier must flag
6. **Stale Agent**: Leave an agent `in_progress` — closure must be blocked

Each negative control MUST:
- Name the scenario and the break method
- Define expected behavior explicitly
- Record actual behavior
- State pass/fail of the negative control itself
- Be included in `NEGATIVE_CONTROL_REPORT.json`

### Negative Control Pass Criteria

A negative control PASSES when:
- Actual behavior MATCHES expected behavior
- The system correctly detects and reports the problem
- The system does NOT allow closure with the break in place

A negative control FAILS when:
- The system does NOT detect the break
- The system allows closure despite the break
- The system reports the break incorrectly

---

## Complexity Floors

Every DRY-phase MUST declare complexity floors. These are MINIMUM requirements that cannot be waived.

| Floor | Minimum | Measurement | Priority |
|-------|---------|------------|----------|
| Agent Count | Minimum number of worker agents spawned | Count from `AGENT_REGISTRY.json` | P0 |
| Progress Events | Minimum number of progress events recorded | Count from `AGENT_PROGRESS.jsonl` | P0 |
| Artifact Count | Minimum number of artifacts produced | Count from `ARTIFACT_CHECKLIST.json` | P0 |
| Verifier Runs | Minimum number of verifier executions | Count verifier result files | P1 |
| Transcript Length | Minimum transcript size (tokens/lines) | Measure transcript file(s) | P1 |
| Negative Controls | Minimum number of negative controls executed | Count from `NEGATIVE_CONTROL_REPORT.json` | P0 |
| Phase Duration | Minimum elapsed time for the phase | Timestamp delta in `CLOSURE.json` | P1 |

**Rule**: If any P0 complexity floor is unmet, the phase CANNOT close. No exceptions. No caveats.

---

## Diagnosis Report

Before closure, the Main Agent MUST produce a diagnosis report covering:

1. **Complexity Floor Verification**: All floors checked, all P0 floors met
2. **Agent Behavior Analysis**: Were agents productive? Any repeated failures?
3. **Verifier Effectiveness**: Did verifiers catch all known breaks?
4. **Negative Control Results**: Summary of all negative control outcomes
5. **Unresolved Issues**: P1/P2 items deferred with rationale
6. **Recommendations**: For next phase or for repair if needed

Diagnosis report format: `DIAGNOSIS_REPORT.md` (human-readable) + `DIAGNOSIS_REPORT.json` (machine-readable).

---

## POSITIVE_NEGATIVE_CLOSED Requirement

Per `SCORING_SYSTEM_GATE.md`, full mission closure requires `POSITIVE_NEGATIVE_CLOSED`:

- **POSITIVE**: All required deliverables, features, integrations VERIFIED as complete
- **NEGATIVE**: All negative controls executed, all expected behaviors confirmed
- **CLOSED**: Phase formally closed with `CLOSURE.json`, handoff generated, state updated

A phase with `POSITIVE` only (deliverables done, negative controls skipped) is INCOMPLETE.
A phase with `NEGATIVE` only (controls tested, deliverables partial) is INCOMPLETE.
Only `POSITIVE_NEGATIVE_CLOSED` = DONE.

---

## Handoff Requirements

Upon closure, the Main Agent MUST:

1. Generate `session-rotation-handoff.json` using `core/handoff/generate-handoff.ps1`
2. Verify handoff integrity using `core/handoff/handoff-verify.ps1`
3. Set `allowedNextPhase` in `CLOSURE.json` (list of valid next phases)
4. Ensure all agents are in terminal state (`completed`, `failed`, or `closed`)
5. Update `FACTORY_STATE.json` or equivalent state tracking

---

## Closure Criteria

### REQUIRED FOR CLOSURE

1. **All P0 Deliverables Complete**: Every P0 deliverable verified present and working
2. **All P0 Features Complete**: Every P0 feature passes acceptance test
3. **All P0 Integrations Validated**: Every P0 integration confirmed functional
4. **All Negative Controls Executed**: Every negative control run with results
5. **All P0 Complexity Floors Met**: No floor below minimum
6. **Verifier PASS**: `VERIFIER_RESULT.json` shows all P0 checks PASS
7. **Diagnosis Report**: `DIAGNOSIS_REPORT.md` and `.json` produced
8. **Handoff Generated and Verified**: `session-rotation-handoff.json` clean
9. **POSITIVE_NEGATIVE_CLOSED**: All three components satisfied
10. **No Stale Agents**: All agents terminal

### FORBIDDEN FOR CLOSURE

- ❌ Closure with unmet P0 deliverable (even if "almost done")
- ❌ Closure with negative control skipped (even if "obviously fine")
- ❌ Closure with complexity floor below minimum
- ❌ Scoring-as-gate (per SCORING_SYSTEM_GATE.md)
- ❌ Summary-as-evidence for any P0 claim
- ❌ Manual PASS without verifier JSON
- ❌ Stale agents still `in_progress`

---

## Verifier JSON Requirement

Same schema as H-phase. See `phase-templates/H-phase-template.md` for the full verifier JSON schema.

All DRY-phase verifier runs MUST produce machine-readable JSON with `nativeGenerated: true`.

---

## SCORING_SYSTEM_GATE Warning

This DRY-phase template adheres to `SCORING_SYSTEM_GATE.md`:

> No core module may emit PASS/FAIL based on a computed score. All gating must be verifier-based and evidence-backed.

Do NOT add scoring metrics, weighted scores, or score-based thresholds to this phase specification.
