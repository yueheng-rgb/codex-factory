# Simulation Scenario 5: Same path, changed fingerprint
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 5 of 10

## Setup
- Project P is registered with pathFingerprint = "abc123"
- Project root content has changed → fingerprint now "def456"
- User selects Project P folder

## Expected Behavior
1. Mount gate resolves path → finds Project P
2. Computes current pathFingerprint → "def456"
3. Mismatch detected
4. Status → UNKNOWN_NEEDS_CONFIRMATION
5. User asked: "Project path fingerprint changed. Is this the same project?"
6. If yes → userConfirmedIdentity = true, update fingerprint
7. If no → treat as new/unknown project

## Expected Verdict: ✅ PASS (confirmation required, not silently accepted)
