# MULTI_AGENT_DECISION_GATE.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: D — Multi-Agent Decision Gate
> Version: 1.0.0

---

## Purpose

Define when and how Factory must ask the user whether to enable multi-agent orchestration. Multi-agent mode is powerful but must never start without explicit user confirmation.

---

## When Multi-Agent Question Is Required

The multi-agent question MUST be asked when ALL of the following criteria are met:

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | Project includes both server-side and client-side code | Yes |
| 2 | Project requires a database | Yes |
| 3 | Project has 3+ distinct modules/services | Yes |
| 4 | Project has user authentication/authorization | Yes |
| 5 | Estimated implementation scope > 5 files | Yes |

If 3+ of the above criteria are met → **Mandatory multi-agent question**.

## When Multi-Agent Question Is Optional

| # | Criterion | Behavior |
|---|-----------|----------|
| 1 | Project is fullstack but small (2-3 files) | Suggest but don't require |
| 2 | Project has independent frontend + backend | Suggest |
| 3 | User explicitly mentions "parallel" or "多 agent" | Ask immediately |

## When Multi-Agent Should NOT Be Suggested

| # | Criterion |
|---|-----------|
| 1 | Single-file change or fix |
| 2 | Documentation-only change |
| 3 | Configuration-only change |
| 4 | Small project (< 5 files estimated) |
| 5 | Simple CRUD without auth |

---

## The Multi-Agent Question Template

When the gate triggers, the following question MUST be presented:

> **Multi-Agent Decision Required**
>
> This project qualifies for multi-agent orchestration:
> - [reason 1]
> - [reason 2]
> - [reason 3]
>
> Multi-agent mode can parallelize independent workstreams (e.g., frontend + backend simultaneously) but requires explicit coordination.
>
> **Enable multi-agent mode?**
> - **Enable** — I will assign roles and coordinate parallel work
> - **Single agent** — I will work sequentially
> - **Decide later** — Re-ask at the next milestone

## Hard Rules

1. **Multi-agent MUST NOT start without user confirmation.**
2. **Multi-agent MUST NOT be the universal default.**
3. **Multi-agent MUST NOT bypass the user for large projects.**
4. **The question MUST be asked before any implementation code is written.**
5. **If user says "Decide later", re-ask at the next natural milestone.**
6. **If user declines multi-agent, do not re-ask for the same project phase.**

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Silently starting multi-agent for large projects | Violates user sovereignty |
| Making multi-agent the default without question | Over-engineering small projects |
| Assuming "large project = always multi-agent" | User may prefer single-agent control |
| Never asking the question for large projects | Misses parallelization opportunity |
