# Codex Conversation / Branch / Worker Thread Mechanism Investigation

**Date:** 2026-06-22
**Phase:** Investigation (pre-H10)
**Verdict:** CONFIRMED — Codex `spawn_agent` with `fork_context:false` already provides the isolation boundary Workers need. Separate conversations/threads are unnecessary.

---

## 1. Current Codex Environment Model (Observed)

### Conversation / Thread

Codex exposes `create_thread`, `fork_thread`, `list_threads`, `read_thread` tools. A "thread" is the internal unit of a conversation session. Threads can be created, forked, and read. The main agent lives in the "current conversation" — this is the user-facing interaction surface.

### Task / Goal

Codex has `get_goal`, `create_goal`, `update_goal`. Each conversation has an active goal with status tracking (`complete`, `blocked`). Tokens and elapsed time are tracked per goal.

### Agent

`spawn_agent` creates sub-agents within the current conversation. Key parameters:
- `fork_context: false` = clean context, no history from parent
- `fork_context: true` = forked history from branching point
- `model` = optional model override (inherits parent by default)
- `agent_type` = `default`, `explorer`, or `worker`

Agents communicate via `send_input`, close via `close_agent`, resume via `resume_agent`.

### Branch / Worktree (Codex-native)

**There is NO native Codex "branch" or "worktree" concept.** These are filesystem-level simulations created by the Factory.

### Branch / Worktree (Factory-simulated)

The S0/S1/S2 pilots established a filesystem-level isolation pattern:
```
targets/phase6c-s0-subagent-pilot/
  branches/agent-s0-builder-data/    ← per-agent capsule, result, delta
  branches/agent-s0-builder-ui/
  worktrees/agent-s0-builder-data/   ← isolated workspace directory
  worktrees/agent-s0-builder-ui/
  worktrees-summary/                 ← aggregated workspace state
  agent-mailbox/messages.jsonl       ← inter-agent messaging
```

A "branch" in Factory terms = a capsule directory containing `INPUT_CAPSULE.md`, `BRANCH_RESULT.md`, `BRANCH_DELTA.json`.
A "worktree" in Factory terms = an isolated subdirectory where one agent writes code.

### Repo / Project

All agents share the same filesystem and repository. Isolation is enforced by:
1. Write-scope rules ("only write to `worktrees/<AGENT_ID>/src/`")
2. Sentinel-based cross-contamination detection (designed in 6C-E)
3. Contract-first import rules (no worktree paths in source code)

### Cloud Sandbox

Not applicable. Desktop Codex runs on the local machine with full filesystem access.

---

## 2. New Conversation Behavior (H9-P4 Rotation Protocol)

When a new Codex conversation opens on the same project/repo:

| Question | Answer |
|----------|--------|
| What state is inherited? | **Nothing from chat history** (unless `fork_context:true`). Filesystem state is shared. Phase lock, quarantine registry, run directories are all on disk. |
| What state is NOT inherited? | Previous conversation's message history, agent memory, in-flight `spawn_agent` children. |
| Does it know previous conversation history? | **No.** Must read phase lock and resume capsule from disk. |
| Does it read repo files only? | No — it reads any disk file. The `verify-new-window-readiness.ps1` script mandates reading specific governance files. |
| Does it share worktree state? | Yes — worktrees are on disk and shared. |
| Does it create a separate worktree? | No — Codex does not create worktrees. The Factory creates them. |

---

## 3. Thread / Branch / fork_context Analysis

| Mechanism | History Inheritance | Stale Phase Risk | Worker Isolation Safe? |
|-----------|-------------------|------------------|----------------------|
| `fork_context: false` | None (clean) | None | **Yes** — S0/S1/S2 all used this |
| `fork_context: true` | Full parent history at fork point | High (could inherit stale phase state) | No — risk of phase lock bleed |
| New conversation window | None (clean) | Low if `verify-new-window-readiness.ps1` passes | Yes — but heavyweight |
| `fork_thread` + `send_input` | Forked thread history | Medium (must filter) | Maybe — not tested in pilots |

**Conclusion:** `fork_context: false` is the correct isolation mechanism for Workers. New conversations are only needed for rotation/compression handoffs, not for per-worker isolation.

---

## 4. Repo Traces Found

### Primary Evidence (Phase 6C-S0 Subagent Pilot)
- `targets/phase6c-s0-subagent-pilot/` — Complete pilot with per-agent branches, worktrees, capsules, mailbox
- `branches/agent-s0-*/` — `INPUT_CAPSULE.md`, `BRANCH_RESULT.md`, `BRANCH_DELTA.json`
- `worktrees/agent-s0-*/` — Isolated source directories
- `agent-mailbox/messages.jsonl` — 8 reconstructed handoff messages
- `templates/S1_AGENT_CAPSULE_TEMPLATE.md` — Agent capsule template
- `templates/S1_INTERFACE_CONTRACT_TEMPLATE.json` — Interface contract template
- `docs/S1_CONTRACT_FIRST_RUNBOOK.md` — 45-60min contract-first runbook
- `scripts/validate-agent-isolation.ps1` — Isolation validator

### Secondary Evidence (Phase 6C-S2 Rollover Pilot)
- `targets/phase6c-s2-rollover-pilot/` — Rollover/continuation pilot
- Proved: native runtime mailbox (12 native messages, 0 reconstructed)
- Proved: rollover continuation with `resume_agent`

### Design Documents
- `PHASE_6C-E_DESIGN_REVIEW.md` — Context isolation design with sentinel detection, context budgets, write-guards
- `harness/docs/HARNESS_EVIDENCE_FLOW.md` — 13-step evidence flow from Task Plan to Audit Bundle
- `harness/docs/HARNESS_MINIMUM_CLOSURE_MODEL.md` — ENGINEERING_PASS vs AUDIT_PASS vs PARTIAL
- `harness/schemas/AGENT_EVIDENCE_SCHEMA.json` — Per-agent evidence requirements (orchestrator, builder, validator, integrator)
- `harness/schemas/harness-spawn/pre-spawn-worker-contract.schema.json` — Worker contract schema with 30+ required fields

### Governance (H9-P4)
- `governance/harness-readiness/conversation-rotation-policy.json` — Rotation protocol
- `scripts/harness-readiness/create-resume-capsule.ps1` — Capsule creator
- `scripts/harness-readiness/verify-resume-capsule.ps1` — Capsule verifier
- `scripts/harness-readiness/verify-new-window-readiness.ps1` — New-window verifier

### Harness Worker Scripts
- `harness/scripts/harness-spawn/generate-worker-spawn-prompt.ps1` — Prompt generator
- `harness/scripts/harness-spawn/validate-pre-spawn-run-plan.ps1` — Pre-spawn validator
- `harness/scripts/harness-worker/verify-worker-output-contract.ps1` — Post-spawn verifier
- `harness/scripts/harness-worker/enforce-worker-output-before-freeze.ps1` — Freeze enforcer
- `harness/scripts/harness-spawn/check-worker-simplicity-risk.ps1` — Simplicity check

---

## 5. Existing Governance Support Assessment

| Capability | Exists? | Level | Notes |
|-----------|---------|-------|-------|
| Per-worker conversation capsule | Partially | S0 pilot | `INPUT_CAPSULE.md` per agent exists. No Codex-thread-level capsule. |
| Per-worker branch/worktree assignment | YES | S0/S1/S2 | `worktrees/<agent-id>/` + `branches/<agent-id>/` proven |
| Main-agent handoff capsule | YES | H9-P4 | `create-resume-capsule.ps1` for compression rotation |
| New-window readiness verification | YES | H9-P4 | `verify-new-window-readiness.ps1` |
| Compression-count rotation | YES | H9-P4 | Policy at threshold=2 |
| Runtime mailbox coordination | YES (S2) | Native | 12 native messages, proven in S2 |
| Agent isolation validation | YES | S0 | `validate-agent-isolation.ps1` |
| Contract-first interface lock | YES | S1 runbook | `INTERFACE_CONTRACT.json` freeze before spawn |
| Worker output freeze | YES | H8 | `enforce-worker-output-before-freeze.ps1` |
| Sentinel-based leakage detection | DESIGNED | 6C-E | Not yet implemented as script |

---

## 6. Recommended Factory Design

### Should each Worker get its own Codex conversation?

**No.** `spawn_agent` with `fork_context: false` already provides clean context. A new conversation window is heavyweight (requires handoff, capsule verification, phase lock re-read) and adds no isolation benefit beyond what `fork_context: false` already provides.

Exception: When `compressionCount >= 2` or agent limit is hit, the Main Agent conversation itself should rotate (per H9-P4). Workers are closed before rotation.

### Should each Worker get its own worktree?

**Yes.** Filesystem-level worktrees (`worktrees/<agent-id>/src/`) are the proven isolation mechanism:
- Proven in S0 (3 builders + 1 validator, each with own worktree)
- Proven in S2 (3 builders + rollover continuation)
- Write-scope rules enforced by convention + sentinel detection

### Should Main Agent remain the only integrator?

**Yes.** The orchestrator/integrator is the Main Agent:
- Spawns Workers
- Collects results (BRANCH_RESULT.md, BRANCH_DELTA.json)
- Merges worktree outputs into canonical
- Runs validation
- Never delegates integration to a Worker

### What must be passed to each Worker?

1. **Task contract** (mission, owned files, required exports, required evidence)
2. **Input capsule** (`INPUT_CAPSULE.md` with task description, write scope, acceptance criteria)
3. **Interface contract** (`INTERFACE_CONTRACT.json` with shared types, export names, import paths)
4. **Worktree path** (exclusive write scope)
5. **Forbidden files list** (explicit guard)

### What must NOT be passed to each Worker?

1. Other Workers' task briefs or capsules
2. Other Workers' workspace paths
3. Phase lock internals
4. Full conversation/chat history
5. Other Workers' private sentinel files
6. Global project implementation details beyond the contract

### How should Worker results return to Main Agent?

1. **Filesystem:** `BRANCH_RESULT.md` + `BRANCH_DELTA.json` written to `branches/<agent-id>/`
2. **Mailbox:** Native `messages.jsonl` entry with `HANDOFF` message type
3. **Worktree:** Source files in `worktrees/<agent-id>/src/`
4. **Evidence:** Test results, typecheck output in worktree directory

---

## 7. Proposed H10 Scope — Worker Conversation / Worktree Isolation Protocol

### Goal
Formalize the per-worker isolation protocol proven in S0/S1/S2 into a reusable Factory governance asset.

### Deliverables

1. **`governance/harness-readiness/worker-isolation-policy.json`**
   - Per-worker worktree requirements
   - Per-worker input capsule contract
   - Write-scope enforcement rules
   - Forbidden cross-worker access rules
   - Sentinel leakage detection rules

2. **`scripts/harness-readiness/create-worker-capsule.ps1`**
   - Generates `INPUT_CAPSULE.md` from worker contract + interface contract
   - Writes to `branches/<agent-id>/INPUT_CAPSULE.md`
   - Validates capsule against contract before output

3. **`scripts/harness-readiness/verify-worker-isolation.ps1`**
   - Checks no worktree path imports in src/
   - Checks no foreign sentinel strings in worker output
   - Checks worker wrote only to allowed files
   - Checks BRANCH_RESULT.md and BRANCH_DELTA.json exist

4. **`scripts/harness-readiness/verify-worker-handoff.ps1`**
   - Validates worker handoff artifacts
   - Checks mailbox message exists
   - Checks all required exports are present in worktree

5. **`governance/harness-readiness/worker-isolation-report-template.md`**

6. **`outputs/PHASE_6C_H10_WORKER_ISOLATION_PROTOCOL_REPORT.md`**

### Scope Boundaries (H10 does NOT)

- Create new Codex threads/conversations per worker (unnecessary)
- Implement OS-level isolation (containers, VMs)
- Implement GPU/process isolation
- Replace spawn_agent with an alternative mechanism
- Change the Main Agent → Worker spawn flow
- Start DRY18-B

### What H10 SHOULD prove

- Workers receive only their own task inputs
- Workers write only to their own worktree
- Worker handoff artifacts are complete and verifiable
- Cross-contamination is mechanically detectable (sentinel)
- Main Agent integration gate requires all worker handoffs verified

---

## 8. What Is Confirmed

1. Codex `spawn_agent` with `fork_context: false` provides clean context isolation for Workers
2. Filesystem worktrees are a proven isolation mechanism (S0, S1, S2)
3. Contract-first development prevents naming drift between Workers
4. Runtime mailbox coordination works natively (proven in S2)
5. Main Agent as sole integrator is the correct pattern
6. New conversation windows are only needed for compression rotation, not per-worker isolation
7. H9-P4 rotation protocol correctly handles window handoff

## 9. What Is Uncertain

1. **Provider-level cognitive isolation:** Sub-agents share the same Codex model family. We prove mechanical partition (filesystem, contracts, sentinels) but not model-internal memory separation.
2. **OS-level isolation:** No separate process or container boundaries. Enforced by convention + detection.
3. **Long-run stability:** S0/S1/S2 were 45-60 minute runs. Multi-hour/overnight stability not tested.
4. **Cross-machine isolation:** Single-machine, single-OS-user context. Not tested across machines.

## 10. Risks to Codex Factory

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Worker reads another Worker's worktree | Medium | Sentinel detection (6C-E design), contract-first naming rules |
| Worker modifies files outside worktree | Medium | Write-scope rules in capsule, orchestrator write-guard audit |
| Worker handoff artifacts incomplete | Low | `verify-worker-handoff.ps1` (proposed H10) |
| Stale context in Worker (wrong fork_context) | Low | All pilots used `fork_context: false` successfully |
| Compression rotation needed during Worker execution | Medium | Close workers before rotation; workers are ephemeral |

---

## 11. Files Inspected (No Modifications)

- `governance/harness-readiness/conversation-rotation-policy.json`
- `scripts/harness-readiness/create-resume-capsule.ps1`
- `scripts/harness-readiness/verify-resume-capsule.ps1`
- `scripts/harness-readiness/verify-new-window-readiness.ps1`
- `targets/phase6c-s0-subagent-pilot/PHASE_6C-S0_REAL_SUBAGENT_PILOT_REPORT.md`
- `targets/phase6c-s0-subagent-pilot/PHASE_6C-S0-R2_FINAL_REPORT.md`
- `targets/phase6c-s0-subagent-pilot/templates/S1_AGENT_CAPSULE_TEMPLATE.md`
- `targets/phase6c-s0-subagent-pilot/templates/S1_INTERFACE_CONTRACT_TEMPLATE.json`
- `targets/phase6c-s0-subagent-pilot/branches/agent-s0-builder-ui/INPUT_CAPSULE.md`
- `targets/phase6c-s0-subagent-pilot/docs/S1_CONTRACT_FIRST_RUNBOOK.md`
- `targets/phase6c-s0-subagent-pilot/scripts/validate-agent-isolation.ps1`
- `targets/phase6c-s0-subagent-pilot/agent-mailbox/messages.jsonl`
- `targets/phase6c-s2-rollover-pilot/PHASE_6C-S2_FINAL_REPORT.md`
- `PHASE_6C-E_DESIGN_REVIEW.md`
- `harness/prompts/orchestrator-agent.md`
- `harness/schemas/AGENT_EVIDENCE_SCHEMA.json`
- `harness/schemas/harness-spawn/pre-spawn-worker-contract.schema.json`
- `harness/docs/HARNESS_MINIMUM_CLOSURE_MODEL.md`
- `harness/docs/HARNESS_EVIDENCE_FLOW.md`
- `harness/docs/HARNESS_ENGINEERING_MAP.md`
- `harness/scripts/harness-spawn/generate-worker-spawn-prompt.ps1`
- `harness/scripts/harness-spawn/validate-pre-spawn-run-plan.ps1`
- `harness/governance/harness-readiness/current-phase-lock.json`
- `harness/governance/harness-readiness/quarantined-runs.json`

**No files modified.**
