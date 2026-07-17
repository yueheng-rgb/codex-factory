# FACTORY-BUILD-PACK-STAGING-P7 — D: Clean User Workflow Trial

**Timestamp:** 2026-06-28T17:20:00+08:00

---

## WF-1: Simple Project (fresh-simple-project)

| Step | Command | Expected | Result |
|------|---------|----------|--------|
| 1 | `factory.ps1 install` | 3 modes, Build Lite default | ✅ |
| 2 | `factory.ps1 bootstrap` | 18/18 checks | ✅ |
| 3 | `factory.ps1 preflight` | Security Gate NOT triggered | ✅ |
| 4 | `factory.ps1 phase-close` | Ledger/snapshot/guard updated | ✅ |

---

## WF-2: Deployed-Trace (fresh-deployed-trace-project)

| Step | Command | Expected | Result |
|------|---------|----------|--------|
| 1 | `factory.ps1 install` | Same as WF-1 | ✅ |
| 2 | `factory.ps1 bootstrap` | 18/18 checks | ✅ |
| 3 | `factory.ps1 preflight` | **Security Gate TRIGGERED**, 6 blocking | ✅ |
| 4 | `factory.ps1 phase-close` | BLOCKED, no ZIP handoff | ✅ |

---

## WF-3: Long-Horizon (fresh-long-horizon-project)

| Step | Command | Expected | Result |
|------|---------|----------|--------|
| 1 | `factory.ps1 install` | Same as WF-1 | ✅ |
| 2 | `factory.ps1 bootstrap` | Context Space flagged | ✅ |
| 3 | `factory.ps1 preflight` | Context Space mounted | ✅ |
| 4 | `factory.ps1 phase-close` | Snapshot updated, guard written | ✅ |

---

**Verdict:** 3/3 workflows PASS. All gates trigger correctly.
