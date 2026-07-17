# DRY18+ Required Factory Controls

**Governance:** `governance/harness-readiness/dry18-required-controls.md`  
**Effective:** All DRY18+ runs  
**Audit:** H9 meta verifier enforces these controls  
**Updated:** H9-P1 floor reconciliation

---

## DRY18+ Mandatory Complexity Floors

These are **mandatory minimums** — no DRY18+ candidate plan may PASS readiness below these floors:

| Metric | Mandatory Floor |
|---|---|
| Workers | >= 5 |
| JS Files | >= 45 |
| Named Exports | >= 85 |
| Cross-Worker Deps | >= 40 |
| Scenarios | >= 20 |
| External Packages | 0 (forbidden) |

**PASS_WITH_CAVEAT is NOT allowed for missing mandatory floors.**  
**FAIL_CONTRACT_DRIFT is the classification for floor violations.**

### Preferred Targets (above floor, aspirational)

| Metric | Preferred |
|---|---|
| Workers | 6-8 |
| JS Files | 50-60 |
| Named Exports | 100+ |
| Cross-Worker Deps | 50+ |
| Scenarios | 24-30 |

### Candidate Placeholder Examples (historical, pre-P1)

H9 initially used candidate values (3 workers, 6 JS files, etc.) as placeholder examples. These were **pre-P1 issue** values and do NOT represent current DRY18+ readiness. The H9-P1 floor reconciliation fixes this.

---

## 1. Pre-Spawn Validation (H7)

Every DRY18+ run must pass pre-spawn validation:
- Worker contracts must be locked before spawn
- `spawnAllowed=true` only after preSpawnValidationPassed=true
- Simplicity guard active: minimum source files, minimum exports, no shallow signals
- Verifier: `scripts/harness-spawn/*` + H7 pipeline

## 2. Post-Spawn Worker Output Validation (H8)

Every worker output must pass post-spawn contract enforcement:
- Owned file violations detected
- Forbidden file/dependency violations detected
- Missing required exports detected
- External package evidence rejected
- Freeze manifest verified
- Verifier: `scripts/harness-worker/verify-worker-output-contract.ps1`

## 3. Acceptance Evidence Integrity (H8-P1)

Every acceptance report must include:
- Transcript file
- Runner command and exit code
- Per-scenario assertions with assertionCount > 0
- Scenario-level input/expected/actual summaries
- evidenceRefs for traceability
- No hardcoded PASS patterns
- No skipped-as-PASS
- Verifier: `scripts/harness-acceptance/verify-acceptance-evidence-integrity.ps1`

## 4. Target-Gate Negative Controls (H8-P2)

Every target-gate negative must:
- Use live execution (no preclassified-only evidence)
- Include targetScenarioId in acceptance JSON
- Expected failed scenarios must match actual failures
- Non-target scenario failures classified as FAIL_HARNESS_NOISE
- Fault manifest with before/after hashes
- Transcript, command, exitCode all present
- Verifier: `scripts/harness-acceptance/verify-acceptance-evidence-integrity.ps1` (negative-target-gate mode)

## 5. Live Negative Control Builder (H6)

Every negative control must be built using:
- Copy-then-inject-one-bug methodology
- `build-live-negative-control.ps1` or equivalent
- Fault manifest with before/after SHA256 hashes
- Scenario adaptation governance (`verify-scenario-adaptation.ps1`)
- Verifier: `scripts/harness-negative/verify-live-negative-evidence.ps1`

## 6. External Reference Plan (H6-P1)

If `securitySensitiveDomain=true`:
- External reference plan required
- Authoritative references (OWASP or equivalent) with source URLs
- Factory-control mapping table
- No contradictory external-access claims
- Verifier: `scripts/phase6c-h6-p1-external-reference-reconciliation-verify.ps1`

## 7. Complexity Budget (H4) — H9-P1 Hardened

Every run must satisfy derived metrics against DRY18+ mandatory floors:
- Workers >= 5 (mandatory)
- JS files >= 45 (mandatory)
- Named exports >= 85 (mandatory)
- Cross-worker deps >= 40 (mandatory)
- Scenarios >= 20 (mandatory)
- Floor violations classified as FAIL_CONTRACT_DRIFT
- PASS_WITH_CAVEAT cannot hide missing mandatory floors
- Verifier: `scripts/harness-enforcement/verify-complexity-budget.ps1` + H9 readiness gate

## 8. Pipeline Controls

Required for every DRY18+ run:
- RUN_STATE.jsonl with sequential event log
- Worker freeze manifests with file hashes
- Integration patch ledger (integration-patches.jsonl)
- Report sanitizer (no control characters, no corrupted paths)
- Classifier with exact taxonomy values
- Audit contract with all detection gates enabled

## 9. Legacy Evidence Rejection

DRY18+ runs MUST NOT:
- Use legacy acceptance format (name/passed instead of scenarioId/status)
- Accept missing transcript/command/exitCode
- Accept preclassified-only negatives
- Reference DRY17-B-P1 acceptance format as acceptable

## 10. Verdict Taxonomy

All classifications must use exact taxonomy values:
PASS, PASS_WITH_CAVEAT, PASS_PENDING_RECONCILIATION,
FAIL_TARGET_GATE, FAIL_HARNESS_NOISE, FAIL_MISSING_EVIDENCE,
FAIL_CONTRACT_DRIFT, FAIL_CLOSED_EVIDENCE_MUTATION,
FAIL_VERIFIER_TAMPER, FAIL_INTEGRATION_UNRECORDED_PATCH

Generic FAIL is forbidden.

---

**H9-P1 enforces:** This governance document now includes mandatory complexity floors. Any DRY18+ run below floors is classified FAIL_CONTRACT_DRIFT.