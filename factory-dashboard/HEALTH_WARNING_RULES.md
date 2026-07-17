# HEALTH_WARNING_RULES.md

> Part of: FACTORY-STATE-DASHBOARD-0
> Section: G — Health & Warning Rules
> Version: 1.0.0

---

## Purpose

Define when the dashboard shows 🟢 HEALTHY, 🟡 WARNING, or 🔴 CRITICAL for each state category. These rules drive the dashboard's diagnostic value.

---

## Health Indicators

| Indicator | Meaning | User Action |
|-----------|---------|-------------|
| 🟢 HEALTHY | Normal, no issues | None |
| 🟡 WARNING | Needs attention but not blocking | Review and decide |
| 🔴 CRITICAL | Blocking or corrupted | Must resolve before continuing |
| ⚪ UNKNOWN | Cannot determine | Investigate |

---

## Category Rules

### Project Identity
| Condition | Indicator |
|-----------|-----------|
| projectId valid, userConfirmedIdentity=true | 🟢 |
| userConfirmedIdentity=false | 🟡 |
| projectId missing | 🔴 |
| pathFingerprint mismatch | 🟡 |
| contentFingerprint mismatch | 🟡 |
| status = UNKNOWN_NEEDS_CONFIRMATION | 🟡 |
| status = DELETED | 🔴 |
| status = MIGRATED | 🟡 |

### Phase
| Condition | Indicator |
|-----------|-----------|
| currentPhase valid, verifier PASS | 🟢 |
| currentPhase valid, verifier FAIL | 🔴 |
| no verifier result | 🟡 |
| no phase report | 🟡 |
| lastPhaseClose > 7 days with no new phase | 🟡 |

### Blockers & Risks
| Condition | Indicator |
|-----------|-----------|
| No active blockers, no active risks | 🟢 |
| Active risks but no blockers | 🟡 |
| 1+ active blockers | 🔴 |
| Foreign blocker/risk detected | 🟡 (FOREIGN) |

### Memory & Context
| Condition | Indicator |
|-----------|-----------|
| Memory healthy, mount clean | 🟢 |
| Stale snapshot (> 7 days) | 🟡 |
| Foreign context detected | 🟡 |
| Memory corrupted/missing | 🔴 |
| Mount state inconsistent | 🔴 |

### Cleanup
| Condition | Indicator |
|-----------|-----------|
| No pending plan, last cleanup recent | 🟢 |
| Pending cleanup plan exists | 🟡 |
| Pending plan > 30 days | 🟡 |
| Cleanup state missing | ⚪ |

### Agent Ledger
| Condition | Indicator |
|-----------|-----------|
| All entries have projectId, verdict, outputs | 🟢 |
| Missing projectId in any entry | 🟡 |
| FAIL verdict in any entry | 🟡 |
| No integrator verdict | 🟡 |
| No entries (but multi-agent was used) | 🔴 |
| Anonymous agent entry | 🔴 |

### Paths
| Condition | Indicator |
|-----------|-----------|
| All paths exist, match projectId | 🟢 |
| Path missing | 🔴 |
| Path foreign | 🟡 (FOREIGN) |
| Path stale | 🟡 |
| Path tampered | 🟡 |

---

## Warning Escalation

If 3+ WARNING indicators → dashboard header shows 🟡 OVERALL: NEEDS ATTENTION
If 1+ CRITICAL indicators → dashboard header shows 🔴 OVERALL: BLOCKED

---

## Stale/Corrupt/Missing Detection

### Stale Detection
- Snapshot/attach packet older than 7 days → WARNING
- Phase report older than 30 days with no successor → WARNING
- Last cleanup > 90 days → WARNING

### Missing Detection
- Required path does not exist → CRITICAL
- Verifier result missing for current phase → WARNING
- Agent ledger missing when multi-agent enabled → WARNING

### Corrupt Detection
- JSON parse failure on any governance file → CRITICAL
- Schema validation failure → CRITICAL
- Fingerprint mismatch → WARNING

### Foreign Detection
- FOREIGN_PROJECT_CONTEXT marker found → WARNING
- Path belongs to different projectId → WARNING
- Agent ledger entry has foreign_references → WARNING
