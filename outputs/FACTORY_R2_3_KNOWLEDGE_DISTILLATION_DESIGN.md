# FACTORY R2.3 — Knowledge Distillation Design

> **Phase:** FACTORY-R2.3-KNOWLEDGE-SKILL-ECOSYSTEM / Step A
> **Date:** 2026-07-05
> **Status:** DESIGN

---

## 1. Core Principle: Research Agent ≠ Search Engine

### Problem

The original R2.0 Research Agent (RSRC-001) was designed as a "search agent" — it would search external sources and return results. With DeepSeek as the model, this is not viable:

- DeepSeek has limited real-time search capability
- No multimodal (cannot process images/diagrams from search results)
- AI answers cannot be treated as authoritative knowledge

### Redesign

**RSRC-001 = Research Intake / Curator Agent**

It does NOT search. It:
1. Receives raw search results from external providers (human, ChatGPT, GLM, Perplexity, search engines)
2. Cleans, normalizes, and formats them into Research Packets
3. Cross-references against existing knowledge bank
4. Flags gaps, conflicts, uncertainties
5. Recommends knowledge capsules and skill candidates
6. Passes to Librarian for classification and deduplication

### Two Search Modes

| Mode | Purpose | Who Searches | When | Output |
|------|---------|-------------|------|--------|
| **Knowledge Reserve Search** | Build Factory knowledge bank, skill bank, playbooks | Human / ChatGPT / GLM / Perplexity / Claude | Offline, proactive | Knowledge Capsules, Playbooks, Skill Candidates |
| **Project-time External Search** | Get latest docs, framework versions, error solutions during project | Future: GLM / Search MCP / external model | During project work | Research Packets (time-sensitive) |

---

## 2. Distillation Roles

### Role Chain

```
External Provider → Research Intake → Librarian → Architect → Security → Verifier → Integrator
     (outside)         (RSRC-001)      (LIB-001)   (ARCH-001)  (SEC-001)  (VER-001)  (INTG-001)
```

### 2.1 External Search Provider (Outside Factory)

**Who:** Human, ChatGPT, GLM, Claude, Perplexity, search engine, academic database

**Responsibilities:**
- Execute search query
- Collect raw results with source URLs
- Note uncertainty and confidence
- Mark AI-generated vs human-curated content

**Output:** Raw Research Intake (see schema)

**Constraints:**
- Must provide source links for every claim
- Must distinguish facts from opinions
- Must note retrieval date for freshness tracking
- Cannot directly inject into Factory knowledge bank

### 2.2 Research Intake Agent (RSRC-001)

**Input:** Raw Research Intake (from external provider)

**Responsibilities:**
- Validate intake format (required fields present)
- Normalize source types and trust levels
- Cross-reference claims against existing knowledge bank
- Flag conflicts with existing VERIFIED knowledge
- Identify potential knowledge capsules
- Identify potential skill candidates
- Assess freshness risk
- Produce Research Packet

**Output:** Research Packet

**Permissions:**
- Read: knowledge-bank/ (existing capsules, registry)
- Write: knowledge-bank/research/ (research packets only)
- Forbidden: write to skill registry, write to knowledge capsules

**Handoff:** To LIB-001 for classification

**Can approve入库?** ❌ No — only formats and flags

### 2.3 Skill Librarian Agent (LIB-001)

**Input:** Research Packet (from RSRC-001)

**Responsibilities:**
- Classify research findings by domain
- Deduplicate against existing knowledge capsules
- Assign initial trust level to findings
- Route to Architect for engineering assessment (if technical)
- Route to Security for risk check (if security-relevant)
- Create/update knowledge capsule drafts
- Create skill candidate drafts
- Maintain registry entries

**Output:** Knowledge Capsule drafts, Skill Candidate drafts, registry updates

**Permissions:**
- Read: knowledge-bank/ (all), skill registry
- Write: knowledge-bank/capsules/, knowledge-bank/playbooks/, registry entries (draft only)
- Forbidden: approve VERIFIED status, modify source code

**Handoff:** To ARCH-001 (technical assessment) or SEC-001 (security assessment)

**Can approve入库?** ❌ No — drafts only, needs Architect + Security + Verifier

### 2.4 Architect Agent (ARCH-001)

**Input:** Knowledge Capsule draft / Skill Candidate draft (from LIB-001)

**Responsibilities:**
- Assess engineering applicability
- Check against Factory architecture rules (anti-overengineering, stack decision guide)
- Validate decision rules against known best practices
- Flag anti-patterns that conflict with Factory standards
- Approve or reject technical content

**Output:** Engineering assessment (APPROVE / REJECT / NEEDS_REVISION)

**Permissions:**
- Read: knowledge-bank/, governance/rules/
- Write: assessment notes only
- Forbidden: approve without STACK_DECISION_GUIDE cross-check

**Handoff:** To VER-001 for verification

**Can approve入库?** ⚠️ Technical approval only — needs Verifier + Integrator

### 2.5 Security Agent (SEC-001)

**Input:** Knowledge Capsule draft / Skill Candidate draft (route from LIB-001 when security-relevant)

**Responsibilities:**
- Check for insecure patterns in code snippets
- Check for secrets/keys in examples
- Check for deprecated/unsafe API recommendations
- Flag skill candidates that violate Factory security rules

**Output:** Security assessment (APPROVE / BLOCK / NEEDS_REVISION)

**Permissions:**
- Read: knowledge-bank/
- Write: assessment notes only
- Forbidden: modify source

**Handoff:** To VER-001

**Can approve入库?** ⚠️ Security approval only

### 2.6 Verifier Agent (VER-001)

**Input:** Knowledge Capsule draft / Skill Candidate draft (with ARCH + SEC assessments)

**Responsibilities:**
- Verify all fact claims have source references
- Verify source references are accessible
- Verify skill candidate instructions are clear and actionable
- Verify no conflicting rules with existing VERIFIED knowledge
- Verify freshness (not expired)
- Run negative controls on skill candidate instructions

**Output:** Verification report (PASS / FAIL / NEEDS_REVISION)

**Permissions:**
- Read: knowledge-bank/, source references
- Write: verification report only
- Forbidden: approve without source verification

**Handoff:** To INTG-001 for final入库

**Can approve入库?** ⚠️ Verification approval only

### 2.7 Integrator Agent (INTG-001)

**Input:** Knowledge Capsule / Skill Candidate (with ARCH + SEC + VER approvals)

**Responsibilities:**
- Final review of all approvals
- Assign final trust level (VERIFIED / TRUSTED / AVAILABLE)
- Write to knowledge capsule ledger
- Write to skill registry (registry.jsonl)
- Update playbook if applicable
- Record handoff to ledger

**Output:** Finalized knowledge capsule / skill candidate in registry

**Permissions:**
- Read: all assessments
- Write: knowledge-bank/capsules/, knowledge-bank/registry.jsonl
- Forbidden: approve without all 3 assessments (ARCH + SEC + VER)

**Handoff:** To PM-001 (notification)

**Can approve入库?** ✅ YES — sole final approver

### 2.8 Optional: Domain Reviewer (Human)

**Who:** Domain expert (human)

**When:** HIGH-severity knowledge (e.g., security patterns, financial transaction rules)

**Input:** Knowledge Capsule draft marked for human review

**Output:** Human review notes

**Can approve入库?** ⚠️ Advisory only — INTG-001 still makes final decision

---

## 3. Source Trust Matrix

| Source Type | Trust Level | Freshness Required | Direct Rule? | Security Review | Citation Required |
|-------------|-------------|-------------------|--------------|-----------------|-------------------|
| Official Documentation | VERIFIED | ≤ 12 months | ✅ Yes | ❌ Not needed | ✅ URL + version |
| Standards / RFC / Specs | VERIFIED | Version-pinned | ✅ Yes | ❌ Not needed | ✅ RFC number |
| Big-Tech Engineering Blog | TRUSTED | ≤ 24 months | ⚠️ Reference only | ❌ Not needed | ✅ URL + date |
| Academic Paper (peer-reviewed) | TRUSTED | ≤ 5 years | ❌ Reference only | ❌ Not needed | ✅ DOI / title |
| Mature Open-Source Project (>1000★) | TRUSTED | ≤ 12 months | ⚠️ Pattern only | ✅ Required | ✅ Repo URL + version |
| Community Template / Starter | AVAILABLE | ≤ 6 months | ❌ Reference only | ✅ Required | ✅ Repo URL |
| Stack Overflow (accepted, >10 votes) | AVAILABLE | ≤ 24 months | ❌ Reference only | ⚠️ Code only | ✅ URL |
| AI-Generated Content (ChatGPT, GLM, etc.) | UNVERIFIED | N/A | ❌ NEVER | ✅ Required | ✅ Model + prompt + date |
| Unverified Skill Marketplace | UNVERIFIED | Unknown | ❌ NEVER | ✅ Required | ✅ Source URL |
| Anonymous / Untraceable Source | BLOCKED | N/A | ❌ NEVER | N/A | N/A |

### Trust Level Semantics

| Level | Can be used as... | Can become skill? | Auto-load? |
|-------|-------------------|-------------------|------------|
| VERIFIED | Authoritative reference | ✅ After full pipeline | ✅ Yes |
| TRUSTED | Strong reference | ✅ After ARCH+SEC+VER | ✅ With warning |
| AVAILABLE | Supplementary reference | ⚠️ After full pipeline + extra review | ❌ No |
| UNVERIFIED | Discovery only | ❌ Must go through full pipeline first | ❌ No |
| BLOCKED | Never | ❌ Cannot enter registry | ❌ No |

---

## 4. Skill / Knowledge Import Policy

### 4.1 Import Pipeline

```
Raw Intake → Format Validation → Source Check → Content Audit
→ Cross-Reference → Trust Assignment → Role Assessments
→ Verification → Integration → Registry Entry
```

### 4.2 Skill States

| State | Meaning | Can Be Used? | Who Can Transition? |
|-------|---------|-------------|---------------------|
| `candidate` | Proposed, not yet reviewed | ❌ No | LIB-001 → adapted |
| `adapted` | Reformatted for Factory, pending review | ❌ No | ARCH-001 / SEC-001 → verified or rejected |
| `verified` | Passed all checks, ready for use | ✅ Yes | INTG-001 → registry active |
| `rejected` | Failed review, reason documented | ❌ No | INTG-001 (final) |
| `deprecated` | Was verified, now outdated/unsafe | ❌ No (warning) | LIB-001 |
| `quarantine` | Security concern found post-verification | ❌ No (BLOCKED) | SEC-001 |

### 4.3 Required Checks Per Import

| Check | Automated? | Performed By | Block on Fail? |
|-------|-----------|-------------|----------------|
| License check | ⚠️ Manual | LIB-001 | ✅ BLOCK if incompatible |
| Security scan (secrets, unsafe code) | ⚠️ Semi-auto | SEC-001 | ✅ BLOCK |
| Escalation check (sudo, rm -rf, curl | bash) | ⚠️ Semi-auto | SEC-001 | ✅ BLOCK |
| External link check (phishing, dead links) | ❌ Manual | LIB-001 | ⚠️ Flag only |
| Version record | ✅ Auto | LIB-001 | N/A |
| Verifier sign-off | ❌ Manual | VER-001 | ✅ BLOCK if no sign-off |
| Cross-reference conflict check | ⚠️ Semi-auto | RSRC-001 | ⚠️ Flag only |

### 4.4 Rollback / Deprecate Rules

1. **Deprecation trigger:** Skill unused for 6 months → LIB-001 reviews → mark deprecated or keep
2. **Security deprecation:** SEC-001 finds vulnerability → immediate BLOCK → INTG-001 marks deprecated
3. **Supersede:** New version passes full pipeline → old version marked `deprecated`, points to new
4. **Rollback:** If verified skill found to have issues → mark `quarantine` → re-review → restore or reject
5. **Archive:** Deprecated skills kept 12 months then moved to `knowledge-bank/archive/`

---

## 5. Cloud Decision

### Current Stance: LOCAL-FIRST, NO CLOUD

| Data Type | Local | Cloud | Rationale |
|-----------|-------|-------|-----------|
| Project code | ✅ Required | ❌ NEVER | Proprietary, may contain secrets |
| API keys / secrets | ✅ Required | ❌ NEVER | Security |
| User data / PII | ✅ Required | ❌ NEVER | Privacy |
| Private knowledge capsules | ✅ Required | ❌ NEVER | Competitive advantage |
| Skill registry (internal) | ✅ Required | ❌ NEVER | Contains assessment history |
| Research packets | ✅ Required | ❌ NEVER | May reference private projects |
| Failure lessons | ✅ Required | ❌ NEVER | May contain project details |
| **Public skill manifest** | ✅ Primary | ⚠️ Future option | Only version index + hash + public metadata |
| **Release manifest** | ✅ Primary | ⚠️ Future option | Only public release info |
| **Public playbook index** | ✅ Primary | ⚠️ Future option | Only index, not capsule content |

### Cloud Update Mechanism (Future)

If cloud sync is added in the future:
- Must be opt-in per artifact
- Must use cryptographic signing (hash verification)
- Must have separate "public" and "private" channels
- Must NOT auto-sync — always manual trigger
- Local is always the source of truth

---

## 6. R2.3 Sub-Phase Roadmap

| Phase | Name | Scope | Est. Duration |
|-------|------|-------|---------------|
| **R2.3-A** (current) | Research Intake Protocol | Schemas + role design + trial example | 1 session |
| R2.3-B | External Skill & Knowledge Source Survey | Catalog 20+ external sources across 6 domains | 1-2 sessions |
| R2.3-C | Knowledge Distillation Pipeline MVP | Automate RSRC→LIB→ARCH→SEC→VER→INTG chain | 2-3 sessions |
| R2.3-D | Ecommerce Architecture Playbook Trial | Run full chain on high-scale-ecommerce topic | 1-2 sessions |
| R2.3-E | Skill Registry Runtime Integration | Connect registry to agent spawn (auto-load skills) | 2-3 sessions |

---

> **Design Status:** COMPLETE. Roles defined, trust matrix established, import policy documented, cloud decision made. Ready for R2.3-A schemas + protocol doc.

