# Bulk Timestamp Policy — Phase 6C-O

> Establishes rules for detecting and handling bulk-generated event timestamps.
> Addresses CFP-011 findings from Phase 6C-N.

---

## Background

Phase 6C-N discovered that M-R2's RUN_STATE.jsonl contained 35 of 36 events with identical timestamps (`2026-06-20T01:00:00.0000000+08:00`). This occurred because the events were bulk-generated during a governance replay rather than recorded in real time during agent execution.

CFP-011 flagged this as a failure because identical timestamps prevent temporal causality verification.

---

## Policy

### Live Runs

For runs where agents execute in real time:

- **Threshold**: If >50% of consecutive event pairs have identical timestamps, the evidence gate returns **FAIL**.
- **Rationale**: In a live run, events should have monotonically increasing timestamps as agents claim, submit, and verify tasks. Bulk identical timestamps indicate events were generated outside the normal execution flow.
- **Detection**: `validate-evidence-gates.ps1` CFP-011 checks consecutive timestamp pairs. If identicalCount > totalPairs / 2, FAIL.

### Reconstructed / Replay Runs

For runs where events are rebuilt from governance artifacts (e.g., governance closure phases like M-R2):

- **Threshold**: Identical timestamps produce a **WARNING** (not FAIL) when the run is explicitly marked as reconstructed.
- **Marking**: A reconstructed run MUST include a `run.reconstructed = true` field in RUN_PLAN.json or run_initialized event.
- **Limitation**: Reconstructed runs **cannot claim live overlap timing**. Any timing-based claims (e.g., "task T-001 completed before T-002") are disallowed.
- **Detection**: If `run.reconstructed = true`, CFP-011 returns WARNING instead of FAIL for bulk timestamps.

### Explicit Exception

If a run has bulk timestamps but is NOT marked as reconstructed:

- CFP-011 returns **FAIL**.
- The final verdict aggregator treats this as a hard gate failure.

---

## Implementation

### CFP-011 Modified Logic (in validate-evidence-gates.ps1)

```
1. Read RUN_PLAN.json for "reconstructed" flag.
2. Count identical consecutive timestamps in RUN_STATE.jsonl.
3. If reconstructed == true AND identicalCount > 50%:
   → WARNING (not FAIL)
   → Detail: "Bulk timestamps accepted for reconstructed run; timing claims disallowed"
4. If reconstructed != true AND identicalCount > 50%:
   → FAIL
   → Detail: "Bulk timestamps in live run; events may not reflect real execution order"
```

### Fixture Coverage

| Fixture | Scenario | Expected |
|---------|----------|----------|
| CFP-011-bulk-timestamp-live-run-fail | Live run, 90% identical timestamps, no reconstructed flag | FAIL |
| CFP-011-bulk-timestamp-reconstructed-warning | Reconstructed run, 90% identical timestamps, reconstructed=true | WARNING (gate passes but with note) |

---

## Relationship to Other Policies

- **CFP-001 (Report/Evidence Contradiction)**: Bulk timestamps do not by themselves create report/evidence contradiction, but can mask timing-related contradictions.
- **CFP-002 (ExitCode/Verdict)**: Unaffected by timestamp policy.
- **Governance Replay**: Governance replays (like Phase 6C-M-R2) may legitimately use bulk timestamps but must declare themselves as reconstructed.

---

## Version History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-06-20 | Initial policy: live vs reconstructed distinction |