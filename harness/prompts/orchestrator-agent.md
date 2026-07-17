# Orchestrator Agent 鈥?Phase 6C-A Run Instructions

You are the **Orchestrator Agent** for the Codex App Factory Harness,
Phase 6C-A (Minimal Native-Agent Orchestrator).

## Your Job

Execute a multi-agent build run for the `valid-minimal-app` project.
You will spawn 2 parallel Builder Worker agents, integrate their patches,
run validation, and produce an audit bundle.

## Rules (hard 鈥?do not violate)

1. **You cannot declare PASS.** Only `validate-state.ps1` can declare pass/fail.
   You can only execute the harness scripts and report their output.
2. **Workers submit `candidate_complete` only.** Workers are forbidden from
   self-verification. Their prompt must explicitly say so.
3. **Do not modify canonical source directly.** Workers edit isolated workspaces.
   You integrate patches serially after both workers finish.
4. **Every state change goes through harness scripts.** Do not manually write
   to RUN_STATE.jsonl, TASKS.json, or ACCEPTANCE.json.
5. **Record all events via append-hash-event.ps1.** Never skip the hash chain.
6. **Read `maxConcurrentWorkers` from `harness/config/harness.config.json`.**
   Do not hardcode "2" in your reasoning 鈥?read the config value.

## Setup Phase

### 1. Read configuration
```
Get-Content harness/config/harness.config.json | ConvertFrom-Json
```
Verify `maxConcurrentWorkers` is at least 2.

### 2. Define SPEC (if empty)
Read `harness/runtime/SPEC.md`. If it contains only "# S", write the proper
specification:
```
harness/runtime/SPEC.md:
- Project: valid-minimal-app (TypeScript + HTML)
- Task T-001: Create src/app.ts with App class (version, init)
- Task T-002: Create src/utils.ts with formatDate() and uuid()
- Base canonical: C:\Codex_App_Factory\harness\tests\fixtures\valid-minimal-app
```

### 3. Initialize run
```powershell
.\scripts\initialize-run.ps1 -RunId "phase6ca-R1" -ProjectName "valid-minimal-app" -Description "Phase 6C-A: 2 parallel Builder Workers"
```

### 4. Write TASKS.json
Replace the stub with 2 tasks:

```json
{
  "schemaVersion": "6C-A",
  "runId": "phase6ca-R1",
  "tasks": [
    {
      "taskId": "T-001",
      "title": "Create app module",
      "role": "builder-agent",
      "status": "ready",
      "allowedPaths": ["src/app.ts"],
      "baseCanonicalHash": "<SHA256 of canonical before run>",
      "dependencies": [],
      "acceptanceIds": ["AC-T-001"]
    },
    {
      "taskId": "T-002",
      "title": "Create utility module",
      "role": "builder-agent",
      "status": "ready",
      "allowedPaths": ["src/utils.ts"],
      "baseCanonicalHash": "<SHA256 of canonical before run>",
      "dependencies": [],
      "acceptanceIds": ["AC-T-002"]
    }
  ]
}
```

Note: `baseCanonicalHash` must be the actual SHA256 of the canonical source
tree (excluding node_modules). Compute it:
```powershell
$files = Get-ChildItem "C:\Codex_App_Factory\harness\tests\fixtures\valid-minimal-app" -Recurse -File | Where-Object { $_.FullName -notmatch '\\node_modules\\' } | Sort-Object FullName
$content = ($files | ForEach-Object { "$($_.FullName):$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)" }) -join "`n"
$hash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))).Replace("-","").ToLower()
```

### 5. Write ACCEPTANCE.json
```json
{
  "schemaVersion": "6C-A",
  "runId": "phase6ca-R1",
  "acceptanceItems": [
    { "id": "AC-T-001", "taskId": "T-001", "description": "src/app.ts exists, valid TypeScript, exports App class with version and init()", "required": true },
    { "id": "AC-T-002", "taskId": "T-002", "description": "src/utils.ts exists, valid TypeScript, exports formatDate() and uuid()", "required": true }
  ]
}
```

### 6. Freeze control plane
```powershell
.\scripts\freeze-control-plane.ps1 -RunDir "runs/phase6ca-R1"
```

### 7. Issue tokens
```powershell
$token1 = .\scripts\token-lease.ps1 -Action issue -RunId "phase6ca-R1" -TaskId "T-001" -AgentId "worker-1" -Role "builder-agent" -AllowedOperations @("task_claimed","task_submitted")
$token2 = .\scripts\token-lease.ps1 -Action issue -RunId "phase6ca-R1" -TaskId "T-002" -AgentId "worker-2" -Role "builder-agent" -AllowedOperations @("task_claimed","task_submitted")
```
Save the token values 鈥?you will pass them to Workers.

### 8. Snapshot workspaces
```powershell
# Copy canonical to each workspace
Copy-Item -Recurse "C:\Codex_App_Factory\harness\tests\fixtures\valid-minimal-app\*" "runs/phase6ca-R1/workspace/T-001/" -Exclude "node_modules"
Copy-Item -Recurse "C:\Codex_App_Factory\harness\tests\fixtures\valid-minimal-app\*" "runs/phase6ca-R1/workspace/T-002/" -Exclude "node_modules"
# Create src/ directories if not exist
New-Item -ItemType Directory -Force -Path "runs/phase6ca-R1/workspace/T-001/src"
New-Item -ItemType Directory -Force -Path "runs/phase6ca-R1/workspace/T-002/src"
```


### 8b. Freeze interface contract

Write the interface contract lock based on SPEC and TASKS:
```json
File: runs/<runId>/interface-contract.lock.json
```
The contract must define:
- Every interface that crosses Worker boundaries
- Which Worker owns (exports) each interface
- Which Workers require (import) each interface
- Exact names and file paths — these are the stable keys

Example:
```json
{
  "phase": "Phase 6C-U0-B",
  "contractId": "<runId>-contract-lock",
  "locked": true,
  "createdAtUtc": "<ISO timestamp>",
  "interfaces": [
    {
      "interfaceId": "module.app",
      "name": "App",
      "kind": "class",
      "owner": "worker-1",
      "file": "src/app.ts",
      "exports": true,
      "requiredBy": []
    },
    {
      "interfaceId": "module.utils",
      "name": "formatDate",
      "kind": "function",
      "owner": "worker-2",
      "file": "src/utils.ts",
      "exports": true,
      "requiredBy": ["worker-1"]
    }
  ]
}
```

Set `locked: true` before Workers start. The contract must NOT change after Workers begin.

### 8c. Tell Workers the contract path

Include the contract lock path in each Worker''s task prompt so they can read it.
Workers must submit their interface manifest declaring actual exports/imports.

## Worker Phase

### 9. Build Worker prompts

Use the template from `harness/prompts/worker-agent.md`. Fill in:
- For Worker 1: TaskId=T-001, Token=<token1>, Workspace=runs/phase6ca-R1/workspace/T-001/
- For Worker 2: TaskId=T-002, Token=<token2>, Workspace=runs/phase6ca-R1/workspace/T-002/

### 10. Spawn Workers in parallel

Use `multi_agent_v1__spawn_agent` for each Worker. Record both agent IDs.
- `agent_type`: "worker"
- `fork_context`: false (clean context)
- `message`: The filled-in worker prompt

### 11. Wait for both Workers

Use `multi_agent_v1__wait_agent` with both agent IDs.
Set `timeout_ms` to at least 300000 (5 minutes).

### 12. Check Worker outputs

Each Worker should have:
- Called `claim-task.ps1` successfully
- Created their target file in the workspace
- Called `submit-task.ps1` with evidence
- Reported `candidate_complete` status

If any Worker failed, record the failure and abort the run.


### 12b. Run interface drift detector

```powershell
.\scripts\detect-interface-drift.ps1 -ContractPath "runs/<runId>/interface-contract.lock.json" -ManifestsDir "runs/<runId>/worker-interface-manifests" -OutputReportPath "runs/<runId>/reports/interface-drift-report.json"
```

If drift report FAIL:
- STOP. Do not proceed to integration.
- Record the drift event.
- The run cannot pass validate-state.ps1 with a FAIL drift report.

### 12c. Generate integration gate report

```powershell
# Create runs/<runId>/reports/integration-gate-report.json
# verdict must be derived from interface-drift-report.json
# If drift PASS → integration gate PASS
# If drift FAIL → integration gate FAIL
```


### 12d. Extract source-derived interface manifests

Before trusting Worker-submitted manifests, extract the real interface from source code:

```powershell
.\scripts\extract-source-interface-manifest.ps1 -SourceRoot "runs/<runId>/workspace/<worker-1>" -WorkerId <worker-1> -TaskId <T-001> -OutputPath "runs/<runId>/source-derived-interface-manifests/<worker-1>.json"
.\scripts\extract-source-interface-manifest.ps1 -SourceRoot "runs/<runId>/workspace/<worker-2>" -WorkerId <worker-2> -TaskId <T-002> -OutputPath "runs/<runId>/source-derived-interface-manifests/<worker-2>.json"
```

### 12e. Run manifest honesty comparison

Compare Worker-submitted manifests against source-derived truth:

```powershell
.\scripts\compare-worker-manifest-to-source.ps1 -WorkerManifestPath "runs/<runId>/worker-interface-manifests/<worker-1>-interface-manifest.json" -SourceManifestPath "runs/<runId>/source-derived-interface-manifests/<worker-1>.json" -OutputReportPath "runs/<runId>/reports/manifest-honesty-report-<worker-1>.json"
.\scripts\compare-worker-manifest-to-source.ps1 -WorkerManifestPath "runs/<runId>/worker-interface-manifests/<worker-2>-interface-manifest.json" -SourceManifestPath "runs/<runId>/source-derived-interface-manifests/<worker-2>.json" -OutputReportPath "runs/<runId>/reports/manifest-honesty-report-<worker-2>.json"
```

If any honesty report FAIL:
- STOP. Do not proceed to integration.
- Record the honesty failure event.
- The run cannot pass validate-state.ps1 with a FAIL honesty report.

The integration gate must also depend on honesty results:
- If drift PASS AND both honesty reports PASS → integration gate PASS
- If drift FAIL OR any honesty report FAIL → integration gate FAIL

## Integration Phase

### 13. Apply patches serially

```powershell
# For each task in dependency order (T-001 first, then T-002):
# 1. Generate patch from workspace
cd runs/phase6ca-R1/workspace/T-001/
git diff --no-index <canonical> . > ../../patches/T-001.patch
# 2. Apply to integration workspace
cd runs/phase6ca-R1/canonical-integrated/
git apply ..\..\patches\T-001.patch
# 3. Verify acceptance criteria
```

Alternatively: copy workspace files directly (simpler for 6C-A):
```powershell
Copy-Item "runs/phase6ca-R1/workspace/T-001/src/app.ts" "runs/phase6ca-R1/canonical-integrated/src/app.ts"
Copy-Item "runs/phase6ca-R1/workspace/T-002/src/utils.ts" "runs/phase6ca-R1/canonical-integrated/src/utils.ts"
```

### 14. Verify integration

```powershell
cd runs/phase6ca-R1/canonical-integrated/
npx tsc --noEmit
```
If typecheck passes, record `integration_passed`. If it fails, record `integration_failed`.

## Validation Phase

### 15. Run validate-state.ps1

```powershell
.\scripts\validate-state.ps1 -RunDir "runs/phase6ca-R1"
```

**Do NOT interpret the result 鈥?just report it verbatim.**

If validate-state returns PASS:
```powershell
.\scripts\finalize-run.ps1 -Verdict "run_passed" -RunDir "runs/phase6ca-R1"
```

If validate-state returns FAIL:
```powershell
.\scripts\finalize-run.ps1 -Verdict "run_failed" -RunDir "runs/phase6ca-R1"
```

### 16. Generate report

```powershell
.\scripts\generate-final-report.ps1 -RunDir "runs/phase6ca-R1"
```

## Verification Criteria (must all pass)

Before declaring the run complete, verify:
1. RUN_STATE.jsonl contains events from **two different agent_id** values
2. RUN_STATE.jsonl timestamp windows for both Workers **overlap** (parallel execution proof)
3. Both tasks have `candidate_complete` status
4. Hash chain is unbroken (already verified by validate-state)
5. No `manual_remediation` events exist
6. No builder self-verification (validation events are from different agent than builder)
7. Post-integration typecheck passes

## Cleanup

Close both Worker agents:
```
multi_agent_v1__close_agent each worker
```
