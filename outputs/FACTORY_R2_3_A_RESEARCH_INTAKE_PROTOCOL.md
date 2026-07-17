# FACTORY R2.3-A — Research Intake Protocol

> **Phase:** FACTORY-R2.3-A-RESEARCH-INTAKE-PROTOCOL
> **Date:** 2026-07-05
> **Status:** DESIGN COMPLETE
> **Depends on:** R2.2 Agent Runtime Binding (completed)

---

## 1. Core Design Decision

### Research Agent ≠ Search Engine

The original R2.0 Research Agent was designed as a search-doer. **This is wrong for DeepSeek.** DeepSeek has limited real-time search capability and no multimodality.

**New model:** Research Agent (RSRC-001) = **Research Intake / Curator**

It does NOT search. It:
1. Receives raw search results from external providers
2. Validates, normalizes, and cross-references
3. Produces Research Packets
4. Recommends Knowledge Capsules and Skill Candidates
5. Passes to Librarian for the distillation pipeline

### Two Distinct Search Pipelines

```
┌──────────────────────────────────────────────────────┐
│           KNOWLEDGE RESERVE SEARCH                    │
│  (Build Factory knowledge bank, offline, proactive)   │
│                                                       │
│  Human / ChatGPT / GLM / Perplexity / Claude          │
│       │                                               │
│       ▼                                               │
│  Research Intake (raw format)                         │
│       │                                               │
│       ▼                                               │
│  RSRC-001: Clean → Normalize → Cross-reference        │
│       │                                               │
│       ▼                                               │
│  LIB-001: Classify → Deduplicate → Draft Capsules     │
│       │                                               │
│       ▼                                               │
│  ARCH → SEC → VER → INTG (full pipeline)              │
│       │                                               │
│       ▼                                               │
│  Knowledge Capsules + Skill Candidates → Registry     │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│           PROJECT-TIME EXTERNAL SEARCH                │
│  (During project work, on-demand, time-sensitive)     │
│                                                       │
│  Future: GLM / Search MCP / other strong-search model │
│       │                                               │
│       ▼                                               │
│  Research Intake (raw format)                         │
│       │                                               │
│       ▼                                               │
│  RSRC-001: Fast-track validation → Research Packet    │
│       │                                               │
│       ▼                                               │
│  Direct to requesting agent (ARCH / IMPL)             │
│  (Skip full distillation — time-sensitive)            │
│       │                                               │
│       ▼ (post-project)                                │
│  Retrospective distillation into Knowledge Bank       │
└──────────────────────────────────────────────────────┘
```

---

## 2. Search Provider Abstraction

### Provider Types

| Provider | Capability | Strengths | Weaknesses | Freshness | Citation | TrustLimit | DirectSource |
|----------|-----------|-----------|------------|-----------|----------|------------|-------------|
| `human_manual` | Human-curated multi-source | Cross-reference, domain expertise | Slow, subjective | As-of-now | Always | TRUSTED | ❌ No |
| `chatgpt` | Broad knowledge, good synthesis | Fast, well-structured | Hallucination risk, no real-time | Training date | Recommended | AVAILABLE | ❌ No |
| `glm_search` | Real-time search + synthesis | Current, Chinese-optimized | May miss English sources | Real-time | Always | TRUSTED | ⚠️ With verification |
| `claude` | Long-context analysis | Deep reasoning, artifact generation | No real-time search | Training date | Recommended | AVAILABLE | ❌ No |
| `perplexity` | Real-time search + citations | Current, well-cited | May hallucinate citations | Real-time | Always | TRUSTED | ⚠️ With verification |
| `search_engine` | Raw web results | Broadest coverage, unfiltered | No synthesis, noise | Real-time | Always | AVAILABLE | ❌ No |
| `official_docs` | Direct from framework/library | Authoritative | Limited to one source | Version-pinned | Always | VERIFIED | ✅ Yes |
| `community_sources` | GitHub, Stack Overflow | Practical, battle-tested | Quality varies | Varies | Recommended | AVAILABLE | ❌ No |
| `paper_search` | Academic papers | Rigorous, peer-reviewed | May be theoretical | Static | Always | TRUSTED | ❌ Reference only |
| `repo_search` | Open-source code search | Real implementation | Project-specific | As-of-repo | Recommended | AVAILABLE | ❌ No |

### Provider Selection Rules

- **Knowledge Reserve Search**: Prefer `human_manual` + `glm_search` + `perplexity` + `official_docs`
- **Project-time Search**: Future: `glm_search` + `search_engine` + `official_docs`
- **Code-level questions**: `repo_search` + `community_sources` + `official_docs`
- **Architecture decisions**: `human_manual` + `official_docs` + `paper_search`

---

## 3. Complete Distillation Pipeline

```
STEP 1: External Search (outside Factory)
  → Raw results with sources

STEP 2: Research Intake Formatting (human or automated)
  → research-intake.schema.json

STEP 3: RSRC-001: Intake → Research Packet
  → Validate format, normalize sources, cross-reference
  → Flag conflicts, assess freshness
  → Recommend capsules + skill candidates
  → Output: research-packet.schema.json

STEP 4: LIB-001: Packet → Capsule/Skill Drafts
  → Classify by domain
  → Deduplicate
  → Draft knowledge capsules
  → Draft skill candidates
  → Output: knowledge-capsule draft, skill-candidate draft

STEP 5: ARCH-001: Engineering Assessment
  → Check against Factory rules (anti-overengineering, stack guide)
  → Validate decision rules
  → APPROVE / REJECT / NEEDS_REVISION

STEP 6: SEC-001: Security Assessment (if applicable)
  → Scan code snippets for secrets/unsafe patterns
  → Check for deprecated API recommendations
  → APPROVE / BLOCK / NEEDS_REVISION

STEP 7: VER-001: Verification
  → Verify source URLs accessible
  → Verify fact claims consistent
  → Run negative controls
  → PASS / FAIL / NEEDS_REVISION

STEP 8: INTG-001: Final Integration
  → All assessments passed? → ACCEPT
  → Write to knowledge capsule ledger
  → Write to skill registry (candidate → adapted)
  → Record handoff

STEP 9 (post-verification use): VER-001: Runtime Verification
  → After skill used in real project
  → Adapted → Verified
  → Registry updated
```

---

## 4. Schema Reference

| Schema | Location | Purpose |
|--------|----------|---------|
| `research-intake.schema.json` | `schemas/` | Raw search result import format |
| `research-packet.schema.json` | `knowledge-bank/research/` | Cleaned, cross-referenced research output |
| `knowledge-capsule.schema.json` | `schemas/` | Validated knowledge unit |
| `skill-candidate.schema.json` | `schemas/` | Proposed skill for review |

---

## 5. Trial Example: High-Scale Ecommerce

A complete offline example demonstrates the full chain:

| Step | File | Description |
|------|------|-------------|
| 1. Raw Intake | `examples/high-scale-ecommerce-research-intake.example.json` | Human-researched raw results about ecommerce architecture |
| 2. Research Packet | `examples/high-scale-ecommerce-research-packet.example.json` | RSRC-001 cleaned output with fact claims, consensus, risks |
| 3. Knowledge Capsule | `examples/high-scale-ecommerce-knowledge-capsule.example.json` | CAP-ecommerce-inventory-deduction — decision rules, anti-patterns |
| 4. Skill Candidate | `examples/high-scale-ecommerce-skill-candidate.example.json` | SKILL-CAND-ecommerce-inventory — trigger conditions, instructions |

**Topic:** 高并发库存扣减
**Sources:** Alibaba Cloud, Meituan, Stripe, PostgreSQL, Kafka, AWS
**Trust:** 4 VERIFIED (official docs), 2 TRUSTED (engineering blogs)
**Output:** 1 knowledge capsule + 1 skill candidate (both in `draft`/`candidate` status)

---

## 6. Cloud Policy (Reaffirmed)

| Policy | Status |
|--------|--------|
| Local-first | ✅ DEFAULT |
| Project code on cloud | ❌ NEVER |
| Secrets/keys on cloud | ❌ NEVER |
| User data on cloud | ❌ NEVER |
| Research packets on cloud | ❌ NEVER (may reference private projects) |
| Knowledge capsules on cloud | ❌ NEVER (competitive advantage) |
| Public skill manifest on cloud | ⚠️ FUTURE OPTION (version index + hash only) |
| Cloud sync auto-trigger | ❌ NEVER — manual only |
| Local is source of truth | ✅ ALWAYS |

---

## 7. Key Rules

1. **Research Agent is a curator, not a search engine.** RSRC-001 receives, cleans, formats — never searches.
2. **GLM/ChatGPT/Perplexity results are UNVERIFIED until processed through the full pipeline.**
3. **Human search results are TRUSTED ceiling, not VERIFIED.**
4. **Official docs are the only direct VERIFIED source type.**
5. **No skill enters registry without ARCH + SEC + VER + INTG approval.**
6. **Knowledge reserve search and project-time search are distinct pipelines.**
7. **All claims must have source references.**
8. **AI-generated answers alone are never enough to verify a fact.**
9. **Local-first. No cloud for knowledge/skills/projects.**

---

## 8. File Inventory (R2.3-A)

```
NEW FILES:
schemas/
├── research-intake.schema.json          # External search result import format
├── knowledge-capsule.schema.json        # Validated knowledge unit schema
└── skill-candidate.schema.json          # Proposed skill schema

examples/
├── high-scale-ecommerce-research-intake.example.json      # Step 1: Raw intake
├── high-scale-ecommerce-research-packet.example.json      # Step 2: Research packet
├── high-scale-ecommerce-knowledge-capsule.example.json    # Step 3: Knowledge capsule
└── high-scale-ecommerce-skill-candidate.example.json      # Step 4: Skill candidate

outputs/
├── FACTORY_R2_3_STATE_GAP_REPORT.md                       # 35 artifacts audited, 14 gaps
├── FACTORY_R2_3_KNOWLEDGE_DISTILLATION_DESIGN.md          # Roles, trust matrix, import policy
└── FACTORY_R2_3_A_RESEARCH_INTAKE_PROTOCOL.md             # This document
```

---

## 9. R2.3 Sub-Phase Status

| Phase | Status | Output |
|-------|--------|--------|
| **R2.3-A** (this phase) | ✅ COMPLETED | 3 schemas + 4 examples + 3 reports |
| R2.3-B | PENDING | External skill/knowledge source survey |
| R2.3-C | PENDING | Knowledge distillation pipeline MVP (automate RSRC→INTG chain) |
| R2.3-D | PENDING | Ecommerce architecture playbook trial (run full chain) |
| R2.3-E | PENDING | Skill registry runtime integration (auto-load skills at spawn) |

---

> **R2.3-A DELIVERED.** Research Agent redefined as Intake/Curator. Two search pipelines designed. Four schemas created. Full trial example chain demonstrated. Local-first reaffirmed. Ready for R2.3-B external source survey.

