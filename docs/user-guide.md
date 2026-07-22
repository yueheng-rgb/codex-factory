# Codex Factory User Guide

> **Current path:** new installations should use the V5 `factoryctl` control
> plane and the [Chinese V5 guide](CONTROL_PLANE_V5_GUIDE.zh-CN.md). The V5
> multi-Agent option lets the Codex main Agent dispatch resident Agents first
> and create temporary subagents only when needed; users do not need to open
> worker windows or paste prompts. The PowerShell workflows later in this file
> are the hardened V4 compatibility path and remain manual.

## V5 Automatic Workflow

```powershell
Set-Location C:\Codex_App_Factory
powershell -ExecutionPolicy Bypass -File .\packages\factory-cli\install.ps1 `
  -ProjectRoot C:\Projects\my-app `
  -MultiAgent `
  -Search none `
  -MaxThreads 4

factoryctl doctor --project C:\Projects\my-app --json
```

After installation, start the project task in Codex. The generated project
rules and control-plane skill tell the main Agent to plan the DAG, dispatch
resident roles, create temporary roles for uncovered work, exchange Context
Packets outside the compressed frontend conversation, and require independent
verification before acceptance. Multi-Agent and external GLM search are
separate opt-in switches. GLM requires the user's `ZHIPUAI_API_KEY`; keys never
belong in tracked configuration.

Factory inherits the model/runtime selected in Codex. It does not implement or
certify a DeepSeek provider; DeepSeek compatibility must be proven in the
user's actual Codex runtime with a real model/tool-call smoke task.

## Legacy V4 Concepts and Workflows

### Provider
A V4 provider entry is compatibility metadata. It is not proof that Factory
implemented or connected that provider. Historical choices included:
- **LLM/runtime label** — OpenAI, DeepSeek, etc. (the actual Codex runtime owns the connection)
- **Search provider** — none (default), glm_zhipu, or custom
- **Memory provider** — local_snapshot
- **CI provider** — none (default), github_actions, or local_only

All configured in `factory.config.json`. GLM is **optional** — not required.

### Skill Pack
A reusable bundle of engineering rules, prompts, and validation criteria
for a specific project type. Examples: admin-system, ecommerce, saas, miniapp.

Each pack contains:
- `rules.md` — what the agent must follow
- `prompts.md` — ready-to-use prompts
- `validation.md` — how to verify the work
- `examples/` — example tasks showing expected output

### Knowledge Pack
Your own professional knowledge, imported locally. Never uploaded.
Each entry tracked with `source_file`, `source_hash`, `line_or_section_reference`.
Can be exported as evidence for verification.

### Evidence Pack
A structured collection of verifiable claims with source attribution.
Generated from Knowledge Packs or produced by workers.
Every claim must have a source — no unsourced statements in prompts.

### Task Graph
The decomposition engine converts a requirement into a structured graph:
- **Nodes**: individual tasks with risk levels (P0-P3), effort estimates, types
- **Edges**: dependencies between tasks
- **Assignments**: which worker handles which task

### Worker Capsule
A self-contained assignment for one worker. Contains:
- Assigned task IDs and descriptions
- **Allowed files** — what the worker may modify
- **Forbidden files** — what the worker MUST NOT touch
- Required output artifacts
- Completion criteria
- Forbidden actions (e.g., cannot self-approve, cannot touch other workers' files)

### Handoff
When a worker completes (or is blocked), they produce a handoff JSON:
- Status: COMPLETED / PARTIAL / BLOCKED / FAILED
- Files changed
- Artifacts produced
- Test results
- Blockers and assumptions
- Handoff notes for the integrator

**Placeholder handoffs are rejected.** Only real worker outputs pass validation.

### Artifact
A verifiable output from a task. Must be non-empty and traceable.
Examples: source files, test results, API specs, verification reports.
**No artifact = no PASS — always.**

### Integrator
The agent (or human) that collects all worker handoffs and checks:
- All workers have handed off
- No boundary violations
- All required artifacts present
- No unresolved blockers
- Ready for integration

### Execution Receipt
The final signed record of a run:
- Tasks completed / blocked
- Artifacts collected
- Test results
- Validation and integration status
- Final status (honest — not auto-promoted to VERIFIED)

---

## Legacy V4 User Workflows

### Run the Demos
```powershell
# 1. Decompose the admin-system demo
pwsh runtime/task-decomposition-engine.ps1 `
  -Requirement examples/task-decomposition/admin-system-requirement.md `
  -OutputDir outputs/my-admin-system

# 2. Start a run
pwsh runtime/agent-execution-runtime.ps1 -Command start -PlanDir outputs/my-admin-system

# 3. Explore the output
#    - worker-capsules/ — see what each worker should do
#    - execution-run.json — run metadata
```

### Onboard an Existing Project
```powershell
# 1. Run the onboarding wizard
pwsh runtime/project-onboarding-wizard.ps1

# 2. Import your project's docs as knowledge
pwsh runtime/knowledge-pack-manager.ps1 -Command add -Name my-project -Source ./docs

# 3. Create a skill pack for your project type
pwsh runtime/skill-pack-manager.ps1 -Command create-template -Name my-project-type
```

### Plan a New Project
```powershell
# 1. Write your requirement
#    (Create requirement.md describing what you need)

# 2. Decompose
pwsh runtime/task-decomposition-engine.ps1 -Requirement requirement.md

# 3. Review the task graph, risk classification, and worker plan
#    Adjust before proceeding to execution
```

### Cross-Window Multi-Worker Execution (manual compatibility only)
```powershell
# 1. Start a run
pwsh runtime/agent-execution-runtime.ps1 -Command start -PlanDir outputs/my-project

# 2. Generate handoff templates
pwsh runtime/agent-execution-runtime.ps1 -Command create-handoff-template -RunId <run-id> -WorkerId worker-backend
pwsh runtime/agent-execution-runtime.ps1 -Command create-handoff-template -RunId <run-id> -WorkerId worker-frontend
pwsh runtime/agent-execution-runtime.ps1 -Command create-handoff-template -RunId <run-id> -WorkerId worker-qa

# 3. Open 3 separate Codex windows
#    Paste each worker's prompt (from outputs/V4_4/live-cross-window-kit/)

# 4. Collect and verify
pwsh runtime/agent-execution-runtime.ps1 -Command validate-live-handoff -RunId <run-id>
pwsh runtime/agent-execution-runtime.ps1 -Command collect-artifacts -RunId <run-id>
pwsh runtime/agent-execution-runtime.ps1 -Command validate -RunId <run-id>
pwsh runtime/agent-execution-runtime.ps1 -Command integrate -RunId <run-id>
pwsh runtime/agent-execution-runtime.ps1 -Command close -RunId <run-id>
```

### Knowledge-Enhanced Work
```powershell
# 1. Import your knowledge
pwsh runtime/knowledge-pack-manager.ps1 -Command add -Name company-standards -Source ./internal-docs

# 2. Index and build evidence
pwsh runtime/knowledge-pack-manager.ps1 -Command index -Name company-standards
pwsh runtime/knowledge-pack-manager.ps1 -Command build-evidence -Name company-standards

# 3. The knowledge will be referenced (with source attribution) during task decomposition
#    and worker execution
```

### Create Custom Skill Packs
```powershell
# 1. Create template
pwsh runtime/skill-pack-manager.ps1 -Command create-template -Name my-pack -OutputDir packs/my-pack

# 2. Edit packs/my-pack/rules.md, prompts.md, validation.md

# 3. Validate
pwsh runtime/skill-pack-manager.ps1 -Command validate -Name my-pack

# 4. Enable
pwsh runtime/skill-pack-manager.ps1 -Command enable -Name my-pack
```

---

## Safety Model

### No Artifact = No PASS
Every task must produce a verifiable, non-empty artifact.
Missing artifacts block validation. Placeholder outputs are rejected.
This is the **core safety rule** — cannot be bypassed.

### Worker Boundaries
Each worker capsule defines `allowed_files` and `forbidden_files`.
Workers cannot write outside their allowed directories or into other workers' territory.
**Boundary violations are detected at handoff validation and block integration.**

### Forbidden Files
Cross-worker patterns prevent workers from touching each other's code.
V4.4.1 refined this from keyword patterns (e.g., `src/*/auth*`) to cross-worker
directory boundaries (e.g., `src/worker-frontend/*`).

### Placeholder Rejection
Template handoffs with "FILL IN" or empty arrays are **automatically rejected**.
Only real worker outputs with actual files_changed, artifacts_produced, and
meaningful handoff_notes pass validation.

### GLM is Optional
You are never required to use GLM. If you use GPT, Claude, or have native
search tools in your Codex environment, set `search_provider=none` and you're done.
GLM is one option among many — DeepSeek users may find it useful.

### Local Knowledge Privacy
Knowledge Packs store your documents locally. They are **never uploaded**.
The `build-evidence` command adds source tracking but does not send data anywhere.
Your `.env` file (with API keys) is gitignored and never committed.

### Manual ≠ Autonomous
Codex Factory provides structure, boundaries, and verification.
It does NOT auto-complete projects. Workers still need to do the work.
Cross-window execution requires you to open separate Codex windows.
The agent-adapter mode (for automated dispatch) is NOT_CONFIGURED.

### Execution Receipts are Honest
The final receipt reflects actual collected evidence:
- `READY_FOR_MANUAL_WORKER_EXECUTION` — capsules created, waiting for workers
- `LIVE_CROSS_WINDOW_VERIFIED` — all workers completed, all artifacts present
- `LIVE_CROSS_WINDOW_BLOCKED` — issues found, cannot proceed
- Never auto-promoted to VERIFIED without evidence
