# SCORING_SYSTEM_GATE

## Rule
**No core module may emit PASS/FAIL based on a computed score.**

## Rationale
Scoring systems found in Factory history (risk-classifier, drift-severity, evidence-classification) demonstrated risks:
- Scores can replace transcript/verifier evidence
- High scores can mask P0 blocking issues
- Scores can downgrade hard floor failures to caveats
- Scores can come from Codex self-report without independent verification
- No scoring system had negative controls testing scoring accuracy

## Enforcement
- All gating must be verifier-based: binary check (met/not-met), not weighted score (0.0-1.0).
- Hard floors cannot be caveated below threshold.
- Machine-readable verifier JSON required for all PASS verdicts.
- This gate applies to all core and optional modules.

## Reference
H18-A0 Legacy Capability Inventory: governance/factory-state/h18-a0-legacy-capability-inventory.json