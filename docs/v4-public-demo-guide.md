# V4 Public Demo Guide

## 10-Step Walkthrough

### 1. Clone the Repo
```powershell
git clone git@github.com:yueheng-rgb/codex-factory.git
cd codex-factory
```

### 2. Run Init
```powershell
powershell -File runtime/codex-factory-init.ps1
```
Choose your LLM provider, search provider (default: none), and CI provider.

### 3. Run Doctor
```powershell
powershell -File runtime/codex-factory-doctor.ps1
```
Fixes any config or environment issues.

### 4. Choose Provider
Edit `factory.config.json` (copy from `factory.config.example.json`).
- GPT users: no external search needed (search_provider=none)
- DeepSeek users: optionally set search_provider=glm_zhipu
- All choices are optional — no vendor lock-in

### 5. Add a Skill Pack
```powershell
powershell -File runtime/skill-pack-manager.ps1 -Command create-template -Name my-pack -OutputDir packs/my-pack
powershell -File runtime/skill-pack-manager.ps1 -Command enable -Name my-pack
```

### 6. Add a Knowledge Pack
```powershell
powershell -File runtime/knowledge-pack-manager.ps1 -Command add -Source ./my-project-docs -Name project-knowledge
powershell -File runtime/knowledge-pack-manager.ps1 -Command build-evidence
```
Knowledge stays local — never uploaded. Every claim has source_file + source_hash.

### 7. Run Task Decomposition
```powershell
powershell -File runtime/task-decomposition-engine.ps1 `
  -Requirement examples/task-decomposition/admin-system-requirement.md `
  -OutputDir outputs/my-project
```
Produces: task_graph, worker_plan, validation_plan, risk_classification, agent_execution_plan.
All files non-empty, valid JSON, integrity-checked.

### 8. Start Execution Runtime
```powershell
powershell -File runtime/agent-execution-runtime.ps1 -Command start -PlanDir outputs/my-project
```
Creates run workspace with worker capsules.

### 9. Generate Worker Capsules & Handoffs
```powershell
powershell -File runtime/agent-execution-runtime.ps1 -Command create-handoff-template -RunId <run-id> -WorkerId worker-backend
powershell -File runtime/agent-execution-runtime.ps1 -Command create-handoff-template -RunId <run-id> -WorkerId worker-frontend
```
Distribute to separate Codex windows using the live test kit at `outputs/V4_4/live-cross-window-kit/`.

### 10. Verify
```powershell
powershell -File runtime/agent-execution-runtime.ps1 -Command validate-handoff -RunId <run-id>
powershell -File runtime/agent-execution-runtime.ps1 -Command collect-artifacts -RunId <run-id>
powershell -File runtime/agent-execution-runtime.ps1 -Command validate -RunId <run-id>
powershell -File runtime/agent-execution-runtime.ps1 -Command integrate -RunId <run-id>
powershell -File runtime/agent-execution-runtime.ps1 -Command close -RunId <run-id>
```

## Key Principles
- **No artifact = no PASS** — every task must produce verifiable output
- **Manual mode is honest** — never claims autonomous completion
- **Boundary enforcement** — workers cannot cross into each other's territory
- **Knowledge stays local** — your documents are never uploaded
- **GLM is optional** — you choose your providers

## What V4 Has Proven
- Real cross-window execution: 3 independent Codex windows, 8/8 artifacts, 79 tests
- CI remote verification: V3.4.2 strict mode on GitHub Actions (15/15 PASS)
- Boundary enforcement: rogue workers correctly rejected
- Output reliability: no 0-byte files, no fake PASS
