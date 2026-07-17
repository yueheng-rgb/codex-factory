# Closure Decision Protocol

## Pre-Closure Requirements
1. All hard floors met (verifier confirmed).
2. All negative controls executed and detected (0 gaps).
3. Cross-scope contamination resolved or classified non-blocking.
4. Agent registry updated (all agents closed or archived).
5. Progress events recorded for all phase transitions.

## Closure Steps
1. Run phase verifier → get gate results JSON.
2. Check no P0 failures → if found, DO NOT CLOSE.
3. Check no P1 caveats → if found, repair before closure.
4. Record P2 caveats in current-factory-state.json.
5. Update currentTrustedPhase.
6. Set allowedNextPhase.
7. Generate session-rotation-handoff.json.
8. Generate phase report.

## Anti-Closure Patterns (BLOCK)
- Closure with P0 failure unresolved.
- Closure with unmet hard floor.
- Closure with negative gaps > 0.
- Closure without verifier JSON.
- Closure with stale agents still active.
- Closure with manual PASS-only verdict.