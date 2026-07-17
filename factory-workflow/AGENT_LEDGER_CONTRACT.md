# AGENT_LEDGER_CONTRACT.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: J — Agent Ledger Contract
> Version: 1.0.0

---

## Purpose

Define what every agent (main or sub-agent) must record in the agent ledger. The ledger provides traceability, debugging support, and responsibility attribution — preventing anonymous multi-agent output.

---

## Ledger Entry Schema

Every agent action that produces output must record:

```json
{
  "agent_id": "string",
  "agent_role": "Architect | Backend Worker | Frontend Worker | Integrator | QA | Main",
  "timestamp": "ISO 8601",
  "phase": "FACTORY-XXX-N",
  "input_artifacts": ["path1", "path2"],
  "output_artifacts": ["path3", "path4"],
  "verdict": "PASS | FAIL | PARTIAL",
  "known_caveats": ["caveat1", "caveat2"],
  "parent_agent": "agent_id or null",
  "handoff_to": "agent_id or null"
}
```

---

## Ledger Fields

| Field | Required | Description |
|-------|----------|-------------|
| `agent_id` | Yes | Unique identifier from spawn or self-assigned |
| `agent_role` | Yes | Role from Multi-Agent Role Profile |
| `timestamp` | Yes | When the action completed |
| `phase` | Yes | Current Factory phase |
| `input_artifacts` | Yes | Paths of artifacts consumed |
| `output_artifacts` | Yes | Paths of artifacts produced |
| `verdict` | Yes | PASS / FAIL / PARTIAL |
| `known_caveats` | Yes | Known limitations (empty array if none) |
| `parent_agent` | No | Parent agent ID (null for main agent) |
| `handoff_to` | No | Agent this work was handed off to |

---

## Ledger Location

```
governance/factory-workflow/agent-ledger.jsonl
```

One JSON object per line (JSONL format for append-only integrity).

---

## Ledger Integrity Rules

| Rule | Enforcement |
|------|------------|
| Append-only | New entries append, never modify existing |
| Immutable | Once written, entry cannot be changed |
| Every agent writes its own entries | No agent writes for another |
| Timestamps must be monotonic | Newer entries have >= timestamps |
| Output artifacts must exist | Verifier checks paths exist |

---

## Integrator Acceptance/Rejection

The Integrator agent (or Main agent in single-agent mode) must review the ledger and record:

```json
{
  "integrator_verdict": "ACCEPT | REJECT",
  "reviewed_entries": ["agent_id_1", "agent_id_2"],
  "rejection_reasons": ["reason1"],
  "failure_attribution": "agent_id or NONE"
}
```

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Agent ledger omitted | No traceability |
| Agent outputs anonymous | Cannot attribute work |
| No failure attribution | Cannot debug |
| Ledger entries modified after write | Integrity violation |
| Agent writes entries for another agent | Attribution fraud |
