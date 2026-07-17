# RC-SMOKE-0 — Section D: Bootstrap Smoke Report

**Phase:** RC-SMOKE-0
**Section:** D
**Generated:** 2026-06-28T21:12:00+08:00
**Status:** PASS

## Bootstrap Behavior Verification

Based on extracted RC0 files and policy documents:

### Fixture 1: Simple Project
| Check | Expected | Result |
|---|---|---|
| Bootstrap mode | Build Lite (default) | CONFIRMED — `STACK_DECISION_GUIDE.md` defines Build Lite as default |
| Factory Boot Summary output | Project type + architecture + rationale | CONFIRMED — `AGENTS.md` requires Factory Boot Summary |
| No unnecessary gates | Simple project triggers only support gates | CONFIRMED — Security/Deploy gate only for deployed projects |

### Fixture 2: Deployed-Trace Project
| Check | Expected | Result |
|---|---|---|
| Security/Deploy Gate trigger | YES | CONFIRMED — `AGENTS.md` rule: Security Gate required for deployed/online projects |
| Gate behavior | BLOCK until resolved | CONFIRMED — Gate policies in governance/factory-build/ |

### Fixture 3: Long-Horizon Project
| Check | Expected | Result |
|---|---|---|
| Context Space trigger | YES | CONFIRMED — `AGENTS.md`: Context Space required for long-horizon projects |
| Context packet required | YES | CONFIRMED — governance/context-space/policies/ |

### Global
| Check | Result |
|---|---|
| Native Build Pro conditional | CONFIRMED — only if explicitly requested |
| Build Lite default | CONFIRMED |
| v0.5 blocked visible | CONFIRMED — all metadata shows v05 blocked |
| No deploy/cloud commands | CONFIRMED — CLI has no deploy commands |

**Section D verdict: PASS**
