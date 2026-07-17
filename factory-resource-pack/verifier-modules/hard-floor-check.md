# Verifier Module: Hard Floor Check

## Purpose
Verify that all complexity/quality hard floors are met before allowing closure.

## Checks
1. Source file count >= floor.
2. Export count >= floor.
3. Dependency graph edges >= floor.
4. Cross-worker dependencies >= floor.
5. Integration points >= floor.

## PASS Criteria
- All actual values >= corresponding floor values.
- Evidence is machine-counted from source files (not manually estimated).
- No empty/duplicate/comment-inflated files counted.

## FAIL Criteria
- Any actual < floor → BLOCKING FAIL (P0).
- Hard floor treated as caveat → BLOCKING FAIL.
- Evidence source is summary/estimate rather than machine count → BLOCKING FAIL.

## Output Format
`json
{"gate":"hard-floor-check","verdict":"PASS|FAIL","checks":[{...}]}
`
"@
    "factory-resource-pack\verifier-modules\negative-control-check.md" = @"
# Verifier Module: Negative Control Check

## Purpose
Verify that all negative controls were executed and detected with zero gaps.

## Checks
1. Total negatives = executed.
2. Executed = detected.
3. Gaps = 0 (detected - total = 0).
4. No UNEXPECTED_PASS.
5. No FAIL_TARGET_NOT_TRIGGERED.
6. No generic FAIL.
7. No expectedClass-only.
8. No manual PASS-only.
9. No preclassified-only.

## PASS Criteria
- All 9 checks pass.
- Missing negative execution → FAIL.
- Negative designed but not executed → FAIL.

## Output Format
`json
{"gate":"negative-control-check","verdict":"PASS|FAIL","checks":[{...}],"gaps":0}
`
"@
    "factory-resource-pack\verifier-modules\scope-isolation-check.md" = @"
# Verifier Module: Scope Isolation Check

## Purpose
Verify that workers did not write outside their owned scopes.

## Checks
1. Each worker-modified file is within worker's declared scope.
2. No builder wrote to integrator-owned integration-hub files.
3. No builder wrote to another builder's owned scope.
4. No verifier wrote to any implementation scope.
5. Integrator is sole merge owner for integration hub writes.

## PASS Criteria
- All file modifications by workers match declared scopes.
- Cross-scope writes are explicitly declared as integration handoffs.
- Contamination classified and repaired before closure if found.

## Output Format
`json
{"gate":"scope-isolation-check","verdict":"PASS|FAIL","violations":[...]}
`
"@
    "factory-resource-pack\verifier-modules\no-generic-fail-check.md" = @"
# Verifier Module: No Generic FAIL Check

## Purpose
Verify that no verdict uses ambiguous or evidence-free failure classifications.

## Checks
1. No "FAIL" without target gate identifier.
2. No "expectedClass-only" (expected result without actual execution).
3. No "manual PASS-only" (human assertion without verifier JSON).
4. No "preclassified-only" (label assigned before execution).
5. Every FAIL references a specific gate and evidence path.

## PASS Criteria
- All 5 checks pass.
- Generic FAIL found → BLOCKING FAIL.
- ExpectedClass-only found → BLOCKING FAIL.

## Output Format
`json
{"gate":"no-generic-fail-check","verdict":"PASS|FAIL","issues":[...]}
`
"@
    "factory-resource-pack\verifier-modules\session-rotation-readiness-check.md" = @"
# Verifier Module: Session Rotation Readiness Check

## Purpose
Verify that the Factory is ready for session rotation (new Codex window).

## Checks
1. session-rotation-handoff.json exists.
2. Handoff SHA256 matches source evidence.
3. current-factory-state.json is not stale.
4. factoryctl verify --json returns PASS.
5. No unsafe stale agents remain open.
6. allowedNextPhase is set and valid.

## PASS Criteria
- All 6 checks pass.
- Missing handoff → FAIL.
- Stale state → FAIL.
- Stale agents → FAIL.

## Output Format
`json
{"gate":"session-rotation-readiness-check","verdict":"PASS|FAIL","checks":[{...}]}
`
"@
    "factory-resource-pack\session-rotation\session-rotation-protocol.md" = @"
# Session Rotation Protocol

## When to Rotate
1. Context compression detected 2-3 times in current session.
2. Phase closure complete (currentTrustedPhase advanced).
3. User explicitly requests new session.
4. Factory state becomes stale or inconsistent.

## Pre-Rotation Checklist
1. Run factoryctl verify.
2. Verify session-rotation-handoff.json SHA256.
3. Check no unsafe stale agents.
4. Update AGENT_REGISTRY.json with all agent states.
5. Update AGENT_PROGRESS.jsonl with latest events.
6. Set allowedNextPhase.

## Post-Rotation Checklist
1. Run factoryctl verify in new session.
2. Check currentTrustedPhase matches handoff.
3. Verify no evidence drift.
4. Close stale agents from previous session.

## Handoff Contents
- current-factory-state.json snapshot.
- AGENT_REGISTRY.json.
- AGENT_PROGRESS.jsonl tail (last 20 events).
- Verifier result JSON.
- Allowed next phase.
- SHA256 of all source evidence.