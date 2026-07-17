# STATE_DASHBOARD_DATA_MODEL.md

> Part of: FACTORY-STATE-DASHBOARD-0
> Section: B — Dashboard Data Model
> Version: 1.0.0

---

## Purpose

Define the unified data model for the Factory state dashboard. Every field here is surfaced to the user via CLI, Markdown, or JSON output.

---

## Dashboard Fields

### Identity
| # | Field | Source |
|---|-------|--------|
| 1 | `projectId` | Project registry |
| 2 | `projectName` | Project registry |
| 3 | `projectStatus` | Project registry (ACTIVE/PAUSED/ARCHIVED/FROZEN/DELETED/MIGRATED/UNKNOWN_NEEDS_CONFIRMATION) |
| 4 | `rootPath` | Project identity |
| 5 | `workingCopyPath` | Project identity |
| 6 | `factoryInstallPath` | Project identity |
| 7 | `externalConversationSpacePath` | Project identity |
| 8 | `governancePath` | Project identity |
| 9 | `outputsPath` | Project identity |

### Phase
| # | Field | Source |
|---|-------|--------|
| 10 | `currentPhase` | Phase ledger |
| 11 | `lastPhaseClose` | Phase ledger |
| 12 | `latestVerifier` | Latest verifier result JSON |
| 13 | `latestPhaseReport` | Latest phase report MD |

### Blockers & Risks
| # | Field | Source |
|---|-------|--------|
| 14 | `activeBlockers` | Blocker records (current projectId only) |
| 15 | `activeRisks` | Risk records (current projectId only) |

### Gates
| # | Field | Source |
|---|-------|--------|
| 16 | `enabledGates` | Gate configuration |

### Memory & Context
| # | Field | Source |
|---|-------|--------|
| 17 | `memoryStatus` | Memory quality state |
| 18 | `cleanupStatus` | Cleanup state (pending plan, last executed) |
| 19 | `mountStatus` | Mount isolation state |

### Warnings
| # | Field | Source |
|---|-------|--------|
| 20 | `foreignContextWarnings` | FOREIGN_PROJECT_CONTEXT entries detected |
| 21 | `staleWarnings` | Stale snapshots/attachments |
| 22 | `missingEvidenceWarnings` | Missing CORE_EVIDENCE or phase reports |

### Agent Ledger
| # | Field | Source |
|---|-------|--------|
| 23 | `agentLedgerSummary` | Agent ledger summary (count, roles, last activity) |

### Recommendation
| # | Field | Source |
|---|-------|--------|
| 24 | `nextRecommendedAction` | Computed from current state |

---

## Health Indicators

Each field may have a health indicator:
- 🟢 **HEALTHY** — normal, no issues
- 🟡 **WARNING** — stale, foreign, or needs attention
- 🔴 **CRITICAL** — missing, corrupt, or blocking
- ⚪ **UNKNOWN** — cannot determine

---

## Schema

See: `factory-dashboard/schemas/state-dashboard.schema.json`
