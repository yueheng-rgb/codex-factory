# Integrator-Verifier Boundary Protocol

> Phase: H18 · Category: protocols · Stability: stable
> Depends on: BOUNDARY.md, role-model/agent-role-matrix.json, evidence-hierarchy.md

## Purpose

This protocol defines the hard boundary between the Integrator and Verifier roles.
These roles are intentionally adversarial: the Integrator modifies the codebase
through merges, while the Verifier inspects it readonly. This separation is the
primary defense against self-approved, unverified code entering the integration hub.

## Role Boundaries

### Integrator — Sole Merge Owner

The Integrator is the ONLY agent authorized to merge code into the integration hub.

**Integrator owns:**
- The integration hub scope (the merged codebase)
- The merge process and conflict resolution
- The dependency graph during integration
- Repair declarations on worker outputs
- The decision to accept or reject worker outputs for integration

**Integrator does NOT own:**
- Individual worker implementation scopes
- Verification of merge integrity (Verifier owns this)
- PASS/FAIL gate decisions (Verifier owns this)
- Architecture decisions (Architect owns this)
- Task assignment (Main Agent owns this)

### Verifier — Readonly Inspector

The Verifier is a readonly agent. It inspects, checks, and produces JSON verdicts.
It NEVER modifies code, configuration, or infrastructure.

**Verifier owns:**
- Gate checking against evidence
- PASS/FAIL JSON verdict production
- Evidence chain validation
- Gap detection in evidence
- Specific failure reason reporting

**Verifier does NOT own:**
- Code modification of any kind
- Implementation decisions
- Merge decisions (Integrator owns this)
- Repair implementation (Builder owns this)
- Closure decisions (Main Agent owns this)

## Interaction Protocol

### Phase 1: Worker Output Verification (Verifier)

Before integration begins, Verifier checks individual worker outputs.

**Inputs to Verifier:**
- Worker completion reports
- Worker transcripts
- Worker contract outputs
- Worker contract gate definitions

**Outputs from Verifier:**
- Per-worker JSON verdict (PASS/FAIL per gate)
- Evidence references for each verdict
- Gap report if evidence is insufficient

**Verifier MUST NOT:**
- Fix worker issues directly
- Suggest implementation changes (that is repair, not verification)
- Produce verdict without checking all evidence sources

### Phase 2: Integration (Integrator)

After all worker outputs have verifier PASS, Integrator begins merging.

**Integrator process:**
1. Confirm all worker contracts have verifier PASS
2. Confirm dependency order is satisfied
3. Merge worker outputs in dependency order
4. Resolve merge conflicts
5. Document all conflict resolutions
6. Declare any repairs needed
7. Produce integration integrity report

**Integrator MUST NOT:**
- Merge before verifier PASS on all worker outputs
- Modify worker implementation code during merge (declare repair instead)
- Self-verify merge integrity
- Bypass dependency ordering

**When Integrator finds issues:**
- Merge conflict -> resolve and document
- Worker output issue -> declare repair, request Builder rework
- Architecture violation -> flag to Architect, block merge
- Unresolvable conflict -> escalate to Main Agent

### Phase 3: Integration Verification (Verifier)

After Integrator completes the merge, Verifier checks integration integrity.

**Verifier checks:**
- All worker outputs present in integration hub
- Merge conflicts resolved and documented
- No worker code modified during merge (only merged)
- Dependency graph integrity maintained
- Integration hub compiles/builds (if applicable)
- No orphaned or duplicate artifacts

**Verifier outputs:**
- Integration integrity JSON verdict
- Per-check PASS/FAIL with evidence references
- Gap report for any missing documentation

**Verifier MUST NOT:**
- Fix integration issues
- Modify the integration hub
- Suggest merge strategies (that is Integrator domain)

## Conflict Resolution: When Integrator and Verifier Disagree

### Scenario 1: Verifier FAIL on worker output, Integrator wants to proceed

**Rule:** Verifier FAIL is authoritative. Integrator MUST NOT merge worker
output with active FAIL verdict.

**Resolution path:**
1. Integrator may request Verifier re-check with additional context
2. Verifier re-runs check and produces updated verdict
3. If still FAIL -> Integrator must declare repair or reject worker output
4. If Integrator believes FAIL is incorrect -> escalate to Main Agent with evidence
5. Main Agent may request Auditor review of the Verifier process
6. If Auditor finds Verifier error -> Verifier corrects verdict
7. If Auditor confirms Verifier -> Integrator must comply
8. Founder may override any gate with explicit acknowledgment

### Scenario 2: Verifier FAIL on integration integrity, Integrator disagrees

**Rule:** Same as above. Verifier FAIL on integration is authoritative.

**Resolution path:**
1. Integrator provides evidence that Verifier check is in error
2. Verifier re-runs with Integrator evidence
3. If still FAIL after re-check -> Integrator must repair integration
4. Escalation path same as Scenario 1

### Scenario 3: Integrator declares repair, Verifier checks the repair

**Rule:** Repairs are new work. They follow the same worker contract -> verifier
check cycle. Integrator does not self-verify repairs.

**Resolution path:**
1. Integrator declares repair with scope and requirements
2. Main Agent spawns repair worker (or reassigns original Builder)
3. Repair worker implements fix under repair contract
4. Verifier checks repair output
5. Verifier PASS -> Integrator may re-integrate
6. Verifier FAIL -> another repair cycle or replacement

### Scenario 4: Boundary dispute — is this verification or implementation?

**Rule:** If an action modifies code, files, or configuration, it is NOT verification.

**Examples of verification (Verifier may do):**
- Read files and compare to contract
- Run readonly checks (lint, type-check, build verification)
- Produce JSON verdicts
- Report gaps in evidence

**Examples of implementation (Verifier MUST NOT do):**
- Fix a failing test
- Correct a type error
- Add missing configuration
- Resolve a merge conflict
- Suggest specific code changes ("change line 42 from X to Y")

**If boundary is unclear:**
- Default to "do not modify" — if in doubt, it is not verification
- Escalate to Main Agent for boundary clarification
- Main Agent consults governance layer for ruling

## Anti-Patterns

- Integrator self-verifying merge -> governance violation
- Verifier suggesting code fixes -> boundary violation
- Integrator modifying worker code during merge -> should declare repair
- Verifier producing PASS without checking all evidence -> incomplete verification
- "The merge was trivial, no need to verify" -> ALL merges require verification
- Integrator and Verifier being the same agent -> separation of concerns violation

## Evidence Chain for Integration

Every integration must produce this evidence chain:

1. All worker verifier PASS verdicts (JSON)
2. Integrator merge report (conflict resolutions, repair declarations)
3. Integration hub state (post-merge codebase)
4. Integration integrity verifier PASS verdict (JSON)
5. Closure decision from Main Agent (references all above)

Missing any link in the chain invalidates the integration.

## Version

| Field | Value |
|--------|-------|
| Phase | H18 |
| Category | protocols |
| Stability | stable |
| Depends on | BOUNDARY.md, role-model/agent-role-matrix.json, evidence-hierarchy.md |
| Referenced by | main-agent-scheduling-protocol.md, worker-reporting-protocol.md |
