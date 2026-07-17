# FACTORY-REAL-VALIDATION-READINESS-0 — Failure and Repair Plan

**Date**: 2026-06-29
**Phase**: FACTORY-REAL-VALIDATION-READINESS-0
**Sub-step**: F

---

## 1. Failure Mode Catalog (13 Scenarios)

| # | Failure | Default Response | Repair Action |
|---|---------|-----------------|---------------|
| F-01 | Bootstrap fails | STOP. Record defect. Do not retry automatically. | Check Factory install integrity; re-run preflight; if persistent, create R1 repair issue |
| F-02 | CLI name mismatch | WARN. Record discrepancy. Continue if non-blocking. | Log actual vs expected CLI name; fix in R1 repair if persistent |
| F-03 | Dashboard fails | STOP. Record defect. | Check `.codex-factory/` integrity; verify phase-ledger is readable |
| F-04 | projectId mismatch | STOP. Record defect. Do not proceed. | Verify project identity file; check working copy vs original mapping |
| F-05 | Multi-agent decision not asked | WARN. Record gap. Continue. | Multi-agent is conditional; missing ask = context did not trigger gate |
| F-06 | Cleanup target ambiguous | STOP. Do not execute cleanup. | Output PLAN only; require user to specify target explicitly |
| F-07 | Phase close fails | STOP. Record defect. Do not mark phase complete. | Check phase-ledger writability; run recovery script; retry phase close |
| F-08 | Missing verifier | FAIL. Phase cannot close without verifier. | Run verifier; if verifier itself broken, create R1 repair issue |
| F-09 | Agent ledger incomplete | WARN. Record gap. Continue. | Missing agent records = evidence gap but not safety violation |
| F-10 | R1 docs confusing | WARN. Record feedback. Continue. | User feedback → R1 repair backlog; does not block validation |
| F-11 | Context ledger does not update | FAIL. Phase close blocked. | Run recovery script; verify phase-ledger path and permissions |
| F-12 | Direction guard becomes stale | FAIL. Phase close blocked. | Check if nextRecommendedPhases includes completed phases; run reconciliation |
| F-13 | Mount packet FRESH but source state stale | FAIL. Do not trust packet. | Cross-reference phase-ledger vs conversation-space; run ledger reconciliation if needed |

## 2. Default Response Protocol

```
IF safety boundary violated (S-01 through S-16):
    → STOP immediately
    → Record defect with full context
    → Do NOT patch silently
    → Create R1 repair issue
    → Do NOT continue to v0.6

IF non-safety failure (F-02, F-05, F-09, F-10):
    → WARN
    → Record gap
    → Continue if user confirms

IF context state stale/corrupt:
    → STOP
    → Run recovery plan (FACTORY-RECOVERY-0 protocol)
    → Re-run mount freshness check
    → Do NOT proceed until FRESH

IF verifier fails:
    → FAIL
    → Phase cannot close
    → Create R1 repair issue
```

## 3. Repair Issue Template

```json
{
  "issue_id": "R1-REPAIR-{seq}",
  "discovered_in": "FACTORY-REAL-VALIDATION-0",
  "failure_mode": "F-{NN}",
  "severity": "BLOCKING|WARNING",
  "description": "...",
  "evidence_paths": ["..."],
  "recommended_fix": "...",
  "status": "OPEN"
}
```

## 4. Recovery Plan Reference

When context state is stale or corrupt, invoke `FACTORY-RECOVERY-0` protocol:
1. Read trusted source hierarchy (phase-ledger > verifier JSONs > direction guard)
2. Cross-reference conversation-space against phase-ledger
3. Run `factory-context-ledger-reconciliation` if gaps found
4. Regenerate attach packet and snapshot
5. Re-verify mount freshness
