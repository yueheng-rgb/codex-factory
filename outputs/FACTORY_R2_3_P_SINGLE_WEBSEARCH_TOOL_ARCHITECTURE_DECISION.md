# Single WebSearch Tool Architecture Decision

**Date:** 2026-07-10
**Phase:** FACTORY-R2.3-P-SINGLE-WEBSEARCH-TOOL-SELECTION-GATE
**Decision:** Converge to Single WebSearch Tool / Search Provider Pipeline

---

## Architecture Decision

Codex Factory external search is served by exactly **one** WebSearch Tool pipeline. No independent Search Agent. No dual truth sources.

`
                    need_search detector
                           |
                    Provider Selector
                           |
              +------------+-----------+
              |                        |
        WebSearch Tool           WebSearch Tool
        (Direct API)             (MCP Server)
              |                        |
              +------------+-----------+
                           |
                    Search Quality Gate
                           |
                    Research Intake
                    (evidence receiver)
                           |
                    Evidence Pack Builder
                           |
              +------------+-----------+
              |            |           |
         ARCH-001     VER-001     IMPL-*
        (read EP)    (verify EP)  (read EP only)
`

---

## What Changed

| Before | After |
|--------|-------|
| Search Engine + Search Agent | Single WebSearch Tool |
| Two parallel search channels | One pipeline |
| Search Agent as active route | Deprecated (DIR-007) |
| Dual search as deferred option | Deprecated (DIR-008) |
| Future Search Agent | Deprecated (DIR-009) |

---

## Active Directions

| ID | Direction | Status |
|:---:|-----------|:---:|
| DIR-004 | Evidence Search Loop | active |
| DIR-010 | Single WebSearch Tool Pipeline | **active** |
| DIR-011 | Search Provider via API or MCP | active |

---

## WebSearch Tool Patterns Supported

1. **Direct API** (current): GLM Search, Tavily, Exa, Brave — REST API calls
2. **MCP Server** (future): Search exposed as MCP tool — deferred until MCP sandbox maturity

Both patterns feed the same pipeline. Provider selection gate picks the best for current context.

---

## Hard Constraints

- Only ONE external search truth source
- Evidence Pack is the sole fact carrier to agents
- Implementer NEVER calls provider directly
- Search results NEVER enter skill registry directly
- No independent Search Agent with network access
- No Search Agent summary as evidence
