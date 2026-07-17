# R2.3-K Read-only Search Adapter Report

## Adapter Capabilities

- Import search results from 10 provider types (human, GLM, ChatGPT, Claude, Perplexity, search engine, official docs, community, papers, repos)
- Zero API keys, zero network calls
- Converts to Research Intake Packets for Librarian/Curator processing

## Example Results

| Input | Provider | Accepted | Quality | Trust |
|-------|----------|:---:|:---:|------|
| good-official-docs | official_docs_manual | ✅ | 10/10 high_quality | TRUSTED_REFERENCE |
| bad-ai-no-sources | chatgpt_search_manual | ❌ | 4/10 needs_review | NEEDS_HUMAN_REVIEW |
| mixed-community-official | community_sources_manual | ✅ | 10/10 high_quality | REFERENCE_ONLY |

## Access Control

- RSRC-001 (Research Agent): ALLOWED
- LIB-001 (Librarian): ALLOWED
- IMPL-FE-001 (Implementer): REJECTED — must go through Research Intake pipeline
