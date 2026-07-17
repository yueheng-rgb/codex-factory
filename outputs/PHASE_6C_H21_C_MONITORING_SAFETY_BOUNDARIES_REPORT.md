# PHASE 6C — H21-C / Monitoring Safety Boundaries Report

**Phase**: H21-C
**Parent**: H21-B (Monitoring Prototype)
**Status**: PASS
**Generated**: 2026-06-24T19:57:30+08:00

---

## 1. Repairs Applied

### 1.1 Monitoring Script Syntax Bug (Line 28)
- **Bug**: `if(Test-Path "$pack\MANIFEST.json" -and (Test-Path "$pack\MANIFEST.sha256"))` — PowerShell parses the first `Test-Path` expression incorrectly due to missing parentheses around `-and`.
- **Fix**: Wrapped each `Test-Path` in parentheses: `if((Test-Path "$pack\MANIFEST.json") -and (Test-Path "$pack\MANIFEST.sha256"))`
- **Impact**: MANIFEST_SHA_MISMATCH check was silently skipped. Now correctly executes.

### 1.2 PLUGIN_PRODUCTION Context-Aware Matching
- **Bug**: Original regex `$pj -match 'EXPERIMENTAL' -and $pj -notmatch 'production.ready'` used fuzzy string matching. Could misclassify.
- **Fix**: Structured JSON field match: `'"scaffoldStatus"\s*:\s*"EXPERIMENTAL"'`
- **Rationale**: plugin.json declares `"scaffoldStatus": "EXPERIMENTAL"` with note "Not production-ready." This is the EXPECTED state — monitoring should PASS, not ALERT.
- **Detail output**: Now emits "EXPERIMENTAL status confirmed - expected" for transparency.

---

## 2. Safety Boundaries — Verified

All 10 boundaries from `h21-monitoring-safety-boundaries.json` are enforced:

| # | Rule | Mechanism | Enforced |
|---|------|-----------|----------|
| 1 | Automation alert != verifier PASS | Separate verdict enum: MONITORING_PASS/ALERT/ERROR | ✅ |
| 2 | Monitoring result != phase closure evidence | evidenceWeight: signal-only | ✅ |
| 3 | Monitoring must be readonly | doesNotMutateState: true in schema | ✅ |
| 4 | Cannot update currentTrustedPhase | No write path in monitoring script | ✅ |
| 5 | Cannot mark phase PASS | No phase verdict in monitoring output | ✅ |
| 6 | Cannot create final ZIP | No file creation in monitoring | ✅ |
| 7 | Cannot archive/modify evidence | Readonly access only | ✅ |
| 8 | Cannot suppress verifier FAIL | factoryctl result passed through verbatim | ✅ |
| 9 | Cannot convert alert to PASS | Separate verdict enum — no conversion path | ✅ |
| 10 | Can recommend action only | recommendedAction field is advisory | ✅ |

---

## 3. Re-run Verification

```
Monitoring verdict: MONITORING_PASS
Checks: 6/6 PASS, 0 alerts
  PHASE_MISMATCH: PASS (currentTrustedPhase=H20)
  FINAL_ZIP_EARLY: PASS (No ZIP)
  MANIFEST_SHA_MISMATCH: PASS (SHA256 validated)
  FACTORYCTL_FAIL: PASS (verdict=PASS)
  MISSING_HANDOFF: PASS
  PLUGIN_PRODUCTION: PASS (EXPERIMENTAL status confirmed - expected)
```

---

## 4. Verdict

**H21-C: PASS**. Both bugs repaired. All 10 safety boundaries verified. Monitoring prototype produces clean MONITORING_PASS. Ready for H21-D (negative controls).
