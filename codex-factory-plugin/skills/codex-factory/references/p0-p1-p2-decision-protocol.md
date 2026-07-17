# P0-P1-P2 Decision Protocol

> Phase: H18 · Category: protocols · Stability: stable
> Depends on: BOUNDARY.md, role-model/agent-role-matrix.json, evidence-hierarchy.md

## Purpose

This protocol defines the three-tier failure and caveat classification system
used for all gate failures, verifier findings, and closure decisions. Every
failure discovered during verification must be classified as P0, P1, or P2.
Misclassification is a governance violation.

## Classification Definitions

### P0 — Hard Floor Failure

A P0 failure is a non-negotiable blocker. It represents a condition that, if
unresolved, makes the work product fundamentally invalid or dangerous.

**P0 criteria (ANY of the following):**

1. **Evidence chain broken:** Missing registry entry, missing transcript,
   missing progress event, or missing contract output for any worker.

2. **Scope boundary violation:** Worker implemented outside contract scope,
   Main Agent wrote into worker scope, or Integrator modified worker code
   during merge.

3. **Verifier FAIL on a gate:** Any gate that receives a verifier FAIL verdict
   (not a caveat-worthy issue, but a hard failure of a defined gate).

4. **Separation of concerns violation:** Builder self-verified, Integrator
   self-verified merge, same agent performed conflicting roles on same module.

5. **Architecture violation:** Implementation contradicts architecture
   constraints in a way that affects system integrity.

6. **Data integrity risk:** Implementation could cause data loss, corruption,
   or security vulnerability.

7. **Founder intent violation:** Implementation contradicts explicit founder
   direction or scope definition.

8. **Protocol governance violation:** Any agent violated a MUST NOT clause
   in their role definition or a protocol.

9. **Missing artifact:** Contract output that was specified as required is
   entirely absent (not just incomplete).

10. **Compromised evidence:** Transcript edited after session, progress event
    fabricated, registry entry falsified.

**P0 consequences:**
- Closure is BLOCKED unconditionally
- Cannot be downgraded to P1 or P2
- Cannot be caveated
- Cannot be deferred to next phase
- Must be resolved before ANY closure decision
- Founder override is the ONLY way to proceed past a P0, and requires explicit,
  documented acknowledgment of the specific P0 being overridden

**P0 resolution:**
- Assign repair worker with explicit P0-targeting contract
- Full verifier re-check after repair
- Repair is itself subject to P0/P1/P2 classification
- P0 repair failure -> replacement protocol

### P1 — Phase-Blocking Caveat

A P1 caveat is a significant issue that must be resolved before the next phase
can begin, but does not block closure of the current phase.

**P1 criteria (ANY of the following):**

1. **Incomplete output:** Contract output exists but is partially incomplete
   (missing non-critical sections, incomplete documentation, partial test
   coverage below contract threshold).

2. **Known limitation with phase impact:** A known limitation that will
   definitely affect work in the next phase (e.g., API returns incomplete
   data that next-phase UI depends on).

3. **Stale progress:** Worker progress events show gaps or staleness that
   suggest the completion claim may not reflect full state, but evidence
   chain is otherwise intact.

4. **Dependency risk:** Output that passes current-phase gates but has
   characteristics that may cause issues for downstream dependents.

5. **Non-blocking architecture deviation:** Implementation deviates from
   architecture in a way that does not break current phase but creates
   technical debt or future constraints.

6. **Verifier caveat with phase impact:** Verifier identifies an issue that
   passes current gates but flags it as "will cause problems in next phase."

7. **Partial evidence:** Evidence exists for most but not all sub-components
   of a gate. Gate passes, but evidence is incomplete for specific items.

**P1 consequences:**
- Current phase closure MAY proceed (with P1 recorded)
- Next phase is BLOCKED until P1 is resolved
- Must be explicitly listed in closure decision
- Repair plan must be in place before next phase starts
- P1 may escalate to P0 if repair reveals deeper issues

**P1 resolution:**
- Repair contract generated for next-phase prep window
- Verifier re-check before next phase starts
- P1 not resolved before next phase -> next phase remains blocked
- Multiple unresolved P1s -> Main Agent must assess whether phase should be
  re-opened

### P2 — Non-Blocking Caveat

A P2 caveat is a known issue that is recorded for visibility but does not
block current or next-phase work.

**P2 criteria (ANY of the following):**

1. **Cosmetic issue:** UI alignment, naming inconsistency, minor formatting
   that does not affect functionality.

2. **Documentation gap:** Missing or incomplete documentation for non-critical
   components. Does not affect ability to use or integrate the output.

3. **Optimization opportunity:** Code works correctly but could be more
   efficient. No performance SLA is violated.

4. **Test coverage gap:** Additional tests would improve coverage but current
   coverage meets contract minimum.

5. **Future enhancement note:** A feature or improvement that would be nice
   to have but is out of scope.

6. **Known minor limitation:** A limitation that the worker acknowledges, with
   a clear workaround or acceptance rationale.

7. **Verifier observation:** Verifier notes something that does not fail any
   gate but is worth recording.

**P2 consequences:**
- Does NOT block current phase closure
- Does NOT block next phase
- Recorded in closure decision for transparency
- Tracked in caveat registry for future phases
- May be addressed in any future phase at discretion of Planner/Founder
- P2 may escalate to P1 if it becomes blocking for later work

**P2 resolution:**
- Optional: may be addressed in backlog
- Not required before next phase
- Accumulation of many P2s on same component -> Main Agent may flag for review

## Decision Flow

```
Verifier produces gate results
    |
    v
For each FAIL or finding:
    |
    +-- Matches P0 criteria? --Yes--> BLOCK CLOSURE
    |                                   No downgrade. No deferral.
    |                                   Repair required.
    |
    +-- Matches P1 criteria? --Yes--> RECORD P1
    |                                   Current phase may close.
    |                                   Next phase BLOCKED until repair.
    |
    +-- Matches P2 criteria? --Yes--> RECORD P2
                                        No blocking.
                                        Tracked for visibility.
```

## Classification Rules

### Rule 1: When in doubt, classify higher

If a finding could be either P1 or P2, classify as P1. If it could be P0 or
P1, classify as P0. Over-classification is safe; under-classification is
dangerous.

### Rule 2: No downgrading P0

A P0 finding CANNOT be downgraded to P1 or P2. The only way past a P0 is
resolution (repair -> verifier PASS) or founder override with explicit
acknowledgment. A P0 does not become P1 because "it is probably fine."

### Rule 3: Classification is the Main Agent responsibility

The Verifier reports findings but does not classify P0/P1/P2. The Main Agent
classifies findings based on this protocol. If classification is contested,
the Auditor reviews and the Founder has final say.

### Rule 4: Founder override must be explicit

If the Founder overrides a P0 or P1, the override must:
- Reference the specific P0/P1 finding
- State the rationale for override
- Be recorded in the progress ledger
- Be acknowledged by Main Agent in closure decision
- Not be treated as precedent for future overrides

### Rule 5: Cumulative P2s may trigger review

If a component accumulates more than 10 P2 caveats, the Main Agent should
flag it for review. Accumulation of P2s may indicate a systemic issue that
warrants P1 or P0 reclassification.

## Anti-Patterns

- "It is probably fine, let us call it P2" -> P0 under-classification
- "We will fix it next phase" for a P0 -> P0 cannot be deferred
- Calling everything P0 -> over-classification dilutes P0 meaning
- Calling everything P2 -> avoiding accountability
- "The founder will override it" -> do not pre-assume override
- Classifying without verifier input -> classification requires evidence

## Classification Examples

| Finding | Classification | Rationale |
|----------|----------------|-----------|
| Worker transcript missing | P0 | Evidence chain broken |
| Test coverage 70% (contract requires 80%) | P1 | Incomplete output |
| Variable name typo in non-public code | P2 | Cosmetic, no functional impact |
| Builder self-reported PASS | P0 | Separation of concerns violation |
| API response missing optional field | P1 | May affect next-phase UI |
| Log message format inconsistent | P2 | Cosmetic |
| Main Agent wrote 3 lines in worker file | P0 | Undeclared write into worker scope |
| Integration conflict not documented | P1 | Missing documentation |
| Comment has a typo | P2 | Cosmetic |
| Security vulnerability in auth code | P0 | Data integrity risk |

## Version

| Field | Value |
|--------|-------|
| Phase | H18 |
| Category | protocols |
| Stability | stable |
| Depends on | BOUNDARY.md, role-model/agent-role-matrix.json, evidence-hierarchy.md |
| Referenced by | main-agent-scheduling-protocol.md, integrator-verifier-boundary.md, claim-classification.md |
