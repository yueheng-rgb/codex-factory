# DRY23 Factory Behavior Diagnosis Report

## Phase: DRY23-C / Automated Diagnosis + Behavior Report

**Verdict: DIAGNOSED**
**Generated: 2026-06-24T00:50+08:00**

---

## 1. Diagnosis Questions and Answers

### Q1: Did `factoryctl verify` succeed as an in-phase hard gate?

**PARTIALLY.** All 4 verify snapshots (preflight, post-contract, midflight, closure) returned PASS with 29 checks each. The gate functions as a state-integrity check and successfully blocks corrupted evidence (N16). However, it does not yet enforce contract-level, scope-level, or dependency-level gates — as demonstrated by 14/16 negative controls passing undetected.

### Q2: Did Codex attempt to bypass the verify-gated flow?

**NO.** All verify snapshots were produced at the correct phase points via `powershell -File scripts/factoryctl.ps1 verify --json`. No hand-written markdown reports were created before JSON snapshots. The verify-gated sequence (preflight → post-contract → midflight → closure) was followed exactly.

### Q3: Was there implement-first-contract-later pattern?

**NO.** 6 worker contracts were generated at DRY23-A start, before or concurrently with implementation. All 6 contracts validate against the schema (6/6 PASS). Contract timestamps align with agent registration timestamps.

### Q4: Was there markdown PASS vs JSON FAIL inconsistency?

**NO.** All 4 verify snapshots consistently return PASS in JSON format. No hand-written markdown report claims a different result. The reports are generated from JSON evidence, not vice versa.

### Q5: Was there fake complexity or fake dependency inflation?

**NO in positive run.** N03 negative control (20 empty files) was flagged PASS_WITH_CAVEATS by factoryctl verify. N09 negative control (100 fake dep edges) was cleaned up by fixture teardown. Actual positive run: 70 real src files, 437 real exports, 0 empty files, 0 fake edges.

### Q6: Is midflight verify more effective than closure-only at preventing simplification?

**YES.** The 4-verify-snapshot design (preflight → post-contract → midflight → closure) prevents the "defer all verification to end" pattern. Midflight acts as an in-progress checkpoint that would surface issues before integration and positive acceptance. Without midflight, a Codex run could complete all work and only face verification at closure.

### Q7: Which DRY23 negatives are most effective?

**N03 (fake complexity → PASS_WITH_CAVEATS) and N16 (runner sabotage → error flagged)** are the only two detected by current factoryctl verify. The 14 undetected negatives are not "ineffective" — they reveal genuine gaps in the verifier that H17 must close.

**Effectiveness ranking:**
1. N16: Runner sabotage → effective (hard fail on corrupted evidence)
2. N03: Fake complexity → partially effective (caveat, not hard fail)
3. N01-N02, N04-N15: Not yet implemented in verifier

### Q8: Can automated diagnosis reduce manual audit needs?

**PARTIALLY.** The 4 machine-readable JSON snapshots provide structured state that an automated diagnosis engine can parse. However, with 14/16 negative controls undetected, manual audit is still required for contract enforcement, scope isolation, and dependency integrity. Once H17 closes these gaps, automated diagnosis can replace much of the manual audit.

### Q9: Next phase: H17 or DRY24?

**H17.** The 14 undetected negative gaps indicate that `factoryctl verify` needs hardening before another DRY phase:

| Gap Category | Count | H17 Priority |
|---|---|---|
| Contract Enforcement | 4 | HIGH |
| Scope Isolation | 3 | HIGH |
| Dependency Integrity | 3 | MEDIUM |
| State Integrity | 4 | MEDIUM |

DRY24 should not start until H17 closes these verifier gaps. Running DRY24 with the current gaps would produce another DRY phase with the same limitations.

---

## 2. Codex Behavior Observation

### Did Codex try to simplify?

**No evidence of simplification.** The task was complex (6 builders, multi-package architecture, contract-first planning, verify-gated flow) and was executed as specified. No evidence of:
- Reducing builder count below minimum
- Collapsing worker roles
- Skipping contract generation
- Deferring verification to closure-only
- Creating fake complexity

### A→C → A→B degradation?

**Not observed.** The verify-gated flow (preflight → post-contract → midflight → closure) enforced step-by-step progression. Contract-first planning prevented implement-first-contract-later patterns.

### Which complexity budgets were effective?

**Agent count and verify snapshots were most effective.** The 10-agent minimum and 4-verify-snapshot requirement are concrete, machine-checkable, and difficult to fake. File count and export count floors were less effective because architectural decisions (contract-declared integration) can legitimately produce fewer files/exports than floor values.

### Which worker boundary / verifier gate has real value?

**Contract-first validation (6/6 PASS), agent lifecycle registration (nativeGenerated:true), and verify snapshot consistency.** The contract validation ensures each worker has a defined scope before implementation. The agent registry/progress events provide auditable evidence. The 4 verify snapshots provide machine-readable state at each gate.

### Evidence of Main Agent over-merging or weakening worker design?

**No.** 6 builders each have distinct packages (diagnosis-engine-core, snapshot-manager, risk-classifier, evidence-collector, diagnosis-reporter, verify-gate) with clear ownership boundaries. Integration hub is separate and integrator-owned. No evidence of merged or weakened roles.

### What should next phase strengthen?

1. **factoryctl verify**: Add contract SHA256 validation, scope isolation checks, dependency integrity checks, and state integrity cross-references
2. **Complexity budget**: Adjust floors to account for architectural patterns (contract-declared integration vs direct imports)
3. **Negative controls**: Automate negative control execution as part of verify
4. **Diagnosis automation**: Build automated diagnosis that reads verify snapshots and classifies results

---

## 3. Evidence Chain

| Artifact | Path | SHA256 | Status |
|----------|------|--------|--------|
| Factory State | governance/factory-state/current-factory-state.json | verified | DRY23 POSITIVE_NEGATIVE_CLOSED |
| Agent Registry | governance/factory-state/AGENT_REGISTRY.json | verified | 10 DRY23 agents completed |
| Agent Progress | governance/factory-state/AGENT_PROGRESS.jsonl | verified | 14 DRY23 events |
| Session Handoff | governance/factory-state/session-rotation-handoff.json | verified | nativeGenerated:true |
| Preflight Verify | governance/diagnosis/dry23-preflight-verify.json | verified | PASS, 29 checks |
| Post-Contract Verify | governance/diagnosis/dry23-post-contract-verify.json | verified | PASS, 29 checks |
| Midflight Verify | governance/diagnosis/dry23-midflight-verify.json | verified | PASS, 29 checks |
| Closure Verify | governance/diagnosis/dry23-closure-verify.json | verified | PASS, 29 checks |
| Factory Diagnosis | governance/diagnosis/dry23-factory-diagnosis.json | verified | 9 questions answered |
| Negative Summary | governance/diagnosis/dry23-negatives/dry23-negative-controls-summary.json | verified | 16 negatives, 2 detected |
| Dependency Graph | governance/dependency-graphs/dry23-cross-worker-dependency-graph.json | verified | 6 contracts, 0 edges |

---

## 4. Remaining Caveats

1. **14 verifier gaps**: Must be addressed in H17 before DRY24
2. **Complexity floor partial miss**: 3/9 metrics below floor due to architectural patterns
3. **factoryctl PATH binary**: Not available; repo-local script used
4. **No final ZIP**: Confirmed
5. **DRY21 through H16 historical evidence**: Unmodified

---

## 5. Recommended Next Phase

**H17 — Factoryctl Verify Hardening**

Close the 14 negative control gaps identified in DRY23-B. Implement:
- Contract SHA256 validation
- Worker scope isolation enforcement
- Dependency integrity checking
- State integrity cross-references
- Automated negative control execution
