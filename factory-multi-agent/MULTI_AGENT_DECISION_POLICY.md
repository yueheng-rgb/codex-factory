# MULTI_AGENT_DECISION_POLICY.md

> Part of: FACTORY-MULTI-AGENT-ORCHESTRATION-1 / B
> Version: 1.0.0

## When Multi-Agent MUST Be Offered (Mandatory Question)

| # | Trigger | Rationale |
|---|---------|-----------|
| 1 | Fullstack app (server + client + database) | Natural parallelism |
| 2 | Service + client architecture | Independent workstreams |
| 3 | Database + API + UI | Three-layer separation |
| 4 | Long-horizon project (> 20 estimated files) | Work decomposition value |
| 5 | Multi-module repo (3+ independent modules) | Module-level parallelism |
| 6 | Real deployed trace detected | Security/QA separation needed |
| 7 | Security + QA + implementation roles needed | Role specialization |
| 8 | Package handoff required | Build/package parallelism |
| 9 | User says: 大项目 / complex / long horizon / 多模块 | Explicit user signal |

## When Single-Agent Build Lite Is Recommended

| # | Condition |
|---|-----------|
| 1 | Single-file change or fix |
| 2 | Documentation-only change |
| 3 | Configuration-only change |
| 4 | Small project (< 10 estimated files) |
| 5 | Simple CRUD without auth |
| 6 | All changes in same module with tight coupling |

## When Build Lite First, Multi-Agent Later

| # | Condition |
|---|-----------|
| 1 | Architecture unclear — single agent designs, then multi-agent builds |
| 2 | User wants to review design before parallel work |
| 3 | Unfamiliar project type — single agent learns, then parallelizes |

## When Multi-Agent Should Be Refused/Delayed

| # | Condition |
|---|-----------|
| 1 | Project in RECOVERY LEVEL_2 or LEVEL_3 |
| 2 | Corrupt state detected |
| 3 | projectId unconfirmed |
| 4 | Cleanup plan pending execution |
| 5 | User explicitly declines |

## Required Question Format

When the mandatory question triggers:

```
## Multi-Agent Decision Required

This project qualifies for multi-agent orchestration:
- [reason 1]
- [reason 2]

**Recommended Mode:** Multi-Agent Build Pro
**Expected Roles:** [Architect, Backend Worker, Frontend Worker, Integrator, QA]
**Overhead:** [estimated additional coordination cost]
**Risk:** [specific risks for this project type]

Choose:
1. **Build Lite (single agent)** — sequential, simpler, lower overhead
2. **Multi-Agent Build Pro** — parallel roles, contracts, handoffs
3. **Build Lite first, escalate later** — design with single agent, build with multi-agent
```

## Anti-Patterns
- ❌ Large project → auto-enable multi-agent without asking
- ❌ Multi-agent as universal default
- ❌ Removing Build Lite
- ❌ Making Native Build Pro the default
