# STATE_DASHBOARD_REQUIREMENTS.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: I — State Dashboard Requirements
> Version: 1.0.0-requirements

---

## Purpose

Define what Factory state must be visible to the user. This is a **requirements document**, not a web app specification. The state dashboard may eventually be a CLI view, a web UI, or integrated into the Codex app — but NOT in this phase.

---

## State Categories to Surface

### 1. Project Status
| Field | Description |
|-------|-------------|
| Current Phase | Active phase name (e.g., FACTORY-DEFAULT-WORKFLOW-0) |
| Phase Status | ACTIVE / COMPLETED / BLOCKED |
| Bootstrap Status | Whether Bootstrap was run |
| Mode | Build Lite / Native Build Pro |
| Multi-Agent | Enabled / Disabled / Not Applicable |

### 2. Build State
| Field | Description |
|-------|-------------|
| Last Build | Timestamp of last build |
| Build Status | Success / Failed / Not Run |
| Artifact Path | Path to latest build output |

### 3. Agent State (if multi-agent)
| Field | Description |
|-------|-------------|
| Active Agents | Number and roles of active agents |
| Agent Ledger | Link to agent ledger |
| Last Handoff | Timestamp of last agent handoff |

### 4. Governance State
| Field | Description |
|-------|-------------|
| Last Verifier Run | Timestamp and result |
| Open Negative Controls | Count of failing controls |
| Phase Reports | Links to phase reports |
| Strategy Decisions | Links to strategy decision docs |

### 5. Cleanup State
| Field | Description |
|-------|-------------|
| Pending Cleanup Plan | Whether a cleanup plan exists |
| Cache Size | Approximate size of Factory cache |
| Last Cleanup | Timestamp of last cleanup execution |

---

## Non-Requirements (This Phase)

The following are explicitly NOT required in this phase:

- ❌ Web UI for state dashboard
- ❌ Real-time monitoring
- ❌ Database-backed persistence
- ❌ Graph visualization
- ❌ Alerting/notification system
- ❌ Multi-project dashboard

The state dashboard is a **CLI-queryable JSON structure** for now. Visualization may come in a future phase.

---

## CLI Query

```
factory state
```

Expected output: JSON blob with all state categories above.

## Future Consideration

If needed, the state dashboard can evolve into a web UI, but only after:
- FACTORY-STATE-DASHBOARD-0 (requirements validation)
- Real project validation confirms need
