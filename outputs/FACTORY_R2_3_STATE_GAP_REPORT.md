# FACTORY R2.3 — State & Gap Check Report

> **Phase:** FACTORY-R2.3-KNOWLEDGE-SKILL-ECOSYSTEM / Step A
> **Date:** 2026-07-05
> **Purpose:** Audit all R2.x artifacts, classify maturity, identify gaps

---

## 1. Complete Artifact Inventory

### 1.1 Agent Definitions (R2.1 — 9 files)

| File | Maturity | Verifier? | Real Project Validated? |
|------|----------|-----------|------------------------|
| `router.agent.json` | Runtime-Ready (loaded by agent-loader.ps1) | ❌ | ❌ |
| `research.agent.json` | Runtime-Ready (schema only, no search backend) | ❌ | ❌ |
| `architect.agent.json` | Runtime-Ready | ❌ | ❌ |
| `librarian.agent.json` | Runtime-Ready (schema only, no import pipeline) | ❌ | ❌ |
| `implementer.agent.json` | Runtime-Ready (3 variants) | ❌ | ❌ |
| `verifier.agent.json` | Runtime-Ready | ❌ | ❌ |
| `security.agent.json` | Runtime-Ready | ❌ | ❌ |
| `integrator.agent.json` | Runtime-Ready | ❌ | ❌ |
| `drift-auditor.agent.json` | Runtime-Ready | ❌ | ❌ |

**Gap:** All 9 agent definitions are loadable at runtime (R2.2 verified). However, they are **definition-only**: no agent has been spawned with these definitions applied. The permission gate and handoff validator work against the definitions in simulation, but no real agent has had its scope enforced at spawn time.

### 1.2 Handoff Bus (R2.1 — 3 artifacts)

| Artifact | Maturity | Notes |
|----------|----------|-------|
| `handoff.schema.json` | Runtime-Ready | Validated in simulation, 6/6 tests passed |
| `handoff-index.jsonl` | Runtime-Ready | Appended successfully in simulation |
| `handoffs/` directory | Empty | Ready for per-handoff files |

**Gap:** The handoff bus can validate and record, but no agent workflow actually produces handoffs according to the schema.

### 1.3 Contract Templates (R2.1 — 4 files)

| File | Maturity | Notes |
|------|----------|-------|
| `pic.schema.json` | Schema-Only | Never instantiated for a real project |
| `ac.schema.json` | Schema-Only | Never instantiated for a real project |
| `fc.schema.json` | Schema-Only | Never instantiated for a real project |
| `ngc.schema.json` | Schema-Only | Never instantiated for a real project |

**Gap:** All 4 contract schemas are valid JSON and parseable (R2.2 verified). But they have never been used to guard an actual project. The `governance/contracts/active/` directory is empty.

### 1.4 Skill Registry (R2.1 — 3 artifacts)

| Artifact | Maturity | Notes |
|----------|----------|-------|
| `skill-registry.schema.json` | Schema-Only | Valid JSON, no entries |
| `registry.jsonl` | Schema-Only | Empty (header only) |
| `skill-import-policy.md` | Doc-Only | Not enforced by any runtime |

**Gap:** The skill registry exists as a schema and empty ledger. No skills have been registered. The import policy is documented but not automated.

### 1.5 Research Packet Schema (R2.1 — 2 artifacts)

| Artifact | Maturity | Notes |
|----------|----------|-------|
| `research-packet.schema.json` | Schema-Only | Valid JSON |
| `source-priority.md` | Doc-Only | Priority rules documented |

**Gap:** No research packet has ever been created. No research intake format exists. The Research Agent (RSRC-001) has no search backend. The schema assumes the agent does the searching — this needs redesign for multi-provider intake.

### 1.6 Drift Control (R2.1 — 2 artifacts)

| Artifact | Maturity | Notes |
|----------|----------|-------|
| `drift-check.schema.json` | Schema-Only | Valid JSON |
| `drift-types.md` | Doc-Only | 13 drift types documented |

**Gap:** Never run on any project. No drift report has been generated. Drift Auditor (AUD-001) has no active checkpoints triggered.

### 1.7 Failure Lessons (R2.1 — 2 artifacts)

| Artifact | Maturity | Notes |
|----------|----------|-------|
| `failure-lesson.schema.json` | Runtime-Ready | Schema validated |
| `lessons.jsonl` | Runtime-Ready | 3 real lessons from PROJ-051 |

**Gap:** Lessons captured but not yet fed back into skill updates or playbook improvements (LIB-001 not triggered).

### 1.8 Runtime Modules (R2.2 — 6 scripts)

| Script | Maturity | Notes |
|--------|----------|-------|
| `agent-loader.ps1` | Runtime-Ready | 50/50 checks passed |
| `permission-gate.ps1` | Runtime-Ready | 5/5 permission tests passed |
| `execution-context.ps1` | Runtime-Ready | 11 contexts generated |
| `handoff-validator.ps1` | Runtime-Ready | 8 checks + index recording |
| `contract-checker.ps1` | Runtime-Ready | 6/6 schemas parseable |
| `runtime-simulation.ps1` | Runtime-Ready | 6/6 simulation tests passed |

**Gap:** All runtime scripts work in isolation. But they are not integrated into a single workflow. No script calls another script as part of a pipeline. Each is a standalone tool.

---

## 2. Maturity Classification Summary

| Classification | Count | Items |
|----------------|-------|-------|
| **Runtime-Ready** (loadable, testable, validated) | 21 | 9 agent defs + 3 handoff bus + 3 failure lessons + 6 runtime scripts |
| **Schema-Only** (valid JSON, never instantiated) | 9 | 4 contracts + 3 skill registry + 1 research packet + 1 drift check |
| **Doc-Only** (text only, not enforced) | 3 | skill-import-policy.md, source-priority.md, drift-types.md |
| **Empty/Waiting** | 2 | handoffs/ directory, contracts/active/ directory |

### What's Missing (Critical Gaps)

| Gap | Severity | Blocking |
|-----|----------|----------|
| No contract instantiation for any project | HIGH | R2.3 contract-first workflow |
| No research intake format | HIGH | R2.3-A (this phase) |
| Research Agent designed as search-doer, not intake-curator | HIGH | R2.3-A redesign |
| No knowledge capsule schema | HIGH | R2.3-A |
| No skill candidate schema | HIGH | R2.3-A |
| No distillation role definitions | HIGH | R2.3-A |
| No real agent spawn with context enforcement | MEDIUM | R2.3-E |
| No drift report on any project | MEDIUM | R2.3-C |
| Skill registry has zero entries | MEDIUM | R2.3-E |
| Runtime scripts not integrated into pipeline | LOW | R2.3-B |
| No search provider abstraction | HIGH | R2.3-A |

---

## 3. Verifier Coverage Gap

No artifact has a dedicated verifier:

| Artifact | Who Should Verify | Current State |
|----------|-------------------|---------------|
| Agent definitions | VER-001 checks JSON validity + field completeness | agent-loader.ps1 does basic validation |
| Contract templates | VER-001 checks schema -> instance roundtrip | contract-checker.ps1 checks existence |
| Research packets | VER-001 checks source provenance + fact consistency | None |
| Knowledge capsules | VER-001 checks validatedFacts against sources | None |
| Skill candidates | VER-001 checks instructions don't violate Factory rules | None |
| Drift reports | VER-001 checks drift claims against actual code | None |
| Handoff index | VER-001 checks ledger integrity | handoff-validator.ps1 does basic checks |

---

## 4. Real Project Validation Gap

**Zero** R2.x artifacts have been validated against a real project:

- No PIC/AC/FC/NGC contract has been created for any project
- No agent has been spawned with R2.2 permission gate active
- No handoff has been produced by a real agent workflow
- No drift report has been generated on real code

The only "real" data is the 3 failure lessons from PROJ-051 (医师系统小程序), captured post-hoc.

---

## 5. Priority Action Items for R2.3

Based on gap analysis, R2.3 should focus on **Knowledge Ecosystem completion** before contract-first workflow:

1. **Redesign Research Agent** → Research Intake / Curator (R2.3-A)
2. **Create search provider abstraction** (R2.3-A)
3. **Create knowledge capsule schema** (R2.3-A)
4. **Create skill candidate schema** (R2.3-A)
5. **Define distillation roles** (R2.3-A)
6. **Create trial example** (R2.3-A)
7. **Survey external skill/knowledge sources** (R2.3-B)
8. **Build distillation pipeline** (R2.3-C)
9. **Run trial on ecommerce architecture** (R2.3-D)
10. **Integrate skill registry with runtime** (R2.3-E)

## 6. DeepSeek Reality Check

**Critical finding:** The current model (DeepSeek) has limited search capability and no multimodality. This directly impacts the Research Agent design:

- ❌ Research Agent CANNOT be "the model that searches the web"
- ✅ Research Agent MUST be "the curator that receives, cleans, formats, and reviews external search results"
- ❌ Cannot assume real-time web search during project execution
- ✅ Must support offline intake from human-provided or other-AI-provided search results
- ❌ Cannot trust AI-generated answers as authoritative knowledge
- ✅ Must require source provenance, citation, and multi-source consensus

This means the Research Agent (RSRC-001) definition needs to be updated from "search agent" to "research intake/curator agent".

---

> **State Verdict:** R2.1+R2.2 delivered solid infrastructure (35 artifacts). The critical gap is the Knowledge Ecosystem — research intake, knowledge capsules, skill candidates, distillation roles. R2.3-A must fill this gap.

