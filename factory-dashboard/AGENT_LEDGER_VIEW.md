# AGENT_LEDGER_VIEW.md

> Part of: FACTORY-STATE-DASHBOARD-0
> Section: E — Agent Ledger View
> Version: 1.0.0

---

## Purpose

Define how the agent ledger is displayed in the dashboard. Every agent's work must be visible, attributable, and auditable from `factory state --agents`.

---

## View Fields

### Per-Agent Entry (from agent-ledger.jsonl)
| Field | Display |
|-------|---------|
| `agent_id` | Always shown |
| `agent_role` | Always shown |
| `projectId` | Always shown |
| `timestamp` | Always shown |
| `phase` | Always shown |
| `input_artifacts` | Always shown |
| `output_artifacts` | Always shown (never omit) |
| `verdict` | PASS ✅ / FAIL ❌ / PARTIAL ⚠ |
| `known_caveats` | Always shown |
| `parent_agent` | Shown if not null |
| `handoff_to` | Shown if not null |
| `foreign_references` | Shown with FOREIGN_REFERENCE warning |

### Summary View
| Field | Display |
|-------|---------|
| Total entries | Count |
| Entries by role | Breakdown |
| PASS/FAIL/PARTIAL counts | Breakdown |
| Last activity | Timestamp |
| Integrator verdict | ACCEPT/REJECT (from integrator acceptance) |
| Failure attribution | Which agent (if any) |

---

## Display Format (`factory state --agents`)

```markdown
## 🤖 Agent Ledger

**Total Entries:** {count}
**By Role:** Architect: {n}, Backend: {n}, Frontend: {n}, Integrator: {n}, QA: {n}
**Verdicts:** ✅ {passCount} | ❌ {failCount} | ⚠ {partialCount}
**Last Activity:** {timestamp}
**Integrator Verdict:** {ACCEPT/REJECT/PENDING}

### Entries

| Agent | Role | Phase | Verdict | Outputs | Caveats |
|-------|------|-------|---------|---------|---------|
| {id} | {role} | {phase} | {verdict} | {count} files | {count} caveats |

### Agent Details

#### {agent_role} — {agent_id}
- **Time:** {timestamp}
- **Phase:** {phase}
- **Inputs:** {input_artifacts list}
- **Outputs:** {output_artifacts list}
- **Verdict:** {verdict}
- **Caveats:** {known_caveats list}
- **Parent:** {parent_agent or "None (root)"}
- **Handoff to:** {handoff_to or "None"}
- **Foreign Refs:** {foreign_references or "None"}
```

---

## Integrity Checks (in view)

| Check | Display if FAIL |
|-------|-----------------|
| Missing `projectId` | 🔴 "MISSING PROJECT ID — entry rejected" |
| Missing `agent_id` | 🔴 "ANONYMOUS AGENT — cannot attribute" |
| `output_artifacts` empty | 🟡 "NO OUTPUT FILES — agent produced nothing" |
| `verdict` missing | 🔴 "NO VERDICT — agent did not self-evaluate" |
| Integrator verdict missing | 🟡 "NO INTEGRATOR VERDICT — handoff incomplete" |
| Failure attribution missing | 🟡 "NO FAILURE ATTRIBUTION" |

---

## Schema

See: `factory-dashboard/schemas/agent-ledger-view.schema.json`
