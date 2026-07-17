# FACTORY-REAL-VALIDATION-READINESS-0 — Safety Boundary Checklist

**Date**: 2026-06-29
**Phase**: FACTORY-REAL-VALIDATION-READINESS-0
**Sub-step**: D

---

## 1. Pre-Trial Safety Gates

Must ALL pass before any real trial begins:

| # | Gate | Check |
|---|------|-------|
| S-01 | Original project read-only | No files modified in original directory during trial |
| S-02 | Working copy required | All trial work happens in working copy, never original |
| S-03 | No server connection | No outbound HTTP/SSH/DB connections to production |
| S-04 | No deploy execution | No `deploy`, `publish`, `push`, `rsync` commands |
| S-05 | No production DB | No connection strings with production credentials |
| S-06 | No real secret printing | Secrets detected are masked, never echoed |
| S-07 | Cleanup PLAN only | `factory cleanup` outputs plan; DELETE requires explicit user confirmation |
| S-08 | Multi-agent requires user confirmation | Factory asks; user must explicitly approve before spawn |
| S-09 | Dashboard/snapshot/attach not evidence | TIER-3 classification enforced; verifier JSONs are TIER-1 |
| S-10 | Package QA not correctness proof | QA gate is hygiene check, not verification |
| S-11 | Security Gate not deploy permission | Security findings are informational, not deployment authorization |
| S-12 | Context ledger phase close required | Every phase must close with phase-ledger update |
| S-13 | Mount freshness before trial | Attach Packet must be FRESH before trial starts |
| S-14 | Mount freshness after trial | Attach Packet must be FRESH after phase close |
| S-15 | RISK-CS-002 acknowledged | TCM project excluded unless user certifies secret rotation complete |
| S-16 | User explicit approval recorded | Trial does not start without user consent |

## 2. During-Trial Safety Checks

| # | Check | If Violated |
|---|-------|-------------|
| D-01 | No file writes outside working copy | Stop trial; record defect |
| D-02 | No network connections to unapproved hosts | Stop trial; record defect |
| D-03 | No process spawns with elevated privileges | Stop trial; record defect |
| D-04 | No modification of v0.5-R1 package | Stop trial; record defect |
| D-05 | No modification of External Conversation Space except phase-ledger append | Stop trial; record defect |

## 3. Post-Trial Safety Verification

| # | Check | Evidence |
|---|-------|----------|
| P-01 | Original project unchanged | Before/after file inventory diff empty |
| P-02 | Working copy disposable | Can be deleted without affecting original |
| P-03 | No secrets in outputs | Forbidden content audit clean |
| P-04 | Phase-ledger appended correctly | New entry with verdict, timestamp, verifier reference |
| P-05 | Direction guard not stale | nextRecommendedPhases updated, no completed phases listed |
