# FACTORY-AGENT-2 Negative Controls Report

**Phase**: FACTORY-AGENT-2  
**Total Negatives**: 40  
**Executed**: 40  
**Detected**: 40  
**Gaps**: 0  

---

## Summary

All 40 negative controls were executed through the AGENT-2 runtime hardening suite. Every negative control triggered its intended gate. No unexpected passes occurred.

## Negative Categories

| Category | Count | Result |
|---|---|---|
| Capsule validation (N01-N08) | 8 | 8/8 DETECTED |
| Report validation (N09-N13) | 5 | 5/5 DETECTED |
| Handoff validation (N14-N17) | 4 | 4/4 DETECTED |
| Close receipt validation (N18-N21) | 4 | 4/4 DETECTED |
| Scope isolation (N22-N26) | 5 | 5/5 DETECTED |
| Evidence integrity (N27-N29) | 3 | 3/3 DETECTED |
| Anti-deception gates (N30-N34) | 5 | 5/5 DETECTED |
| Hardening boundaries (N35-N36) | 2 | 2/2 DETECTED |
| Boundary compliance (N37-N40) | 4 | 4/4 DETECTED |

## Key Results

- ✅ No UNEXPECTED_PASS
- ✅ No FAIL_TARGET_NOT_TRIGGERED
- ✅ No generic FAIL
- ✅ No expectedClass-only
- ✅ No manual PASS-only
- ✅ No preclassified-only

## Evidence

- `governance/factory-agent/factory-agent-2-negative-control-summary.json`
- `harness/runs/factory-agent-2-runtime-hardening-simulation/negative-controls/negative-suite-result.json`
