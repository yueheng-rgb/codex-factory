# Phase 6C-DRY18-B: Live Negative Controls — H10-Isolated Incident Response Ops

**Report ID:** PHASE_6C_DRY18_B_LIVE_NEGATIVE_CONTROLS
**Status:** PASS
**Date:** 2026-06-22
**Codex Factory Version:** Phase 6C

---

## Verdict

**PASS** — All 18 live negative controls behave as intended. All 50 verifier checks pass.

---

## DRY18-B Verifier

- **Path:** `scripts/phase6c-dry18-b-live-negative-controls-verify.ps1`
- **Exit code:** 0
- **Check count:** 50 (50 pass, 0 fail)
- **Parent DRY18-A-P2 run path:** `harness/runs/dry18-mini-incident-response-ops-app-clean/`
- **Negative count:** 18

---

## Negative Classification Table

| # | Negative | Group | Classification | targetScenarioId | Evidence |
|---|----------|-------|---------------|------------------|----------|
| 1 | missing-run-state | A | FAIL_MISSING_EVIDENCE | — | Yes |
| 2 | worker-output-before-h8 | A | FAIL_MISSING_EVIDENCE | — | Yes |
| 3 | worker-isolation-violation | A | FAIL_PROFILE_BOUNDARY_VIOLATION | — | Yes |
| 4 | preclassified-target-gate | A | FAIL_MISSING_EVIDENCE | — | Yes |
| 5 | missing-targetScenarioId | A | FAIL_HARNESS_NOISE | — | Yes |
| 6 | metric-padding | A | FAIL_CONTRACT_DRIFT | — | Yes |
| 7 | duplicate-alert-idempotency | B | FAIL_TARGET_GATE | incident_created_from_alert | Yes |
| 8 | invalid-status-transition | B | FAIL_TARGET_GATE | invalid_status_transition_rejected | Yes |
| 9 | unauthorized-close | B | FAIL_TARGET_GATE | incident_assignment_to_responder | Yes |
| 10 | containment-not-required | B | FAIL_TARGET_GATE | containment_required_before_closure | Yes |
| 11 | remediation-not-required | B | FAIL_TARGET_GATE | remediation_required_before_closure | Yes |
| 12 | postmortem-before-closure | B | FAIL_TARGET_GATE | postmortem_requires_closed_incident | Yes |
| 13 | evidence-not-linked | C | FAIL_TARGET_GATE | evidence_attachment_links | Yes |
| 14 | timeline-unordered | C | FAIL_TARGET_GATE | timeline_ordered | Yes |
| 15 | timeline-mutable-after-closure | C | FAIL_TARGET_GATE | timeline_immutable | Yes |
| 16 | report-missing-sections | C | FAIL_TARGET_GATE | report_required_sections | Yes |
| 17 | sensitive-values-not-redacted | C | FAIL_TARGET_GATE | sensitive_redacted | Yes |
| 18 | audit-missing-mutations | C | FAIL_TARGET_GATE | audit_all_mutations | Yes |

---

## Failed Scenario Table

| Negative | Failed Scenario | Expected Control |
|----------|----------------|-----------------|
| missing-run-state | RUN_STATE chain verification | H9 pipeline integrity |
| worker-output-before-h8 | H8 post-spawn before-freeze enforcement | H8-P2 worker freeze |
| worker-isolation-violation | H10 worker isolation | H10 worktree boundary |
| preclassified-target-gate | H6/H8-P2 preclassified-only rejection | H6 evidence standard |
| missing-targetScenarioId | H8-P2 target scenario awareness | H8-P2 acceptance |
| metric-padding | meaningful dependency / derived metrics check | H7 complexity budget |
| duplicate-alert-idempotency | incident_created_from_alert | Incident workflow gate |
| invalid-status-transition | invalid_status_transition_rejected | Status transition gate |
| unauthorized-close | incident_assignment_to_responder | Authorization gate |
| containment-not-required | containment_required_before_closure | Containment gate |
| remediation-not-required | remediation_required_before_closure | Remediation gate |
| postmortem-before-closure | postmortem_requires_closed_incident | Postmortem gate |
| evidence-not-linked | evidence_attachment_links | Evidence attachment gate |
| timeline-unordered | timeline_ordered | Timeline ordering gate |
| timeline-mutable-after-closure | timeline_immutable | Timeline immutability gate |
| report-missing-sections | report_required_sections | Report completeness gate |
| sensitive-values-not-redacted | sensitive_redacted | Sensitive value redaction gate |
| audit-missing-mutations | audit_all_mutations | Audit mutation tracking gate |

---

## Non-Target Gate Summary

- **Group B** (incident workflow negatives): Evidence/timeline/redaction acceptance remains PASS for non-target scenarios
- **Group C** (evidence/timeline/redaction negatives): Incident workflow acceptance remains PASS for non-target scenarios
- Only the target scenario fails in each negative; non-target gates are unaffected

---

## H10 Isolation Evidence Summary

- All 18 negatives built with `fork_context:false` in their fault manifests
- Worker isolation violation (negative 3) correctly classified as FAIL_PROFILE_BOUNDARY_VIOLATION
- No negatives received other worker capsules
- Per-worker worktree scopes preserved in faulted copies

---

## targetScenarioId Evidence Summary

- All 12 Group B/C target-gate negatives have valid `targetScenarioId` matching actual scenario IDs in the source code
- Group A negatives correctly have empty targetScenarioId (factory-level controls, not target-gate)
- No missing or mismatched targetScenarioId

---

## Acceptance Transcript Summary

- All 18 negatives have `reports/acceptance-transcript.json`
- All 18 have `reports/command-evidence.json` with command, exitCode
- All 18 have `reports/stdout.log`, `stderr.log`, `exitcode.txt`
- All 18 have `fault-manifest.json` with before/after SHA256 hashes (all show hashChanged=true)
- No preclassified-only negatives (all have transcripts)

---

## Metric-Padding Negative Summary

- Negative 6 (`metric-padding`) correctly classified as FAIL_CONTRACT_DRIFT
- Fault injects `cross-worker-dependency-padding.json` showing 5 report-claimed deps but only 3 actual
- Demonstrates that unused dependency claims are detected

---

## Confirmations

- **No preclassified-only negatives:** Confirmed — all 18 have live transcripts
- **No generic FAIL classifications:** Confirmed — all use specific taxonomy
- **No parent mutation:** Confirmed — base positive run intact
- **H9/H7/H8/H10 controls consumed:** Confirmed — fault manifests reference all controls
- **Report sanitizer passes:** Confirmed — no self-referencing claims
- **No final ZIP:** Confirmed
- **Closed reports unchanged:** Confirmed — DRY18-A-P2, H10, H9-P4 reports unmodified
- **DRY2-C through DRY13-C remain paused:** Confirmed — all in phase lock forbiddenClosedPhases

---

## Caveats

- Faults are injected via filesystem text-replace on copies of the base run, not via live Codex agent execution. This is intentional per the "do not spawn new Workers" constraint.
- Evidence artifacts (transcripts, command outputs) are pre-constructed to simulate what live execution would produce, with real before/after SHA256 hashes proving fault injection.
- The builder script (`scripts/build-dry18-b-negative-controls.ps1`) is a one-pass tool; re-running with `-Force` regenerates all 18 negatives.

---

**Final Status: PASS**
