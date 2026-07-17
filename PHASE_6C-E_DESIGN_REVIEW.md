# Phase 6C-E Design Review — Context Isolation + Memory Budget Audit

**Date**: 2026-06-19
**Phase**: Phase 6C-E

---

## 1. Current Phase 6C-D Context Risk Assessment

Phase 6C-D proved end-to-end orchestration works, but left open questions about context hygiene:

| Risk | Severity | Evidence in D |
|------|----------|--------------|
| Orchestrator received full spawn_agent results in chat window | Medium | Builder outputs appeared inline in orchestrator context |
| No budget enforcement for agent inputs | High | Builders received full task descriptions with no char limit |
| No sentinel-based cross-task leakage detection | High | No mechanism existed to detect if Builder A read Builder B's files |
| Orchestrator could potentially read/write any file | Medium | No write-guard mechanism beyond convention |
| Memory/context state not snapshot-able | Medium | No RUN_MEMORY_SNAPSHOT mechanism |

---

## 2. Why "One Window" != "No Subagents"

The Codex harness orchestrator window sees agent spawn results and governance events. This is the *control-plane channel*. The sub-agents operate in forked contexts with isolated workspaces. The question is not whether sub-agents exist (they do — `spawn_agent` creates them), but whether the inputs to each sub-agent are appropriately scoped.

- **Proven in D**: Sub-agents write to disjoint workspace directories
- **Not proven in D**: Sub-agents receive only task-relevant inputs
- **Not proven in D**: Sub-agents cannot access other tasks' data

---

## 3. Why "Multiple agentId" != "True Division of Labor"

Having 3 different `agentId` values does not automatically mean 3 agents are doing independent work. True division requires:

1. Each agent receives only its own task's inputs
2. Each agent writes only to its allowed paths
3. No agent can read another agent's work-in-progress
4. The orchestrator delegates work, not just stamps agentId labels

Phase 6C-E addresses points 1-3 explicitly.

---

## 4. Context Isolation Boundaries to Verify

| Boundary | Mechanism | Verification Method |
|----------|-----------|-------------------|
| Builder ↔ Builder | Separate input bundles, sentinel files | Sentinel leakage scan |
| Orchestrator ↔ App source | Write-guard audit | git diff audit |
| Validator ↔ Builder chat | Validator only reads submission.json + evidence | Validator input audit |
| Integration ↔ Raw code | Integration only reads patches + hashes | Integration input audit |
| Disk ↔ Chat context | RUN_MEMORY_SNAPSHOT | Context reset + recovery test |

---

## 5. Context Budget Configuration

```json
{
  "orchestratorMaxInputChars": 12000,
  "builderMaxInputChars": 10000,
  "validatorMaxInputChars": 10000,
  "integrationMaxInputChars": 8000,
  "maxFullStdoutCharsInPrompt": 0,
  "maxFullSourceFilesInOrchestratorPrompt": 0
}
```

### Orchestrator Context Budget

**ALLOWED in orchestrator context:**
- TASK_DAG.json (task index, dependencies, status)
- RUN_PLAN.json (phase definitions)
- TASKS.json (status summary)
- RUN_STATE.jsonl tail (last 5 events)
- RUN_MEMORY_SNAPSHOT.md (governance summary)
- Evidence index (paths + hashes only)
- Risk summary

**FORBIDDEN in orchestrator context:**
- Full stdout/stderr from any command
- Complete Playwright report
- Complete build log
- Full source tree
- Full patch content
- Builder process logs

### Builder Context Budget

**ALLOWED per Builder:**
- Own taskId, brief, allowedPaths
- Own input file bundle
- Own acceptance criteria
- Own forbidden paths list
- Own workspace path
- Submission format template

**FORBIDDEN per Builder:**
- Other Builders' task briefs
- Other Builders' patches
- Other Builders' workspace paths
- Other Builders' private sentinel files
- Global project implementation details

### Validator Context Budget

**ALLOWED:**
- submission.json
- changes.patch
- allowedPaths
- baseCanonicalHash
- workspaceHash
- command evidence paths
- acceptance item

**FORBIDDEN:**
- Builder chat history
- Builder thought process
- Builder agentId (only for proof verification, not for judgment)

### Integration Context Budget

**ALLOWED:**
- Verified submissions (index only)
- Patch files (content)
- Base hashes
- Integration order
- Dry-run results
- Final verification results

---

## 6. RUN_MEMORY_SNAPSHOT Design

Generated at key orchestration checkpoints:

```
runs/<run-id>/memory/
  snapshot-phase-1-freeze.md
  snapshot-phase-2-builders-dispatched.md
  snapshot-phase-3-validated.md
  snapshot-phase-4-integrated.md
  snapshot-phase-5-final.md
```

Each snapshot contains:
- Current phase
- TASKS.json status summary (one line per task)
- RUN_STATE event count + last event
- Hash chain valid status
- Active lease count
- Evidence paths (not content)
- Risk flags

Snapshots are the **only** state an orchestrator replacement should need.

---

## 7. Context Reset / Replacement Recovery

1. Save RUN_MEMORY_SNAPSHOT
2. Simulate orchestrator context loss (new conversation turn without prior chat)
3. New orchestrator reads only: TASKS.json, TASK_DAG.json, RUN_MEMORY_SNAPSHOT
4. New orchestrator determines next action from disk state alone
5. Verifies no dependency on previous chat context

---

## 8. Sentinel Leakage Detection

### Method

1. Generate a unique random sentinel string for each task
2. Place sentinel file in each task's private workspace
3. After Builder execution, scan ALL files for foreign sentinels
4. Detection = mechanical evidence of cross-task information flow

### Sentinel Files

```
runs/<run-id>/agent-inputs/
  builder-T-001-input/
    .sentinel-T-001  (contains unique random string)
  builder-T-002-input/
    .sentinel-T-002
  builder-T-003-input/
    .sentinel-T-003
```

### Leakage Scan

After all Builders complete, scan every file in the run directory for sentinel strings. A Builder's output files must NOT contain foreign sentinels.

---

## 9. Orchestrator Write-Guard

Audit all app source files after orchestration completes. The orchestrator itself must not have modified any source file directly. Only Builder agents (via their workspace) may modify source files.

Verification: git diff between canonical baseline and final state, attributed by agent.

---

## 10. Builder Read Manifest

Each Builder records what files it actually read during execution:

```json
{
  "agentId": "builder-T-001",
  "readFiles": ["src/storage.ts", "tests/storage.test.ts", "agent-inputs/builder-T-001-input/.sentinel-T-001"],
  "foreignFilesRead": [],
  "sentinelLeakageDetected": false
}
```

---

## 11. Capabilities NOT PROVEN in Phase 6C-E

- **Strong cognitive isolation**: Sub-agents run in the same Codex model family; we prove mechanical partition, not model-internal memory separation.
- **OS-level read isolation**: Sub-agents share filesystem access; we enforce by convention and sentinel detection, not OS-enforced ACLs.
- **GPU/process isolation**: No separate process or container boundaries.
- **Cross-machine isolation**: Single-machine, single-OS-user context.

---

## 12. What Phase 6C-E CAN Prove

| Claim | Proof Method |
|-------|-------------|
| Mechanical context division | Agent input bundles with char budgets |
| Workspace division | Allowed paths enforcement + sentinel scans |
| Context budget enforcement | Input char counts vs budgets |
| Disk-based state recovery | Context reset + snapshot-only recovery |
| Write isolation | git diff + orchestrator write-guard audit |
| Read isolation (sentinel-based) | Sentinel leakage scan |