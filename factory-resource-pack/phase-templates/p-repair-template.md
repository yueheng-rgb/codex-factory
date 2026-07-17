# P-Repair Phase Specification Template

> **Category**: phase-templates | **Stability**: stable | **Phase Type**: P1/P2 Repair
>
> Use this template to create a P1 or P2 repair phase. Repair phases fix gaps found during verification of a parent phase.

---

## P-Repair Metadata

| Field | Value |
|-------|-------|
| **Phase ID** | P?-REPAIR—replace with actual repair phase ID |
| **Parent Phase** | REQUIRED—the phase whose gaps are being repaired |
| **Repair Priority** | P1 or P2 (P0 failures require parent phase re-execution, not repair) |
| **Gap Source** | Reference to `VERIFIER_RESULT.json` or `NEGATIVE_CONTROL_REPORT.json` that identified gaps |
| **Owner Agent Role** | P?-Repair-Builder |
| **Scope** | Targeted repair of specific gaps only—no scope creep |
| **Start Condition** | Parent phase closure (possibly with unresolved P1/P2) + gap inventory documented |

---

## Gap Identification

### Gap Inventory

List every gap to be repaired. Each gap must reference its source.

| Gap ID | Source | Priority | Description | Impact |
|--------|--------|----------|-------------|--------|
| G-01 | `VERIFIER_RESULT.json` check `xxx` | P1 | (describe the gap) | (what breaks if unfixed) |
| G-02 | `NEGATIVE_CONTROL_REPORT.json` NC `xxx` | P1 | (describe the gap) | (what breaks if unfixed) |
| ... | ... | ... | ... | ... |

### Gap Classification

- **P1 Gap**: Should fix. Documented in parent closure as unresolved. Phase can close with P1 gaps if rationale provided.
- **P2 Gap**: Nice to fix. Non-blocking observation. Phase can close without addressing.
- **P0 Gap**: BLOCKING. Parent phase should not have closed with P0 gaps. This indicates a verifier or closure defect. ESCALATE.

> ⚠️ **P0 Gap Rule**: If a P0 gap is found, the parent phase closure is suspect. Do NOT repair P0 gaps in a repair phase. Instead, escalate to Main Agent for parent phase re-evaluation.

---

## Repair Actions

For each gap, define the repair action:

| Gap ID | Repair Action | Verification Method | Expected Outcome |
|--------|-------------|-------------------|-----------------|
| G-01 | (specific fix) | (how to verify fix worked) | (what success looks like) |
| ... | ... | ... | ... |

### Repair Constraints

- Repair scope is LIMITED to identified gaps. No new features. No refactoring. No "while we're here" changes.
- Repair actions must be VERIFIABLE. Each fix must have a corresponding verification step.
- Repair actions must NOT introduce new gaps. Each fix is verified in isolation and then the full suite is re-run.
- Repair actions must NOT modify parent phase artifacts except to add repair documentation.

---

## Re-Verification

After all repairs are applied, re-run verification:

### Re-Verification Steps

1. **Gap-Specific Re-Verification**: For each repaired gap, run the check that originally failed and confirm it now passes
2. **Full Verifier Re-Run**: Run the complete parent phase verifier to ensure:
   - All previously-PASS checks remain PASS (no regressions)
   - All repaired gaps now PASS
3. **Negative Control Re-Run**: Re-run all negative controls to ensure:
   - Repairs did not break negative control detection
   - All negative controls still produce expected behaviors
4. **Evidence Refresh**: Update evidence references to point to new verifier runs

### Re-Verification Output

Produce a new `VERIFIER_RESULT.json` that:
- References the original parent phase verifier
- Shows all checks: original PASS checks confirmed, repaired gaps now PASS
- Has `nativeGenerated: true`
- Includes a `repairContext` block:
```json
{
  "repairContext": {
    "parentPhase": "string",
    "parentVerifierRef": "string",
    "repairedGaps": ["G-01", "G-02"],
    "repairTimestamp": "ISO8601",
    "originalGapCount": "number",
    "repairedGapCount": "number",
    "unresolvedGapCount": "number"
  }
}
```

---

## False Closure Prevention

Repair phases are high-risk for false closure. Apply these safeguards:

### Pre-Repair Safeguards

1. **Confirm Gap Is Real**: Reproduce the gap before repairing it. Do not fix phantom gaps.
2. **Confirm Gap Is In Scope**: Verify the gap is P1 or P2. P0 gaps require escalation.
3. **Confirm Parent Phase Closed**: Parent phase must be formally closed before repair begins.

### Post-Repair Safeguards

1. **Regression Check**: Full verifier re-run confirms no regressions
2. **No New Gaps**: Verifier confirms no new gaps introduced
3. **Evidence Integrity**: All new evidence is verifier-backed, not summary-based
4. **No Scope Creep**: Artifact diff confirms only targeted repairs, no extra changes

### Repair Closure Criteria

- [ ] All targeted gaps repaired and re-verified
- [ ] Full verifier re-run shows no regressions
- [ ] Negative controls re-run successfully
- [ ] `CLOSURE.json` updated with repair context
- [ ] Parent phase `CLOSURE.json` updated to reference repair
- [ ] Handoff updated if session rotation occurred

### Forbidden Patterns

- ❌ Repairing gaps that were never verified as real
- ❌ Expanding repair scope beyond identified gaps
- ❌ Changing parent phase artifacts beyond repair documentation
- ❌ Closing repair phase without full re-verification
- ❌ Repairing P0 gaps in a P1/P2 repair phase
- ❌ Using summary-based evidence for repair verification
- ❌ Manual PASS for any repaired gap

---

## Verifier JSON Requirement

Same schema as H-phase verifier. See `phase-templates/H-phase-template.md`.

Repair verifier runs additionally require the `repairContext` block shown above.

---

## SCORING_SYSTEM_GATE Warning

Per `SCORING_SYSTEM_GATE.md`: No scoring system may be used to determine repair completeness. All repair verification must be binary (gap fixed / gap not fixed), not scored.
