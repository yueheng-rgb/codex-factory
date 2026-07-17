# FACTORY-AGENT-2 Runtime Simulation Report

**Generated**: 2026-06-26T03:00:00+08:00
**Phase**: FACTORY-AGENT-2 / Worker Capsule + Reporting Runtime Hardening
**Step**: H — Runtime Simulation

---

## Simulation Configuration

| Component | Count |
|---|---|
| Orchestrator | 1 |
| Architect | 1 |
| Builder | 2 |
| Integration Lead | 1 |
| Reviewer | 1 |
| Verifier | 1 |
| Integrity Checker | 1 |
| **Total agents** | **8** |

## Artifacts Generated

| Type | Valid | Invalid |
|---|---|---|
| Worker Capsules | 8 | 0 |
| Progress Reports | 8 | 1 |
| Handoffs | 2 | 1 |
| Close Receipts | 8 | 1 |
| Scope Definitions | 1 | 1 |
| Evidence Manifests | 1 | 1 |
| **Total** | **28** | **5** |

## Combined Suite Result

| Metric | Value |
|---|---|
| Verdict | AGENT_PROTOCOL_BLOCKED |
| Artifacts Checked | 33 |
| PASS | 28 |
| BLOCKED | 5 |
| ERROR | 0 |

## Blocked Artifacts (Expected)

| Artifact | Validator | Checks | Passed | Failed |
|---|---|---|---|---|
| Invalid progress report | validate-progress-report.ps1 | 13 | 11 | 2 |
| Invalid handoff | validate-worker-handoff.ps1 | 13 | 10 | 3 |
| Invalid close receipt | validate-agent-close-receipt.ps1 | 14 | 12 | 2 |
| Invalid scope (cross-write) | check-scope-isolation.ps1 | 6 | 4 | 2 |
| Invalid evidence (SHA mismatch + phantom) | check-evidence-integrity.ps1 | 6 | 2 | 4 |

## Key Findings

1. ✅ All 8 valid worker capsules pass validation (19/19 checks each)
2. ✅ All 8 valid progress reports pass validation
3. ✅ All 2 valid handoffs pass validation with SHA256
4. ✅ All 8 valid close receipts pass validation
5. ✅ Valid scope isolation case passes
6. ✅ Valid evidence integrity case passes (SHA256 matches)
7. ✅ Invalid progress report blocked (detail too short, markdown-only)
8. ✅ Invalid handoff blocked (empty files, no evidence)
9. ✅ Invalid close receipt blocked (empty evidence paths)
10. ✅ Invalid scope case blocked (forbidden scope write detected)
11. ✅ Invalid evidence case blocked (SHA mismatch + phantom file)
12. ✅ No product benchmark started
13. ✅ No v0.5 package created
14. ✅ All simulated agents either closed or blocked with reason
