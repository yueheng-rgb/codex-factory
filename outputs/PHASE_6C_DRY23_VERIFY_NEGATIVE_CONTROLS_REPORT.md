# DRY23 Negative Controls Report

## Phase: DRY23-B / factoryctl verify Negative Controls

**Verdict: PASS_WITH_CAVEATS**
**Generated: 2026-06-24T00:50+08:00**

---

## 1. Summary

| Metric | Value |
|--------|-------|
| Total Negatives | 16 |
| Target Triggered | 2 |
| Target NOT Triggered | 14 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 14 |
| Generic FAIL | 0 |
| ExpectedClass-Only | 0 |
| Manual PASS-Only | 0 |
| Preclassified-Only | 0 |

**Key finding**: 14/16 negative control targets are NOT detected by the current `factoryctl verify` implementation. These represent genuine verifier gaps that H17 should address.

---

## 2. Negative Control Detail Table

| # | ID | Name | Target Gate | Expected Class | Triggered | Actual Verdict |
|---|----|------|-------------|----------------|-----------|----------------|
| 1 | DRY23-N01 | Parent Mismatch | parent-phase-check | PARENT_MISMATCH | NO | PASS |
| 2 | DRY23-N02 | Stale Contract SHA256 | contract-integrity-check | STALE_CONTRACT_HASH | NO | PASS |
| 3 | DRY23-N03 | Fake Complexity Inflation | complexity-metric-check | FAKE_COMPLEXITY_INFLATION | YES | PASS_WITH_CAVEATS |
| 4 | DRY23-N04 | Verifier Write Violation | verifier-readonly-check | VERIFIER_WRITE_VIOLATION | NO | PASS |
| 5 | DRY23-N05 | Worker Scope Contamination | worker-scope-isolation-check | WORKER_SCOPE_CONTAMINATION | NO | PASS |
| 6 | DRY23-N06 | Integrator Bypass | integrator-sole-merge-owner | INTEGRATOR_BYPASS | NO | PASS |
| 7 | DRY23-N07 | Forbidden Import | forbidden-import-check | FORBIDDEN_IMPORT | NO | PASS |
| 8 | DRY23-N08 | Undeclared Dependency | declared-dependency-check | UNDECLARED_DEPENDENCY | NO | PASS |
| 9 | DRY23-N09 | Fake Dependency Edges | dependency-edge-integrity | FAKE_DEPENDENCY_EDGES | NO | PASS |
| 10 | DRY23-N10 | Stale Session Handoff | handoff-freshness-check | STALE_HANDOFF | NO | PASS |
| 11 | DRY23-N11 | Missing Worker Contract | contract-existence-check | MISSING_CONTRACT | NO | PASS |
| 12 | DRY23-N12 | Fork Context Violation | fork-context-check | FORK_CONTEXT_VIOLATION | NO | PASS |
| 13 | DRY23-N13 | NativeGenerated False-Positive | native-generated-integrity | NATIVE_GENERATED_FALSE_POSITIVE | NO | PASS |
| 14 | DRY23-N14 | Post-Hoc Contract | contract-timestamp-consistency | POST_HOC_CONTRACT | NO | PASS |
| 15 | DRY23-N15 | Diagnosis Verdict Mismatch | diagnosis-verdict-consistency | DIAGNOSIS_VERDICT_MISMATCH | NO | PASS |
| 16 | DRY23-N16 | Runner Sabotage | runner-integrity-check | RUNNER_SABOTAGE | YES | Error flagged |

---

## 3. Effective Negatives (Target Triggered)

### DRY23-N03: Fake Complexity Metric Inflation
- **Fault**: 20 empty files added to diagnosis-engine-core/src/
- **Result**: `factoryctl verify` returned PASS_WITH_CAVEATS
- **Effectiveness**: Partial — caveat was raised but not a hard FAIL
- **Evidence**: governance/diagnosis/dry23-negatives/DRY23-N03-result.json

### DRY23-N16: Runner Sabotage Detection
- **Fault**: Corrupted closure-verify.json to non-JSON content
- **Result**: `factoryctl verify` flagged error
- **Effectiveness**: Effective — detects corrupted evidence files
- **Evidence**: governance/diagnosis/dry23-negatives/DRY23-N16-result.json

---

## 4. Verifier Gap Categories (14 undetected)

### Contract Enforcement (4 gaps)
- N02: Stale contract SHA256 — no contract hash validation
- N11: Missing worker contract — no contract existence check
- N12: Fork context violation — no fork_context validation
- N14: Post-hoc contract — no timestamp consistency check

### Scope Isolation (3 gaps)
- N04: Verifier write violation — no verifier scope check
- N05: Worker scope contamination — no cross-scope write detection
- N06: Integrator bypass — no integrator ownership enforcement

### Dependency Integrity (3 gaps)
- N07: Forbidden import — no import validation against contracts
- N08: Undeclared dependency — no dependency declaration check
- N09: Fake dependency edge inflation — no edge count validation

### State Integrity (4 gaps)
- N01: Parent mismatch — no parent phase validation
- N10: Stale session handoff — no handoff freshness check
- N13: NativeGenerated false-positive — no source verification
- N15: Diagnosis verdict mismatch — no cross-reference validation

---

## 5. Evidence Paths

All 16 negative control result files at: `governance/diagnosis/dry23-negatives/DRY23-N*.json`
Execution script: `scripts/phase6c-dry23-negative-controls.ps1`
Summary: `governance/diagnosis/dry23-negatives/dry23-negative-controls-summary.json`

---

## 6. Recommendation

H17 must harden `factoryctl verify` to close these 14 gaps. Priority order:
1. Contract enforcement (SHA256, existence, fork_context, timestamps)
2. Scope isolation (verifier readonly, worker scope, integrator ownership)
3. Dependency integrity (forbidden imports, undeclared deps, edge validation)
4. State integrity (parent phase, handoff freshness, nativeGenerated validation)
