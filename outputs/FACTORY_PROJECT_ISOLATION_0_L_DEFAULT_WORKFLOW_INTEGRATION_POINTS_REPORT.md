# FACTORY-PROJECT-ISOLATION-0 — L: Default Workflow Integration Points Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: L — Default Workflow Integration Points
> Date: 2026-06-29

---

## Purpose

Identify where DEFAULT-WORKFLOW-0 protocols need to be updated to incorporate project isolation. These are **identified integration points**, not implemented changes — v0.5 zip is not modified.

---

## Integration Points

### 1. Default Startup Protocol (B of DEFAULT-WORKFLOW-0)

| Current | Required Update |
|---------|-----------------|
| Step 1: Check for `.codex-factory/` | Also check project identity in registry |
| Step 4: Factory Bootstrap | Bootstrap must resolve projectId before reading state |
| Step 6: Preflight | Preflight must detect cross-project context contamination |

### 2. Natural Language Cleanup Contract (G of DEFAULT-WORKFLOW-0)

| Current | Required Update |
|---------|-----------------|
| Step 1: Interpret the request | Must resolve projectId first |
| Step 2: Produce cleanup PLAN | PLAN must be scoped to current projectId only |
| Step 3: Require confirmation | Confirmation must show project name + id |

### 3. Project Path Handoff Contract (F of DEFAULT-WORKFLOW-0)

| Current | Required Update |
|---------|-----------------|
| 7 path categories | Add projectId to handoff template |
| UNKNOWN_WITH_REASON | Add project identity context |

### 4. Agent Ledger Contract (J of DEFAULT-WORKFLOW-0)

| Current | Required Update |
|---------|-----------------|
| Entry schema (10 fields) | Add required `projectId` field |
| Ledger location | Per-project ledger + global ledger distinction |

### 5. State Dashboard Requirements (I of DEFAULT-WORKFLOW-0)

| Current | Required Update |
|---------|-----------------|
| 5 state categories | Add active project identity display |
| CLI: `factory state` | Add foreign-context warnings to output |

---

## Implementation Timing

All integration points are deferred to:
- **FACTORY-V05-R1** (if CLI/packaging repair needed)
- Or a dedicated **FACTORY-INTEGRATION** phase

No v0.5 zip modification in this phase.
