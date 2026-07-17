# AGENT_LEDGER_ISOLATION.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: H — Agent Ledger Isolation
> Version: 1.0.0

---

## Purpose

Ensure agent ledger entries are strictly scoped to the project in which the agent operated. Agent outputs from one project must never be attributed to or mixed with another project's ledger.

---

## Isolation Rules

### Rule 1: projectId Required in Every Entry
```
Every agent ledger entry MUST include "projectId" field.
IF entry missing projectId → REJECT entry
   "Agent ledger entry rejected: missing projectId. Agent [id] must include project context."
```

### Rule 2: One Ledger Per Project
```
Each project has its own agent ledger file:
  {project.governancePath}/agent-ledger.jsonl

Global agent ledger (for Factory-internal agents):
  %USERPROFILE%\.codex-factory\agent-ledger.jsonl
```

### Rule 3: Ledger Write Gate
```
BEFORE writing to project ledger:
  Verify agent's active projectId matches ledger's projectId
  IF mismatch → REJECT
    "Agent [id] is assigned to project [A] but attempted to write to project [B] ledger."
```

### Rule 4: Cross-Project Agent Output
```
IF an agent produces output that references another project's artifacts:
  Mark as FOREIGN_REFERENCE in agent ledger
  Do NOT merge into current project's active state
  Log: "Agent [id] output references foreign project [id]."
```

### Rule 5: Agent Attribution Traceability
```
Agent ledger entries must be traceable:
- agent_id → spawn record
- projectId → project registry
- output_artifacts → verifiable paths

IF any link in chain is broken → mark entry with integrity WARNING
```

---

## Ledger Entry Schema (Updated)

```json
{
  "agent_id": "string",
  "agent_role": "string",
  "projectId": "uuid (REQUIRED — new field)",
  "timestamp": "ISO 8601",
  "phase": "string",
  "input_artifacts": ["path"],
  "output_artifacts": ["path"],
  "foreign_references": ["projectId or null"],
  "verdict": "PASS | FAIL | PARTIAL",
  "known_caveats": ["string"],
  "parent_agent": "agent_id or null",
  "handoff_to": "agent_id or null"
}
```

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Agent ledger entry missing projectId | Cannot attribute work |
| Agent from Project A writes to Project B ledger | Cross-contamination |
| Agent output from Project A attributed to Project B | Wrong attribution |
| Foreign references merged without marking | Silent contamination |
| Broken traceability chain | Cannot verify provenance |
