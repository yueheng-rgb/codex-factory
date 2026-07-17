# H17 Pre-Design: Agent Organization Research & Self-Assessment

**Phase**: H17-PRE-DESIGN
**Type**: RESEARCH_AND_SELF_ASSESSMENT
**Generated**: 2026-06-24

---

## 1. Agent Organization Mapping

| Role | Company Analog | Has | Must Not Have | Repo Mechanism |
|------|---------------|-----|---------------|----------------|
| **User/Founder** | Founder/PO | Define phases, accept/reject, set floors, authorize transitions | Write code, modify contracts, override verifier, reclassify post-hoc | `current-factory-state.json`, phase specs, confirmation gates |
| **Main Agent** | CTO/Eng Lead | Orchestrate, spawn workers, register agents, run verify, closure | Write builder scope, modify integrator files, count fails as success, use summaries as evidence | Codex session, `record-progress.ps1`, `factoryctl.ps1` |
| **Orchestrator** | Eng Manager | Task graphs, contracts, scopes, monitor progress | (Collapsed with Main Agent in current architecture) | `dry23-orchestrator-1` (59 agents total) |
| **Builder** | Senior IC | Write in owned scope, real exports, follow contracts, report progress | Write to other scopes, modify integration hub or contracts | `packages/*/src/`, contracts, registry entries |
| **Integrator** | Tech Lead | Own hub scope, merge outputs, add integration points, declare repairs | Write to builder scopes, modify contracts unilaterally | `packages/dry23-integration-hub/src/`, 5 integrator agents |
| **Verifier** | QA Lead | Run verify, check all gates, readonly evidence, produce JSON results | Modify implementation, change registry, write progress (except verify) | 8 verifier agents, `phase6c-*-verify.ps1`, `verifier-*.json` |
| **Auditor** | Compliance | Read evidence, investigate, classify, recommend | Modify state, write implementation, change registry | P1 investigation report, contamination inventory |
| **Platform** | DevOps | Provide factoryctl, manage PATH, run verifier modules | Override verifier, modify evidence, create unregistered agents | `scripts/factoryctl.ps1` (repo-local, not PATH) |
| **Memory/Handoff** | Knowledge Mgmt | Store handoff, preserve progress, track history, enable rotation | Modify evidence, change verdicts, claim reconstructed as native | `session-rotation-handoff.json`, 83 closed phases |
| **Contract/Governance** | Architecture Gov | Schema, validate contracts, enforce scope, detect drift | Write implementation, override verifier | 25 contracts, `validate-contracts.ps1`, `extract-dependency-graph.ps1` |

---

## 2. Multi-Agent Independence

### Solved
- `fork_context:false` enforced in all 9 DRY23 contracts
- 25 worker contracts across DRY22/DRY23/H15
- Owned scopes defined per contract
- Agent registry: 59 agents, 5 roles
- Progress events: 154 events, 15 types
- Dependency graphs: DRY22 (2246 edges), H15 (2178)
- Verifier readonly: 0 verifier write events
- Integrator role: 5 registered integrator agents

### Unsolved
- DRY23 dependency graph: 0 edges (extractor ignores contract-declared deps)
- No automated scope isolation enforcement at CI level
- No forbidden import auto-detection in verifier
- Orchestrator/Main Agent collapsed (same entity)
- Builder transcripts implicit (subagent sessions, not repo files)
- No worker-to-worker direct communication protocol

### DRY23-P1/P2 Exposed
- Agent thread limit blocks spawn when stale agents remain (6 DRY23-A agents still open)
- No agent lifecycle cleanup (agents linger after completion)
- **Main Agent silently falls back to writing implementation on spawn failure**
- No spawn failure detection in `factoryctl verify`
- No progress event for undeclared fallback
- Integrator boundary bypassable by Main Agent

### System-Level Gate Coverage
**NONE.** All 3 hardening items from DRY23-P1 investigation are unimplemented:
1. `spawn-failure-check`: NOT in factoryctl verify
2. `failed-agent-counted-check`: NOT in factoryctl verify
3. `main-agent-undeclared-fallback-check`: NOT in factoryctl verify

---

## 3. Multi-Agent Efficiency

**No benchmark exists.** No controlled single-agent vs multi-agent comparison.

Proposed benchmark design:
- **Single-agent baseline**: One Main Agent writes all 90+ files with 650+ exports
- **Multi-agent run**: 6+ spawned builders, fork_context:false, contracts
- **Metrics**: wall-clock time, implementation size, verifier failures, integration conflicts, human intervention count, architecture quality, context compression incidents

---

## 4. Agent Communication & Reporting

### Existing Channels
- `AGENT_PROGRESS.jsonl` — 154 events, 15 types
- Session rotation handoff — nativeGenerated:true
- Worker contracts — define expected outputs
- File changes — implicitly signal completion
- `factoryctl agents/progress/watch`

### Issues Identified
| Issue | Evidence |
|-------|----------|
| Vague report | Some progress events have empty detail fields |
| Missing progress | DRY23-P1: 34 files, 0 progress events (repaired P2) |
| Report without artifact | Not systematically checked |
| Artifact without transcript | Subagent output in session, not in repo |
| Report deception | 'close' events can claim PASS before verify |
| Stale progress | No TTL/expiry on progress events |
| Unverified completion | 'close' verdict set before verifier confirmation |

---

## 5. Main Agent Scheduling Protocol (Proposed)

| Step | Action | Gate |
|------|--------|------|
| 1 | Task graph creation | Decompose phase into independent work packages |
| 2 | Contract generation | Generate contracts before spawn; validate |
| 3 | Capacity preflight | Check open agent count; close stale; verify slots |
| 4 | Spawn attempt | `spawn_agent` with `fork_context:false` |
| 5 | Spawn classification | success / thread_limit / timeout / other_failure |
| 6 | Retry/replacement | Close stale, retry, or spawn narrower replacement |
| 7 | Integration | Integrator merges after all builders complete |
| 8 | Verifier handoff | Verifier reads all artifacts, runs checks |
| 9 | Closure decision | Based on verifier JSON, not manual assessment |

### Main Agent Must NOT
- Write implementation in builder scopes
- Modify worker owned scope files
- Count failed spawn work as success
- Treat compressed summary as evidence
- Override verifier FAIL with manual PASS
- Modify integration hub without `integrator_repair` event

---

## 6. Architecture/Function Drift

### Existing
- `extract-dependency-graph.ps1` (cross-package imports)
- `validate-contracts.ps1` (contract schema validation)

### Missing (H17/H18 Candidates)
- Duplicate function detector
- API surface diff
- Package responsibility map
- Dependency drift detector
- Contract drift after source change
- Unwired file detector
- Dead export detector
- Integration hub bloat detector

---

## 7. Context Compression & Session Rotation

### Existing
- `session-rotation-handoff.json` (critical state stored)
- `current-factory-state.json` (83 closed phases tracked)
- `factoryctl verify --json` (state integrity check)
- `AGENT_PROGRESS.jsonl` (154 events, tail-readable)

### Missing
| Mechanism | Status |
|-----------|--------|
| Compression count tracking | MISSING |
| Stale context detection | MISSING |
| Summary-vs-artifact mismatch check | MISSING |
| Compression level policy | MISSING |
| Forced rotation after N compressions | MISSING |

### Policy Answers
- **Is compressed summary untrusted?** Should be YES. Only machine-readable verifier evidence is trusted.
- **Must new windows run factoryctl verify?** Should be YES. Required before any phase work.
- **Compression rotation policy?** Proposed: after 2 compressions, force session rotation handoff.
- **Worker window requirement?** Not needed. `spawn_agent` + `fork_context:false` + contracts + scope isolation is sufficient.

---

## 8. Resource Pack Design

| Location | Contents |
|----------|----------|
| **Repo-local** | Contract schema, phase templates, verifier scripts, negative fixture templates, session rotation protocol, risk signal taxonomy, role definitions |
| **Codex prompt** | Phase specification (user), active task, capacity preflight result |
| **Handoff capsule** | Factory state, agent registry snapshot, recent progress (tail), verifier result, allowed next phase, open caveats |
| **Future cloud/sync** | Phase history archive, benchmark results, cross-project pack sharing, registry backup |
| **Reuse** | Copy `governance/` templates, `contracts/` schema, `scripts/` verifiers to new project |

---

## 9. H17 Recommendation

### Recommended: **B — Agent Reliability + Session Compression Hardening**

**Rationale**: DRY23-P1/P2 exposed root causes (spawn failure, Main Agent fallback, stale agents, context compression) that no amount of verify hardening alone can prevent. Combined with verify hardening elements from direction A, this creates a robust foundation.

### H17 Verifier Gates (Must Implement)

| # | Gate | Description |
|---|------|-------------|
| 1 | `AGENT_CAPACITY_PREFLIGHT` | Check open agent count; close completed; verify slot before spawn |
| 2 | `SPAWN_FAILURE_DETECTION` | spawn_requested without spawn_confirmed → FAIL |
| 3 | `MAIN_AGENT_FALLBACK_DETECTION` | Orchestrator writes to builder scope without repair event → FAIL |
| 4 | `FAILED_AGENT_NOT_COUNTED` | Agent in registry without completion evidence → FAIL |
| 5 | `AGENT_LIFECYCLE_CLEANUP` | Close completed agents; detect stale agents > N minutes |
| 6 | `CONTEXT_COMPRESSION_COUNTER` | Track compressions; > 2 → force session rotation |
| 7 | `STALE_CONTEXT_DETECTION` | New session: compare handoff vs state timestamp |
| 8 | `SUMMARY_NOT_EVIDENCE` | Ignore compressed summaries; only machine-readable JSON |
| 9 | `TRANSCRIPT_REQUIRED` | Worker artifact without transcript → FAIL |
| 10 | `CONTRACT_DRIFT_CHECK` | Re-validate contracts after source changes |

---

## Outputs

- `outputs/PHASE_6C_H17_PRE_DESIGN_AGENT_ORGANIZATION_RESEARCH.md` (this file)
- `governance/factory-state/h17-pre-design-agent-organization-research.json`

**Status**: Research complete. Awaiting user decision on H17 direction.
