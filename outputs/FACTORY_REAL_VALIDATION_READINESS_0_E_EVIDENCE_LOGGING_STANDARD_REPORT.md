# FACTORY-REAL-VALIDATION-READINESS-0 — Evidence and Logging Standard

**Date**: 2026-06-29
**Phase**: FACTORY-REAL-VALIDATION-READINESS-0
**Sub-step**: E

---

## 1. Required Evidence for Real Trial

Every real trial MUST capture the following:

| # | Evidence Item | Format | Evidence Level |
|---|---------------|--------|----------------|
| EV-01 | projectId | String (e.g., `PROJ-20260629-001`) | TIER-1 |
| EV-02 | Selected folder path | Absolute path | TIER-1 |
| EV-03 | Working copy path | Absolute path (or `NONE` if no working copy) | TIER-1 |
| EV-04 | Factory install path | Absolute path | TIER-1 |
| EV-05 | Command logs | Full command + stdout/stderr per step | TIER-1 |
| EV-06 | Exit codes | Integer per command | TIER-1 |
| EV-07 | Dashboard output | Full text of `factory dashboard` | TIER-3 |
| EV-08 | Agent ledger (if multi-agent) | Agent spawn/handoff/close records | TIER-2 |
| EV-09 | Cleanup plan output | Full text of `factory cleanup` | TIER-2 |
| EV-10 | Phase close report | Full text of phase-close output | TIER-1 |
| EV-11 | Verifier result | Verifier JSON path + verdict + check count | TIER-1 |
| EV-12 | Mount freshness before trial | freshnessStatus + freshnessCheckedAt | TIER-1 |
| EV-13 | Mount freshness after trial | freshnessStatus + freshnessCheckedAt | TIER-1 |
| EV-14 | Phase-ledger tail after phase close | Last 3 entries from phase-ledger.jsonl | TIER-1 |
| EV-15 | Direction guard nextRecommendedPhases after phase close | nextRecommendedPhases array | TIER-1 |
| EV-16 | Limitations and caveats | Free-text: what was NOT validated | TIER-2 |
| EV-17 | Before/after file inventory (if project changes) | `Get-ChildItem -Recurse` diff | TIER-2 |
| EV-18 | User approval record | Timestamp + user confirmation text | TIER-1 |

## 2. Evidence Level Classification (per Evidence Taxonomy)

| Level | Definition | Examples |
|-------|------------|----------|
| **TIER-1** | Direct, verifiable, machine-readable | Verifier JSON, exit codes, phase-ledger, command logs |
| **TIER-2** | Human-readable, requires interpretation | Cleanup plan, agent ledger, limitations, file inventory |
| **TIER-3** | Navigation/context only, not evidence | Dashboard output, snapshot, attach packet |
| **TIER-4** | Rejected: not usable as evidence | Compressed summaries, chat-only claims without file backing |

## 3. Evidence Storage

| Item | Path Pattern |
|------|-------------|
| Trial evidence | `governance/factory-validation/trials/{projectId}/` |
| Command logs | `{trialDir}/command-logs.jsonl` |
| Dashboard captures | `{trialDir}/dashboard-output.md` |
| Verifier results | `{trialDir}/verifier-result.json` |
| Before/after inventory | `{trialDir}/file-inventory-before.json`, `...after.json` |
| Phase close evidence | `governance/context-space/current/phase-ledger.jsonl` (appended) |

## 4. Logging Format

Command logs use JSONL:
```json
{"seq":1,"command":"factory bootstrap --path C:\\project","exitCode":0,"stdout":"...","stderr":"","timestamp":"2026-06-29T14:00:00+08:00"}
```

## 5. Evidence Integrity

- SHA256 of all evidence files recorded in trial manifest
- No evidence modified after phase close
- Evidence chain: trial → verifier → phase-ledger → direction guard → snapshot
