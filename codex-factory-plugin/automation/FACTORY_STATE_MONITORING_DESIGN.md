# Factory State Monitoring — Automation Design

**Phase**: H20-D
**Status**: FEASIBILITY ASSESSMENT

## Feasibility Assessment

| Task | Feasibility | Classification |
|---|---|---|
| Periodic factoryctl verify | PARTIALLY_VERIFIED | automation_update tool exists; periodic scheduling not tested |
| Factory state drift monitoring | HYPOTHESIS | Requires state snapshot + diff; tool exists but integration untested |
| currentTrustedPhase mismatch detection | PARTIALLY_VERIFIED | Simple comparison task; automation capability not proven |
| Final ZIP early creation detection | PARTIALLY_VERIFIED | File existence check; automation trigger not tested |
| Manifest SHA mismatch detection | PARTIALLY_VERIFIED | Hash comparison; periodic run not tested |
| Stale agent monitoring | HYPOTHESIS | Requires AGENT_REGISTRY polling; automation interval untested |

## Safety Rules

1. Automation alert is NOT verifier PASS — it is a signal requiring human verification
2. Monitoring tasks must NOT mutate governance state without explicit phase
3. Automation cannot be closure evidence by itself
4. Automation status: HYPOTHESIS — requires H21+ stress testing

## Recommended Pattern

```json
{
    "task": "factory-state-drift-check",
    "schedule": "manual-only-until-H21",
    "action": "alert-only",
    "mutationAllowed": false,
    "verifierBacked": false
}
```
