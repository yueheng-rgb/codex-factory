# Real Cross-Window Live Test (V4.4)

## What It Is

V4.4 verifies that Codex Factory's worker capsules can be distributed to
real, independent Codex windows for parallel task execution. Unlike V4.3's
simulation (single-repo, convention-based isolation), V4.4 tests true
cross-window isolation.

## Simulation vs. Live Test

| Aspect | V4.3 Simulation | V4.4 Live Test |
|--------|----------------|----------------|
| Workers | Simulated in same repo | Real separate Codex windows |
| Isolation | Convention-based | True process/window isolation |
| Context | Shared project history | Each worker sees only its prompt |
| Verification | Simulated artifacts | Real worker-produced outputs |
| Classification | CROSS_WINDOW_SIMULATION_VERIFIED | LIVE_CROSS_WINDOW_VERIFIED |

## How to Run

### 1. Prepare
Read `outputs/V4_4/live-cross-window-kit/MAIN_CONTROLLER_INSTRUCTIONS.md`

### 2. Open 3 Windows
Open 3 NEW Codex windows. Each gets exactly ONE worker prompt.

### 3. Distribute Prompts
- Window A → `WORKER_1_BACKEND_PROMPT.md`
- Window B → `WORKER_2_FRONTEND_PROMPT.md`
- Window C → `WORKER_3_TEST_VALIDATION_PROMPT.md`

### 4. Collect Handoffs
When each worker finishes, save their `worker-handoff.json` to:
```
runs/v44-live-cross-window/live-handoffs/
```

### 5. Validate
```powershell
powershell -File runtime/agent-execution-runtime.ps1 -Command validate-live-handoff -RunId v44-live-cross-window
powershell -File runtime/agent-execution-runtime.ps1 -Command summarize-live-run -RunId v44-live-cross-window
```

## Avoiding Context Pollution
- Do NOT paste full project history into worker windows
- Do NOT paste other workers' prompts
- Each worker should ONLY see their own WORKER_PROMPT.md
- Workers must NOT read each other's outputs

## Dry Run
The dry run creates placeholder handoffs and confirms they are REJECTED.
This ensures the validation pipeline does not accept templates as real work.

## Acceptance
- LIVE_CROSS_WINDOW_VERIFIED: 3/3 workers produced real, validated handoffs
- LIVE_CROSS_WINDOW_PARTIAL: Some workers completed, some blocked
- LIVE_CROSS_WINDOW_BLOCKED: All rejected or placeholders
