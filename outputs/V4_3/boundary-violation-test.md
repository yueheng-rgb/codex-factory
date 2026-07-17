# V4.3 Boundary Violation Test

## Test Setup
- Worker: rogue-backend
- Capsule: worker-backend-capsule.json (forbidden: src/*/auth*, config/secrets*)
- Handoff claims: `src/backend/auth.ts`, `src/backend/secrets.ts`, `src/frontend/Dashboard.tsx`

## Results

| File | Issue |
|------|-------|
| `src/backend/auth.ts` | VIOLATION: matches forbidden `src/*/auth*` |
| `src/backend/auth.ts` | OUT_OF_BOUNDS: not in allowed files |
| `src/backend/secrets.ts` | OUT_OF_BOUNDS: not in allowed files |
| `src/frontend/Dashboard.tsx` | OUT_OF_BOUNDS: not in allowed files |

## Verdict: BOUNDARY_VIOLATION_DETECTED_AND_REJECTED

The boundary enforcement correctly identified 4 violations:
1. Direct forbidden pattern match (src/*/auth*)
2-4. Files outside the worker's allowed directories

The rogue worker's handoff would be rejected by `validate-handoff` and would
block integration until the violations are resolved.

## Conclusion
Cross-window boundary enforcement is functional. Workers cannot silently
modify files outside their capsule boundaries.
