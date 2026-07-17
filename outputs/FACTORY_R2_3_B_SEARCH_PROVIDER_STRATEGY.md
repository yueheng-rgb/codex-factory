# FACTORY R2.3-B — Search Provider Strategy

> **Phase:** FACTORY-R2.3-B
> **Date:** 2026-07-09

---

## 1. Core Principle: Search Provider ≠ Research Agent

Search Provider = external tool that finds information.
Research Agent (RSRC-001) = internal curator that receives, cleans, validates, and transforms.

**RSRC-001 does NOT search. It intakes.**

## 2. Two Search Pipelines

### Knowledge Reserve Search (Offline, Proactive)

Purpose: Build Factory knowledge bank, skill bank, playbooks.

`
Human / GLM / ChatGPT / Perplexity
    │
    ▼ Raw results + citations
Research Intake Format (JSON)
    │
    ▼
RSRC-001: Clean, normalize, cross-reference
    │
    ▼
Research Packet → LIB-001 → Knowledge Capsules / Skill Candidates
`

### Project-time Search (On-demand during project)

Purpose: Get latest docs, framework versions, error solutions.

`
GLM / Perplexity / Official Docs
    │
    ▼ Raw results
Research Intake (fast-track)
    │
    ▼
RSRC-001: Quick validation
    │
    ▼
Direct to requesting agent (ARCH / IMPL)
    │
    ▼ (post-project)
Retrospective distillation into Knowledge Bank
`

## 3. Provider Positioning

| Provider | Best For | When to Use | API Needed? |
|----------|----------|-------------|-------------|
| **GLM Search** | Chinese ecosystem docs, miniapp, WeChat | Knowledge Reserve (Chinese) | Yes (future) |
| **ChatGPT Search** | Broad synthesis, English ecosystem | Knowledge Reserve (English) | Account needed |
| **Perplexity** | Citation-rich, verifiable results | Both (when citations critical) | Yes |
| **Claude Search** | Architecture analysis, deep reasoning | Architecture Search | Account needed |
| **Google Search** | Broadest web, error lookup | Project-time (manual) | No |
| **GitHub Repo Search** | Code examples, templates, patterns | Template search | No (public) |
| **Official Docs Search** | Authoritative API/syntax reference | Project-time (always first) | No |
| **Baidu Search** | Chinese content, CSDN, Zhihu | Project-time (Chinese) | No |
| **Zhihu/Juejin/CSDN** | Chinese developer community | Supplementary (Chinese) | No |
| **Paper Search** | Academic backing for architecture | Architecture research | No |

## 4. When to Connect APIs

| Phase | Connect API? | Reason |
|-------|-------------|--------|
| **Now (R2.3-B)** | ❌ No | Survey only, no execution |
| **R2.3-C** | ❌ No | Build adapter interface, no real API |
| **R2.3-D** | ⚠️ Maybe | If trial project needs real-time search |
| **R2.3-E** | ✅ Yes | Full Research Intake pipeline with GLM adapter |

## 5. GLM Search Adapter Design (Future)

`json
{
  "adapterId": "ADAPT-GLM-001",
  "providerType": "glm_search",
  "inputFormat": "research-intake.schema.json",
  "outputFormat": "research-packet.schema.json",
  "requiresApiKey": true,
  "rateLimit": "10/minute",
  "cacheStrategy": "7-day TTL for Knowledge Reserve, 1-day for Project-time",
  "fallbackProvider": "perplexity-search"
}
`

## 6. Research Intake Boundary

**What RSRC-001 does:**
- Receives raw research-intake JSON
- Validates format completeness
- Normalizes source types and trust levels
- Cross-references against existing knowledge bank
- Flags conflicts with VERIFIED knowledge
- Produces research-packet JSON

**What RSRC-001 does NOT do:**
- Call any search API directly
- Scrape websites
- Trust AI-generated content without verification
- Write to skill registry (LIB-001 does that)
- Make architecture decisions (ARCH-001 does that)

