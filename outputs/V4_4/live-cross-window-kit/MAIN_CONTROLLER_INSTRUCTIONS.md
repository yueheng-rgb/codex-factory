# Main Controller Instructions — V4.4 Real Cross-Window Live Test

## Your Role
You are the **Main Controller / Integrator** for a real cross-window Codex test.
You coordinate 3 independent worker Codex windows and verify their outputs.

## What You Do (Step by Step)

### Step 1: Open 3 Separate Codex Windows
Open 3 NEW Codex windows (or conversations) — one for each worker:
- **Window A**: Backend Worker
- **Window B**: Frontend Worker
- **Window C**: Test & Validation Worker

### Step 2: Distribute Worker Prompts
Copy EXACTLY the following prompts to the corresponding windows:
- Window A → paste `WORKER_1_BACKEND_PROMPT.md` (this kit)
- Window B → paste `WORKER_2_FRONTEND_PROMPT.md` (this kit)
- Window C → paste `WORKER_3_TEST_VALIDATION_PROMPT.md` (this kit)

**CRITICAL**: 
- Do NOT paste the full project history into worker windows
- Do NOT paste other workers' prompts
- Each worker should ONLY see its own prompt

### Step 3: Wait for Workers
Each worker will produce:
- `worker-handoff.json` (their handoff file)
- A list of artifacts they produced
- A summary of what they did

### Step 4: Collect Handoffs
When a worker finishes, copy their `worker-handoff.json` output and
save it to: `runs/v44-live-cross-window/live-handoffs/<worker-id>-handoff.json`

### Step 5: Validate
After all 3 workers return (or if any are BLOCKED):
```powershell
powershell -File runtime/agent-execution-runtime.ps1 -Command import-live-handoff -RunId runs/v44-live-cross-window
powershell -File runtime/agent-execution-runtime.ps1 -Command validate-live-handoff -RunId runs/v44-live-cross-window
powershell -File runtime/agent-execution-runtime.ps1 -Command summarize-live-run -RunId runs/v44-live-cross-window
```

### Step 6: Report
Tell me (the user/auditor) the final status:
- Which workers completed?
- Which artifacts were produced?
- Any boundary violations?
- Final classification: LIVE_CROSS_WINDOW_VERIFIED or LIVE_CROSS_WINDOW_BLOCKED or LIVE_CROSS_WINDOW_PARTIAL

## Rules
- Never claim PASS for a missing artifact
- Never accept a BLOCKED worker as completed
- Never ignore a boundary violation
- Placeholder handoffs are NOT valid handoffs
- V3.4.2 strict remote verification remains the authoritative evidence
