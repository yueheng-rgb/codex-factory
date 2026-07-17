# Search Agent Deprecation Report

**Date:** 2026-07-10
**Phase:** FACTORY-R2.3-P Direction Correction
**Decision:** Deprecate Independent Search Agent; Converge to Single WebSearch Tool

---

## Background

Codex Factory previously explored a multi-component search architecture including an independent Search Agent alongside a Search Engine / Provider Adapter. User review identified that this dual-channel approach lacks mainstream practice support and introduces hidden risks.

## Evidence Review

### Mainstream Practice Survey

| Product/Project | Pattern | Notes |
|-----------------|---------|-------|
| OpenAI Codex / ChatGPT | Single tool-calling search | WebSearch tool as one tool among many |
| Claude | Single tool-use search | Search integrated as tool, not agent |
| Cursor | Single context injection | Search results as context, not agent |
| Copilot | Single retrieval pipeline | Retrieval as service, not agent |
| Perplexity | Single search pipeline | Search-first architecture |
| LangChain / LlamaIndex | Tool abstraction | Search as tool, agents call tools |
| MCP ecosystem | Tool/server pattern | Search exposed as MCP server tool |

**Finding:** No mainstream AI coding product deploys two parallel search truth sources. The universal pattern is a single WebSearch Tool / Provider, optionally with crawl/extract enrichment.

### Hidden Risks of Dual-Channel Architecture
1. **Truth source conflict:** Two search channels may return conflicting results with no reconciliation mechanism
2. **Cost duplication:** Two search API calls for the same query
3. **Agent confusion:** Implementer receives two sources, unclear which to trust
4. **Pipeline complexity:** Two parallel quality gates, intakes, evidence packs
5. **No incremental value:** A single well-configured provider achieves the same result

---

## Deprecated Directions

| Direction ID | Title | Reason |
|:---:|-------|--------|
| DIR-007 | Independent Search Agent as Active Route | No mainstream support; dual-channel risk |
| DIR-008 | Dual Search Channel | No evidence of benefit; creates conflict |
| DIR-009 | Search Agent as Future Default | Future converges to Single WebSearch Tool |

---

## Retained Components

These components remain valid within the Single WebSearch Tool pipeline:

| Component | Status | Role |
|-----------|:---:|------|
| need_search detector | ACTIVE | Determines when to trigger search |
| Provider Selector | ACTIVE | Selects best provider for query |
| WebSearch Tool / Adapter | ACTIVE | Single external search interface |
| Optional crawl/extract | DEFERRED | Future enrichment |
| Search Quality Gate | ACTIVE | Validates results before intake |
| Research Intake | ACTIVE | Evidence receiver, not agent |
| Evidence Pack Builder | ACTIVE | Sole fact carrier to agents |
| Implementer | RESTRICTED | Reads Evidence Pack only |

---

## Forbidden Patterns

- Independent Search Agent making autonomous decisions
- Search Agent summary bypassing Evidence Pack
- Two parallel search truth sources
- Implementer consuming raw search results directly
- Search Agent with direct network access
